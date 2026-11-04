# wsCHARS: pack sizes and web checks (Nov 3 2026, branch ws/chars-pack, unbaked, Demo 49 lightmaps)

Design: `design/godot-build-hosting.md` "Shared packs". Builds: `.scratch/builds/base` (this branch's merge of
main + ws/chars-live, before CHARS) and `.scratch/builds/chars` (after), both from `tools/export_web.sh`.

## Pack sizes (MB; desktop = mobile to the byte)
| Pack | Before | After |
|---|---|---|
| w1 | 98.91 | 85.21 |
| w2 | 97.35 | 82.91 |
| w3 | 31.98 | 31.98 |
| w4 / w5 / w6 | 36.73 / 38.68 / 21.66 | 36.65 / 38.60 / 21.58 |
| w1y26 | 43.09 | 43.09 |
| w2y26 | 68.10 | 66.39 |
| w3y26 | 14.85 | 17.81 (+ npc/anims.res) |
| w4y26 / w5y26 / w6y26 | 31.35 / 33.48 / 21.79 | 31.27 / 33.40 / 21.71 |
| items (shared) | – | 22.64 |
| chars (shared) | – | 42.23 |
| chars_w1 / chars_w2 | – | 0.39 / 1.88 |
| all packs, one kind | 538.0 | 577.7 |

`DRY_RUN=1 tools/publish_build.sh .scratch/builds/chars`: all checks pass; main site 614 MB, desktop site 574 MB
(the dry run was before the w3y26 animation change: +3 MB each).

## Checks
| Check | Result |
|---|---|
| `tools/qa/char_clothed_test.gd` (native) | CHAR CLOTHED OK (1608 checks) |
| `tools/qa/char_editor_test.gd --only=unit` (native) | CHAR EDITOR OK (16 checks) |
| `tools/qa/shared_webtest.js`, all 12 maps, desktop packs, third person (final build) | SHARED WEB OK: items mounted before the scene, character packs mounted, 3 attendants dressed from presets, 0 console errors on every map |
| `tools/qa/shared_webtest.js`, all 12 maps, mobile packs, 390x844 touch, third person | SHARED WEB OK, 0 console errors on every map (w3y26 and w1 re-run on the final build) |
| `tools/qa/char_webtest.js` (B2's: owner editor K, menu AVATAR tab, phone) | CHAR WEB OK, 0 errors desktop and phone |
| `tools/qa/movetest.js` wing 1 | loads, touch walk MOVED, 0 errors |

Software rendering (swiftshader); character packs arrive 7–123 s after load there.

## Pictures (all unbaked)
- `wsCHARS-all-maps-desk-unbaked.jpg`: the 12 maps, desktop packs, third person (the player's preset body).
- `wsCHARS-all-maps-phone-unbaked.jpg`: the 12 maps, mobile packs at phone width (taken before the w3y26
  animation fix: the 2026 outside shows the body in its bind pose there; fixed, see the next file).
- `wsCHARS-w3y26-avatar-animated-phone-unbaked.jpg`: the 2026 outside after the fix.
- `wsCHARS-w1-attendant-preset-desk-unbaked.jpg`, `wsCHARS-w2-attendant-items-desk-unbaked.jpg`: the
  PLACEHOLDER attendants on their presets; wing 2 also shows the Blender items from the shared pack.
- `wsCHARS-web-owner-editor-desk-unbaked.jpg`, `wsCHARS-web-avatar-creator-desk-unbaked.jpg`: both editors on the web.
