# Reading the directory kiosk: legibility (Godot mall)

Workstream ws/directory, Nov 4 2026. Follows `design/godot-directory.md` (the kiosk, the panels,
the reader) and `design/godot-dialogue.md` (the camera that goes to a person you talk to).

**Steven's problem:** the store names on the kiosk are too pixelated to read. He would like the
camera to go to the kiosk the way it goes to a person you talk to, and text that reads by itself,
perhaps by zooming to the list or the map. Balance the real kiosk's look against legibility. Text
is moving off the game screen into the menu, so no new overlay text; text on the kiosk is fine.

## Decided (Steven, Nov 4 2026, after seeing the A / B / C prototypes)
1. **Option B is the kiosk.** The camera frames the sign, then moves in to the store list at
   reading size (one column a page on a phone, swipe to turn); tapping a name lights it (the pink
   outline is fine) and glides the camera to the store on the map. **No overlay text.** A and C
   are removed (`scripts/directory_look.gd`, `tools/qa/dirlook_mini.gd` and the `?dirlook=` flag
   are gone; option B now lives in `scripts/directory_ui.gd`, which replaces the old flat reader).
2. **Yes to full iPhone sharpness, project-wide** (`allow_hidpi=true`, `scripts/hidpi.gd`). The 3D
   world keeps today's render resolution, except while the camera is on the kiosk.
   **Not yet checked on a real iPhone** (see "Steven to check" below).
3. **The 1990s / 2026 time-travel switch is on the kiosk itself**: a dark plate on the frame's
   bottom rail with two keys labelled "1990s" and "2026", the current year's key lit. Not a
   screen overlay.
4. **Keep a confirm before jumping**, styled like the game's menu.
5. **Unnamed 2026 map blocks:** keep the lit list line in view if cheap. Done where it is cheap
   (below, "What was built").

## What was built (option B, final)
- **Opening** (`directory_kiosk.gd interact()` → `directory_ui.gd open()`): the HUD hides, the
  player freezes, and a reader camera glides from the player's view to the kiosk in 0.6 s (cubic
  in-out, FOV 70 → 40°). It frames the whole sign **with the year switch under it** and holds 0.8 s,
  then moves in to the list's first page at **0.72 screen px per panel px** (capitals ~10 px).
- **Pages** (`_columns()`, `_make_pages()`, computed at run time from the click areas): as many
  list columns side by side as fit the screen at reading size, then down those columns a screen
  at a time (12 % overlap). A phone in portrait gets one column per page; a computer gets the
  list, the legend and the map's edge. Swipe left / right, the arrows, the d-pad or the stick
  turn the page.
- **Picking a store:** tap its name (or its block on the map). Every list line and map block it
  has lights on the sign itself (`#ff2d6f` outline and a light tint, drawn by the quad's shader),
  and the camera glides to its block on the map:
  - **When a lit list line and the block fit one view at ≥ 0.5 px per panel px** (a computer, a
    phone held sideways, a few stores on a portrait phone), the camera frames both, using the
    store's list line nearest the block. This is the "cheap" answer to question 5.
  - **Otherwise** (most stores on a portrait phone): the block with its neighbours at 0.54. The
    name is then on the line you tapped (still lit when you go back with **<**) and in the
    confirm. Measured from `hotspots.json` on a 390-wide phone: keeping both in view would take
    0.3 px per panel px for 26 of 43 2026 stores (capitals ~4 px), so it is not cheap there.
- **The confirm:** tap the lit store again (or Enter / A on the map) and "Jump to this store?"
  opens with the store's name (1995: with its number) and "Loads Wing N" when the jump changes
  wing, with **Yes, go there** / **Cancel**, in the game menu's colours (`scripts/menu/menu.gd`:
  dark brown ground, cream and gold type, amber for the chosen button, rounded corners).
  Yes calls `player.jump_to()`.
- **Back and close:** an **X** box (close) and, off the whole-sign view, a **<** box (map → list
  → whole sign). They are the only things drawn over the view besides the confirm.
- **The year switch** (`directory_kiosk.gd _build_switch()`, made at run time, so no rebuild or
  rebake): a 0.40 × 0.088 m dark plate on the frame's bottom rail, two 0.182 m keys, "1990s"
  (teal `#2a8a96` when lit) and "2026" (cyan `#3fa9d8`). Tap the other year's key on the
  whole-sign view, or press Y (keyboard or gamepad) anywhere in the reader: the sign closes and
  MENU2's time-travel trip (`scripts/timetravel_trip.gd begin()`) starts from this kiosk.
  Tapping the current year's key does nothing. The real 2026 kiosk has no such switch: it is
  the game's addition, kept small and in the frame's own materials.
- **Sharp type:** the sign is drawn from the 4x panels (`tex/dir/hi/panel_<year>.png`, 4096 ×
  4580) on a quad 3 mm in front of the kiosk's own panel, only while reading; the picture is
  released on close.
- **Controls:** touch / mouse as above; keys and gamepad: up / down (W S, d-pad, stick) step from
  store to store down the list, turning pages; left / right turn the page; Enter / Space / E / A
  pick, then ask; Esc / Backspace / B go back, then close; Y travels in time.

## Full device pixels (scripts/hidpi.gd, project.godot)
- `project.godot`: `window/dpi/allow_hidpi=true` and the autoload `Hidpi`
  (`scripts/hidpi.gd`). **Shared file:** two lines.
- At start and on every resize, `Hidpi` sets `root.content_scale_factor = devicePixelRatio`
  (max 3), so every HUD, menu and screen keeps its size and becomes sharper, and
  `root.scaling_3d_scale = 1 / devicePixelRatio`, so the 3D world costs what it cost before.
- While the camera is on the sign, `directory_ui.gd _sharp()` puts the 3D scale at 1.0 (the view
  is then one unshaded quad), and back on close.
- WebXR: the 3D scale is held at 1.0 while `use_xr` is on (a headset renders its own eye buffers).
- Native Linux / Windows windows report scale 1 and are unchanged. Tests force a factor with
  `Engine.set_meta("hidpi", 3.0)` (`--hidpi=3`).

## Steven to check on his iPhone
1. **Everything's text is sharper** (HUD, menu, dialogue, shop), with the same sizes as before.
   If anything is half or a third its old size, or the touch spots are off, `hidpi.gd` has missed
   a screen: say which.
2. **The frame rate walking the halls** is the same as before (the 3D is still drawn at 390 × 844
   and stretched). If it is worse, the lever can be turned off by setting `allow_hidpi=false`.
3. **The kiosk:** the list reads without zooming; swipe pages; tap a name, the map, the lit block,
   the confirm; the 1990s / 2026 keys on the kiosk. Safari memory with the 4x panel open (~100 MB
   of texture while reading).

## Earlier: the three options as prototyped (history)
Kept as the record of what Steven chose from. The `?dirlook=` flag, `directory_look.gd` and
`dirlook_mini.gd` named below no longer exist.

### Why it is pixelated today (measured)
1. **The sign is shown whole, so the type is tiny.** The list type's capitals are about **14 panel
   px** tall (in `tex/dir/panel_*.png`, 2048 × 2290). Shown whole, the sign is drawn at 0.175 screen
   px per panel px on a 390-wide phone, which makes the capitals **2.4 px** tall. On a 1280 × 720
   desktop it is 0.28, so the capitals are **3.9 px**. No texture size can make that readable. You
   have to be closer, at about **0.7 px per panel px (capitals ~10 px)**.
2. **The game draws an iPhone at 390 × 844 pixels and Safari stretches that ×3.**
   `project.godot` has `window/dpi/allow_hidpi=false`, so every glyph is at most a third as sharp
   as the phone's screen. Even zoomed in, today's text is soft (see the crops below).
3. **Today's flat reader draws the 2048 px picture without mipmaps.** Godot's default canvas
   filter is plain linear, so drawing the picture at a sixth of its size skips pixels. That breaks
   the small type into the jagged marks in the left crop below, where it could have been a smooth
   grey blur. This is a one-line fix (`view.texture_filter = LINEAR_WITH_MIPMAPS`); option C uses it.

![](../production/qa/evidence/directory-opt-legibility-iphone-crops.jpg)
`directory-opt-legibility-iphone-crops.jpg`. All three crops are shown at the iPhone's physical
pixels:
- **Left:** today's reader, whole sign.
- **Middle:** option B's list page on today's canvas (1x, stretched by Safari).
- **Right:** the same page with the game drawing at device pixels (3x).

### The options (prototyped behind `?dirlook=`, now removed)
Turn on with **`?dirlook=a`**, **`b`** or **`c`** on the game URL (native: `-- --dirlook=b`).
Without the flag, the kiosk opens today's reader unchanged (checked).

**What all three share:**
- The camera leaves the player and glides to the kiosk in 0.6 s (cubic in-out, FOV 70 → 40°), as
  the talk camera does. The HUD hides as in a conversation. Closing glides back.
- **No new words on screen:** the only things drawn over the view are an **X** box and, in B, a
  **<** box.
- A and B select a store by lighting it on the sign itself: every list line and map block it has,
  tinted, with a pink outline (`HILITE #ff2d6f`, the colour today's reader uses), drawn by the
  sign's own shader. Tapping the lit store again jumps there.
- A and B draw the sign from a **4x panel** (`tex/dir/hi/panel_<year>.png`, 4096 × 4580, the same
  painter at `DIR_K=4`) on a quad 3 mm in front of the kiosk's panel. The quad exists only while
  you read, so the big picture is only in memory then.

#### A: Face the sign (free zoom)
- **What it looks like:** the camera stops square on the whole lit panel in its aluminium frame.
  Pinch or the wheel dollies the camera in; drag pans across the sign. Tap a name or a block and it
  lights on the sign; tap it again to go.
  - Evidence: `directory-optA-<2026|1995>-<desktop|phone>-unbaked.jpg`.
- **Authenticity:** the highest. It is what standing at the kiosk is like: the real sign, nothing
  laid over it.
- **iPhone legibility:** the whole sign is unreadable (2.3 px capitals). Every visit needs a pinch
  to about 4x and a drag before anything reads. Once there, it reads like B (~10 px capitals; sharp
  only with device pixels, below).
- **Cost to finish:** about 0.5 day.
  - Dolly limits and inertia, gamepad zoom/pan, keyboard.
  - The year toggle and the confirm (see Open questions).
  - Update `dirtest.js`, a web check.

#### B: List, then map (guided)
- **What it looks like:**
  - The camera frames the whole sign for half a second, then moves in to the store list at reading
    size (0.72 screen px per panel px, capitals ~10 px).
  - **Phone:** one column at a time, a screen tall. Swipe or the arrows turn the page.
  - **Desktop:** both list columns, the legend and the edge of the map on one page.
  - Tap a name: it lights (both lines for a store listed twice) and the camera glides across the
    sign to the store's block on the map, also lit, framed with its neighbours. A second tap goes;
    **<** or a tap off the stores goes back to the list.
  - Evidence: `directory-optB-<2026|1995>-<desktop|phone>-unbaked.jpg`, and
    `directory-optB-<2026|1995>-iphone3x-unbaked.jpg`.
- **Authenticity:** high. It is how you read the real kiosk: find the name, note its colour dot,
  look across to the block. Only the camera moves, and nothing is added except the lit outline.
- **iPhone legibility:** the best without any effort from the player. The list opens readable at
  ~10 CSS px capitals. With device pixels it is crisp (right crop).
  - **2026:** the real sign's map has **no store names on the blocks** (only the logo blocks), so on
    the map the name is the lit list line. On a desktop it is in the same view. On a phone you see
    the lit block, and the name stays on the page you picked it from.
  - **1995:** the 1994-style map has numbers on the blocks, and they read at the map framing.
- **Cost to finish:** about 1–1.5 days.
  - Page turning on every input (swipe, d-pad, stick, keys).
  - Picking on the map directly, landscape phones, a gamepad cursor.
  - The year toggle and the confirm, `dirtest.js`, a web check.

#### C: Camera in, then the flat copy takes over
- **What it looks like:**
  - The camera glides to the kiosk as in A. On arrival, today's reader (`directory_ui.gd`) opens
    with its picture laid exactly over the 3D panel's place on screen. There is no dimming and no
    drawn frame (the real 3D frame is around it), so nothing visibly jumps.
  - From then on it is today's reader: wheel/pinch zoom, drag, tap, the hover name tag, the
    "Jump to this store?" box, the 1995/2026 time-travel toggle.
  - On a phone it opens already zoomed to the list at reading size. The mipmap fix is on.
  - Evidence: `directory-optC-<2026|1995>-<desktop|phone>-unbaked.jpg`, and
    `directory-optC-2026-iphone3x-unbaked.jpg`.
- **Authenticity:** medium.
  - The arrival is the 3D kiosk.
  - After that it is a flat picture with today's buttons, the name tag and the confirm box. Those
    are overlay text, which is what Steven is moving into the menu.
  - The flat copy is a little brighter than the lit 3D panel, so the handover shows as a slight
    brightening.
- **iPhone legibility:** as B on the list, since it opens at the same scale. It is the sharpest of
  the three with device pixels, because 2D is always drawn at full resolution there (see the lever
  below). Desktop opens on the whole sign (3.8 px capitals) and needs the wheel.
- **Cost to finish:** about 0.5 day. Almost everything exists and is tested. The work is the
  handover on window resize and the brightness match. It keeps today's overlay text unless that
  text moves to the menu.

#### The sharpness lever (applies to A, B and C; Steven's call, global)
Draw the game at device pixels on phones:
- `allow_hidpi=true`.
- At start, `root.content_scale_factor = devicePixelRatio`, so the HUD keeps its size.
- `root.scaling_3d_scale = 1 / devicePixelRatio`, so the 3D world costs what it costs today.

While the camera is on the sign (A, B), `directory_look.gd _sharp()` raises the 3D scale to 1.0.
The view is then one unshaded quad, which is cheap even at 3x. C's flat copy is 2D and already
sharp.
- **Benefits:** every HUD and menu text on an iPhone gets 3x sharper too.
- **Risks:**
  - Global and untested on a real iPhone. The cloud cannot measure frame rate or Safari memory.
  - The 4x panel is ~100 MB of texture memory per year when uncompressed. ASTC would blur the type.
    3072 px is the fallback.
  - Some WebGL devices cap textures at 4096. The 4x panel is 4580 px tall, so the fallback would be
    needed there too.
  - Without the lever, the 4x panel buys nothing over 2048 on a phone (0.72 px per 2048-px is
    already downsampling). It matters only at device pixels or a big desktop window.
- Simulated natively with `--hidpi=3 --resolution 1170x2532`
  (`directory-opt*-iphone3x-unbaked.jpg`).

## How the map gets regenerated (layout changes, e.g. the C2 corner / Zales s33+s34)
Nothing bakes a picture of today's outline into code. The reader reads the painted panels and
their click areas, and those come from the layout files. This is how Steven's C2-corner change
(`ws/corner-2026`) reaches the kiosk at integration:
1. `godot --headless --path . --script res://tools/stores/directory/make_data.gd` writes `map.json`
   from `layout_mall.json` / `layout_2026.json` (`map_data.gd`).
2. `python3 tools/stores/directory/paint_dir.py` writes `tex/dir/panel_<year>.png` and
   `tex/dir/hotspots.json`.
3. **New:** `DIR_K=4 DIR_OUT=tex/dir/hi python3 tools/stores/directory/paint_dir.py`, then delete
   `tex/dir/hi/back.png` and `hotspots.json` there. This writes the 4x panels the reader uses. The
   click areas stay the 2048 ones, scaled.
4. Rebuild the wings: their `gen/<wing>/directory.json` jump spots come from the layout too.

**What follows the layout:**
- **1995:** the plan is drawn from the game's map, so the moved court and the Orange Julius corner
  unit appear by themselves.
- **2026:** the coloured blocks are the **real sign's diagram, traced** (`paint_dir.py BLOCKS`). A
  layout change moves the stores' stretches on those blocks (`map_spot_2026`, from frontage order)
  and the click areas, not the block outlines. Zales on s33+s34 gets one stretch spanning both.

The pages and map framings are computed at run time from the click areas (`_columns()`,
`_make_pages()`), so they follow a repainted list or map without changes.

## Files (branch ws/directory)
- **Runtime:**
  - `scripts/directory_ui.gd`: the reader (option B), rewritten; the old flat reader is gone.
  - `scripts/directory_kiosk.gd`: `interact()` opens the reader; the year switch on the frame
    (`_build_switch()`, `switch_key_at()`, `switch_key_pos()`).
  - `scripts/hidpi.gd` (new autoload) and `project.godot` (`allow_hidpi=true`, autoload `Hidpi`).
  - `tex/dir/hi/panel_1995.png`, `panel_2026.png` (+ `.import`: lossless, mipmaps). They ride in
    the existing `tex/dir/*` export filter.
- **Painter:** `tools/stores/directory/paint_dir.py`: `DIR_K` / `DIR_OUT` overrides (defaults
  unchanged).
- **Tests:**
  - `tools/stores/directory/kiosk_test.gd` (new): the whole reader, natively, in the preview room.
  - `tools/stores/directory/ui_test.gd`: the in-wing keyboard jump, updated for B.
  - `tools/qa/menu_test.gd`: its directory step checks the year switch on the kiosk.
  - Removed: `tools/stores/directory/ui_shot.gd`, `tools/qa/dirlook_mini.gd`.
  - **Out of date:** `tools/stores/directory/dirtest.js` (web) still clicks where the old flat
    reader drew the sign; it needs rewriting against the camera view before the next web check.
- **No rebake:** the kiosk is dynamic (the switch is made at run time) and nothing baked changed.

## Checks (Nov 4 2026, final)
- `xvfb-run -a -s "-screen 0 1600x2600x24" godot --path . --rendering-driver opengl3 --resolution
  <size> --script res://tools/stores/directory/kiosk_test.gd -- --year=<1995|2026> [--hidpi=3]
  --out=<prefix>` → **KIOSK TEST OK (25 checks)** for 1280 × 720 both years and 1170 × 2532 at
  `--hidpi=3` (an iPhone at device pixels) both years. Open, camera, 3D at full scale, list at
  reading size, swipe a page and back, tap a name (lit, camera on the block), tap the lit block
  (confirm, names the store), Yes (`jump_to` with the store's spot), closed and 3D scale restored,
  Enter / Down / Esc, the current year's key does nothing, the other year's key starts the trip.
- Evidence (unbaked, the preview room): `production/qa/evidence/directory-B-final-<desktop|
  phone3x>-<1995|2026>-unbaked.jpg`.
- In-wing keyboard jump (`godot --headless --path . --script res://tools/stores/directory/ui_test.gd
  -- <scene> <name>`): `wing1.tscn dil` → Dillard's (#67) in wing 5, and `wing1_2026.tscn foot` →
  Foot Locker in wing 2_2026: **UI TEST OK** both. The test now waits for the list (up to 12 s),
  since a wing's first frames hitch while its characters bake.

## Open questions for Steven
1. The year switch is not on the real 2026 kiosk. Is a small dark plate with two keys on the
   bottom rail right, or would you rather it be lit buttons in the sign's cyan band?
2. On a portrait phone the map view for most stores shows the lit block without its name (the
   2026 sign has no names on blocks). The name is in the confirm and on the lit line when you go
   back. Enough?
