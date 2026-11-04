# Radio Shack: front and store (1995 map, store s21b)

**Sources (Oct 7, 2026).**
- The Southland facade record (level 3, from Steven's photos): "a deep brown fascia box with the lit red wordmark standing off it on dark returns, a bright soffit, and an aluminium-and-glass front on a green marble plinth", with a dressed window.
- The 1993 Hammond Square commercial (23.8–24.15 s) shows the red "Radio Shack" letters of the period.

**Accuracy level:** 3 for the front. The inside is a period type.

**Guessed:** the depth (16 m of the 30 m stall), the door position, the fixtures.

**Frame.** An 8 m front facing west onto the east hall (x = 2, z 26–34), between Coach House Gifts and GNC. Map tiles x 149–156, y 113–116.

## Front (rebuilt Oct 7, 2026: Steven's sign pass)
- **Steven (Oct 7):** "the overall building facade needs to be that one" (refs/radio-shack-front.png); the other four photos (refs/radio-shack-letters-1..4.png) show how the 3D letters are built. Two words, "Radio Shack".
- A black fascia band, 1.9 m deep, with the red channel letters: the logo traced from refs/radio-shack-letters-1.png (warped square-on onto the frontal photo), 4.2 m across, red acrylic faces lit from inside, dark returns 12 cm deep, a darker red trim cap, and a red halo on the fascia. Built by `tools/stores/signs/` (make_logos.py → rs_logo.json, channel.gd).
- Glass in black frames on a low black base, the door at the left, a pale stone pier at the end; the window dressed with boxed electronics on black risers.
- **Superseded:** the deep brown fascia, aluminium frames and green marble plinth from the facade record.

## Inside (walkable; rebuilt Oct 20, 2026)
**Source:** the video Steven sent ("Christmas shopping at RadioShack in 1999", a mall store, 6:44). He asked to recreate it "as closely as possible to the layout and details shown in the video". The store is four years later than the 1995 map. Kept from it are the fixtures, colours and kinds of goods. No products or brand marks are copied: the goods are painted by `tools/stores/small/paint_rs.py`, and the only words are department headers.

- **Walls (0:00–0:44, 5:20–5:56).** Grey shelf units to 2.3 m along the left wall, the right wall and the back:
  - three shelf levels with red price strips on their lips;
  - boxed goods low and black out-of-box electronics above (phones, cordless phones, answering machines, scanners), each item with a small white tag;
  - white pegboard of blister-packed parts from 1.35 m to the top.
- **Above the walls (1:00–1:20, 3:24).** A black-and-white striped valance, then a navy band to a dark charcoal lay-in ceiling with bright 2 × 4 troffers.
- **Headers.** "Telephones" over the left wall and "Cellular" over the right. The back wall carries a red "PowerZone" header over a wall of battery cards (0:56–1:20, 2:36–3:00).
- **Cash wrap (0:00–2:20, 4:00–6:40).**
  - A 6.4 m glass showcase counter runs down the right side on a black kick base, with phones on glass shelves inside.
  - Two beige CRT terminals sit on the clerks' side. Each has a blue screen, a colour-keyed keyboard and a card swiper.
  - Black bags are stacked at the far end.
  - The clerks' aisle and the phone wall behind are beyond the walk grid (u > 6.4).
- **Floor (0:48–0:56).**
  - A low double-sided gondola of boxed goods down the middle.
  - Stacks of R/C truck boxes (purple-blue with yellow flames, invented).
  - A blue R/C monster truck on a white pedestal inside the door.
  - A satellite dish display with a card.
  - Dark grey carpet.
- **Guessed.** Which side the counter is on (the video only shows the clerks' backs to a phone wall), and the depth (16 m).
- **Code.** `tools/stores/small/radio_shack.gd`, materials `s6_rs_*` in `store2.gd`, stock sheets `md_stock_rs*`.

## Files
`tools/stores/small/store2.gd` (the four Wave 6 shops, materials `s6_*`), `paint.py` → `tex/sm/`; the sign: `tools/stores/signs/` (materials `sg_rs_*`). `rs_letters.json` is no longer used.

## Nov 1, 2026 (workstream D): back-of-store detail and standalone items
**Source:** the same 1999 video, now as 1 fps frames (`refs/new/radioshack_1999/`, 404 frames). New from the back of the store (frames ~185–240, 4:20–4:50): a grey board of wire and cable reels with white tags (f189–f197), brown Christmas shipping cartons with red and white tape stacked by the counter's end, and the black podium the clerk opened the R/C box on (f209–f237). Frames show real logos and products; only fixtures, colours and layout are taken.

**Built (radio_shack.gd):**
- `spools()`: a double-sided grey panel, 1.6 m long and 1.9 m high, on the floor behind the gondola (u 2.75, d 12.2–13.8): five rows of reels a side (mostly black, a few red, blue and gold), each with a hub and a white tag, a black header strip.
- `cartons()`: four brown cartons with red tape and a white label strip, and the black podium, at the counter's end (d 9.3–10.6, u 4.15–5.55). An aisle of about 1 m stays open to the back.
- `items()`: instances the standalone items below from `data/items/radioshack.json`, as separate nodes under `Items` in the wing scene (named by item id).

**Standalone items (for inventory; pick-up is workstream B+C's).** Eight generic 1995 electronics, all under the invented brand VOLTARO with invented model names (IP rule: no real product names, logos or box art; "Realistic", "Enercell", "TRC", "Talkabout" and the like are deliberately avoided):

| id | what | class | where |
|---|---|---|---|
| rs_scanner | Scan-50 handheld 50-channel scanner, rubber antenna, keypad, LCD | hand | counter glass top |
| rs_walkie_talkies | Chatter 2, a pair of 49 MHz walkie-talkies with telescoping antennas | hand | counter |
| rs_rc_car_box | Thunderclaw 1:10 R/C 4x4 in its box (invented truck art) | hand | on the R/C box stack inside the door |
| rs_cordless_phone | 900 MHz cordless phone, handset on its base | hand | counter |
| rs_battery_card | AA alkaline 4-pack on a blister card | pocket | counter |
| rs_pager | Beeper 2000 numeric pager | pocket | counter |
| rs_cb_radio | CB-440 40-channel mobile CB with its mic | hand | counter |
| rs_microcassette | micro-cassette recorder | pocket | counter |

- **Period check (1995):** 900 MHz cordless phones (1990s), numeric pagers, 40-channel CB, handheld programmable scanners, 49 MHz walkie-talkies, micro-cassette recorders, 27 MHz R/C trucks: all sold in 1995. FRS radios (1996) are deliberately not used.
- **Pipeline:** `tools/stores/radioshack_items/paint_items.py` paints one atlas per item (`items/radioshack/tex/*.png`, 1024 px; the R/C box and phone 2048 px) and writes `spec.json` (parts in metres, origin at the bottom centre, front +z). `make_items.gd` (run under xvfb, not headless) builds `items/radioshack/<item>.res` meshes, `<item>.tscn` scenes (root Node3D named by id, metadata `item_id`, `item_name`, `item_class`) and 256 px transparent icons `items/radioshack/icons/<item>.png`.
- **Data:** `data/items/radioshack.json`, a list of `{"id", "name", "class", "scene", "icon", "year": 1995, "place": {"wing": 1, "year": 1995, "pos": [x, y, z], "yaw": deg}}`. Positions are world metres in the wing scene; yaw turns the item's front (+z) about y (180 = facing the shoppers in front of the counter).
- **Guessed:** which items, their placement on the counter top (the video's counter shows phones inside the showcase; the glass top is used so the items can be reached), the brand.
- Evidence: `production/qa/evidence/wsD-radioshack-preview-unbaked.jpg`, `wsD-radioshack-items-unbaked.jpg` (close-ups and the eight icons).

## Selling (workstream SHOPS, Nov 3, 2026; `design/godot-shops.md`)
- The eight standalone items are no longer picked up: they stay on the counter as stock on show (`data/items/radioshack.json` "display", built by `radio_shack.gd items()` into the wing as before, same spots: no rebake) and are bought from a PLACEHOLDER attendant in the clerks' aisle (x 6.4 to 10.2, z 32.75 to 33.15, facing the shop; TALK spot 8.2, 30.9).
- The shop also sells ten shelf kinds the walls show (corded phone, answering machine, clock radio, cellular phone, 9 V, C 2-pack, an IC card, a plug adapter, an AC adapter, a spool of speaker wire) as labelled STAND-INs. Prices are the research note's estimates (`design/research/radioshack-1995-prices.md`), marked so in `data/story/shops.json`. Not sold: the DSS dish, the computers header and the display monster truck (the note's open questions).
