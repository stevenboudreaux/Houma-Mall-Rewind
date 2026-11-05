# Payless ShoeSource: front (1995 map, store s4)

**Sources (Oct 7, 2026).** Steven's three photos (photos/payless). Sign pass only; the generic interior stays (shoe stores on hold).

**Front (16 m, facing −x at x = 2, z 50–66).** A black fascia box (2.9–4.6 m, 0.3 m proud) over a wide open front, cream piers at the ends, "Payless ShoeSource" in yellow lit letters with the two O's in orange, traced from photos/payless/01 (9.0 m across).

**Guessed:** the sizes. The photos are post-1995; the ShoeSource name dates from the 1990s.

**Files:** `tools/stores/signs/fronts.gd` (payless), materials `sg_pay_*`.

## Inside (Nov 1, 2026, workstream G)
The generic interior picture is replaced (`fronts26/store.gd` `payless_inside()`): the self-serve
store, white walls of shoe-box ends under a yellow stripe, two rows of low islands of boxes with a
sample shoe on top, red try-on benches, grey floor. **Guessed:** the chain's period look; no photo of
the Southland inside. Evidence `wsG-1995-payless-unbaked.jpg`.

## Walk-in interior from Steven's video (Nov 4, 2026, ws/interiors)
**Asked for (Steven, voice note Nov 3):** "Payless, that's from a going-out-of-business sale, 2019 I think,
but just remove all of the going-out-of-business stuff, but the layout ... that's exactly what it looked
like, the shoes and all that stuff." Replaces the Nov 1 guessed inside (`fronts26/store.gd payless_inside()`
now calls `tools/stores/payless/store.gd`). **1995 only:** Payless (s4) is on the 1995 map; in 2026 the
unit is Victoria's Secret / PINK, and Payless closed in 2019.

**What the video shows** (`refs/new/payless/payless2019_t000_NNN.jpg`, 0.5 fps, NNN ~ seconds / 2 + 1; not
Southland): 001 the front from the mall; 005-009, 189, 307 the front zone on a **wood-look plank floor**,
white display tables of single shoes, slatwall end caps of socks; 017-047, 121, 303-305 **long double-sided
gondolas of sloped shelves of open shoe boxes** (lids tucked behind, the shoe in the box, size on the box
end) running front to back over a **grey-brown loop carpet**; 237 white **slatwall end caps** facing the
front aisle; 305 a small **upholstered bench** in an aisle; 177, 183 the **orange oval try-on mat** with
rings of circles; 219-289 the **bags and backpacks** wall and shelves at the front; white walls, lay-in
ceiling, fluorescent troffers. Left out: every sale sign, price card and "store closing" banner, and the
2019 goods (phone chargers, licensed plush, branded boxes).

**How it maps onto s4** (16 m front at x = 2 facing the Dillard's court, 28 m deep; wing 2):
- **Walk-in:** tiles x 149-161, y 125-132 opened (`tools/open_interiors.py`, `layout_mall.json`): the sales
  floor to 26 m; the stock room behind the back wall (door at the right) stays shut.
- Front zone (0-4.6 m): wood-look planks (`tex/pay/wood.png`), three white display tables with nested
  lower tables and single shoes (the shoe kit, `small/shoes.gd`), the bags and backpacks wall on the left
  (`bags.png`), socks / hosiery / shoe care on slatwall on the right (`pegs.png`) and the cash counter
  with a register by the right wall.
- Sales floor (4.6-26 m, carpet `carpet.png`): six double-sided gondolas (0.92 m deep, 1.9 m high, seven
  sloped shelves a side) in two runs with a cross aisle at ~14.5-15.8 m; 1.36 m aisles; slatwall end caps
  of peg goods at both ends; the same sloped shelving round both side walls and the back wall; category
  headers (WOMEN, MEN, KIDS, ATHLETIC) over the side walls; brown upholstered benches with orange oval
  mats in the aisles. The shelves are textured quads (`shelves.png`: four rows, dress / sneaker / sandal /
  boot, open boxes with a shoe and a size tag), so ~10,000 boxes cost a few hundred quads.
- Lights: troffer rows over the aisles with a spot under every other one; three omnis in the front zone.

**Guessed:** the depth of the sales floor (26 m) and the stock room, the number of gondolas and the cross
aisle (the video's store is similar but not Southland's), the counter's place, the category headers'
words and colours (an invented 1995 look; the video's store has none legible), all goods (invented,
1995-safe: socks, knee-highs, polish, insoles, laces, plain bags). The 2019 decor (wood-look floor,
white slatwall) is used for 1995 because Steven says it is what the store looked like.

**Checked by looking (Nov 4):** the size labels on every gondola face and both side walls read mirrored
(`shelves_side` picked the texture direction from the viewer's left); fixed, the back wall was already right.

**Layout hunks (`layout_mall.json`, for the hand merge):** `walk` rows 125-132, columns 149-161 set to `1`
(the sales floor; written by `tools/open_interiors.py` `OPEN["s4"]`); `"s4"` added to `interiors_open`
(between `"s36"` and `"s42"`).

**Evidence (unbaked, probe-lit preview):** `production/qa/evidence/interiors-payless-1995-{doorway,frontzone,
counter,aisle,aisle-back,gondola,backwall}-unbaked.jpg`. **Rebake:** wing 2 (1995); the
walk grid changed (`layout_mall.json`), so `gen/w2/wing.json` and wing 1's stand-in of the front.

**Shoppable (built Nov 4, Steven's yes: shop `payless`, `design/godot-shops.md` "ws/interiors"; Steven also kept the 1990s look as built). Was proposed:** a counter shop at the cash counter (1995): a pair of
shoes in a box (one item per kind: sneakers, pumps, sandals, boots), a 3-pack of socks, shoe polish. The boxes
on the shelves stay painted (not pick-ups).
