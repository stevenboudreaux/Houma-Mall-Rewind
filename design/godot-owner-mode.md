# Owner mode: every owner tool in one place (Godot mall, branch `ws/owner-tools`, Nov 4 2026)

**Asked for (Steven, Nov 4, 18:36), owner ("master editor") mode:**
1. In owner mode all the old corner buttons come back on screen for him (Jump to, View, Avatar, Bag, the
   Menu label, the year jump), which UI-OFFSCREEN hid for everyone. Normal players keep the clean screen.
2. An owner directory in the menu: the kiosk's store list and jump, plus the 1990s / 2026 switch, so he can
   jump anywhere and between years from the menu. Nobody else gets it: everyone else walks to a kiosk.
3. One owner section in the menu gathering every owner tool, instead of loose buttons on the screen.
4. His own pictures on the mall's posters and ad panels (like the 2D game's poster upload).
5. Every playable emulator cabinet in Pocket Change becomes an NES.

## Who is the owner
A browser where the mall editor was unlocked: localStorage `southland-editor` = `1`, set by the main game's
secret code, the hallway code (`player.gd` `SECRET`, at the restroom hall's dead end; on a phone the swipe
version), or any visit with `?owner=1`. `player.is_owner()` is the one test; natively (tests, the editor)
it is Engine meta `mall_owner`. Being the owner only shows the tools; publishing anything still needs a
GitHub token with write access (the one the mall editor keeps, localStorage `southland-gh`).

## 1. The owner's screen
| | Visitor | Owner |
|---|---|---|
| Menu | the small unlabelled icon on touch devices; Tab / Esc on a desktop (UI-OFFSCREEN) | the labelled **Menu (Tab)** button on every device, under the fps line |
| Jump to (J), Bag (I), View (V), Avatar (C) | in the menu only | **on screen**, top right, as before UI-OFFSCREEN |
| Year: **Visit 2026 / Back to 1995 (Y)** | none (the year changes only at a kiosk, MENU2) | **on screen** under Jump to; a tap or **Y** (keyboard) switches the year where he stands, with the time-travel trip (`player._switch_year()`); hidden while the menu or a full-screen moment is open |
| fps line ("Houma Mall Rewind · Godot mall (1995) 60 fps") | none | top left; can be turned off in OWNER (kept in localStorage `mall-owner-hud`) |
| Reflections, Benches & plants, Lighting, Edit signs, Publish signs, Arcade, Shirt words | none | **in the OWNER tab** (no longer loose on the screen) |
| the signs' / pictures' status line ("Tap a sign …") | none | top left, while a tool is on |
| contextual owner buttons (Edit character (K) by a preset shopper, the prize counter's Edit / Publish words) | none | unchanged: they show where they apply |

How (small hunks, nothing renamed): `menu.gd _tuck_corner_buttons()` tucks a visitor's corner buttons, or the
owner's loose tool buttons (`owner_tool_buttons()`), into the hidden `OffscreenHud` holder; their own code
still sets `.visible` and lays out round them (VR's menu still reads `player.buttons[2].visible`), and every
hand-made tap test checks `is_visible_in_tree()` (added in `signs.gd` and `npc_shirt.gd`). It runs every
0.5 s, so tools made later (Signs, ShirtWords are added deferred) are tucked too. `player.owner_hud_sync()`
shows the year button for the owner and starts the corner column under the fps line.

## 2. The owner directory (menu, OWNER, DIRECTORY)
- **The list:** the stores on the kiosk's sign for that year (the ids in `tex/dir/hotspots.json`; no vacant
  units), each with its jump spot from `gen/<wing>/directory.json` (every wing's file lists the whole mall;
  wings without one, outside and the cinema lobby, read `gen/w1/`). Alphabetical; the 1990s carry the 1994
  list's numbers as on the sign ("26  Lane Bryant · wing 1"). One column on a phone, two or three wider.
- **The year keys** "1990s" / "2026" pick whose stores are listed. **Travel to 2026 here** (or the 1990s)
  switches the year where he stands (the same as the on-screen year button).
- **Jumping:** tap a store: the kiosk's question, "Jump to this store?", with the store and what loads
  ("Loads Wing 1", "Travels to 2026 · Loads Wing 2"); Yes (or Enter / A) closes the menu and calls
  `player.jump_to(wing, year, x, z, yaw)`: at once in this wing and year, otherwise that wing's / year's
  file loads there, with the time-travel trip across years. No, Esc or a tap outside goes back to the list.
- Keys / pad as every tab: arrows / d-pad move, Enter / A press; Q / E, LB / RB change tabs.
- Visitors: no OWNER tab (`menu.tabs()` is MAIN, INVENTORY, CONTROLS), so no directory outside a kiosk.

## 3. The OWNER tab's tools (menu, OWNER, TOOLS; `scripts/menu/owner_tab.gd`)
Each row only when the tool exists in this wing / year; behaviour unchanged, only where it is reached:
| Tool | What it does | Was |
|---|---|---|
| Owner HUD (fps line) on / off | the fps line | always on |
| Quick jump | the J panel (Sears, the entrance, Dillard's, JCPenney) | Jump to (J) |
| Year: Travel to … here | `player._switch_year()` | — (new, also on screen) |
| Edit signs on / off · Publish signs (n) | `signs.gd` (design/godot-owner-signs.md); the menu closes so he can tap a sign | top-left buttons |
| Arcade on / off | `signs.gd` Arcade mode: tap a PLAYABLE cabinet to put an NES game on it | top-left button |
| Edit pictures on / off · Publish pictures (n) | `pictures.gd` (below) | new |
| Shirt words | `npc_shirt.gd`'s form (1995, where the shopper is) | top-right button |
| Character editor | `chars/char_owner.gd` open, when a preset shopper is within 3 m (also K and its own button) | K only |
| Reflections, Benches & plants, Lighting | `player.gd`'s toggles | top-right buttons |
| The opening screen: Show it again | `menu.gd _owner_opening()` (also still under CONTROLS) | CONTROLS |

Not in the tab (they already work from the page or the place): the lighting panel (`web/shell.html`
`mallLight`, a page overlay on the owner's browser), the prize counter's words (inside its closer look),
the debug consoles (`window.mallFlags`, `window.mallLady`).

## 4. Pictures: the owner's own pictures on posters and ad panels
**Model (as recommended in the brief, like the owner signs):** Edit pictures → tap a poster → choose a
picture on the device → it shows at once (a draft kept in this browser) → Publish pictures commits it.
- **Which surfaces ("slots")** are found in the wing's own meshes when it loads, by material name
  (`scripts/pictures.json`), so there is no rebuild and no rebake:
  - **framed**: the nine framed Courier ads (design/godot-wall-posters.md; wing 1, 1990s). id `ad.<name>`
    (the ad's file name, e.g. `ad.gryders`). A new picture gets a **new frame wrapped round its own
    aspect**: the print's longer side stays 1.15 m, the same 6 cm white mat and 4.5 cm black rails, centred
    where the old print was; the old frame, mat and print are taken out of `dyn_posters` (a filtered copy
    of the mesh; the original is kept and put back on reset).
  - **panels**: poster and ad panels: the lit poster stands in front of Spencer's and the other 2026 poster
    panels (`f26_posters_lit`, `f26_posters`, `f26_phone_poster`, `cm_posters`), and in the 1990s the
    cinema's poster cases, the wall posters in the music and game stores (`cin_posters`, `gb_bl_posters`,
    `md_ss_posters`, `y95_gz_ads`, `ap_posters`, `w9_posters`, `poster`). Each flat patch of one of those
    materials (two triangles sharing an edge and the same art) at least 0.25 m across and no longer than 4×
    its width is one slot; long friezes are left out. id `<year>:<material>@<x>,<y>,<z>` (its centre to
    0.1 m), stable while the store's build keeps the panel in place. A new picture is **fitted inside the
    panel**, its aspect kept, on a dark backing that covers the old art, 4 mm in front of it; backlit
    panels stay unshaded.
  - Found today: wing 1 1990s 9 framed + 12 panels; wing 1 2026 6 panels; wing 2 2026 9 panels (Spencer's
    stands, the phone poster, the cm posters). Remove a material from `pictures.json` "panels" to take its
    surfaces out.
- **Choosing a picture:** the page's own dialog (`web/shell.html` `window.mallPictures.pick`): a real
  `<input type=file accept="image/*">` under "Choose a picture", so the iPhone's photo picker opens from his
  own tap; the picture is drawn to a canvas at most **1024 px** on its longer side and kept as a **JPEG**
  (quality 0.86, stepping down if it is over ~900 KB); a preview with its size; **Use this picture**,
  **Cancel**, and **Original picture** (reset) when the slot shows a custom one.
- **Draft:** localStorage `southland-pictures-draft` = {id: {data: JPEG data URL, w, h} | {reset: true}}. It
  survives a reload and a wing change. A browser keeps ~5 MB per site: about 15 pictures; past that it
  says so and the pictures stay up until a reload. Reset on a slot that was never published just drops
  the draft; on a published one it is a draft "reset" until published.
- **Publish pictures** (`window.mallPictures.publish`): with the editor's token, one commit per picture,
  `prototypes/godot-mall/play/posters/<safe id>-<8-hex content hash>.jpg` on `main` (the same picture twice
  is not uploaded again), then `prototypes/godot-mall/play/posters.json` read live and merged (new ones
  added, resets removed, everything else kept) and written against the live sha; a conflict stops with
  "someone else changed the poster pictures; reload and publish again".
- **How players get them:** `pictures.gd` reads `posters.json` next to the game (`{"pictures": {id: {file,
  w, h}}}`) and fetches each picture with an HTTP request; the frames and panels are made at run time.
- **Where the pictures live (the R2 move):** in the repo, under `prototypes/godot-mall/play/`. The Pages
  workflow copies main's tracked `play/` files to the site root on every push to main (design/godot-build-hosting.md;
  "Packs on R2" moved only the game packs to R2), so `posters.json` and `posters/*.jpg` are served at the
  site root beside `signs.json` and `roms.json`, about a minute after Publish. Nothing goes to R2 and no
  rebuild, export or rebake is needed. Size: a picture is ~100–300 KB; the site's 1 GB check in
  `pages.yml` counts them (it now holds only the page, the engine and main's `play/` files).
- Old picture files stay in `play/posters/` when replaced or reset (only the list changes); delete them by
  hand if the folder grows.

## 5. The arcade: NES only (design/godot-arcade-roms.md)
All twelve playable cabinets (`signs.gd` `ARCADE`) are NES: NES-red outline on the PLAYABLE sticker, "NES"
in Arcade mode; `play/emu.html`'s setup page says "This is an NES cabinet" and accepts only `.nes`, `.fds`,
`.unf` whatever the link names; play always uses the `nes` core; writing `roms.json` drops entries for other
systems, and the game ignores them. `play/roms.json` on this branch and on main (Nov 4) is empty, so no entry
was dropped. No ROM files are added: ROMs remain only what the owner uploads himself.

## Files
| File | What |
|---|---|
| `scripts/menu/owner_tab.gd` | the OWNER tab: DIRECTORY and TOOLS (new) |
| `scripts/menu/menu.gd` | OWNER hunks: `tabs()`, `is_owner()`, `owner_tool_buttons()`, the labelled Menu button, `_build_owner` |
| `scripts/player.gd` | OWNER hunks: the year button for the owner (tap, Y), `owner_hud_on` / `set_owner_hud`, the column's top, the `Pictures` node |
| `scripts/pictures.gd`, `scripts/pictures.json` | Pictures (new) |
| `scripts/signs.gd` | `set_editing`, `set_arcade`, `publish`, `draft_count`; native owner for tests; NES `ARCADE`; visibility-checked taps |
| `scripts/npc_shirt.gd` | visibility-checked tap |
| `web/shell.html` | `window.mallPictures` (between `PICTURES-BEGIN` / `PICTURES-END`) |
| `play/emu.html` | NES only |
| `play/posters.json`, `play/posters/` | the published pictures (empty) |

## Tests (unbaked)
- `tools/qa/owner_test.gd` (native, wing 6): **OWNER TEST OK (45 checks)**: visitor: no corner buttons, the
  icon, no fps, no OWNER tab, Y does nothing; owner: every corner button on screen at 1280×720, 390×844 and
  844×390, labelled Menu, loose tools tucked, taps on Jump to / Bag / Menu work; the directory lists 76
  (1990s) / 46 (2026) stores, no vacancies, the question and its note, No, Yes jumps to the stall's spot,
  the 2026 key, Enter answers Yes, Travel switches the year, a jump in this wing moves at once, the phone
  list fits; the tools (HUD off / on, Edit signs, Arcade, Edit pictures, Reflections); then Y loads 2026.
- `tools/qa/pictures_test.gd` (native, mocked chooser and publisher): wing 1 1990s **PICTURES TEST OK (19
  checks)** (nine framed ads at 1.15 m, the picture's aspect, the old frame out of the mesh, the new frame,
  the draft kept and back after a reload, portrait, reset, publish, a published reset, a cinema case panel,
  a visitor can't edit); wing 2 2026 **OK (6)** (Spencer's poster stand); wing 1 2026 OK (4).
- `tools/qa/pictures_publish_test.js` (Node, mocked GitHub API): **OK (18 checks)**.
- `tools/qa/pictures_pick_webtest.js` (Chromium, the dialog): **OK (9 checks)** (a 3000×2000 picture comes
  back 1024×683 JPEG).
- `tools/qa/arcade_nes_webtest.js` (Chromium, `emu.html` served locally, GitHub and the CDN mocked): **OK (14)**.
- Still passing: `menu_unit_test.gd` MENU UNIT OK (64), `ui_offscreen_test.gd --wing=6` UI OFFSCREEN TEST OK
  (35, after merging ws/ui-offscreen's touch-only icon), `kiosk_test.gd --year=1995` KIOSK TEST OK (25).
- Updated, not rerun (needs a web export, too big for the shared box's disk on Nov 4): `signstest.py` now turns
  Edit signs on through the menu (Tab, E×3, right, Enter, down×4, Enter).

## Evidence (`production/qa/evidence/owner-*.jpg`, unbaked)
`owner-screen-buttons-{1280x720,390x844,844x390}-w6`, `owner-visitor-screen-clean-1280x720-w6`,
`owner-screen-buttons-2026-after-year-switch-w6`, `owner-menu-tools-{1280x720,390x844}-w6`,
`owner-directory-{1995,2026}-1280x720-w6`, `owner-directory-ask-1280x720-w6`, `owner-directory-390x844-w6`,
`owner-pictures-framed-{before,after,portrait}-w1`, `owner-pictures-panel-{before,after}-w1` (cinema case),
`owner-pictures-spencers-stand-{before,after}-w2-2026`, `owner-pictures-pick-dialog-phone`,
`owner-arcade-nes-cabinet-w2`, `owner-arcade-nes-setup-phone`, `owner-arcade-nes-setup-done-phone`.

## Open / guesses
- Keyboard **Y** switches the year for the owner only (the label says Y); a gamepad's Y still opens the jump panel.
- The toggles (Reflections, Benches & plants, Lighting) moved into the menu with the other owner tools;
  if Steven wants them back on screen, drop `player.buttons` from `owner_tool_buttons()`.
- Panel ids carry the panel's position: if a store's build moves a poster panel, its published picture
  stops showing there (it stays in `posters.json`); the framed ads' ids are their file names.
- No rebake needed by anything here (all run-time geometry or UI).
