"""What is inside the web packs: list them, check every reference is shipped, compare with the checked-in list.

Workstream PACKS (Nov 8 2026). Demo 52 shipped wing packs without 81 of the generated meshes their scenes use
(store signs, 3D letters, shop stock, Sears' and Dillard's outside faces): stale UIDs in the wing scenes made the
export's dependency walk skip them (tools/fix_stale_uids.gd). Every pack was on R2 at the right size, so no
size or upload check could see it. This looks inside. design/godot-build-hosting.md "Pack contents".

Usage (from the project folder):
  python3 tools/qa/packcontents.py list <a.pck>                 the files inside one pack (size, path)
  python3 tools/qa/packcontents.py check <export dir>           refs + manifest; exit 1 on any difference
  python3 tools/qa/packcontents.py refs <export dir>            only the reference check
  python3 tools/qa/packcontents.py write <export dir>           rewrite tools/qa/pack_manifest/ from this export
                                                                 (refuses while the reference check fails)
The export dir is what tools/export_web.sh writes: index.html (PACK_SIZES, SHARED_PACKS) and the packs.

The manifest (tools/qa/pack_manifest/<pack>.txt) holds each pack's files by source path (`wing1.tscn`,
`gen/w1/dyn_cinf_sign.res`, `tex/sg/ch_name_face.png`): Godot's hashed `.godot/` copies, `.remap`/`.import`
stubs and compiled scripts are folded into the file they stand for, so a list only changes when content does.
Desktop and mobile must list the same files. A build that adds or drops files is refused until the list is
rewritten with `write` and the change is reviewed in the commit (the diff is the build's content change log).
"""
import json, os, re, struct, sys

HERE = os.path.dirname(os.path.abspath(__file__))
MANIFEST = os.path.join(HERE, "pack_manifest")
KINDS = ("desktop", "mobile")
# A wing pack name ("w1", "w2y26") -> its map key in SHARED_PACKS "maps".
WING_RE = re.compile(r"^w[1-6](y26)?$")


def read_dir(f):
    """[(path, offset, size)] of a Godot 4 .pck (format 2-4); f is an open binary file."""
    f.seek(0)
    h = f.read(112)
    magic, ver, _ma, _mi, _pa = struct.unpack_from("<4s4I", h, 0)
    if magic != b"GDPC":
        raise ValueError("not a Godot pack")
    if ver >= 3:
        flags, base, diro = struct.unpack_from("<IQQ", h, 20)
        if flags & 1:
            raise ValueError("encrypted pack directory")
        f.seek(diro)
        d = f.read()
        p = 0
    else:
        flags, base = struct.unpack_from("<IQ", h, 20)
        f.seek(0)
        d = f.read(64 << 20)
        p = 32 + 16 * 4
    if not flags & 2:
        base = 0
    n, = struct.unpack_from("<I", d, p)
    p += 4
    out = []
    for _ in range(n):
        ln, = struct.unpack_from("<I", d, p)
        p += 4
        path = d[p:p + ln].rstrip(b"\0").decode()
        p += ln
        off, size = struct.unpack_from("<QQ", d, p)
        p += 16 + 16 + 4  # offset, size, md5, flags
        out.append((path[6:] if path.startswith("res://") else path, base + off, size))
    return out


def source_path(p):
    """The project file a pack entry stands for, or None for Godot's own copies (.godot/, compiled scripts)."""
    # (.unwrap_cache: the importer's gitignored lightmap-unwrap cache, present or not depending on the machine)
    if p.startswith(".godot/") or p.endswith((".gdc", ".uid", ".unwrap_cache")):
        return None
    for suf in (".remap", ".import"):
        if p.endswith(suf):
            return p[:-len(suf)]
    return p


def contents(pck):
    """Sorted source paths shipped in a pack."""
    with open(pck, "rb") as f:
        return sorted({s for s in (source_path(p) for p, _o, _n in read_dir(f)) if s})


REF_RE = re.compile(rb"res://([A-Za-z0-9_./ -]+?\.[A-Za-z0-9]+)(?=[\x00\"'\s:]|$)")
SCANNED = (".scn", ".res", ".tres", ".tscn")
# References that are never needed in the game: the Dialogue Manager's editor view names its example files
# (addons/dialogue_manager/views/main_view.tscn; Demo 51 shipped without them too).
IGNORE_REFS = (r"^examples/[^/]+\.dialogue$",)


def references(pck):
    """{referenced source path: [pack entries that name it]} for every scene/resource inside the pack."""
    refs = {}
    with open(pck, "rb") as f:
        entries = read_dir(f)
        remap = {}
        for p, o, n in entries:  # x.tscn.remap -> the exported .scn that is really x.tscn
            if p.endswith(".remap"):
                f.seek(o)
                m = re.search(rb'path="res://([^"]+)"', f.read(n))
                if m:
                    remap[m.group(1).decode()] = p[:-6]
        for p, o, n in entries:
            if not p.endswith(SCANNED):
                continue
            f.seek(o)
            who = remap.get(p, p)
            for m in REF_RE.finditer(f.read(n)):
                r = m.group(1).decode()
                if r != who:
                    refs.setdefault(r, set()).add(who)
    return refs


def read_index(export):
    t = open(os.path.join(export, "index.html"), encoding="utf-8").read()
    wings = json.loads(re.search(r"const PACK_SIZES = (\{.*?\}); // PACK_SIZES", t).group(1))
    m = re.search(r"const SHARED_PACKS = (\{.*?\}); // SHARED_PACKS", t)
    shared = json.loads(m.group(1)) if m else {}
    wings = {k: v for k, v in wings.items() if v.get("desktop")}
    shared = {k: v for k, v in shared.items() if v.get("desktop")}
    return wings, shared


def check_refs(export, wings, shared, kind="mobile"):
    """Every res:// path named by a scene or resource in a wing pack must ship in that wing's pack or in a
    shared pack its map loads. Returns problem lines."""
    have = {n: set(contents(os.path.join(export, f"{n}.{kind}.pck"))) for n in list(wings) + list(shared)}
    probs = []
    for w in sorted(wings):
        avail = set(have[w])
        for s, e in shared.items():
            if e.get("maps") == "all" or w in (e.get("maps") or []):
                avail |= have[s]
        refs = references(os.path.join(export, f"{w}.{kind}.pck"))
        for r in sorted(refs):
            if r not in avail and not r.startswith(".godot/") and not any(re.match(i, r) for i in IGNORE_REFS):
                probs.append(f"{w}.{kind}.pck: {r} is referenced by {sorted(refs[r])[0]} but no pack this map loads ships it")
    return probs


def check_manifest(export, wings, shared):
    probs = []
    names = sorted(list(wings) + list(shared))
    listed = sorted(f[:-4] for f in os.listdir(MANIFEST) if f.endswith(".txt")) if os.path.isdir(MANIFEST) else []
    for n in sorted(set(listed) - set(names)):
        probs.append(f"the manifest has pack {n}, the export does not (index.html)")
    for n in sorted(set(names) - set(listed)):
        probs.append(f"the export has pack {n}, the manifest does not")
    for n in names:
        lists = {k: contents(os.path.join(export, f"{n}.{k}.pck")) for k in KINDS}
        if lists["desktop"] != lists["mobile"]:
            d = sorted(set(lists["desktop"]) ^ set(lists["mobile"]))
            probs.append(f"{n}: desktop and mobile differ ({len(d)} files, e.g. {d[0]})")
        if n not in listed:
            continue
        want = [l.rstrip("\n") for l in open(os.path.join(MANIFEST, n + ".txt")) if l.strip() and not l.startswith("#")]
        got = lists["mobile"]
        for p in sorted(set(want) - set(got)):
            probs.append(f"{n}: MISSING {p}")
        for p in sorted(set(got) - set(want)):
            probs.append(f"{n}: new {p}")
    return probs


def write_manifest(export, wings, shared):
    os.makedirs(MANIFEST, exist_ok=True)
    names = sorted(list(wings) + list(shared))
    for f in os.listdir(MANIFEST):
        if f.endswith(".txt") and f[:-4] not in names:
            os.remove(os.path.join(MANIFEST, f))
    for n in names:
        with open(os.path.join(MANIFEST, n + ".txt"), "w") as f:
            f.write(f"# files inside {n}.<desktop|mobile>.pck (tools/qa/packcontents.py write)\n")
            f.write("\n".join(contents(os.path.join(export, f"{n}.mobile.pck"))) + "\n")
    print(f"wrote {len(names)} lists to {os.path.relpath(MANIFEST)}")


def main(argv):
    if len(argv) != 3 or argv[1] not in ("list", "check", "refs", "write"):
        print(__doc__)
        return 2
    cmd, arg = argv[1], argv[2]
    if cmd == "list":
        with open(arg, "rb") as f:
            for p, _o, n in read_dir(f):
                print(f"{n}\t{p}")
        return 0
    wings, shared = read_index(arg)
    probs = []
    for k in KINDS:
        probs += check_refs(arg, wings, shared, k)
    if cmd == "write":
        if probs:
            print("\n".join(probs))
            print(f"refusing to write the manifest: {len(probs)} reference(s) not shipped")
            return 1
        write_manifest(arg, wings, shared)
        return 0
    if cmd == "check":
        probs += check_manifest(arg, wings, shared)
    print("\n".join(probs) if probs else f"packcontents: {len(wings)} wing + {len(shared)} shared packs, every reference shipped"
          + (", contents match tools/qa/pack_manifest/" if cmd == "check" else ""))
    return 1 if probs else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
