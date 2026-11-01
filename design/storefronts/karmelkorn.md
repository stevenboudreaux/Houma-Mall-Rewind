# Karmelkorn: front and shop (1995 map, store s57)

**Source (Oct 7, 2026).** The Southland facade record (level 2, from Steven's photo): "a golden-yellow bulkhead wrapping the corner with the red logotype drawn by hand (the big swash K, then slab-serif capitals, red with a cream edge and a deep red shadow, leaning a little), a lit soffit, and an o[pen front]". (The Hammond commercial's corn shop at 16.8–17.85 s is a different chain, CARMELCORN, and is not used.)

**Accuracy level:** 2 for the front. The inside is a period type.

**Guessed:** the room (the whole 16 m × 10 m corner stall), the L counter, the kettles, the tins, the red tile floor. The sign's capitals are a fitted typeface, not the real lettering (see "The neon sign").

**Frame.** A corner shop, open on two halls. The north front is at z = 60 (x −36 to −20), facing the hall to the north. The east front is at x = −20 (z 60–70). Map tiles x 130–137, y 130–134. u runs along the north front from x = −36.

## Front
- A golden-yellow bulkhead wrapping both fronts, with the "Karmelkorn" neon sign on each (below).
- A lit soffit, and both fronts open.

## Inside (walkable)
- A red tile floor and yellow walls.
- A red L counter along both fronts, with caramel corn heaped under glass and a register.
- Three popcorn kettles on the back wall, and shelves of tins on the west wall.

## The neon sign (Oct 7, 2026)
Steven: "a corner shop like the first image so neon goes on both sides", built with the Cucos method (`design/godot-neon-signs.md`). Sources, his three photos (`refs/` not kept; the square-on one is `tools/stores/signs/src/kk_front.jpg`):
- **Square-on, lit, a mall unit (582 px):** the letter shapes and spacing. Too small to trace letter by letter: the glow joins them.
- **Close-up, lit (377 px):** how it is built. Pink-red tubes run along both edges of every heavy stroke, so the neon is an outline, in open-face cans with red returns.
- **A corner unit, lit by day:** the sign on both bulkheads of the corner. Its letters are later closed-face LED cans; only the layout is taken from it.

**Built as** (`tools/stores/signs/kk_sign.gd`, data `kk_sign.json` from `make_kk.py`, mask `src/kk_cans.png` from `kk_trace.py`):
- **Cans:** 11 sheet-metal cans, 110 mm deep: the K with its arm, top bar and leg; the swash under the A; and the nine capitals. Deep red returns (the photos' "drop shadow"), a cream trim cap, red inside.
- **Neon:** red, 12 mm, on standoffs, as an outline 26 mm inside the walls. A single tube runs down each hairline. Electrodes in black boots, a pool of light on the red pan, a faint halo on the yellow bulkhead.
- **Size:** 6.0 m wide (K's stem to N's serif), 0.75 m tall, caps 0.42 m. Centred on each bulkhead, 0.57 m above its bottom edge: the north front at x −28, the east front at z 65.
- **Letters:** the capitals are Coustard Black (OFL), thinned a little. Each was fitted by correlation into its own box read off the photo, so size and spacing are the photo's. It was scored against 17 open faces; Ultra, Holtwood One SC, Bevan and Alfa Slab One came close. The K's stem is Coustard's I. The arm, top bar, leg and swash are straight strokes measured off a trace of the photo.
- **Materials:** `channel.gd` `kk2_*`. Tubes are emission 1.4 by day and 1.9 at night; the red pan 0.4 by day and 0.75 at night.
- **In the scene:** a dynamic mesh (`gen/w2/dyn_s6kf_sign.res` and `_glow`), with no rebake. `kk_only.gd` rebuilds only the sign. The old flat letters (`kk_letters.json`, `dyn_s6kf_props.res`) are gone from the scene.

**Guesses to own:**
- The real capitals are hand-drawn. Coustard matches their weight, width and serifs, but not each curve; the real R's leg curls more.
- The tube runs follow the can walls at a fixed inset.
- The photos are of other Karmelkorn units in later years; whether Southland's 1995 sign matched them is not known.
- The size is fitted to the bulkhead.

## Files
`tools/stores/small/store2.gd` (`karmelkorn`, `kk_sign`). The sign: `tools/stores/signs/kk_trace.py`, `make_kk.py`, `kk_sign.gd`, `kk_only.gd`; preview `tools/qa/kk_preview.gd`. `kk_letters.json` (from `make_signs.py`) is no longer used.

## Customers (Oct 20, 2026)
Steven: "don't have any NPCs congregate inside KaramelKorn either." Karmelkorn is no longer a store or window goal for the crowd (`npcs.json` "no_browse").

## The back of the shop (Nov 1, 2026, workstream G)
Steven (Oct 28): popcorn in the back "as rich as Pocket Change's prize counter".
`tools/stores/y95/extras.gd` `popcorn_back()` (called at the end of `store2.gd` `karmelkorn()`):
a cream wall of four red-edged shelves over the kettles packed with tins and ribboned cellophane bags,
four tall glass drums of popcorn (caramel, cheese, plain, cherry) between the kettles, a pyramid of
tins on the floor, a rail of hanging bags down the west wall, a red popper cart with corn spilling at
the counter's end. Textures `y95/paint.py` -> `tex/y95/`. **Guessed:** all of it (no photo of the
1995 back of the shop); tins are plain colour bands, no brand art. Evidence
`production/qa/evidence/wsG-1995-karmelkorn-*.jpg`.
