"""The claw's prizes as bag items (workstream ECON, Steven Nov 3 2026: "put the claw plush and pogs in the bag";
design/godot-economy.md "Claw prizes in the bag"). Step 1 of 2.

The claw game (play/claw.html) builds its prizes in three.js. This reads each one, from the page's own meshes and
materials, as plain data (triangles, normals, texture coordinates, colours, which of the page's textures), and
renders its icon with the page's own renderer:
  .scratch/claw_prizes/<kind>.json   the prize's surfaces (the plush or figure; for a POG capsule, the POGs inside)
  tex/items/pc_claw_<kind>.png        its 256 px icon, transparent, a three-quarter view
Step 2, tools/claw_prizes/build_claw_prizes.gd, turns the JSON into models/pc_claw_<kind>.scn for Godot.
Nothing is painted or modelled here; better models (Blender) can replace them later under the same names.

Usage (from the project folder):
  CHROMIUM=/opt/pw-browsers/chromium python3 tools/claw_prizes/export_claw_prizes.py
  godot --headless --path . --script res://tools/claw_prizes/build_claw_prizes.gd
  godot --headless --path . --import
"""
import base64, functools, http.server, json, os, threading
from playwright.sync_api import sync_playwright

PROJ = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
PLAY = os.path.abspath(os.path.join(PROJ, "..", "play"))
OUT = os.path.abspath(os.path.join(PROJ, "..", "..", "..", ".scratch", "claw_prizes"))
# claw/logic.js KINDS that go into the bag (ticket capsules pay tickets instead)
KINDS = ["gator", "crawfish", "pelican", "nutria", "rougarou", "comet", "bruiser", "pogSkull", "pogGator", "pogEye", "slammer"]

JS = r"""(kinds) => {
  const T = window.THREE, out = {};
  const rnd = new T.WebGLRenderer({ antialias: true, alpha: true, preserveDrawingBuffer: true });
  rnd.setSize(256, 256, false); rnd.setPixelRatio(1); rnd.outputColorSpace = T.SRGBColorSpace; rnd.setClearColor(0x000000, 0);
  const texName = (t) => { if (!t || !t.image || !t.image.src) return null; const m = /\/([a-z_0-9]+)\.webp/.exec(t.image.src); return m ? m[1] : null; };
  for (const kind of kinds) {
    const K = window.CLAW.KINDS[kind];
    let g = window.__claw.make({ id: 'bag-' + kind, kind: kind });
    if (K.capsule) { g = g.children[3]; g.removeFromParent(); }          // the POGs, out of their capsule
    g.rotation.set(0, 0, 0); g.position.set(0, 0, 0); g.updateMatrixWorld(true);
    const box = new T.Box3().setFromObject(g), c = box.getCenter(new T.Vector3());
    const root = new T.Group(); root.add(g);
    g.position.set(-c.x, -box.min.y, -c.z);                              // standing on its origin, centred
    root.updateMatrixWorld(true);
    // the surfaces, one per material: world-space triangles (Godot's winding is the same, y up, +z the front)
    const surf = {};
    root.traverse((o) => {
      if (!o.isMesh) return;
      const geo = o.geometry.index ? o.geometry.toNonIndexed() : o.geometry;
      const P = geo.attributes.position, N = geo.attributes.normal, U = geo.attributes.uv;
      const nm = new T.Matrix3().getNormalMatrix(o.matrixWorld), v = new T.Vector3();
      const mats = Array.isArray(o.material) ? o.material : [o.material];
      const groups = geo.groups.length ? geo.groups : [{ start: 0, count: P.count, materialIndex: 0 }];
      for (const gr of groups) {
        // one material: every group uses it (a box keeps six groups, one per face, even then)
        const m = Array.isArray(o.material) ? mats[gr.materialIndex] : o.material; if (!m) continue;
        const map = texName(m.map);
        const key = [m.color.getHexString(), m.roughness, m.metalness, m.opacity, m.alphaTest, map, m.map ? m.map.repeat.toArray().concat(m.map.offset.toArray()).join(':') : ''].join('|');
        const s = surf[key] || (surf[key] = { color: '#' + m.color.getHexString(), rough: m.roughness, metal: m.metalness,
          opacity: m.transparent ? m.opacity : 1, alpha_test: m.alphaTest || 0, map: map, double: m.side === T.DoubleSide, pos: [], nrm: [], uv: [] });
        const rp = m.map ? m.map.repeat : new T.Vector2(1, 1), of = m.map ? m.map.offset : new T.Vector2(0, 0);
        for (let i = gr.start; i < gr.start + gr.count; i++) {
          v.fromBufferAttribute(P, i).applyMatrix4(o.matrixWorld); s.pos.push(+v.x.toFixed(5), +v.y.toFixed(5), +v.z.toFixed(5));
          v.fromBufferAttribute(N, i).applyMatrix3(nm).normalize(); s.nrm.push(+v.x.toFixed(4), +v.y.toFixed(4), +v.z.toFixed(4));
          // three's texture transform and its flipped rows, baked: Godot's v runs down the picture
          const u = U ? U.getX(i) * rp.x + of.x : 0, w = U ? U.getY(i) * rp.y + of.y : 0;
          s.uv.push(+u.toFixed(5), +(1 - w).toFixed(5));
        }
      }
    });
    // the icon: a three-quarter view from the front (the prizes face +z), lit like a shop shelf
    const sc = new T.Scene(); sc.add(root);
    sc.add(new T.HemisphereLight(0xffffff, 0x404050, 2.2));
    const dl = new T.DirectionalLight(0xffffff, 2.4); dl.position.set(1, 2, 2); sc.add(dl);
    const b2 = new T.Box3().setFromObject(root), sz = b2.getSize(new T.Vector3()), m = b2.getCenter(new T.Vector3());
    const r = Math.max(sz.x, sz.y, sz.z) * 0.62 + 0.004;
    const cam = new T.PerspectiveCamera(30, 1, 0.001, 10);
    const dir = K.capsule ? new T.Vector3(0.35, 1.0, 0.75) : new T.Vector3(0.75, 0.45, 1.0);
    cam.position.copy(m).add(dir.normalize().multiplyScalar(r / Math.sin(15 * Math.PI / 180)));
    cam.lookAt(m);
    rnd.render(sc, cam);
    out[kind] = { name: K.name, kind: K.kind, size: [sz.x, sz.y, sz.z], surfaces: Object.values(surf), png: rnd.domElement.toDataURL('image/png') };
  }
  return out;
}"""


def main():
    handler = functools.partial(http.server.SimpleHTTPRequestHandler, directory=PLAY)
    handler.log_message = lambda *a: None
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    port = srv.server_address[1]
    with sync_playwright() as p:
        b = p.chromium.launch(args=["--use-angle=swiftshader", "--enable-unsafe-swiftshader"], executable_path=os.environ.get("CHROMIUM") or None)
        pg = b.new_page()
        errs = []
        pg.on("pageerror", lambda e: errs.append(str(e)))
        pg.goto(f"http://127.0.0.1:{port}/claw.html?machine=1", timeout=180000)
        pg.wait_for_function("!!(window.__claw && window.__claw.make)", timeout=180000)
        res = pg.evaluate(JS, KINDS)
        b.close()
    srv.shutdown()
    os.makedirs(OUT, exist_ok=True)
    for k in KINDS:
        r = res[k]
        with open(os.path.join(PROJ, "tex", "items", f"pc_claw_{k}.png"), "wb") as f:
            f.write(base64.b64decode(r.pop("png").split(",", 1)[1]))
        with open(os.path.join(OUT, f"{k}.json"), "w") as f:
            json.dump(r, f)
        print("%-10s %-32s %6.3f x %6.3f x %6.3f m  %d surfaces, %d triangles" % (k, r["name"], *r["size"], len(r["surfaces"]),
              sum(len(s["pos"]) // 9 for s in r["surfaces"])))
    print("page errors:", errs)
    print("CLAW PRIZES EXPORTED" if not errs else "CLAW PRIZES FAILED")


if __name__ == "__main__":
    main()
