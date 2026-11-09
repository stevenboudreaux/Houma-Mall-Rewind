#!/usr/bin/env python3
"""Unions the room wings' export presets into export_presets.cfg (workstream S, Nov 2 2026;
design/godot-wings.md "Wings 4-6", design/godot-build-hosting.md).

usage: python3 tools/make_presets.py        (from the project folder; idempotent)

For each room wing (4 = Sears / Lynn's, 5 = Dillard's level 1, 6 = the Southland Cinema lobby) and
year (1995, 2026) it writes the preset pair "Wing <n> Desktop" / "Wing <n> Mobile" (2026:
"Wing <n> Desktop 2026" / "... Mobile 2026"), cloned from the matching "Wing 1" preset (its options,
the shell, the texture-format switch) with this wing's scene, custom feature (wing<n> / w<n>y26,
project.godot run/main_scene.<feature>) and filters. Presets with those names are replaced, every
other preset is kept as it is, apart from two small additions to the mall wings' filters (below), and
the sections are renumbered in order. Never edit these presets by hand: edit ROOMS here and re-run.

CHARS (Nov 3 2026, design/godot-build-hosting.md "Shared packs"): it also writes the pair "Shared Desktop" /
"Shared Mobile" (export-pack only; tools/shared_packs.py points them at one shared pack at a time), and
every wing preset leaves out the shared packs' files (tools/shared_packs.py WING_EXCLUDES: the Blender
items models/bl_*, the character models and maps); includes of models/bl_* are dropped.

The additions to the existing presets (also idempotent):
  - wings 1 and 2 (both years) include the anchor's picture in their opening, loaded by path for the
    day lighting (tex/standin/[y26_]from_w4_*.png in wing 1, from_w5 in wing 2);
  - every existing preset excludes the room wings' generated data and lightmaps (gen/w4*/ ...,
    wing4* ...), which "*.json" and the lightmap names would otherwise pull in.
"""
import re
import sys

CFG = "export_presets.cfg"
# CHARS (Nov 3 2026): files that ship in the shared packs, never in a wing pack (tools/shared_packs.py)
# PRIZES (Nov 3 2026): the prize counters' pictures (prizes/*) moved into the items pack: both years' counters use them
SHARED_EXCLUDES = ["models/bl_*", "models/characters/*.glb", "models/characters/*.png", "models/ubc/*.gltf", "models/ubc/*.bin", "models/ubc/*.png", "prizes/*"]
SHARED_NAMES = ("Shared Desktop", "Shared Mobile")
ROOMS = {4: {"mall": 1, "pics": True}, 5: {"mall": 2, "pics": True}, 6: {"mall": 1, "pics": False}}
ALL = [1, 2, 3, 4, 5, 6]


def gens_except(own):
    out = []
    for w in ALL:
        for y in ("", "y26"):
            g = "gen/w%d%s/*" % (w, y)
            if "w%d%s" % (w, y) != own:
                out.append(g)
    return out


def filters(w, year):
    R = ROOMS[w]
    inc_all = ["addons/dialogue_manager/*", "data/story/*"]     # INT (Demo 49): Q's story machinery runs in every wing
    if year == 1995:
        inc = ["*.json", "fonts/*", "scripts/*", "npc/anims.res", "npc/skins/Ch*", "npc/skins/Remy*", "gen/env_*.tres",
               "tex/int_side.png", "tex/pc/video_marquees_blank.png", "tex/kb/dept_blank.png",
               "wing%d_day.lmbake" % w, "wing%d_day.exr" % w, "tex/items/*", "tex/dir/*", "items/*"]   # the stick (models/bl_sr_folse_*) is in the shared items pack (CHARS)
        if R["pics"]:
            inc += ["tex/standin/from_w1_*.png", "tex/standin/from_w2_*.png"]
        # the avatar's bodies (design/godot-avatar.md) as the outside ships them: minus the three it
        # doesn't offer; no shoppers walk the room wings
        exc = ["tools/*", "web/*", "*.md", "npc/skins/Character_*", "npc/skins/Ch06*", "npc/skins/Ch17*", "npc/skins/Ch36*",
               "npc_src/*", "prizes/*", "tex/fronts/*", "fronts.json"]
        exc += gens_except("w%d" % w)
        exc += ["wing%d*" % o for o in ALL if o != w] + ["wing%d_2026*" % w, "main*", "layout_2026.json", "data/eras_2026.json",
                                                         "tex/standin/y26_*", "tex/standin/door_*"]
        exc += ["tex/standin/*"] if not R["pics"] else ["tex/standin/from_w4_*", "tex/standin/from_w5_*"]
    else:
        inc = ["*.json", "fonts/*", "scripts/*", "gen/env_*.tres", "tex/int_side.png", "tex/pc/video_marquees_blank.png",
               "tex/kb/dept_blank.png", "wing%d_2026_day.lmbake" % w, "wing%d_2026_day.exr" % w, "tex/items/*", "tex/dir/*",
               "npc/anims.res", "npc/skins/Ch*", "npc/skins/Remy*", "items/*"]   # the stick (models/bl_sr_folse_*) is in the shared items pack (CHARS)
        if R["pics"]:
            inc += ["tex/standin/y26_from_w1_*.png", "tex/standin/y26_from_w2_*.png"]
        # INT (Demo 49): M's 2026 shoppers walk every 2026 wing, so the skins ship as in wings 1-2 2026
        exc = ["tools/*", "web/*", "*.md", "npc/skins/Character_*", "npc/skins/Ch06*", "npc/skins/Ch17*", "npc/skins/Ch36*",
               "npc_src/*", "prizes/*", "tex/fronts/*", "fronts.json"]
        exc += gens_except("w%dy26" % w)
        exc += ["wing%d*" % o for o in ALL if o != w] + ["wing%d.tscn" % w, "wing%d_day*" % w, "wing%d_night*" % w, "main*",
                                                         "tex/standin/from_*", "tex/standin/door_*", "tex/standin/y26_door_*"]
        exc += ["tex/standin/*"] if not R["pics"] else ["tex/standin/y26_from_w4_*", "tex/standin/y26_from_w5_*"]
    return ",".join(inc_all + inc), ",".join(exc)


def parse(text):
    """[(header, [lines])] for every [section], in order; the header without brackets."""
    secs = []
    cur = None
    for line in text.splitlines():
        m = re.match(r"^\[(.+)\]$", line)
        if m:
            cur = (m.group(1), [])
            secs.append(cur)
        elif cur is not None:
            cur[1].append(line)
    return secs


def presets(secs):
    """[{name, main: [lines], options: [lines]}] in file order."""
    out = []
    for h, body in secs:
        if re.match(r"^preset\.\d+$", h):
            name = next((l.split("=", 1)[1].strip('"') for l in body if l.startswith("name=")), "")
            out.append({"name": name, "main": body, "options": []})
        elif re.match(r"^preset\.\d+\.options$", h):
            out[-1]["options"] = body
    return out


def setkey(lines, key, value):
    return [(key + "=" + value) if l.startswith(key + "=") else l for l in lines]


def getkey(lines, key):
    for l in lines:
        if l.startswith(key + "="):
            return l.split("=", 1)[1]
    return None


def drop_items(lines, key, pred):
    v = getkey(lines, key)
    if v is None:
        return lines
    cur = [x for x in (v.strip('"').split(",") if v.strip('"') else []) if not pred(x)]
    return setkey(lines, key, '"' + ",".join(cur) + '"')


def add_items(lines, key, items):
    v = getkey(lines, key)
    if v is None:
        return lines
    cur = v.strip('"').split(",") if v.strip('"') else []
    for it in items:
        if it not in cur:
            cur.append(it)
    return setkey(lines, key, '"' + ",".join(cur) + '"')


def main():
    P = presets(parse(open(CFG).read()))
    names = {}
    new = []
    for w in ROOMS:
        for year in (1995, 2026):
            for kind in ("Desktop", "Mobile"):
                tname = "Wing 1 %s%s" % (kind, " 2026" if year == 2026 else "")
                tpl = next((p for p in P if p["name"] == tname), None)
                if tpl is None:
                    sys.exit("no template preset " + tname)
                name = "Wing %d %s%s" % (w, kind, " 2026" if year == 2026 else "")
                feat = ("w%dy26" % w) if year == 2026 else ("wing%d" % w)
                scene = ("res://wing%d_2026.tscn" % w) if year == 2026 else ("res://wing%d.tscn" % w)
                inc, exc = filters(w, year)
                main_l = list(tpl["main"])
                main_l = setkey(main_l, "name", '"%s"' % name)
                main_l = setkey(main_l, "custom_features", '"%s"' % feat)
                main_l = setkey(main_l, "export_files", 'PackedStringArray("%s")' % scene)
                main_l = setkey(main_l, "include_filter", '"%s"' % inc)
                main_l = setkey(main_l, "exclude_filter", '"%s"' % exc)
                new.append({"name": name, "main": main_l, "options": list(tpl["options"])})
                names[name] = True
    # CHARS: the two Shared presets (export-pack only), cloned from Wing 1's pair for their options
    for kind in ("Desktop", "Mobile"):
        tpl = next((p for p in P if p["name"] == "Wing 1 %s" % kind), None)
        old = next((p for p in P if p["name"] == "Shared %s" % kind), None)
        main_l = list(tpl["main"])
        main_l = setkey(main_l, "name", '"Shared %s"' % kind)
        main_l = setkey(main_l, "custom_features", '""')
        main_l = setkey(main_l, "export_filter", '"resources"')
        # keep the file list tools/shared_packs.py last wrote
        files = getkey(old["main"], "export_files") if old else "PackedStringArray()"
        main_l = setkey(main_l, "export_files", files)
        main_l = setkey(main_l, "include_filter", '""')
        main_l = setkey(main_l, "exclude_filter", '"scripts/*,*.gd,*.json,data/*,tools/*,web/*,*.md"')
        main_l = setkey(main_l, "export_path", '""')
        new.append({"name": "Shared %s" % kind, "main": main_l, "options": list(tpl["options"])})
        names["Shared %s" % kind] = True
    keep = [p for p in P if p["name"] not in names]
    # the additions to the existing presets
    room_ex = []
    for w in ROOMS:
        room_ex += ["gen/w%d/*" % w, "gen/w%dy26/*" % w, "wing%d*" % w]
    for p in keep:
        n = p["name"]
        if n.startswith("Wing 1") or n.startswith("Wing 2"):
            mw = 1 if n.startswith("Wing 1") else 2
            pic = "tex/standin/%sfrom_w%d_*.png" % ("y26_" if n.endswith("2026") else "", 4 if mw == 1 else 5)
            p["main"] = add_items(p["main"], "include_filter", [pic])
        p["main"] = add_items(p["main"], "exclude_filter", room_ex)
        # PACKS (Nov 8 2026): the 2026 outside had no pocket-item icons (tex/items/*) though its item scenes name
        # them (tools/qa/packcontents.py refs); every other map ships them
        if n.startswith("Wing 3") and n.endswith("2026"):
            p["main"] = add_items(p["main"], "include_filter", ["tex/items/*"])
    # CHARS: no wing pack carries the shared packs' files
    for p in keep + new:
        if p["name"].startswith("Wing "):
            p["main"] = drop_items(p["main"], "include_filter", lambda x: x.startswith("models/bl_") or x.startswith("prizes/"))
            p["main"] = add_items(p["main"], "exclude_filter", SHARED_EXCLUDES)
    out = []
    for i, p in enumerate(keep + new):
        out.append("[preset.%d]" % i)
        out += p["main"]
        out.append("[preset.%d.options]" % i)
        out += p["options"]
    text = "\n".join(out)
    if not text.endswith("\n"):
        text += "\n"
    open(CFG, "w").write(text)
    print("export_presets.cfg: %d presets (%d room-wing presets written)" % (len(keep) + len(new), len(new)))


if __name__ == "__main__":
    main()
