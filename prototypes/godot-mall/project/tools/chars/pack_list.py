#!/usr/bin/env python3
"""B2 (design/godot-character-editor.md): which character files each wing / year pack ships.

models/characters/ holds every body, hair and piece (~76 MB). The wing packs ship none of it (wing 2
is ~96 MB already): each map gets its own character pack, chars_<map>.<desktop|mobile>.pck, fetched
and mounted by scripts/chars/char_pack.gd at start. A character pack ships only:
  - the presets that map uses: data/story/attendants.json (wing, years, "look": "preset") and
    scripts/npcs.json "presets" (shoppers, every interior wing, both years), their bodies and pieces;
  - the player's wardrobe, data/characters/_wardrobe.json (the avatar creator, every pack);
  - the clothed defaults (a tee and jeans) for every body it ships (the clothed rule, B-FIX);
  - the textures those .glb files reference, the skin wrinkle map, the piece patterns.
The game copes with a missing piece (scripts/chars/char_preset.gd offers only pieces in the pack).

    python3 tools/chars/pack_list.py                  # print the lists and sizes
    python3 tools/chars/pack_list.py --preset=wing2   # point the two "Characters" export presets at
                                                      # wing 2 (1995)'s files (tools/chars/export_chars.sh)

Run from the project folder. Only the two "Characters" presets' export_files change.
"""
import json
import os
import re
import struct
import sys

ROOT = os.getcwd()
MC = "models/characters"
FEATURE = {"wing1": (1, 1995), "wing2": (2, 1995), "wing3": (3, 1995),
           "w1y26": (1, 2026), "w2y26": (2, 2026), "w3y26": (3, 2026)}


def load(p):
    return json.load(open(os.path.join(ROOT, p)))


MAN = load(MC + "/characters.json")


def entry(sex, base_id):
    for e in MAN["pieces"]:
        if e["body"] == sex and (e["base_id"] == base_id or e["id"] == base_id):
            return e
    return None


def glb_images(path):
    b = open(path, "rb").read()
    n = struct.unpack("<I", b[12:16])[0]
    j = json.loads(b[20:20 + n])
    return [i["uri"] for i in j.get("images", []) if "uri" in i]


# the clothed rule's defaults (scripts/char_body.gd CLOTHED_DEFAULT, first of each): every pack ships
# them for every body it ships, so a body missing a top or a bottom is always dressed (B-FIX).
CLOTHED_DEFAULT = ["top_tee", "bot_jeans"]


def preset_ids(p):
    """the base ids a preset wears (as char_preset.gd worn(); no base layer since B-FIX)"""
    o = p.get("outfit", {})
    ids = [o.get(k, "") for k in ("under", "top", "bottom", "full", "outer", "shoes")]
    ids += list(o.get("extras", []))
    ids.append((p.get("hair") or {}).get("id", ""))
    return [i for i in ids if i and not i.startswith("base_")]


def files_for(sexes, ids_by_sex):
    files = set()
    for s in sexes:
        files.add(MAN["bodies"][s]["glb"].replace("res://", ""))
    for s, ids in ids_by_sex.items():
        for i in ids:
            e = entry(s, i)
            if e and not e["slot"].startswith("base_"):
                files.add(e["glb"].replace("res://", ""))
    tex = set()
    for f in list(files):
        for u in glb_images(os.path.join(ROOT, f)):
            tex.add(MC + "/" + u)
    tex.add(MC + "/skin_wrinkle.png")
    for e in MAN["pieces"]:
        if e.get("patterns") and e["glb"].replace("res://", "") in files:
            for pn in (MAN.get("patterns") or ["solid", "stripes", "dots", "floral", "check"]):
                tex.add(MC + "/pattern_%s.png" % pn)
            break
    return sorted(files), sorted(tex)


def wardrobe():
    w = load("data/characters/_wardrobe.json")
    out = {}
    for s in w.get("bodies", ["female", "male"]):
        ids = []
        for it in w["pieces"]:
            if it.startswith("all:"):
                ids += [e["base_id"] for e in MAN["pieces"] if e["body"] == s and e["slot"] == it[4:]]
            else:
                ids.append(it)
        out[s] = ids
    return out


def plan():
    atts = load("data/story/attendants.json")["attendants"]
    npc = load("scripts/npcs.json").get("presets", {})
    presets = {}
    d = os.path.join(ROOT, "data/characters")
    for f in os.listdir(d):
        if f.endswith(".json") and not f.startswith("_"):
            presets[f[:-5]] = json.load(open(os.path.join(d, f)))
    W = wardrobe()
    out = {}
    for feat, (wing, year) in FEATURE.items():
        used = []
        for a in atts:
            if a.get("look") == "preset" and int(a.get("wing", 0)) == wing and year in a.get("years", []):
                used.append(a.get("preset"))
        if wing in (1, 2):
            used += [v for v in npc.values() if v]
        ids = {s: list(v) + CLOTHED_DEFAULT for s, v in W.items()}
        sexes = set(W.keys())
        for pid in used:
            p = presets.get(pid)
            if not p:
                continue
            s = p.get("body", "female")
            sexes.add(s)
            ids.setdefault(s, list(CLOTHED_DEFAULT))
            ids[s] += preset_ids(p)
        f, t = files_for(sorted(sexes), ids)
        out[feat] = {"presets": sorted(set(used)), "files": f, "tex": t}
    return out


def size(paths):
    return sum(os.path.getsize(os.path.join(ROOT, p)) for p in paths)


def write(pl, feat):
    """put the map's character files into the "Characters Desktop" / "Characters Mobile" presets
    (export-pack only, export_filter "resources": Godot adds each file's dependencies)."""
    path = os.path.join(ROOT, "export_presets.cfg")
    s = open(path).read()
    e = pl[feat]
    files = ",".join('"res://%s"' % f for f in e["files"] + e["tex"])
    parts = re.split(r"(?m)^(?=\[preset\.\d+\]$)", s)
    done = 0
    for i, part in enumerate(parts):
        if re.search(r'(?m)^name="Characters (Desktop|Mobile)"$', part):
            parts[i] = re.sub(r"(?m)^export_files=PackedStringArray\([^)]*\)$", "export_files=PackedStringArray(%s)" % files, part, count=1)
            done += 1
    if done != 2:
        raise SystemExit("export_presets.cfg: the two Characters presets are missing")
    open(path, "w").write("".join(parts))
    print("Characters presets now list %s: %d files" % (feat, len(e["files"]) + len(e["tex"])))


if __name__ == "__main__":
    pl = plan()
    every = [os.path.join(MC, f) for f in os.listdir(os.path.join(ROOT, MC)) if not f.endswith(".import")]
    print("models/characters/ all files: %.1f MB" % (size(every) / 1e6))
    for feat, e in pl.items():
        print("%-6s presets %-34s %3d glb + %2d textures = %5.1f MB (source files)" % (
            feat, ",".join(e["presets"]) or "-", len(e["files"]), len(e["tex"]), size(e["files"] + e["tex"]) / 1e6))
    for a in sys.argv[1:]:
        if a.startswith("--preset="):
            write(pl, a.split("=", 1)[1])
