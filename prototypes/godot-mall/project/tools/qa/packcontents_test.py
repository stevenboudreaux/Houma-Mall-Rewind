"""Self-test of tools/qa/packcontents.py on small synthetic packs (no Godot, no network).

Usage: python3 tools/qa/packcontents_test.py      (from the project folder; exit 0 = pass)

Builds Godot 4 .pck files the way the 4.7 exporter lays them out (format 3+: header, file data, directory at the
end; relative file base), then checks: the listing and the source-path folding; a wing scene that names a mesh its
pack lacks is caught (the Demo 52 failure); a reference shipped by a shared pack the map loads is fine, one shipped
only for another map is not; the manifest round-trip (write, check, a dropped file, a new file, desktop != mobile).
"""
import json, os, shutil, struct, sys, tempfile

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import packcontents as pc


def make_pck(path, files, ver=3):
    """files: {res-relative path: bytes}. Godot 4 pack, format `ver` (3/4 layout)."""
    data = b""
    entries = []
    for p, b in files.items():
        entries.append((p, len(data), len(b)))
        data += b
    base = 112
    d = struct.pack("<I", len(entries))
    for p, off, n in entries:
        pb = ("res://" + p).encode()
        pb += b"\0" * (-len(pb) % 4)
        d += struct.pack("<I", len(pb)) + pb + struct.pack("<QQ", off, n) + b"\0" * 16 + struct.pack("<I", 0)
    diro = base + len(data)
    h = struct.pack("<4s5IQQ", b"GDPC", ver, 4, 7, 2, 2, base, diro)
    h += b"\0" * (base - len(h))
    with open(path, "wb") as f:
        f.write(h + data + d)


def scn(*refs):
    """A stand-in binary scene: Godot's binary format stores external paths as plain strings."""
    return b"RSRC\0\0" + b"".join(b"\x10\0\0\0res://" + r.encode() + b"\0\0" for r in refs)


def export(tmp, wing_files, shared=None, kinds_differ=False):
    os.makedirs(tmp, exist_ok=True)
    shared = shared or {}
    ps = {n: {"desktop": 1, "mobile": 1} for n in wing_files}
    sp = {n: {"desktop": 1, "mobile": 1, "at": "start", "maps": m} for n, (m, _f) in shared.items()}
    with open(os.path.join(tmp, "index.html"), "w") as f:
        f.write("const PACK_SIZES = %s; // PACK_SIZES\nconst SHARED_PACKS = %s; // SHARED_PACKS\n" % (json.dumps(ps), json.dumps(sp)))
    for n, files in wing_files.items():
        for k in pc.KINDS:
            fl = dict(files)
            if kinds_differ and k == "desktop":
                fl["extra_desktop_only.txt"] = b"x"
            make_pck(os.path.join(tmp, f"{n}.{k}.pck"), fl)
    for n, (_m, files) in shared.items():
        for k in pc.KINDS:
            make_pck(os.path.join(tmp, f"{n}.{k}.pck"), files)


FAILS = []


def expect(cond, what):
    print(("ok   " if cond else "FAIL ") + what)
    if not cond:
        FAILS.append(what)


def main():
    tmp = tempfile.mkdtemp(prefix="packcontents_test_")
    keep_manifest = pc.MANIFEST
    try:
        pc.MANIFEST = os.path.join(tmp, "manifest")
        exp = ".godot/exported/1/export-abc-wing1.scn"
        wing = {
            "wing1.tscn.remap": b'[remap]\n\npath="res://' + exp.encode() + b'"\n',
            exp: scn("gen/w1/dyn_a.res", "gen/w1/dyn_b.res", "models/bl_x/bl_x.glb", "models/characters/body.glb"),
            "gen/w1/dyn_a.res": scn("tex/sg/a_face.png"),
            "tex/sg/a_face.png.import": b"[remap]",
            ".godot/imported/a_face.png-123.s3tc.ctex": b"x",
            "scripts/x.gd.remap": b"", "scripts/x.gdc": b"", "scripts/x.gd.uid": b"",
        }
        items = ("all", {"models/bl_x/bl_x.glb.import": b""})
        chars = ("all", {"models/characters/body.glb.import": b""})
        # 1. listing and folding
        d = os.path.join(tmp, "e1")
        export(d, {"w1": wing}, {"items": items, "chars": chars})
        got = pc.contents(os.path.join(d, "w1.mobile.pck"))
        expect(got == ["gen/w1/dyn_a.res", "scripts/x.gd", "tex/sg/a_face.png", "wing1.tscn"], f"contents folded to source paths: {got}")
        refs = pc.references(os.path.join(d, "w1.mobile.pck"))
        expect(refs.get("gen/w1/dyn_b.res") == {"wing1.tscn"}, "the exported scene's references are read under its source name")
        # 2. the Demo 52 failure: dyn_b named by the scene, not shipped
        w, s = pc.read_index(d)
        probs = pc.check_refs(d, w, s)
        expect(len(probs) == 1 and "gen/w1/dyn_b.res" in probs[0], f"a referenced mesh missing from the pack is caught: {probs}")
        # 3. fixed export: clean, shared packs count, write + check round-trip
        wing_ok = dict(wing, **{"gen/w1/dyn_b.res": scn()})
        d = os.path.join(tmp, "e2")
        export(d, {"w1": wing_ok}, {"items": items, "chars": chars})
        w, s = pc.read_index(d)
        expect(pc.check_refs(d, w, s) == [], "every reference shipped (wing + shared packs)")
        expect(pc.main(["x", "write", d]) == 0, "write succeeds on a clean export")
        expect(pc.main(["x", "check", d]) == 0, "check passes against the list it just wrote")
        # 4. a shared pack for another map does not count
        d = os.path.join(tmp, "e3")
        export(d, {"w1": wing_ok}, {"items": items, "chars": (["w2"], chars[1])})
        w, s = pc.read_index(d)
        probs = pc.check_refs(d, w, s)
        expect(len(probs) == 1 and "models/characters/body.glb" in probs[0], "a file only in another map's shared pack is caught")
        # 5. manifest differences
        d = os.path.join(tmp, "e4")
        smaller = {k: v for k, v in wing_ok.items() if k != "tex/sg/a_face.png.import"}
        export(d, {"w1": smaller}, {"items": items, "chars": chars})
        w, s = pc.read_index(d)
        probs = pc.check_manifest(d, w, s)
        expect(probs == ["w1: MISSING tex/sg/a_face.png"], f"a dropped file is refused: {probs}")
        expect(pc.main(["x", "write", d]) == 1, "write refuses while a reference is not shipped")
        d = os.path.join(tmp, "e5")
        export(d, {"w1": dict(wing_ok, **{"data/new.json": b"{}"})}, {"items": items, "chars": chars})
        w, s = pc.read_index(d)
        expect(pc.check_manifest(d, w, s) == ["w1: new data/new.json"], "a new file is refused until the list is rewritten")
        d = os.path.join(tmp, "e6")
        export(d, {"w1": wing_ok}, {"items": items, "chars": chars}, kinds_differ=True)
        w, s = pc.read_index(d)
        expect(any("desktop and mobile differ" in p for p in pc.check_manifest(d, w, s)), "desktop and mobile must list the same files")
        d = os.path.join(tmp, "e7")
        export(d, {"w1": wing_ok}, {"items": items})
        w, s = pc.read_index(d)
        expect("the manifest has pack chars, the export does not (index.html)" in pc.check_manifest(d, w, s), "a pack missing from the export is refused")
    finally:
        pc.MANIFEST = keep_manifest
        shutil.rmtree(tmp, ignore_errors=True)
    print("packcontents_test:", "FAIL (%d)" % len(FAILS) if FAILS else "all passed")
    return 1 if FAILS else 0


if __name__ == "__main__":
    sys.exit(main())
