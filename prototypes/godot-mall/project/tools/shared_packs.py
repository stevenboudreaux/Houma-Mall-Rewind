#!/usr/bin/env python3
"""Shared packs: files that ship once for the whole mall instead of inside every wing pack
(workstream CHARS, Nov 3 2026; design/godot-build-hosting.md "Shared packs").

Why: a wing pack must stay under GitHub's 100 MB file limit (wing 1 was 98.6 MB at Demo 49) and every
wing pack and its 2026 twin carried its own copy of the Blender items. Now:
  - "items"          every models/bl_* folder (food, drinks, books, toys, fixtures from Blender), and since
                     PRIZES (Nov 3) the prize counters' pictures prizes/* (both years' counters and the
                     prize items use them):
                     downloaded with the wing pack, mounted before the wing's scene loads;
CHAR-STRIP (Nov 8 2026, design/godot-avatar.md): the character packs ("chars", "chars_<map>", fetched once
the mall was running) are gone with the editor and models/ubc/. The cast's files (data/cast.json) ship in
every wing pack (tools/make_presets.py CAST) and are loaded behind the loading card.
The list of packs is tools/shared_packs.json. Each pack is <name>.desktop.pck and
<name>.mobile.pck, exported by tools/export_web.sh through the presets "Shared Desktop" / "Shared Mobile"
(tools/make_presets.py), cached by the page like the wing packs (web/shell.html SHARED_PACKS) and mounted
by scripts/shared_packs.gd (autoload SharedPacks). Every wing preset excludes these files.

    python3 tools/shared_packs.py                       # the packs, their files and source sizes
    python3 tools/shared_packs.py --names               # one pack name per line (export order)
    python3 tools/shared_packs.py --write=<name>        # point the two "Shared" presets at that pack
    python3 tools/shared_packs.py --excludes            # the wing presets' exclude patterns
    python3 tools/shared_packs.py --shell=<outdir>      # the SHARED_PACKS line for index.html (sizes
                                                        # from <outdir>/<name>.<kind>.pck; 0 = not exported)
Run from the project folder.
"""
import fnmatch
import json
import os
import re
import sys

ROOT = os.getcwd()
CFG = "export_presets.cfg"
ALL_MAPS = ["w1", "w2", "w3", "w1y26", "w2y26", "w3y26", "w4", "w5", "w6", "w4y26", "w5y26", "w6y26"]
SKIP_EXT = (".import", ".uid", ".md", ".py", ".blend", ".blend1")
# the patterns the wing presets exclude, so these files are only in the shared packs
WING_EXCLUDES = ["models/bl_*", "prizes/*"]   # prizes/*: PRIZES (Nov 3)


def project_files():
    out = []
    for d, dirs, files in os.walk(ROOT):
        rel = os.path.relpath(d, ROOT)
        if rel.startswith((".godot", ".scratch", "tools", "refs", ".git")):
            dirs[:] = []
            continue
        for f in files:
            if not f.endswith(SKIP_EXT):
                out.append(os.path.normpath(os.path.join(rel, f)).replace(os.sep, "/"))
    return sorted(out)


def packs():
    """[{name, files, maps, at}] in export order (tools/shared_packs.json)."""
    cfg = json.load(open(os.path.join(ROOT, "tools/shared_packs.json")))
    every = None
    out = []
    for p in cfg["packs"]:
        every = every or project_files()
        files = [f for f in every if any(fnmatch.fnmatch(f, g) or fnmatch.fnmatch(f, g.rstrip("*") + "*/*") for g in p["include"])]
        out.append({"name": p["name"], "files": files, "maps": p.get("maps", ALL_MAPS), "at": p.get("at", "start")})
    return out


def write(name):
    """the two "Shared" presets' export_files = this pack's files."""
    p = next((p for p in packs() if p["name"] == name), None)
    if p is None:
        sys.exit("no shared pack " + name)
    s = open(CFG).read()
    files = ",".join('"res://%s"' % f for f in p["files"])
    parts = re.split(r"(?m)^(?=\[preset\.\d+\]$)", s)
    done = 0
    for i, part in enumerate(parts):
        if re.search(r'(?m)^name="Shared (Desktop|Mobile)"$', part):
            parts[i] = re.sub(r"(?m)^export_files=PackedStringArray\([^)]*\)$", "export_files=PackedStringArray(%s)" % files, part, count=1)
            done += 1
    if done != 2:
        sys.exit("export_presets.cfg: the presets Shared Desktop / Shared Mobile are missing (python3 tools/make_presets.py)")
    open(CFG, "w").write("".join(parts))
    print("Shared presets now list %s: %d files" % (name, len(p["files"])))


def shell(outdir):
    """{name: {"desktop": bytes, "mobile": bytes, "at": ..., "maps": [...]}} for web/shell.html."""
    d = {}
    for p in packs():
        sz = {}
        for k in ("desktop", "mobile"):
            f = os.path.join(outdir, "%s.%s.pck" % (p["name"], k))
            sz[k] = os.path.getsize(f) if os.path.exists(f) else 0
        d[p["name"]] = {"desktop": sz["desktop"], "mobile": sz["mobile"], "at": p["at"],
                        "maps": "all" if sorted(p["maps"]) == sorted(ALL_MAPS) else p["maps"]}
    return "const SHARED_PACKS = %s; // SHARED_PACKS" % json.dumps(d, separators=(", ", ": "))


def size(paths):
    return sum(os.path.getsize(os.path.join(ROOT, f)) for f in paths)


if __name__ == "__main__":
    args = sys.argv[1:]
    if "--names" in args:
        print("\n".join(p["name"] for p in packs()))
    elif "--excludes" in args:
        print(",".join(WING_EXCLUDES))
    elif any(a.startswith("--write=") for a in args):
        write(next(a for a in args if a.startswith("--write=")).split("=", 1)[1])
    elif any(a.startswith("--shell=") for a in args):
        print(shell(next(a for a in args if a.startswith("--shell=")).split("=", 1)[1]))
    else:
        for p in packs():
            print("%-10s %-5s %4d files %6.1f MB (source)  maps: %s" % (
                p["name"], p["at"], len(p["files"]), size(p["files"]) / 1e6,
                "all" if p["maps"] == ALL_MAPS else " ".join(p["maps"])))
