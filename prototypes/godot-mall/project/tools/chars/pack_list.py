#!/usr/bin/env python3
"""B2 (design/godot-character-editor.md): which character files each wing / year pack ships.

models/ubc/ holds every body, hair and piece (~54 MB; int-52, Nov 5 2026: the Quaternius UBC bodies replaced
the MakeHuman B1 bodies of models/characters/, which are gone; design/godot-ubc-characters.md). The wing packs ship none of it (wing 2
is ~96 MB already): the character files ship as shared packs (split() below), fetched and mounted by
scripts/chars/char_pack.gd once the mall is running. A character pack ships only:
  - the presets that map uses: data/story/attendants.json (wing, years, "look": "preset") and
    scripts/npcs.json "presets" (shoppers, every interior wing, both years), their bodies and pieces;
  - the player's wardrobe, data/characters/_wardrobe.json (the avatar creator, every pack);
  - the clothed defaults (a tee and jeans) for every body it ships (the clothed rule, B-FIX);
  - the textures those .gltf files reference (and the skin wrinkle map and piece patterns when the
    manifest has them; UBC has neither).
The game copes with a missing piece (scripts/chars/char_preset.gd offers only pieces in the pack).

    python3 tools/chars/pack_list.py                  # print the lists and sizes

Run from the project folder. CHARS (Nov 3 2026): the packs are exported by tools/shared_packs.py
(called from tools/export_web.sh) as "chars" (what every map needs, one pack for the whole mall)
plus "chars_<map>" (only the pieces that map's presets add), see split().
"""
import json
import os
import struct

ROOT = os.getcwd()
MC = "models/ubc"           # int-52: the UBC kit (was models/characters, MakeHuman)
FEATURE = {"wing1": (1, 1995), "wing2": (2, 1995), "wing3": (3, 1995),
           "w1y26": (1, 2026), "w2y26": (2, 2026), "w3y26": (3, 2026),
           # CHARS (Nov 3): the room wings (design/godot-wings.md "Wings 4-6") have the avatar too
           "wing4": (4, 1995), "wing5": (5, 1995), "wing6": (6, 1995),
           "w4y26": (4, 2026), "w5y26": (5, 2026), "w6y26": (6, 2026)}


def map_name(feat):
    """the pack-style map name: wing1 -> w1, w1y26 -> w1y26"""
    return feat.replace("wing", "w")


def load(p):
    return json.load(open(os.path.join(ROOT, p)))


MAN = load(MC + "/ubc.json")


def entry(sex, base_id):
    base_id = MAN.get("aliases", {}).get(base_id, base_id)   # UBC: B1 ids -> the closest UBC piece (char_preset.gd)
    for e in MAN["pieces"]:
        if e["body"] == sex and (e["base_id"] == base_id or e["id"] == base_id):
            return e
    return None


def glb_images(path):
    """the image files a .glb or a .gltf references (a .gltf's .bin buffers are not shipped: Godot's
    import holds the meshes)"""
    if path.endswith(".gltf"):
        j = json.load(open(path))
        return [i["uri"] for i in j.get("images", []) if "uri" in i]
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
    if MAN.get("wrinkle", True) and os.path.exists(os.path.join(ROOT, MC, "skin_wrinkle.png")):
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


def split(pl=None):
    """CHARS (Nov 3, design/godot-build-hosting.md "Shared packs"): the character files as shared packs.
    "chars": what every map needs (both bodies, the wardrobe and clothed defaults, their maps), one
    pack for the whole mall. "chars_<map>": only the pieces that map's presets wear on top of that
    (exported only when there are any). Returns {name: {"files": [...], "maps": [map names]}}."""
    pl = pl or plan()
    common = None
    for e in pl.values():
        s = set(e["files"] + e["tex"])
        common = s if common is None else common & s
    W = wardrobe()
    ids = {s: list(v) + CLOTHED_DEFAULT for s, v in W.items()}
    f, t = files_for(sorted(W.keys()), ids)
    base = set(f + t)
    common = sorted(base | (common or set()))
    out = {"chars": {"files": common, "maps": [map_name(k) for k in FEATURE]}}
    for feat, e in pl.items():
        extra = sorted(set(e["files"] + e["tex"]) - set(common))
        if extra:
            out["chars_" + map_name(feat)] = {"files": extra, "maps": [map_name(feat)], "presets": e["presets"]}
    return out


def size(paths):
    return sum(os.path.getsize(os.path.join(ROOT, p)) for p in paths)


if __name__ == "__main__":
    pl = plan()
    every = [os.path.join(MC, f) for f in os.listdir(os.path.join(ROOT, MC)) if not f.endswith(".import")]
    print(MC + "/ all files: %.1f MB" % (size(every) / 1e6))
    for feat, e in pl.items():
        print("%-6s presets %-34s %3d glb + %2d textures = %5.1f MB (source files)" % (
            feat, ",".join(e["presets"]) or "-", len(e["files"]), len(e["tex"]), size(e["files"] + e["tex"]) / 1e6))
    print("as shared packs (tools/shared_packs.py):")
    for n, e in split(pl).items():
        print("  %-12s %3d files = %5.1f MB (source files), maps %s" % (n, len(e["files"]), size(e["files"]) / 1e6, " ".join(e["maps"])))
