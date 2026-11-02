# Session handoff: workstream GI, Games, Inc. (2026) rebuilt from the walkthrough (Nov 2, 2026)

Branch `ws/gi-games-inc`, cut from main `5b5683e`; main has not moved since. Pushed, **not merged, not
published**. Commits are as Steven with the session trailers. The design record is
`design/storefronts/games-inc-2026.md` (the inventory table and the Nov 2 build notes).

## 1. Why

Steven (Nov 2): the Demo 46 Games, Inc. used Pocket Change's 1990s machine modules — "that's not the
setup." Games, Inc. is its own place in 2026. The brief asked for the real room: its layout, the real
machines as detailed skins, and the real colours. No games yet. Ground rule: build only what the video
shows; no NPC, dialogue or story.

## 2. Sources

- The walkthrough: IMG_4443 (f001-f058) and IMG_4444 (g001-g006), full-res 1 fps frames from the refs
  pack (`refs/derived/full/games/`), plus photo IMG_4445 (shot sideways; rotate it 90°).
- There is no newer Games, Inc. cut in `refs/new/`. The narration stops at 28 s.

## 3. Commits

| Commit | What |
|---|---|
| `9283586` | docs: the inventory table (every machine and fixture, position, size, colours, frame ranges), written before any modelling |
| `447a71f` | feat: the machine kit and the room rebuilt; the attendant spot |
| `1ec15b9` | fix: claw colours as filmed, the die moved out of its column; the `.import` / `.uid` files |
| `f14f14a` | feat: walk grid opened, plush window filled; evidence; build notes |

## 4. What the walkthrough corrected (against Demo 46)

- Walking in, the **GALACTIC PRIZE PORTAL counter is on the left** (behind the plush window) and the
  **party corner with the CLAW MANIA mural is on the right** (behind the right-hand glass bay).
  Demo 46 had them swapped.
- The long LED claw run is on the **left** wall, from the counter's end to the back.
- The right wall carries the coin pushers, the big cabinets and the white merchandisers.
- The two air hockey tables stand **lengthwise**, side by side.
- The "kiddie rides" are two sit-on **motorbike racers** at the back right.
- The ceiling troffers are **2x2 nine-cell parabolic louvres**, not 2x4.
- There is an inside header ("CLAW MANIA") over the right glass bay (IMG_4445).

## 5. The room as built

The store frame: u is metres from the right wall walking in (the food-court side, u 0) to the left wall
(the vacant s52b side, u 8); d is metres in from the hall face.

**Front.** A mustard 6x12 tile frame round three bays:
- the frameless glass pair (u 0.55-2.05, closed);
- the opening (u 2.4-5.05, 2.35 m clear) with the white sign panel and the existing lit sign
  (`y26/parts/games.json`) in its top;
- the plush window (u 5.4-7.45), heaped edge to edge with big generic plush figures.

White end piers; the cream mall wall above the tile head at 3.25 m. Two black A-frame poster stands
inside.

**Walls.**
- Below 2.27 m: white, except the orange prize-counter wall (left, d 0.45-9.4) and tan slatwall (the
  right wall from d 18, and the back wall).
- Above that: a mustard band, a white shelf at 2.42 m, and a red-orange band to the 3.4 m lay-in
  ceiling.
- Plush on the shelves: character-plush colours over the right wall's front half; big inflatable alien
  figures over the left-wall claws.
- Also: the white pipe column (u 3.3, d 20), the thin black pole between the air hockey tables, and the
  exit door standing open into a lit back room with the EXIT sign over it.

**Lighting.**
- 2x2 troffers in two rows about every 3 m, each with a baked spot; square diffusers and grilles
  between them; two black track runs with spot heads.
- Warm spots over the counter.
- The machines' marquees, screens and LED strips are emissive. The violet wash seen in the footage
  will come from the bake; the unbaked shots look brighter and whiter than the real room.

## 6. The machines (kit pieces, placed per the inventory table)

All are in `tools/stores/games_inc/machines/`, one file per machine kind.

**Contract.** The same as Pocket Change's prop modules:
- `footprint(opts)`, `build(b, g, o, f, opts)` and `fill_mat(m, key, b)`;
- materials `gi_m_<kind>_<key>` and `gi_k_<key>`;
- one 1024x512 atlas per kind, painted by `machines/paint.py`, which also writes `atlas.json`, the
  region map the geometry reads.

| Kind (file) | Machines | Where (side, d) |
|---|---|---|
| `counter` | P1 prize wall (black shelving, plush row, GALACTIC PRIZE PORTAL neon panel, 2 TVs), P4 three LED showcases (pink, blue, white), P5 black counter, P6 two card kiosks | Left, 1.0-10.8 |
| `merch` | M2 white merchandiser (plush on top) and a yellow one; M14 PUSH; M15 SUPER STAR plus 4 white; M16 yellow red-ring; M26 purple | Left 11-13; right 23.8-30.5; back |
| `claw` | M1: 27 LED claws (green, white, blue, red, pink, violet, as filmed); M3 white claw by the party corner | Left 12.8-36.2; right 5.0 |
| `pusher` | M4 royal-blue 2-player coin pusher; M6 white/purple 2-player | Right 6.0, 11.0 |
| `dice` | M5 "MONOPOLY ROLL-N-GO"-type dice tower | Middle 11.6 |
| `gunbig` | M7 big 2-player gun cabinet, "ARCADE" | Right 13.2 |
| `racer` | M8 twin sit-down racer; M30 two motorbike racers | Right 15.4; 34.0 |
| `upright` | M9 NERF; M18 tall black upright (mascot panel left plain); M17 CROSSY ROAD; M29 music cabinet | Right 17.8; middle 15.8, 17.6; back |
| `deal` | M10 DEAL OR NO DEAL (keypad console, lit hex platform, stool) | Right 18.8 |
| `hoop` | M11 BASKETBALL PRO | Right 20.4 |
| `ptower` | M12 prize tower (no name); M13 DIZZY CHICKEN | Right 21.4, 22.5 |
| `dome` | M19 pink and M20 blue drop domes (TAP, red "100"); M22 neon-arch ticket game | Middle 19.2-23.8, 24.4 |
| `wheel` | M21 the QUEST wheel | Middle 21.3 |
| `hockey` | M24 blue/yellow and M23 red/orange (with the score arch) air hockey | Middle 26.4-28.8 |
| `alley` | M25 two alley rollers; M27 big-eyed drop column; M28 QUIK DROP | Back wall |

The party corner is in `store.gd`: the Q1 mural on the right wall (d 1.3-4.6), the Q2 two 8 ft tables
lengthwise, and the Q3 trash can.

**IP.**
- Legible cabinet names are plain OFL lettering, not traced logos.
- Licensed character art is replaced by generic abstract translites in the cabinet's colours: the
  superhero pusher topper, the dinosaur cabinet's art, the board-game mascot, and the Pokémon plush
  (the window and shelves).

**Budget.**
- Kit textures: 16 PNGs, about 0.7 MB.
- Geometry stays low: boxes, quads, and low-poly ellipsoids for plush. Glass, domes and small parts
  are dynamic.

## 7. Walk grid (shared-file change)

- **Problem:** s52 has never been walkable in any 2026 build. `make_layout_2026.py` only keeps
  interiors that were open in 1995, and Blockbuster Music (1995 s52) had no walk-in interior. The
  Demo 46 note claiming it was walkable was wrong.
- **Fix:** a commented hunk, `OPEN_2026 = {"s52"}`, opens its rect. The regenerated
  `layout_2026.json` differs from main in exactly 80 walk tiles (cols 89-92, rows 130-149) and nothing
  else.
- **Walls still hold:** the neighbouring tiles (col 88, col 93, row 150) stay shut. The front wall,
  glass, counter, tables, A-frames, columns and every machine are obstacles (`gen/w2y26/collide.json`).
- **Aisles:** at least 1.1 m along both sides of the middle row, and 1.2-1.4 m either side of the air
  hockey tables.

## 8. Interactables

- **None playable,** per the brief.
- **Removed:** the Demo 46 build had carried Pocket Change's owner-renamable marquees into Games, Inc.
  — 37 `pc.*` entries in `gen/w2y26/signs.json`, including a playable Genesis cabinet `pc.video.03`
  and COIN COMET's Play on the pusher. Those came with the 1990s kit, so they are gone; after the
  rebuild, `signs.json` for w2y26 has no `pc.*` entries.
- **No look prompts:** none existed before either. `scripts/prizes.gd`'s closer look only finds
  `*pc*_mach` meshes, and Games, Inc.'s groups were always `gi*_mach`.
- **Attendant spot** (no NPC): `data/story/attendants.json`, the new file `spots[0]` =
  `games_inc_counter`, pos (-111.1, 0, 66.3), yaw 90 (facing the aisle), behind the counter.

## 9. Pack size (w2y26)

Measured in this container. Desktop and mobile came out identical here.

| | Size |
|---|---|
| Before (main's Demo 46 store, with its lightmap) | 70.6 MB (the brief's 71.4 was measured on the Mac) |
| After, with the existing (old) lightmap | 53.3 MB |
| After, no lightmap (the unbaked evidence build) | 49.1 MB |

The drop is Pocket Change's 1024 px machine textures leaving the 2026 pack. The ceiling is 100 MB.

## 10. Verification

- **Build:** `--wing=2 --year=2026` gives `BUILD OK`, with no unknown materials or missing textures.
  The leak messages at exit appear on main's build too.
- **Web build:** w2y26 exported with `wing2_2026_day.lmbake/.exr` moved aside, so the shots are truly
  unbaked. With the old lightmap in place, grey speckled patches show on the new meshes; that is
  expected until the rebake.
- **Load and walk test:**
  - 16 camera loads at 1280x720 and 390x844, **0 console errors**.
  - The touch walk goes from the hall at z 57 through the opening to z 65 inside the store (MOVED,
    0 errors).
  - It ran through a Node port of `tools/qa/movetest.py`, because the container has no Python
    Playwright. The port is not in the repo.
- **Preview renders:** every machine was rendered with `tools/qa/preview.sh` (probe-lit) for the
  side-by-sides.

## 11. Evidence (`production/qa/evidence/`, all unbaked)

| File | Shows |
|---|---|
| `wsGI-zone-front.jpg` | f003, the hall front |
| `wsGI-zone-entrance.jpg` | f012, looking in through the opening |
| `wsGI-zone-counter.jpg` | f019, the prize counter |
| `wsGI-zone-party.jpg` | f022, the party corner and mural |
| `wsGI-zone-rightfront.jpg` | f024, the pushers and dice tower |
| `wsGI-zone-rightmid.jpg` | f038, DEAL, BASKETBALL PRO, the prize towers |
| `wsGI-zone-leftclaws.jpg` | f041, the claw run and the domes |
| `wsGI-zone-middle.jpg` | f029, down the middle |
| `wsGI-zone-hockey.jpg` | IMG_4445, the air hockey end looking front |
| `wsGI-zone-back.jpg` | g005, the back wall |
| `wsGI-zone-fromcounter.jpg` | f027, from behind the counter |
| `wsGI-machines-1..4.jpg` | Every machine kind beside its frame crop (28 pairs) |
| `wsGI-unbaked-entrance.jpg`, `wsGI-unbaked-counter.jpg` | In-game, from the entrance and from the counter |
| `wsGI-iphone-390.jpg` | iPhone width (390 px): entrance and counter |

## 12. Files changed (`git diff --stat origin/main`: 91 files)

All paths under `prototypes/godot-mall/project/` unless noted.

**New:**
- `tools/stores/games_inc/machines/`: `kit.gd`, `claw.gd`, `merch.gd`, `pusher.gd`, `dice.gd`,
  `gunbig.gd`, `racer.gd`, `upright.gd`, `deal.gd`, `hoop.gd`, `ptower.gd`, `dome.gd`, `wheel.gd`,
  `hockey.gd`, `alley.gd`, `counter.gd`, `gallery.gd` (a preview helper; not used by the build),
  `paint.py`, `atlas.json`, plus their `.uid` files;
- `tex/gi/m_*.png` (16) and their `.import` files;
- `data/story/attendants.json`;
- `production/qa/evidence/wsGI-*.jpg` (19) and this file (both repo root).

**Changed:**
- `tools/stores/games_inc/store.gd` (rewritten);
- `tools/make_layout_2026.py` (one hunk);
- `layout_2026.json` (walk tiles only);
- `design/storefronts/games-inc-2026.md` (repo root).

**Untouched:**
- `tools/build_mall.gd`: its existing 2026 hook already calls `games_inc/store.gd` and dispatches
  `gi_` materials;
- `scripts/*`, `web/shell.html`;
- Pocket Change, the 1995 Blockbuster Music, and every other store.

**Not committed (build outputs, rebuilt at integration):** `gen/w2y26/*`, `wing2_2026.tscn`.

**Still on disk but no longer used:** `tex/gi/band.png`, `slat.png`, `mural.png`, and the `gi_band` /
`gi_slat` / `gi_mural` keys in `store.gd`'s `fill_mat`. They are a few KB and harmless; delete them if
you like.

## 13. Integration steps

1. Merge `ws/gi-games-inc`.
   - If another branch also changed `layout_2026.json`, keep both scripts' changes in
     `make_layout_2026.py` and re-run `python3 tools/make_layout_2026.py`; don't hand-merge the JSON.
   - If another branch changed `make_layout_2026.py`'s `KEEP_OPEN`, the `OPEN_2026` hunk sits just
     before `out = dict(L)`.
2. Rebuild **both 2026 wings** (the walk grid changed):
   - `godot --headless --path . --script res://tools/build_mall.gd -- --wing=1 --year=2026`
   - the same command with `--wing=2 --year=2026`
3. Rebake **wing 2 2026** on the Mac (`wing2_2026:fastday`). After copying the bake back, delete
   `.godot/imported/wing2_2026_day.exr-*` before `--import` (the bake lesson in
   `design/godot-2026-year.md`).
4. Run `tools/capture_standin.sh 2 2026`: the Concourse view across the seam changed.
5. Export, check the w2y26 pack size (expect about 53 MB), run movetest on wing 2 2026, then publish
   as usual. `publish_build.sh` refuses a stale stand-in.
6. Check by looking after the bake: the room should read violet-lit as in the footage, not white. If
   the troffer spots overpower the machine glow, lower `lights()` energy 1.4 → 1.0 in `store.gd`.

## 14. Guessed or not seen (also in the design note)

- **Guessed:**
  - every depth position, to ± 1 m;
  - the tables' spacing;
  - the CLAW MANIA header over the right glass bay (seen only far off in IMG_4445);
  - the white column's u;
  - the 2x2 troffer spacing.
- **No legible name, so none shown:** M12 (prize tower), M22 (neon-arch ticket game), M25 (alleys),
  M26 (purple cabinet), M29 (the music cabinet's title).
- **Simplified:** the faces of the alleys and drop columns, and the M6 portrait side panel (an abstract
  colour field).
- **Not in the footage, left empty:** the right wall at d 8-11 and 30-33.8; the back-left corner behind
  the alleys; the counter's staff side; the inside of the front wall left of the opening.

## 15. Open questions for Steven

1. **Which machines should be playable first?** Suggested order:
   - the 2-player coin pusher (COIN COMET's play code from workstream P exists);
   - the drop domes (one TAP button);
   - Crossy Road (tap to hop);
   - then air hockey and Basketball Pro.
2. Should the prize counter get Pocket Change's closer-look prize view? It needs `prizes.gd` taught
   the `gi` groups.
3. Is the white machine by the party corner (M3) a claw or a prize merchandiser?
4. Does he know the names of M12, M22, M25 and M26?
5. The cabinet textures are flatter and cleaner than Pocket Change's worn 1990s ones. The 2026 cabinets
   are clean in the footage too. Does he want more surface detail (logos, wear, LED dot patterns)?

## 16. Notes for whoever continues

- **Machine frame:** the player stands at `o` facing `f`, and the machine fills local
  z ∈ [0, depth] along `f`. `store.gd`'s `on_wall()` / `on_back()` / `put()` take the front edge's
  centre and a direction ("+u" = facing the left wall, and so on).
- **Changing a texture:** edit `machines/paint.py`, re-run it from the project folder (it rewrites
  `atlas.json` too), then `--import`.
- **Previews:** `tools/qa/preview.sh res://tools/stores/games_inc/machines/gallery.gd <out> "<cams>"
  '{"set": 0..5}' lit` (or `'{"one": ["claw", {"color": 2}]}'`). For the whole store with the hall,
  use `MALL_YEAR=2026 tools/qa/preview.sh "store:GAMES, INC. (POCKET CHANGE)" ...`.
- **World coordinates:** s52 spans x -118..-110, z 60..100. `?cam=` yaw: 180 faces into the store.
