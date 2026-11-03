# Session handoff: INT, Demo 49 (Nov 2-3, 2026)

**Merged into `integration`, in order:** ws/q-dialogue `e8c0232`, ws/m-menu `f965460`, ws/r-redemption
`7ad868c`, ws/s-dept-wings `c93033b`, ws/l-lion `43f3cb6`, ws/gi-games-inc `9df5553` (all heads as briefed).
ws/b1-bodies, ws/b2-editor and ws/chars-live were not touched. Commits are as Steven, with the trailers.

## Conflicts and how they were settled
- **export_presets.cfg** (M, R, S): a 3-way, per-preset, per-key merge (comma-list filters token by token:
  a token either side removed goes, every added token stays), never by hand. Then S's
  `tools/make_presets.py` was re-run. That script's room-wing filters were hardcoded, so it now also ships
  `addons/dialogue_manager/*,data/story/*` in wings 4-6, and in 2026 the same NPC skins as the 2026 mall wings
  (M's 2026 shoppers walk every 2026 wing; before this, `npc/*` was excluded there).
- **scripts/inventory.gd** (Q, M): P's `extra`, Q's `flags` and M's `player_name` block all kept.
- **scripts/player.gd** (M, S): Story (Q), Menu (M), then the cinema gates (S). Wing 6 now returns before the
  2026 shoppers are made too (no shoppers in the lobby in either year).
- **Q's "remove when M lands" fallbacks** (`scripts/dialogue/dialogue_state.gd`) removed: `held()` is
  `mall.held_id()`.
- **R:** the `mall.redemption.open()` hunk in `scripts/attendants/attendant.gd` uncommented.
- **data/story/gates.json:** S's version (the cinema only). Q's Dillard's gate and its door locks s2e/s2s
  are gone; Dillard's is open.
  **One gate system per entry:** Q's `story.gd` skips entries with `"threshold"`; S's `cinema_gate.gd` makes
  those. S's until-Q/until-M fallbacks were removed, so `cinema_unlocked` lives only in `mall.flags`,
  holding is `mall.held_id()`, and the locked message goes through `Story.say`.
- **L:** `BL_LION := true`, the else branch and D's `lion()`/`ellipsoid()` dropped, `BL_LION_SCALE 1.0` (0.95 m).
- **data/story/attendants.json:** Q's `"attendants"` and GI's `"spots"` both kept; `story.gd` reads only
  `"attendants"`. No NPC at Games, Inc.
- `layout_2026.json` regenerates byte-identical from `make_layout_2026.py`.

## After the merges
1. `scripts/menu/actions.json`: row `tilt` (kind `fixed`: the pusher page's N/B/Shift, LB/RB, NUDGE, shake).
2. Rebuilt wings 1-6, both years (BUILD OK x12). This also fixed `gen/w3*/wing.json`: S's branch had a stale
   wing 3 build with the anchors' outside doors still in wings 1/2; they are now in 4/5.
3. Stand-ins recaptured: 4, 5, 4 2026, 5 2026, then 1, 2, 1 2026, 2 2026, then 3, 3 2026. All stamps match.
4. CLAUDE-CLOUD.md: the story rule ("Steven writes the story; Claude builds the machinery ...").
5. Tests updated to the merged code: `interact_test.gd` (the bag is M's INVENTORY tab), `flags_test.gd`
   (gates.json holds only the cinema), `wsS_thresholds_test.gd` (the message comes from Story.say).
   New: `tools/qa/int_d49_test.gd`.

## Wing 2 and the lion
The first export put wing 2 at **103.98 MB** (the lion: three 2048 px textures, 8.82 MB, plus its 1.2 MB mesh).
Per the brief, only the lion's own textures were reduced. They keep their 2048 px resolution, stored as lossy
WebP at q 0.85 instead of lossless (8.82 -> 1.89 MB). Wing 2 is now **97.05 MB**. Halving them to 1024 lossless
would have saved only 4.6 MB (99.3 MB), so lossy at full size was the better trade.
Before/after, same camera, unbaked: `production/qa/evidence/int49-lion-before-after-unbaked.jpg`.

## Packs (MB, desktop = mobile to the byte)
| Wing | 1995 | 2026 |
|---|---|---|
| 1 | 98.61 | 42.79 |
| 2 | 97.05 | 67.80 |
| 3 (outside) | 31.68 | 14.55 |
| 4 Sears / Lynn's | 36.43 | 31.05 |
| 5 Dillard's | 38.38 | 33.18 |
| 6 cinema lobby | 21.36 | 21.49 |

- **Wing 1 is at 98.61 MB** (Demo 48: 91.5). The growth is R's prize models (`bl_pc_*`: fingertrap, boombox,
  plush, ~5.5 MB; carried items ship in every wing), the Sears opening picture (0.83) and the dialogue addon.
  It is the next ceiling.
- The 2026 mall wings and the room wings grew by the NPC skins (M's 2026 shoppers).

## Tests (all on the merged code)
- Headless: FLAGS 31, INVENTORY 45, MENU UNIT 35, REDEMPTION 32, PUSHER PLAY 20, DIALOGUE WALK 67, WSS (thresholds and
  cinema gate) both years, INT D49 18 (the Pocket Change attendant opens redemption; a PLACEHOLDER talk at the
  Sound Shop; menu INVENTORY -> CONTROLS (the tilt row) -> YEAR -> close; Games, Inc. 2026 with no attendant).
  With a renderer: INTERACT (wing 2: 19, wing 1: 8), PRIZES 8.
- Web (swiftshader), on the export:
  - **movetest**, all 12 wing/year packs: 0 errors, walk MOVED;
  - **doortest**, both years: 1->3, 2->3, 1->4 (Sears), 4->3, 2->5 (Dillard's, no key), 5->3: all CROSSED, 0 errors;
  - **wsS_webtest**, both years: WSS WEB OK. Sears and Dillard's thresholds both ways; the cinema refuses
    empty-handed, opens holding folse_stick, the next press enters wing 6, and the flag survives a fresh load;
    directory jumps to 4/5;
  - **COIN COMET:** E opens `pusher.html?pos=1`, 0 errors;
  - **year switch:** Y opens the YEAR tab, 2026 reloads into 2026. Under swiftshader it takes over 120 s.
- `tools/qa/dialogue_shots.gd` still has a Dillard's-locked step (Q's): stale, not run, needs updating.

## Mac bake list
`wing1:day wing2:day wing4:day wing5:day wing4_2026:day wing5_2026:day wing1_2026:day wing2_2026:day`
- Wing 1 (1995): its output changed (the Sears box left for wing 4; the cinema roll gate).
- Wing 2 (1995): the removed props' shadows, the lion, the Dillard's box gone to wing 5.
- Wing 1 2026: S's cinema grille moved out of H1a.
- Wing 2 2026: GI's Games, Inc.
- Wing 6 never. Wing 3 unchanged apart from `wing.json` (no rebake).

After the bake, delete `.godot/imported/<lightmap>.exr-*` before `--import`. Bring back only the lightmaps
(`.exr`, `.exr.import` with the right slice counts, `.lmbake`).

**Stand-ins to recapture after the bake, in this order:** `4`, `5`, `4 2026`, `5 2026`, then `1`, `2`,
`1 2026`, `2 2026`, then `3`, `3 2026` (the door pictures show wings 1/2).
