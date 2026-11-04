# The 2026 year in the Godot mall

Added Oct 23, 2026 (Demo 42), after Steven's site visit (34 narrated videos and 40 photos of the
real Southland Mall, Oct 23 2026). Report: "Southland Mall 2026 Site Visit — Analysis for Houma
Mall Rewind" (Claude Doc, https://claude.ai/artifact/Ghfh9EQic36PJc3Cas1Row).

## What it is
The same building as 1995 with the tenants of October 2026. The player switches years in place:
"Visit 2026 (Y)" / "Back to 1995 (Y)" under "Jump to" (top right), or the Y key. The building
stays, the stores change.

## Data
- `prototypes/godot-mall/project/data/eras_2026.json`: the 2026 store list, in mall-data's store
  format (83 units, 29 vacant, 10 re-cut). The same list is `eras["2026"]` in `index.html`'s
  mall-data on the `map-2026` branch (not merged to main).
- `tools/make_layout_2026.py` → `layout_2026.json`: 1995's layout (zones, hall geometry, the Oct
  7–8 corrections) with every store frontage relabelled to the 2026 unit behind it, merged units
  as one front, split units as their own. The 1995 walk-in interiors are shut except Corn Dog 7.

## Build
- `godot --headless --path . --script res://tools/build_mall.gd -- --wing=<n> --year=2026`
  → `wing<n>_2026.tscn`, meshes in `gen/w<n>y26/`.
- 2026 fronts: the anchors' current fronts (`ANCHOR_LOOK_2026`: Lynn's Interiors, Dillard's,
  JCPenney), Corn Dog 7's 3D build (same shop), and the generic front with each tenant's sign for
  everyone else. Vacant units get the grille and "For Lease". No 1990s Courier ads, no info desk.
- In the game (`scripts/player.gd`): no 1995 crowd, Runner, Stockrooms, prizes or shirt words.
- Bake: `AUTOBAKE="wing1_2026:fastday wing2_2026:fastday"` (day only; the game is day-only), the
  lightmap is `wing<n>_2026_day.lmbake`.
- Stand-ins: `tools/capture_standin.sh <n> 2026` → `tex/standin/y26_from_w<n>_{day,night}.png`
  (night is a copy of day) stamped by `tools/wing_hash.sh <n> 2026`.

## Web
- Presets "Wing <n> Desktop 2026" / "Wing <n> Mobile 2026" (feature `w<n>y26`, main scene
  override `run/main_scene.w<n>y26`) → `w1y26.desktop.pck` etc. `tools/export_web.sh` exports both
  years when `wing1_2026.tscn` exists (`YEARS="1995"` to skip) and writes all pack sizes.
- `web/shell.html`: `?year=2026` picks the `y26` packs; the switch sets it and keeps `?wing=` and
  `?cam=`. Crossing the seam keeps the year.
- `tools/publish_build.sh` checks the 2026 stand-in stamps too and ships the 2026 packs and
  lightmaps.

## Signs (Demo 43, Oct 24 2026)
Every store sign the Oct 23 footage shows, rebuilt in 3D (the 1995 traced-sign standard: cans
with returns and trim caps, lit faces, halo glow, backer panels, cabinets, raceways).
- Source: 69 full-res 1080p frames cut from the videos at each sighting (Steven's
  `2026 Mall/_derived/signs/`) plus the photos; squared up with `photo_trace.py`.
- Spec: one file per sign, `tools/stores/signs/y26/parts/<id>.json` (format and rules:
  `tools/stores/signs/y26/README.md`). Letters traced from masks or fitted with an OFL font
  (`y26/src/fonts/`). `make_signs_2026.py` writes the letters and textures, `check_sign_2026.py`
  the overlay checks (`y26/check/`).
- Build: `tools/stores/signs/sign_2026.gd` (geometry, materials `sg_y26_*`), called from the
  generic front (`sign_2026()` in build_mall.gd), the 2026 anchor fronts, and the restroom hall.
  `fascia_color` paints the bulkhead itself; `mount: glass` puts lettering on the storefront
  glass (Wax Utopia, SOLA). Vacant units have no fascia sign (as filmed), only the leasing card.
- 47 specs, 46 with letters. No sign in the footage: Rhea Lana's (posters only), Inspired 2
  Dance (decal only), House of Fadez (mounting holes only). Weakest readings (soft or cut off):
  Great American Cookies, Auntie Anne's, Foot Locker, hi-5, Lola LaBelle, Avant-Garde.
- Not built (one sign per store for now): Shoe Dept. Encore's blade, VS's return-wall sign,
  PINK's dog panel, Cinnamonster's extra plaques, the directory kiosk, exterior signs.
- Evidence: `production/qa/evidence/d43-signs-*.jpg` (frame | baked game), `d43-web-*`.
- **Oct 28 (Demo 45): AT&T and Journeys re-done** from sharp 1080p frames re-cut from the MOVs
  (`2026 Mall/_derived/full/<id>/`), because the Demo 43 traces came from 960 px contact-sheet
  tiles: the AT&T globe had been a blob, and "Journeys"' strokes had merged into one shape. The
  AT&T globe is now built geometrically (a disc cut by four tapering latitude gaps, the 2016 mark);
  Journeys' oval is an ellipse fitted to the panel's edge and the script is traced at 2x with light
  smoothing so every stroke stays separate. Method for the rest of the weak signs: re-cut the frame
  at full resolution with ffmpeg on the Mac (`-vf fps=2 -q:v 2`), pick the square-on one, then
  `photo_trace.py quad` → masks → spec. Evidence `d45-signs-att-journeys.jpg`.
- **Nov 1 (ws/g): Journeys again.** The Demo 45 sign still bloomed into one pale shape in the baked
  build. Now hung as filmed: 25 % larger and lower, dropping in front of the opening's head, deeper
  cyan tubes lit under the glow threshold, a wider dark edge. Two optional spec keys for this
  (`y26/README.md` format): `scale` (enlarges the spec, still capped by the band) and `drop` (lets
  the sign hang below the band). AT&T reads cleanly in the Demo 45 baked shot and was left as is.
  Evidence `wsG-sign-journeys-*.jpg`.
- Bake lesson: `addons/autobake` now bakes only the job's own scene (after the import scan the
  editor could be left on wing1.tscn, and a wing1_2026 job baked wing1). After copying a bake
  back, delete `.godot/imported/<scene>_day.exr-*` before `--import`, or the old texture stays.

## Elevator and restroom hall order (Nov 1, ws/g, step 6 of the Oct 28 sprint)
Steven thought the elevator and the restroom hall were out of order on the map ("those didn't move").
**The footage confirms the map as it is; nothing was changed, in either year.** IMG_4439, walking
west along the Concourse's south side from the Dillard's court, narration at 28-56 s: "...that was
KarmelKorn. And then those are always an ATM. And then you have this structure. And then this one.
And then this one. And then that is the elevator. Then another stall. And then the restroom
hallway... and then after that is where Regis was." Frames f021-f032 show, in order: Cinnamonster
(KarmelKorn), the ATM pier, the black stepped vacant, Auntie Anne's, Cell Xpert, the elevator's
recessed beige doors, Boost Mobile, the restroom hall opening under an exit sign, Fire Haus 3.0 (Regis).
The game has, west of KarmelKorn at z = 60: Afterthoughts/Auntie Anne's (x -40..-36), Naturalizer/
Cell Xpert (-44..-40), the elevator alcove at x -44 (`ELEV_X`, `build_mall.gd`), Special Tees/Boost
(-48..-44), the restroom hall H7 (-50..-48), Regis/Fire Haus (-58..-50): the same order. Evidence
`production/qa/evidence/wsG-elevator-restroom-order.jpg` (frames | game 2026 and 1995). The ATM pier
between Cinnamonster and the black vacant is not built (a free-standing ATM in the footage).

## The C2 / main-entrance corner (Nov 4, ws/corner-2026): PROPOSAL
Zales holds both 1995 stalls (Franks + Orange Julius) with three bays, and the footage shows the
court stepping 4 m south in front of Franks (a return wall, Zales' middle bay faces west), which the
Oct 8 re-cut flattened. Analysis, mismatches, the proposed rects and Steven's questions:
`design/corner-2026-c2.md`. Not applied: `tools/layout_corner_c2.py` applies it after his yes.

## Next
- Build the 2026 storefronts from the footage, one by one (frame references are in the report's
  "Reference frames" table and the per-clip notes). The signs are done (Demo 43).
- 2026-only details: linear LED slots in the hall ceilings, the arched soffit bands every 25–30 m,
  the Solarium zig-zag front, Shoe Dept. Encore's and T-Mobile's exterior doors.
- Low-confidence units (report, Goal 2 table) after Steven's review.
