# Woolworth: front and store (1995 map, store s13)

**Sources (Oct 6, 2026).**
- **The front:** the Southland facade record (level 3, from photos): a red panel fascia, a white light-box with red slab-serif lettering shadowed in gold, and a wide open front onto a bright white five-and-dime.
- **The inside:** a home video of Woolworths at Signal Hill Mall, Statesville, NC, 1991 (YouTube `JtpaAQChCmo`). Steven (Oct 6, 17:54): "this is the exact Woolworth layout, use this." Notes in the project doc `claude/woolworth-interior-notes.md`.
- **Steven (Oct 6):**
  - Southland's Woolworth had the restaurant, on the **right** as you face the store from the mall. It was entered from inside the store and through **its own door from the mall**.
  - **No garden center.**

**Accuracy level:** 3 for the front (record), 2 for the inside (another store's layout, which Steven confirmed matches).

**Guessed (not from a Southland source):**
- the depth (36 m of the 64 m stall: a square sales floor; the stall's back half is left as stockroom);
- the restaurant's mall door: a glass storefront with an aluminium-framed door held open, and a "Restaurant" plate on the fascia over it;
- the red floor stripe and the red band of department names (from the video; Steven asked for both on Nov 1, so they stay; still from another store's video);
- the department layout behind the front end, and the department words.

All packaging, food photos and menu lines are invented. The only real name shown is the store's own. The video's 1991 "Outlet Center / storewide values 50% off" sale cards are left out. The toy aisles reuse Kay-Bee's invented toy packaging.

**Frame.**
- **The unit:** a 36 m front on the east hall (x = −10, z −14 to 22), 36 m deep (to x = −46). Map tiles x 125–142, y 93–110. Lerner Shop is to the north.
- **u** runs along the front from z = −14 (the viewer's right, u = 0) to z = 22.
- **d** runs into the store (−x).

## Front
- **Steven (Oct 7):** the sign is the all-caps lit WOOLWORTH on a dark fascia with cream piers (refs/woolworth-front.png), not the mixed-case video frame (refs/woolworth-video.png). The restaurant's own sign is still to come from Steven.
- **Fascia.** Dark maroon-brown across the whole 36 m, 3.0–4.4 m high, standing 0.25 m out. White wall above.
- **Letters.** WOOLWORTH in lit orange-red channel letters straight on the fascia over the middle of the store's opening: 0.78 m capitals, 8.1 m across, the photo's letter widths and spacing with Coustard Black glyphs (OFL; the photo is too soft to trace), dark returns 12 cm deep, a trim cap, and a halo on the fascia. Built by `tools/stores/signs/` (wl_logo.json, channel.gd).
- **Superseded (Oct 7):** the red panel fascia and the white light-box with Roboto Slab letters.
- **The restaurant's front (u 0–9).** A white bulkhead, glass in aluminium frames, and a 1.75 m door opening with both leaves held open at the left end (u 7.0–8.75, next to the store's pier; Steven, Oct 20: "the new opening that i drew"). Before Oct 20 the door was in the middle (u 3.7–5.3). Red "Restaurant" channel letters on the fascia.
- **Cream piers** between the restaurant and the store (u 9–9.6) and at the store's far end (u 35.55–36).
- **The store's front (u 9.6–36).** Wide open, with a white soffit, downlights, a clock and an exit sign just inside (video 5:34).

## Inside (walkable)
- **Store.**
  - Glossy off-white vinyl. A red stripe edges the main aisle (u 21–24, straight in from the entrance) and the cross aisle (d 17–20). Nov 1: widened from 0.15 m to 0.3 m so it reads from the hall.
  - A white lay-in ceiling at 3.6 m with long rows of troffers 3 m apart.
  - Plain white square columns flank the main aisle.
- **Red band.** White department names on red, high on the left, back and right walls (2.65–3.4 m), over white wall shelving: APPAREL, DOMESTICS, HOUSEWARES, TOYS, PARTY GOODS, GREETING CARDS, SCHOOL SUPPLIES. Nov 1 (Steven: make sure it reads): the texture is now 2048 px per 6 m (was 1024), the names heavier and bigger (caps about 0.36 m), a white pinstripe along both edges, and the band carries a little light of its own (emission 0.25) so the names read across the floor. Checked Nov 1: both the stripe and the band were built and visible; this pass only makes them read better (`production/qa/evidence/wsD-woolworth-preview-unbaked.jpg`).
- **Front end (right of the entrance).**
  - Four checkout lanes running into the store. Each has grey laminate with a red kick stripe, a register, an impulse rack at its head, and a lit lane-number box on a pole (1, 3, 5, 7: video 2:16).
  - Three red carts by the lanes.
- **Customer service (left front corner).** An L counter, a glass upper wall facing the main aisle, and a red-lettered CUSTOMER SERVICE sign (video 2:22).
- **Departments.**
  - Right front: gondolas of health & beauty and candy.
  - Right back: four toy gondolas.
  - Left front: round racks of clothes.
  - Left back: housewares, small appliances and linens.
  - Behind the restaurant: greeting cards and party goods.
- **The restaurant (u 0–9, d 0–14).** Refs for the Nov 1 pass: `refs/era_1995/stores/Woolworth.jpg` (a period lunch counter with stools, matches the built counter), `refs/new/woolworth_corner/` (the same space in 2026, The Billiard Room). Period check: nothing added that postdates 1995.
  - **Walls and light.** A warm, dimmer room. Beige walls over a wood-slat wainscot, brass sconces with globe shades, and framed food photos.
  - **Layout (Steven, Oct 20, from his marked-up screenshot and three reference photos).**
    - **The lunch counter.** It runs down the right side from d 12.8 to d 3.6. Its front is wood-grain panels between black pilasters, under a black top with a steel edge and above a chrome foot rail. At the front it curves round a quarter circle toward the window and ends at the right wall (his curved-end photo).
    - **The stools.** Eighteen chrome stools line the run and follow the curve. Each has an octagonal black foot, a coral or teal vinyl seat and a three-bar chrome back.
    - **The back bar.** It stands against the right wall: stainless cabinets on cream tile with two brown stripes, under a strip of menu cards with 1995 prices (invented) and a stainless canopy. On it are a pie case, a five-tap soda fountain, a soft-serve machine, three green malt mixers, two coffee urns and stacked glasses.
    - **Window booths.** Three booths run along the front glass, right of the door (u 1.75–6.9). Their benches are square to the glass with high channel-tufted backs, around a table on a pedestal (his window-booth photo).
    - **Left wall (Steven, Nov 1).** "Only a few feet of wall after the restaurant's mall door, then a large opening": the wall into the store now runs d 0–1.0, then a 3.6 m wood-framed opening (d 1.0–4.6, 2.4 m high), the red "Restaurant" letters over it on the store side. The three booths sit behind the opening along the left wall (d 4.75–10.85). Before Nov 1: a 1.8 m opening at d 9.4–11.2, the booths at d 2.2–8.3.
    - **Middle.** Two pedestal tables with chairs.
  - **Superseded Oct 20:** the five booths on the right wall, the lattice panels, the counter across the back with its menu board and monitors, and four of the six tables.
  - **Ways in.** From the store through a wood-framed opening with red "Restaurant" letters over it (video 7:37–7:49). From the mall through its own door.
- **The Stockrooms door.** An outline of blue painter's tape on the back wall marks it, in the left back corner (u 34.97–35.8, 2.06 m tall). Steven, Oct 20, from his picture: two uprights, and a top strip laid across them that runs past both. The tape is probe-lit.
- **Not built.** Shoppers and staff, the hanging sale cards, the soda cooler and film display (branded in the video), and a garden center (Steven: none).

## Files
- `prototypes/godot-mall/project/tools/stores/woolworth/store.gd` (geometry, materials `wl_*`) and `paint.py` (textures → `tex/wl/`, plus six stock sheets → `tex/md/`). It uses the media kit (`tools/stores/media/kit.gd`) for wall bays, gondolas and stock.
- Hooks: `tools/build_mall.gd` (dispatch, `BUILT_RECTS`, `wl_` materials) and `tools/open_interiors.py` (s13).

## Selling (workstream SHOPS, Nov 3, 2026; `design/godot-shops.md`)
- A PLACEHOLDER attendant (a woman, Steven) stands on the clerks' side of the lunch counter (x −19 to −16.2, z −12.85 to −12.6, facing the stools) and sells the root beer float ($2, Steven), a hot dog, a hamburger, French fries and coffee. You talk to her from the stools (the TALK spot at −17.5, −10.75).
- The root beer float on the counter is stock on show now, not a pick-up. Nothing in the store's build changed: no rebake.
- **The menu board disagrees:** the painted price strip (`paint_lunch.py`) says ROOT BEER FLOAT $1.49; Steven's price is $2. The board is left as it was (a question for Steven). The hot dog (129¢) and coffee (59¢) follow the board.
