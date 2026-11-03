# Corn Dog 7 — facade and customer area (1995 map, store s54)

Sources (Oct 5, 2026): Steven's board photo `photos/corndog7/20261003212357aakc.jpg` (Dec 2025, from the left,
shows the sign, pier, counter, hood, menu TVs, floor); Google Maps user photos of the Houma shop (Aug 2024 wide
front, a tall shot from the left, a counter/floor close-up, a dining-room wall shot, food on tables); Yelp
photos (food, tabletops). The shop is unchanged since the 1990s, so 2024–25 photos stand for 1995. The sign's
lettering comes from the vector trace made from Steven's photo (index.html, `CD7` / `CD7O`).
Accuracy level: 3 (depth-accurate) — several angles; not yet 4 (Steven has not confirmed the build).
Not from photos (guessed): the kitchen beyond the partition, the 1995 menu boxes and their prices (corn dog
$1.29, fries $.99, lemonade $.99, combo $2.99 — guesses; a dated photo or receipt would fix them), the exact
count of booths and tables.

Frame: `u` runs along the frontage from the store's north end (the mall viewer's left) to its south end
(12 m in the layout: z = 68 → 80 at x = −138); `d` runs into the store (east); `y` up.

## Frontage (what you see from the hall)
- The unit is 12 m wide in the layout; the opening between the piers is ~7 m (u 2.4 → 9.6), set from the
  ratio of the lettering to the front in the 2024 photo. Either side is the mall's wall (white glossy 8-inch
  tile in the 2024 photos; here the mall's own 1995 wall finish), with a fire-extinguisher cabinet at u ≈ 1.6,
  y 1.0–1.7 on the left. The room behind uses the whole 12 m: the dining room runs left behind the mall wall.
- Piers: 0.30 m wide, 0.35 m deep returns, floor to the awning (y 0 → 2.45, an 8 ft opening), navy glossy
  4-inch (10 cm) square tiles with white grout, all faces. Navy ≈ #1b2466.
- Awning / sign box: a bullnose canopy in glossy taxi yellow (#f6dc2c, highlights to #fff27a), vacuum-formed
  panels with faint vertical seams every ~1.3 m. It is about 3/4 of the pier height (photo): vertical front
  face from y 2.45 to 3.55, then a quarter-round roll (radius 0.85) up and back to y 4.40, just under the
  mall ceiling; projection 1.0 m. The two ends are rounded in plan (radius 0.6) and run 0.2 m past the piers.
  Bottom edge: a brushed aluminium trim strip (4 cm). Under the awning a white soffit with a fluorescent strip.
- Navy pinstripe: 7 cm tall, 0.55 m above the bottom edge, round both ends; it stops either side of
  "seasoned fries", which sits across it (close photo). Lettering (navy, the traced vectors): "seasoned
  fries" script, 0.30 m, ~0.85 m in from the left end of the front; "CORN DOG 7" brush caps, 0.48 m tall,
  above the stripe, from ~3.2 m along the front to near its right end; "fresh lemonade" script, 0.24 m,
  below the stripe at the right end, running onto the rounded end.
- Above the awning to the ceiling (y 4.4 → 4.6): vertical oak slats (tongue-and-groove, ~9 cm), medium oak.

## Inside — customer area (walkable), 11 m deep
- Ceiling 2.9 m: 2×4 ft lay-in acoustic tiles, white grid, 2×4 prismatic fluorescent troffers on a 2.4 m grid.
- Floor: wood-look ceramic tile in basketweave blocks (each 30 cm block = three 10×30 cm planks, blocks
  alternating direction), tan / caramel / brown mix, dark grout.
- Walls: yellow 10 cm tile wainscot to 1.5 m with a navy two-tile band at the top, white painted above
  (dining room, left and back). Behind the counter the kitchen is seen through the partition.
- Counter: front face at d 3.0 from u 5.2 to the right pier and on behind the mall wall (a stainless condiment
  table on casters stands against it at u ≈ 8.85), with a 45° chamfer at its left end (u 5.2 → 5.7). Height 1.0 m,
  0.8 m deep. Front: navy 10 cm tile base (two courses), yellow tile field with 3×3 navy checker panels
  (checker = alternating navy/yellow 10 cm tiles, 30 × 30 cm, one panel per ~0.9 m), a navy course under the
  top. Top: brushed stainless with a 5 cm overhang. On it, from u 5.6 to 9.4: glass food cases 0.5 m tall,
  0.55 m deep, stainless frames, lit inside. Brushed stainless hood canopy over the back counter (u 6.0–8.6,
  d 3.6–4.4, y 2.0–2.6).
- Back-bar partition at d 4.5, u 5.2 → 11.7: oak-framed glass panels (y 1.1 → 2.4) over solid oak below,
  oak posts every 1.2 m; two backlit menu boxes (brushed aluminium case; yellow header with the traced
  CORN DOG 7, white panel with navy items) at u 7.9 and 8.95, y 2.25–2.75, angled down toward the queue —
  the 2024 photos show TVs there, which would be wrong for 1995; paper notices on the glass. The kitchen beyond is dim: stainless shelving,
  fryers' glow, a red-shirted crew.
- Dining room: u 0.3 → 5.0, d 3 → 11. Along the left wall five booths (oak ends and benches, dark oxblood
  vinyl seats, butcher-block tables), each 1.3 m long, from d 3.0; each divider rises as an oak frame with
  glass to 2 m and a plant on top. In the open floor three four-tops (butcher-block tops 0.78 m square on
  black pedestal bases, black chairs).
- Screen between dining room and the queue: oak half-wall 1.1 m with glass to 2.2 m between oak posts every
  0.9 m, from d 3.5 to d 8 at u 5.0, with trailing silk plants in planters along the top.
- Queue area d 0 → 3 across the opening: open, two black stanchions optional (not in 1995 photos — omitted).

## Build notes
- Built by `tools/stores/corn_dog_7.gd`, called from `storefront()` for store s54; textures painted by
  `tools/stores/paint_corn_dog_7.py` into `tex/cd7/`.
- Walk grid: tiles x 79–80 × y 134–139 (queue) and x 81–84 × y 134–135 (dining) opened in layout_mall.json
  by `tools/open_interiors.py`; the counter, booths, tables and partitions are obstacles.
- Lights: the troffers (emissive + omni), case lights, soffit strip, menu TVs (emissive).

## Selling (workstream SHOPS, Nov 3, 2026; `design/godot-shops.md`)
- A PLACEHOLDER attendant stands right behind the counter (x −134.06 to −134.0, z 74.2 to 77.4, facing the queue) and sells the corn dog ($2, Steven), crinkle-cut fries and lemonade. TALK spot −135.7, 75.6 in the queue.
- No geometry change: the back worktop (d 3.85 to 4.45) touches the attendant's back below 0.9 m, hidden behind the 1.0 m counter from the shop. No rebake.
- The corn dog on the counter is stock on show now (both years), not a pick-up. In 2026 Corn Dog 7 has no attendant yet, so no corn dog can be had there (a question for Steven).
- **The menu box disagrees:** it says Corn Dog 1.29; Steven's price is $2. Left as it was (a question). Fries and lemonade follow the box (.99).
