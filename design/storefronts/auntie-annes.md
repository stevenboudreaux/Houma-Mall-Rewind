# Auntie Anne's (2026 map, store n56)

**Asked for (Steven, voice note Nov 3 2026):** "I also have the kiosk for Great American Cookie and Auntie
Anne's. Those are pretty perfect. Auntie Anne's: you're gonna need to look at some of the videos from my
walkthrough, but that's exactly what the pretzels look like in the little things [the warming case]."

**Where and when:** 2026 only (`eras_2026.json` / `layout_2026.json` n56: tiles x 128-129, y 130-135, 4 m
front facing north onto the Concourse at z = 60, x -40..-36, 12 m deep; wing 2). In 1995 the unit was
Afterthoughts. Not walk-in: a counter stall, served across the front.

## What the footage shows
- **Southland, Oct 23 2026 (IMG_4439 f024-f025, `refs/derived/frames/IMG_4439/`; f025 is the sharp one).**
  A navy fascia the full width with the lit sign (the Demo 43 spec). Under it, the opening's head: a
  row of digital menu screens across the top and a small navy "Now rolling"-type sign at the right.
  Inside: white subway tile to about 2.2 m, a band of big orange / navy / cream / violet shapes above
  it; light wood slats on the right wall; the counter at the front with a white top over a light
  wood-look front; on its left third the warming case on a royal-blue front with the pretzel mark;
  staff in navy behind; the rolling counter (white top) along the back wall. A pennant banner hung
  that day (left out: temporary).
- **The clip `refs/new/auntie_annes/aa_t000_001-031`** (5 s, 144 x 256, not Southland): the warming case
  close up: stainless stepped tiers, rows of golden-brown salted pretzels leaning back, a front tier of
  navy cups heaped with pretzel bites, the royal-blue counter front with the gold pretzel-and-halo mark
  under it. Very low resolution: shapes and colours only.

## How it maps onto the stall
`tools/stores/auntie_annes/store.gd` (called from `fronts26/store.gd auntie()`, its left-to-right frame):
- Front: the navy fascia and piers (as before), a white header under the fascia with three lit menu
  screens (`tex/aa/screens.png`, invented lines and pictures), the FRESH ROLLED sign (invented words).
- Counter 0.2-0.85 m in, 1.0 m high: wood-look front (`oak.png`), white top; the left 1.5 m is the
  warmer's royal-blue base with the pretzel mark and a HOT • FRESH • ROLLED BY HAND strip (`front.png`).
- **The warmer: the Blender fixture `bl_aa_warmer`** (`tools/blender/assets_src/bl_aa_warmer.py`,
  `models/bl_aa_warmer/`): 1.25 x 0.55 x 0.6 m, three steel tiers, 12 leaning pretzels (every fourth
  cinnamon sugar), 8 navy cups of bites, sloped glass front, lit strip. Placed at run of the build under
  `BlenderProps` (as the lion), so it is baked with the wing.
- Inside, 4.6 m deep (the rest of the 12 m unit is stock, not shown): subway tile + the shapes band on
  the back and left walls, wood slats on the right wall, the rolling counter along the back with dough
  balls, ropes and a tray of shaped pretzels (`rolltop.png`), a two-deck oven at the back right, a
  butter / lemonade station behind the warmer, a register and napkins on the counter.

## Guessed
The depth to the back wall (4.6 m), the oven and the station (not in frame), the header height, the
number of screens (three; f025 shows two and part of a third), every word on screens and signs, the
pretzel count. The fascia sign and the pretzel mark are the tenant's own (IP rule: allowed); the cups
are plain.

**Checked by looking (Nov 4):** the rolling counter's dough was nearly white on white in the first pass;
`paint.py rolltop` now paints bigger, darker dough balls, ropes and a darker tray. The two lemonade
dispensers were bare tinted blocks; they now have a white base and lid, a tinted tank and a black tap.

## Evidence (unbaked, probe-lit preview)
`production/qa/evidence/interiors-auntie-annes-2026-{doorway,warmer,counter,staffside,rolling}-unbaked.jpg`.
The warmer's own Blender sheet was not kept by the first session (the asset script can re-render it).

## Rebake
Wing 2, 2026 (`wing2_2026`).

## Shoppable (built Nov 4, Steven's yes: shop `auntie_annes`, `design/godot-shops.md` "ws/interiors"; as proposed)
A counter shop (`design/godot-shops.md`), 2026: an original salted pretzel, a cinnamon-sugar pretzel, a cup of
pretzel bites, a lemonade. The pretzels in `bl_aa_warmer` are part of the fixture; a hand-item pretzel
(`bl_aa_pretzel`) could reuse its knot path (`KNOT` in the asset script). Prices and the attendant for Steven.

## FOOD3D (Nov 8, 2026): the counter mark and open cups of nuggets
- **The mark under the warmer** is redrawn to match the sign above: the sign's own traced pretzel, in its yellow,
  a halo over it in the same yellow, on a navy disc inside a ring of the sign letters' blue; painted at 1024 px
  (`paint.py front()`). The wordmark is not repeated; no other brand marks.
- **The cups:** open navy cups with a white band and rim (same size and colours as before), heaped above the rim
  with pretzel nuggets, a few spilled on the tier (`bl_aa_nugget_cup_case`, eight on the front tier); the hand
  variant `bl_aa_nugget_cup` is the item `aa_pretzel_nuggets` (`data/items/food3d.json`).
- The pretzels are unchanged (Steven: keep). **Rebake:** wing 2, 2026 (the warmer's mesh changed).
Evidence (unbaked): `wsFOOD3D-aa-sheet.jpg`, `wsFOOD3D-aa-ingame.jpg`, `wsFOOD3D-bl_aa_nugget_cup-sheet.jpg`,
`wsFOOD3D-bl_aa_nugget_cup_case-sheet.jpg`.
