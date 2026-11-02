# The Lion's Share: front and dining room (1995 map, store n36)

**Source (Oct 7, 2026).** The Southland facade record (level 1): "a dark brown brick front with no windows, a carved plaque with the name in gold, two coach lamps, and a single open doorway onto a dim passage that leads back to the dining room." The flat front gives the shield-shaped plaque on the right with "The Lion's Share".

**Accuracy level:** 1. Stand-in type on the plaque (Lora).

**Guessed:** the dining room: dark panelling, red carpet, white cloths, candles, booths along the back wall, ladder-back chairs, sconces.

**Frame.** A 12 m front facing north at z = 48 (x -50 to -38), between Gadzooks and Wicks 'N' Sticks, built the full 12 m deep: a 4 m passage, the dining room behind. The rooms either side of the passage are closed. Map tiles x 123–128, y 118–123.

## Front
- Dark brown brick, no windows; a dark wood door frame; a coach lamp either side of the doorway.
- The carved shield plaque in gold on dark wood, on the right.

## Inside (walkable)
- A dim brick passage with a low dark ceiling and red carpet.
- The dining room: dark panelling, a dark ceiling, booths along the back wall, tables with white cloths and candles, warm sconces.

## Files
`tools/stores/small/wave9.gd`, `paint9.py` → `tex/w9/`. Hooks in `tools/build_mall.gd` and `tools/open_interiors.py`.

## Nov 1, 2026 (workstream D): the gold lions
Steven (Nov 1): "the crest is fine; add the gold lion statues out front, as in the 2D game."
- **Source:** the 2D game (index.html): "a bronze lion sitting on its plinth either side of the door, painted on the brick as if standing in front of it, both looking straight out across the hall", drawn from a photo of a seated gold lion (the game's media `lion`: front view, full flowing mane, upright chest, straight front legs, big paws).
- **Built:** a seated gold lion on a dark plinth either side of the doorway, 1.25 m out from the door jambs and 0.55 m out in the hall: plinth 0.55 m, lion 1.45 m tall. Sculpted from rounded solids (`lion()`, `ellipsoid()` in `wave9.gd`): body, haunches, straight front legs, paws, the tail curled round the plinth, a head with muzzle, ears and dark eyes, and a mane of two rings of flat, downturned locks. Satin gold (`w9_lion_gold`), plinth `w9_lion_plinth`. Both face out; the tail is on the outer side of each.
- **Guessed:** size, plinth, exact spot, the gold finish (the 2D note says bronze, its photo is gold; Steven says gold). The crest, coach lamps and brick are unchanged.
- **Period check:** cast lions at a restaurant door are timeless; fine for 1995.
- Evidence: `production/qa/evidence/wsD-lions-share-preview-unbaked.jpg`, `wsD-lions-share-concepts-closeups-unbaked.jpg`.

## Nov 1, 2026 (workstream T2): the Blender lion, second pass
`models/bl_ls_lion` (Blender, `design/godot-blender-pipeline.md` "Second batch") was rebuilt after Steven's
"they don't look good" and "fill out the side and back": carved face, tiered mane locks front and back,
seated anatomy on the side and back. It is not in the scene yet: it replaces `wave9.gd lion()` when the
integration session swaps it in, at D's two spots (`P(lu, 0, -0.55)`, the right one mirrored). Size guess
to settle: the model is ~0.95 m on a 0.32 m plinth, D's are 1.45 m on 0.55 m.

## Nov 2, 2026: D's lions removed; Blender lion pending
Steven (Nov 2): remove the gold lion statues (workstream D's `wave9.gd lion()`, sculpted from rounded solids). Removed from the build with `lion()` and its `ellipsoid()` helper; the spots either side of the door are empty. The crest (plaque) and the sign stay. **The Blender lion comes in the next job:** its two spots are kept in `tools/stores/small/lion_spots.json` (world floor points, the facing yaw, the mirror flag; logged by the build as `LION_SPOT`) and in a comment in `wave9.gd lions_share()`. Wing 2's day lightmap still carries the removed lions' baked shadows until the next bake.
