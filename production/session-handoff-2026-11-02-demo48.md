# Session handoff: Demo 48 (Job 1), Nov 2, 2026

**State:** published. `main` = `integration` = `b67e43d`; `godot-build` = `3792991` ("Demo 48: COIN COMET playable").
Live: https://stevenboudreaux.github.io/Southland-Mall-95/ (the Pages deploy was not checked from the cloud box: the proxy blocks github.io).

Commits on top of `326ed7c` (all as Steven, with the Claude trailers; the stop hook's noreply request was ignored per Steven's rule):

| commit | what |
|---|---|
| `2b5ab87` | merge `origin/ws/p-coin-pusher` (P's COIN COMET) |
| `50582d3` | removals (Silverman/Goldman, Concepts display, D's lions), directory regenerated, wings 1-2 rebuilt both years |
| `2cfe54c` | pusher: quarters to play, tickets to win; Get quarters; tests; d48 evidence |
| `b67e43d` | pusher tuning shipped (5.3 % into the cup at a 0.5 mm lip); soak table in the design note |

## Setup notes for the next session

- **The brief's handoff file `claude/session-handoff-2026-11-01-FINAL-read-first.md` does not exist** on any branch. Setup followed `CLAUDE-CLOUD.md` instead (clone here is `/home/user/Southland-Mall-95`, Godot in `/home/claude/godot`).
- Restore from `godot-build` **from the repo root** (a `git archive` run inside the project folder fails on the pathspec):
  `git archive origin/godot-build lightmaps standin | tar -x -C prototypes/godot-mall/project`, then move
  `lightmaps/*` into the project folder and `standin/*` into `tex/standin/`. `lightmaps/` on `godot-build` includes the `.exr.import` files (8 EXRs: six day + wing 1/2 night).
- The import took ~25 min.
- **Python Playwright is not preinstalled** (only Node's). `pip install --break-system-packages playwright`, then launch with `executable_path="/opt/pw-browsers/chromium-1243/chrome-linux64/chrome"` (P's scripts read `PW_CHROME` / `CHROMIUM`).
- `tests/unit/pusher/page_test.py` needs `play/` served on :8766: `(cd prototypes/godot-mall/play && python3 -m http.server 8766 &)`.
- `node --test tests/unit/pusher/` (a directory) fails in Node 22; use `node --test tests/unit/pusher/*.test.js`.
- A scratch web build needs `pusher.html`, `pusher/`, `lib/` and `play/*.json` symlinked in from `play/` to test the pusher; **delete those links before `publish_build.sh`**. The one 404 left in a scratch build is `play/prize_text.json` (optional; it exists only once owner prize edits are published).

## Part 1: merge P

Clean merge, no conflict (not even in `scripts/inventory.gd`). `tools/build_mall.gd` was not touched by P; the six "Play COIN COMET" prompts are created at runtime from `scripts/signs.gd` (`scripts/pusher_play.gd`), so the merge itself needed no wing rebuild. P's tests passed before changes: `pusher_play_test.gd` (20 checks), `inventory_test.gd` (45). The Node tests and `page_test.py` were first run after the payout edits had started, so only the Godot tests are a strict baseline.

## Part 2: COIN COMET payout and tuning (`design/storefronts/pocket-change.md`, "Demo 48")

- **Quarters to play, tickets to win.** A drop spends one quarter from `mall-state-<year>.quarters` (new player 20 = $5.00). A coin into the cup pays `CONFIG.ticketsPerCoin` = **50** tickets to `mall.tickets`, no quarter back. P's `currency` switch is removed. `logic.js` has new `tickets()` and `refill()`.
- **HUD** (`play/pusher.html`): QUARTERS and TICKETS chips (top right), a "+50" that rises from the cup (only fades with reduced motion), the cup sound kept, the title card says each coin pays 50 tickets.
- **Get quarters:** shown at 0 quarters, refills to $5.00, free. The note says it is a placeholder for a change machine.
- **Shipped tuning:** lip **0.5 mm** (`logic.js CONFIG.lipMm`), friction **0.06** (unchanged), stroke **9 cm** (deck travel 9.5 cm with the drive's play) and crank period **2.5 s** (`sim.js GEOM`, commented as tunings: the video measured 50 mm and 4.5 s), high quality **760** coins. Result: **5.3 % of coins dropped into the cup, 1.97 coins/min, side holes 20 %.**
  **8 % with a lip was not reached within the 12-run cap (11 runs used).** The owner-only lip setting (⚙, 0-6 mm) is kept.
- **Soak table** (P's size: `soak.mjs <lip> <coins> 400 1 300 '<GEOM JSON>'`; `soak.mjs` now takes a GEOM-override JSON as its 6th argument; ~70 min a run, four in parallel):

  | lip | friction | other | cup % | side % | cup/min |
  |---|---|---|---|---|---|
  | 1 mm | 0.06 | P's machine (stroke 4.5, period 4.5, 540 coins) | 0.0 | 10.8 | 0 |
  | 2 mm | 0.06 | same | 0.0 | 13.5 | 0 |
  | 3 mm | 0.06 | same | 0.0 | 8.5 | 0 |
  | 1 mm | 0.10 | same | 0.0 | 1.3 | 0 |
  | 1 mm | 0.15 | same | 0.0 | 0.0 | 0 |
  | 1 mm | 0.06 | stroke 9 | 0.3 | 23.8 | 0.09 |
  | 1 mm | 0.06 | stroke 9, heap 760 | 1.3 | 23.5 | 0.47 |
  | 1 mm | 0.06 | stroke 9, heap 760, period 2.5 | 1.3 | 24.8 | 0.47 |
  | 1 mm | 0.06 | stroke 12, heap 760, period 2.5 | 1.5 | 26.0 | 0.56 |
  | 1 mm | 0.06 | stroke 9, heap 760, period 2.5, restitution 0.30 | 1.5 | 18.8 | 0.56 |
  | **0.5 mm** | **0.06** | **stroke 9, heap 760, period 2.5** | **5.3** | 20.0 | 1.97 |

- **Known gaps:** phones start at low quality (540 coins), which will pay less than 5.3 % (not soaked). The field still grows (~730 → ~1,300 coins over 700 drops): the machine is still filling, not at a steady state.
- **What to try next:**
  - stroke 12 at lip 0.5 mm;
  - narrower side holes (they take about four times the cup);
  - a starting heap saved from a long soak;
  - P's forward creep on the shelf;
  - a soak at phone quality.
- **Tests now:**
  - `logic.test.js` 13 ok: the wallet pays tickets, no quarter back, 20 drops then a refill.
  - `sim.test.js` 7 ok: the crank's travel is checked against GEOM (9.5 cm); the fresh-fill tolerance is ±45, because the longer stroke settles more coins over the edge.
  - `page_test.py` ALL OK: tickets in the HUD, Get quarters shows at 0 and refills to 20, the coin counts read from CONFIG.
  - Godot tests ok.
- Small edit: the `scripts/inventory.gd` header comment now says tickets come from COIN COMET.

## Part 3: removals (1995; none of these exist in 2026)

All four spots are in **wing 2** (not wing 1).
- **Mr. Silverman's island:**
  - Removed the island block in `tools/stores/directory/kiosk.gd`, plus `island_kiosk()` and the old `gold_kiosk()` ("Mr. Goldman") in `tools/build_mall.gd`.
  - `directory_data.json` "extras" is now empty. `map.json` was regenerated (`make_data.gd`), and `tex/dir/panel_1995.png` and `hotspots.json` were repainted (`paint_dir.py`), so #91 is off the 1995 map. The 2026 panel was byte-identical.
  - `design/godot-directory.md` records the answer: no jewelry island under either name.
- **Concepts display in front of Chick-fil-A:** `wave9.gd display()` and its call removed; the store stays (`design/storefronts/concepts.md`).
- **D's gold lions:** `wave9.gd lion()` and `ellipsoid()` removed. The crest and sign stay; the `w9_lion_*` material cases are still in `fill_mat` but unused.
  - **Spots for the Blender lion** (`tools/stores/small/lion_spots.json`; the build also prints `LION_SPOT` lines): floor points (−47.6, 0, 48.55) and (−43.9, 0, 48.55). Both face +z (yaw 0, out across the hall); the right one is mirrored.
  - D's size was a 1.45 m lion on a 0.55 m plinth (0.62 × 0.72). T2's `models/bl_ls_lion` is ~0.95 m on a 0.32 m plinth: settle the size in the next job.
  - Note: `design/storefronts/lions-share.md`.
- **Notes:** `solarium.md` (women's clothing store, not a chain, not Cleo; question closed) and `rave.md` (women's going-out clothes, a few black items). No geometry change for either.
- **Rebuilt:** wings 1 and 2, both years (`BUILD OK` ×4). Wing 1 changed only in `directory.json` and `dyn_doorpic.res`. Wing 3 was rebuilt too, but its output was unchanged (node-id churn only), so it was reverted and its stamps still match.
- **Stand-ins:** `tools/capture_standin.sh` was run for 1, 2, "1 2026" and "2 2026" (not a bake). All four stamps match `tools/wing_hash.sh`.
- **For the next bake:** wing 2's 1995 day lightmap still carries the baked shadows of the removed island, display and lions. That is expected; the next job bakes.

## Part 4: export, test, publish

- `tools/export_web.sh .scratch/builds/d48`, no rebake. Packs (desktop = mobile): w1 91.5, **w2 93.5**, w3 30.9; 2026: w1 26.3, w2 70.6, w3 13.8 MB. All under 100 MB.
- **Movetest, wing 2, 1995, at the pusher (cam `-104.88,66.03,90,-20`):**
  - the PLAY COIN COMET prompt shows;
  - E opens `pusher.html?pos=1` in the frame;
  - a drop takes a quarter (20 → 19);
  - Back closes the frame.
  - Errors: only the optional `prize_text.json` 404.
- **2026 has no coin pusher** (`gen/w2y26/machines.json` has none; Pocket Change is 1995 only), so the 2026 half of the test does not apply. The evidence shot shows that spot.
- **Removal spots (1995, old lightmaps):** all three are empty.
- **Evidence** (`production/qa/evidence/`):
  - pusher: `d48-w2-1995-pusher-prompt.jpg`, `-pusher-page-drop.jpg`, `-pusher-closed-back-in-mall.jpg`, `d48-pusher-page-getquarters-refilled.jpg`;
  - 2026: `d48-w2-2026-pusher-spot-no-machine.jpg`;
  - removals: `d48-w2-1995-removed-{silverman-spot,lionsshare-front,front-of-chickfila}.jpg`.
- **Publish:** `tools/publish_build.sh` printed "published 3792991"; `origin/godot-build` is at that commit. There was a harmless "push negotiation failed; proceeding anyway" warning. Then `main` was fast-forwarded from `integration` and pushed.

## Open items

1. COIN COMET pays 5.3 %, not 8 %: see "What to try next" (the 12th run is unused).
2. Wing 2 (1995) needs a bake: the removed props' shadows are still in its day lightmap.
3. Blender lion: drop it at the two spots in `lion_spots.json`; decide its size (D's 1.45 m or T2's 0.95 m).
4. The live Pages deploy was not verified from the cloud box.
5. Credit spent: not visible to the session.
