# Pocket Change (store s52b) — prop modules

Pocket Change, the arcade at Southland Mall (Houma, LA), is built in full 3D for the
**1995** map. Steven (Oct 5, 2026): "simulation style … as realistic as possible";
textures are painted, never 8-bit. The room is **dark**: black ceiling, dark walls,
patterned arcade carpet. Most of the light comes from the machines' own screens,
marquees and lamps, plus a few small downlights.

`store.gd` builds the front, the room, the carpet and the lights, and places the machines.
Each kind of machine is its own **prop module** in this folder. Each module comes with a
texture painter.

## Files per module `<m>` (one lowercase word: skee, hoops, crane, ride, video, driver, redeem)
- `tools/stores/pocket_change/<m>.gd`: geometry and materials (contract below).
- `tools/stores/pocket_change/paint_<m>.py`: Python 3 + Pillow (+ numpy). It writes every
  texture the module uses to `tex/pc/<m>_<name>.png`. Re-running it must reproduce the same
  files: seed any randomness.
- Write only these files and your preview images. Do **not** edit `build_mall.gd`,
  `store.gd`, another team's module, `layout_mall.json` or anything under `.godot/`.
  Do not run `godot --import`, the full build, an export, or git.

## Contract (see `demo.gd`, a working minimal example)
```gdscript
static func footprint(opts = {}) -> Vector2        # (width along the player's right, depth along f), metres
static func build(b, g, o, f, opts = {})           # builds ONE machine
static func fill_mat(m, key, b) -> bool            # fills material "pc_<m>_<key>"; false if unknown
```
- **Frame.** The player stands at `o` (on the floor, at the centre of the machine's front
  edge) and faces `f` (a horizontal unit vector). The machine fills local
  x ∈ [−w/2, w/2] (x = the player's right = `f.cross(Vector3.UP)`), y ≥ 0 and
  z ∈ [0, depth] (z runs along `f`, into the machine). `X(o, f)` in demo.gd builds that
  transform. Put `xf * Vector3(x, y, z)` points into `b.quad`, or pass `xf` to `b.box`.
- **Builder helpers** (`b` is `tools/build_mall.gd`):
  - `b.quad(g, mat, [p0, p1, p2, p3], normal, uvs = [], dynamic = false)`. UV (0, 0) is the
    image's top-left. Give explicit UVs for every painted face.
  - `b.box(g, mat, centre_local, size_local, xf, skip_faces = [], dynamic = false)`. Its
    UVs are world-projected at 1 repeat per metre, so it suits tileable materials and
    plain colours.
  - `b.cyl(g, mat, base, r0, r1, h, seg, top, bottom, dynamic)`. World-space and vertical
    only. For other orientations, build your own quads.
  - `b.poly(...)` and `b.tri(...)` (via `b.st(g, mat, dynamic)`), if needed.
  - `b.cur_color` sets the vertex colour, used by materials `vcolor` / `vcolor_matte`.
    Always reset it to `Color.WHITE`.
  - `b.obst(["rect", x0, z0, x1, z1])` adds one axis-aligned walk obstacle covering the
    footprint. Machines are only ever placed facing ±x or ±z.
  - Do not add Light3D nodes. Emission lights the room in the bake. Exception: `ride` may
    add **one** small `b.add_omni(...)` inside its cabin, tagged with
    `b.tag(l, "", e, e)`.
- **Static vs dynamic.** Static geometry (`dynamic = false`) is lightmapped: cabinets,
  panels, lanes, glass-free surfaces, screens and marquees. Use `dynamic = true` for:
  - anything **transparent** (glass, acrylic, nets with alpha);
  - small or fiddly parts: buttons, joysticks, balls, coin-door details, wire, anything
    under about 8 cm.

  Dynamic parts get no baked shadows, so keep them small.
- **Budgets.** Static ≤ ~6,000 triangles per machine; dynamic ≤ ~3,000. Textures: largest
  side ≤ 1024 px (a marquee or artwork can be 1024×512). All of a module's PNGs together
  ≤ 1.5 MB. Aim for ~400–600 px per metre on big faces.
- **Materials.** `fill_mat(m, key, b)` sets `m.albedo_texture = b.tex("pc/<m>_<name>.png")`,
  roughness, metallic and so on.
  - Lit parts (screens, marquees, LED digits, lamps): `m.emission_enabled = true`,
    `m.emission_texture` (usually the albedo), `m.emission = Color.WHITE` with
    `m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY` (the default ADD puts the
    colour on top of the texture and washes it to white), `m.emission_energy_multiplier`, and **both**
    `m.set_meta("e_day", v)` and `m.set_meta("e_night", v)` with the same value. The arcade
    looks the same day and night. Typical values: screens 1.2–2.0, marquees 1.0–1.6, small
    lamps 2–4.
  - Transparent: `m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA`, low alpha,
    `m.cull_mode = BaseMaterial3D.CULL_DISABLED`, and always used on dynamic geometry.
- **The room.** The ceiling is 3.6 m (black), so every machine fits under 3.3 m. The floor
  is a dark patterned carpet. Players walk up to machines from the front.

## Look and period (1995, Houma, Louisiana)
- Everything must be something a 1995 mall arcade really had:
  - CRT screens (curved glass, black bezel, scanline glow);
  - fluorescent-backlit translucent marquees;
  - red 7-segment LED score displays;
  - coin doors with token slots, coin-return buttons and "25¢"/token stickers.
  Pocket Change took its own brass tokens. Not allowed: no LCDs, no card readers, no LED
  matrix boards, no flat screens.
- **Realistic, not cartoon.** Use real proportions in metres (research the real machine
  type's dimensions) and bevelled edges where they show. Paint the wear in: scuffed
  T-molding, worn laminate at the corners, fingerprints on glass and panels, faded stickers,
  instruction cards, serial plates, dust. Sides are wood-grain, laminate or painted
  plywood with art decals, as appropriate.
- **No real-world IP.** Use the real machine **type** and its form factor (a skee-ball alley,
  a basketball cage game, a crane, an enclosed sit-in ride cabinet, a 2-player fighting
  upright, a twin sit-down racer, a pinball machine). Do **not** copy any real game's title,
  logo, wordmark, characters, cabinet artwork or brand name. That includes Skee-Ball,
  Super Shot, Jurassic Park/The Lost World, Sega, Midway, Namco and every real game title.
  - Artwork is original: invented graphic designs, generic subjects (a basketball, a race
    car, a generic dinosaur, stars, flames, neon geometry) and invented game titles that
    don't evoke real ones.
  - Plain generic words are fine: SCORE, BALLS, PLAYER 1, INSERT TOKEN, WINNER, BONUS,
    TICKETS, PUSH TO START.
- Pocket Change paid out **tickets** on its redemption games (skee-ball, basketball): ticket
  dispenser slots with a strip of orange tickets hanging out are a good detail.

## Checking your work
`tools/qa/preview.sh <m> <out-prefix> "<x,y,z,yaw,pitch;…>" '<opts-json>' lit|dark`
renders your module at the origin, facing −z (the player stands at +z). Yaw 0 looks along
−z; yaw 90 looks along −x. It writes one PNG per camera plus `<out-prefix>-sheet.png`.
- One run takes ~30–90 s. Other teams render at the same time.
- Put outputs in `/home/claude/houma-mall-rewind/.scratch/preview/<m>/`.
- Look at your renders with the Read tool, compare them with the references, and iterate.
- `lit` shows the textures. `dark` (only your own emission) is how it reads in the arcade.

Finish with front, three-quarter and side views in both `lit` and `dark` that look right.

## Oct 7, 2026: the floor opened up (Steven)
A false back wall 3.05 m (10 ft) nearer (ROOM_D); nothing behind it. The middle, front to back: the cyclone, two coin pushers back to back, the dinosaur ride with a clear walk past it on the right, two air hockey tables side by side, lengthwise. The island of uprights behind the ride is gone. The right wall: claws, then the skee-ball alleys after the ride, 1.5 m, then the basketball, then video games. The left wall: three video games, a gap beside the ride, then as before. Front: the opening and fascia raised to match the neighbours (HEAD 2.9, FTOP 4.3).
