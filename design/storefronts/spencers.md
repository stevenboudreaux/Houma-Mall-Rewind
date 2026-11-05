# Spencer's (2026 map, store n35): walk-in interior

**Asked for (Steven, voice note Nov 3 2026):** "detailed renderings built off of the inside interior of
Spencer's Gifts" from the YouTube recording he made.

**Where and when:** 2026 only (`layout_2026.json` n35: tiles x 117-122, y 110-123, a 12 m front facing south
onto the Concourse at z = 48, x -62..-50, 28 m deep; wing 2). In 1995 the unit was Gadzooks (also walk-in).
The front (faux brick, two windows, the half-raised graffiti shutter, the sign, poster stands, the lit
vending machine) is the ws/g build from IMG_4440 f001-f002 / IMG_4439 f034-f036 and is unchanged
(`tools/stores/fronts26/store.gd spencers()`; see `fronts-2026.md`).

## What the footage shows (`refs/new/spencers/spencers_t000_NNN.jpg`, 0.5 fps, NNN ~ seconds / 2 + 1)
Not Southland: a large mall Spencer's. It leaves Spencer's at ~257 (other stores, an Aéropostale front).
- 001-011: the front from the mall: brick, a lit sign, a window, the open entry, a drinks cooler inside.
- 011, 049-051, 129-145: **stained concrete floor**, amber-brown and mottled; **a dark open ceiling**.
- 013-021, 205-209: black tables and gondolas with **folded tees** piled on rough plank shelves.
- 027, 257: **the wall of framed tees**: a black wall, square black frames in rows four high.
- 031, 099-117: **black shelving with rough plank shelves**, tumblers and bottles.
- 037-047, 163-167: **brick piers** between black wall bays; black shelving of boxed goods.
- 063-073: **galvanized corrugated panels** hung with carded goods (stickers, keychains).
- 125-147: chrome **spinner towers**; bins and racks of **plush**.
- 169-185: **the mug wall**: rows of mugs on plank shelves with **red shelf-edge strips** (MUGS, WANTED).
- 193-227: a chrome **rounder of jackets**.
- Everything on the shelves is licensed or branded (characters, candy brands, adult novelty): **none of
  it is copied**; only the fixtures, finishes and layout are used, and the goods are invented generic
  shapes and prints (`tools/stores/spencers/paint.py`: invented tee graphics and words like BAYOU,
  GATOR, NOPE, plain coloured mugs and tumblers, carded "STICKER" packs with plain shapes).

## How it maps onto the unit
`tools/stores/spencers/store.gd` (frame x 0..12 left to right from the hall, d into the store):
- **Walk-in.** The 2026 walk grid opens tiles x 117-122, y 112-123 (d 0..24 m), the same rect Gadzooks
  had in 1995 (`tools/make_layout_2026.py`, `OPEN_2026_RECTS`). The stock room (d 24-28) stays shut.
  The windows, the window displays (black risers with goods) and the vending machine are obstacles; the
  entry is the 3.2 m under the shutter.
- Room: stained concrete (`tex/spencers/concrete.png`, world triplanar), black deck at 3.4 m with two black
  ducts, track runs every 3 m; warm spots plus four pink / blue / amber accent washes.
- Left wall, front to back: framed tees (1.4-7.3 m), brick pier, the mug wall (6 plank shelves, ~240 mugs
  as small 3D cylinders with handles), pier, corrugated peg wall, pier, tumblers.
- Right wall: tees (`tex/spencers/tee_rail.png`: folded stacks on two plank shelves, four tees hung
  face-out on a chrome rail, a low plank of stacks; 015, 205-209), pier, tumblers and bottles, pier, tees,
  pier, corrugated peg wall. (Nov 4: the first pass borrowed ws/g's `f26_tees_dark`, a through-the-glass
  sheet of dark tees on near-black that read as wallpaper of symbols up close.)
- Back wall: brick, a framed-tee panel over the black cash wrap with a plank top, register and an impulse
  rack; the stock-room door at the left.
- Floor: four black gondolas of plank shelves with folded tees and boxed gifts (two lines, a cross aisle at
  ~10-12 m), three tiered round tables of folded tees, three spinner towers, two plush bins, a jacket
  rounder (the apparel kit's).

## Guessed
The whole layout inside (the video is a much bigger store: its fixtures were fitted into 12 x 24 m), the
positions of the piers, the accent colours, the cash wrap at the back, every product.

## Evidence (unbaked, probe-lit preview)
`production/qa/evidence/interiors-spencers-2026-{doorway,aisle,teewall,rightwall,mugwall,cashwrap,lookingout,
corrugated}-unbaked.jpg`. Not walk-tested in an export (the box was shared; preview only): the walk grid
opening and the window obstacles should be tried with `tools/qa/doortest.py` in the integration build.

## Layout hunk (`layout_2026.json`, for the hand merge)
`walk` rows 112-123, columns 117-122 set to `1` (written by `tools/make_layout_2026.py`, `OPEN_2026_RECTS`).
Nothing else in the file changed (`interiors_open` is a tool-side list, not read at run time).

## Rebake
Wing 2, 2026 (`wing2_2026`); the 2026 walk grid changed (`layout_2026.json`), so wing 1's 2026 stand-in is
unaffected but `gen/w2y26/wing.json` must be rebuilt.

## Shoppable (a proposal for ws/items; nothing added here)
A counter shop at the cash wrap: an invented-print tee, a mug, a plush, a sticker pack, a lava lamp (Gumballs'
`bl_gb_lavalamp` model, if Steven wants it here). All generic (IP rule). Prices for Steven.
