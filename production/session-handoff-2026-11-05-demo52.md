# Handoff: Demo 52 (Nov 5, 2026, ~9:35 PM CT): eleven workstreams, nov4 bake look

**State: published.** `godot-build` = `30a7645` (no packs; its page names R2 build `20261106-0332-76f5ee18`),
`main` = int-52 (this handoff's commit). Packs: https://pub-848b5102ea0e4d78999797a799545451.r2.dev/builds/20261106-0332-76f5ee18/
(1550 MB, both kinds; uploaded, sizes checked and served with CORS by `publish_build.sh`).
**Steven: please look at the live page** (cloud boxes can't reach github.io).

Records: `production/session-handoff-2026-11-05-int52.md` (merges, conflicts, tests, questions) and
`production/session-handoff-2026-11-05-demo52-prepublish.md` (stand-ins, export, web tests, every screenshot).

## What is in it
items, interiors, corner-2026 (C2 both years), exterior, directory (option B, kiosk 1990s/2026 switch),
ui-offscreen (screen text into the menu), bake-look (nov4 profile), char-editor, chars-ubc (Quaternius UBC;
MakeHuman dropped), lynns (403 pieces, no appliances), owner-tools (owner directory, picture upload, NES-only
Pocket Change cabinets).

## Bakes (Steven's Air, Godot 4.7.2)
- Nov 5, 3:50-4:33 AM: nov4 `day` for wings 1, 2, 4, 5 (both years), `fastday` for wing 3 (both years). All ok.
- Nov 5, 9:05 PM: **wing3_2026 rebaked at `day` (Ultra)**: the Medium bake left the canopy-shadowed pavement at
  the 2026 main entrance pitch black. Fixed: `production/qa/evidence/d52-w3y26-entrance-fixed-rebaked.jpg`.
  After it: `capture_standin.sh 3 2026` (which also rewrites the 2026 door pictures shown in wings 1 and 2),
  import, re-export of wings 3, 1, 2 and the shared step, dry run, publish.

## Packs (MB, desktop = mobile)
| Wing | 1990s | 2026 |
|---|---|---|
| 1 | 87.28 | 49.31 |
| 2 | 91.49 | 70.66 |
| 3 outside | 48.27 | 30.93 |
| 4 Sears / Lynn's | 42.63 | **96.07** |
| 5 Dillard's | 43.53 | 38.37 |
| 6 cinema | 24.40 | 24.53 |
Shared: items 72.98, chars 53.38, chars_w1 0.56, chars_w2 0.82, chars_w2y26 0.09.

## Tests
Native suites: see the int-52 handoff (stockrooms_test's three known Woolworth's back-corner fails remain).
Web (baked, swiftshader): walk moved in 12/12 packs, doors 7/7 crossed, 0 errors; Spencer's 2026 shop opens;
pictures publish / pick and NES cabinets OK. signstest.py and avatar_webtest are stale (not game bugs).

## Open for Steven
1. Check the live page; iPhone: wing 1 memory (fallback `nov4_lite`) and wing 4 2026 at 96 MB.
2. Floor shine: compare `?floorspec=0` (and `?refl=0`) against the default 0.25.
3. 1990s main entrance: "SOUTHLAND MALL" shows twice (parapet letters cut by the canopy + fascia letters). Next round.
4. Spencer's talk camera frames the attendant's face very close.
5. Delete on GitHub: `tmp/publish` (cloud delete refused). Delete `~/GodotProjects/rclone.conf` and
   `~/GodotProjects/_to_delete_d52` on the Air.
6. Carried questions: the int-52 handoff "Questions" section.

## Tooling to fix next
- `capture_standin.sh` doesn't import its new pictures before capturing the mall wings (wings 1/2 were
  recaptured by hand); add an import step.
- `publish_build.sh` still requires `wing{1,2}_night.lmbake` though night is never shown (Demo 51's were copied in).
- signstest.py and avatar_webtest.py: update for the menu-only UI.

## Lessons
- The Mac's computer-use grant expires after 30 idle minutes and a locked screen blocks clicks; overnight bakes
  need Steven to approve again in the morning. `.autobake` + opening the project still works.
- Headless reimport of the ten new lightmaps took over an hour on the 2-CPU box (wing 3's exr longest).
- Cloud bakes of wing 3 need 12 GB swap; this box (2.1 GB disk free) can't.
