# Sound Shop: front and store (1995 map, store s19)

**Sources (Oct 6, 2026).**
- **The front and a look inside:** the 1993 Hammond Square Mall commercial (YouTube `WvaGN9lUpr0`, 4.3–4.9 s). It shows a Sound Shop of the same Louisiana chain: a dark fascia with red italic letters, a wide open front, and a bright white store with wall racks, low white islands and big posters hung high.
- **For period detail:** Valley View Mall, Dallas, Sept 1995 (YouTube `rjvPS1FIqS4`, 3:57–4:17), which shows Camelot Music, a different chain: red letters and a poster band.
- **The layout:** Steven (Oct 6, 18:30): the registers were on the **left** looking in. Behind them was the concert box office: the counter sold concert tickets. It is built as a generic "TICKETS · CONCERT BOX OFFICE" board, with no ticket company's name or logo.

**Nov 1, 2026: the front rebuilt (workstream D).** Steven (Nov 1): the Hammond frames are not available; build the front from the photo `refs/era_1995/stores/Sound_Shop.jpg` (lit yellow-orange SOUND SHOP letters on a fascia over a glass front, mall not recorded) plus the parts of Southland's own Sound Shop front that still stand in 2026 (SOLA, notes_C IMG_4484 s19; `refs/derived/frames/IMG_4484` f040–f052; `refs/derived/signs/sola_IMG_4484_f055.jpg`). Where the photo and this note's Oct 6 text disagree, the photo wins, except that the front stays open (Steven, Nov 1). The "Front" section below is the Nov 1 build; the inside is unchanged.

**Accuracy level:** 2. The front and the inside come from another mall's Sound Shop. Steven's memory sets the counter.

**Open question for Steven.** The 8-bit game's record for Southland's Sound Shop (`facade_records.json`, source not stated) describes a taupe bulkhead, letters lit yellow to orange with a red halo, and a satin-aluminium door frame around one big sheet of glass. The 3D front follows the Hammond video instead: a dark fascia, rose-red letters, open front. If his memory matches the record, the fascia colour, the letters and the glass are quick to change.

**Guessed (not from a Southland source):**
- the depth (24 m, as Kay-Bee next door) and the fixture count;
- the categories on the header boxes (ROCK, POP, R & B, COUNTRY, RAP, JAZZ, CLASSICAL, SOUNDTRACKS, CAJUN & ZYDECO, GOSPEL, NEW RELEASES, CASSETTES). CAJUN & ZYDECO is a guess for a Houma record store;
- the browser bins down the middle (the commercial shows only the front of the store).

All covers, posters, act names and dates are invented: scribbled titles, generic shapes. The ticket board uses real 1995 weekdays (period-art-director).

**Frame (as Kay-Bee's).**
- **The unit:** 6 m wide and 24 m deep. Map tiles x 131–142, y 68–70. It faces east onto the hall between Lane Bryant (north) and Kay-Bee Toys (south).
- **u** runs along the front from z = −64 (the viewer's right, Lane Bryant's side) to z = −58 (u = 6, Kay-Bee's side).
- **d** runs into the store (−x).

## Front (rebuilt Nov 1, 2026)
- **Open storefront (Steven, Nov 1, after the first pass):** "sound shop is an open storefront". No glass and no door: the whole front is open between the pillars, as the Hammond commercial showed. The security grille is rolled up in a slim grey box under the band, with its side tracks at both ends. (A first pass the same day had a glass front with a recessed entry, read from the photo; superseded.)
- **The band (Southland, 2026 frames).** A black textured-stucco fascia band, 2.75–3.6 m, standing 0.45 m out, bull-nosed top and bottom, straight across the middle and curving back to the wall in quarter circles (0.45 m radius) at both ends. A white soffit under it. Cream mall wall above (as the lane today).
- **Letters (photo).** "SOUND SHOP" in fat rounded italic capitals (Nunito Black Italic outlines, `ss_letters.json`, scaled to 0.44 m caps, 4.4 m long), lit yellow-orange faces with red-orange lit returns, on the band's face, and a warm orange omni light washing the band and the floor in front.
- **Pillars (Southland).** Two glossy black round pillars, 0.4 m across, under the band's curved ends, framing the opening.
- **Threshold (Southland).** Black 8-inch tile (0.2 m) from 0.65 m out in the hall to 0.4 m inside the opening.
- **Inside the front.** A white soffit over the first 0.8 m with three downlights; the SALE $9.99 card on its chrome stand just inside, as before.
- **Superseded Nov 1:** the dark grey fascia and the rose-red letters (Hammond commercial via the Oct 6 note); the open front itself stays, as Steven says.
- **Guessed:** the letter size (the photo's letters fill the band); which store the photo shows (not recorded: it may be another Sound Shop of the chain, so the band and pillars follow Southland, the letters follow the photo); the grille box.
- **Period check (1995):** channel letters, open mall front with a roll-up grille, black ceramic tile, stucco fascia: all normal in 1980s–90s malls. No anachronism.
- **Files (Nov 1):** `tools/stores/media/sound_shop.gd` (`front()`), `paint_ss_front.py` → `tex/md/ss_stucco.png`, `ss_tile_black.png`; materials `md_ss_*` in `kit.gd`. Evidence: `production/qa/evidence/wsD-sound-shop-preview-unbaked.jpg`, `wsD-sound-shop-ingame-unbaked.jpg`.

### Oct 6 front (superseded)

- **Fascia.** Dark grey, 2.75–3.6 m, standing 0.22 m out, with a light reveal under it. The mall wall above it is dark grey too, as in the commercial.
- **Letters.** "SOUND SHOP" in fat rounded italic capitals lit rose-red: caps 0.36 m, 3.6 m long. Outlines: Nunito Black Italic (OFL), from `make_letters.py`.
- **Opening.** Wide open between two dark grey piers (0.32 m) with deep reveals. A dark grey soffit with three downlights covers the first 0.8 m.
- **At the door.** A chrome stand with a "SALE $9.99" card.

## Inside (walkable)
- **Room.** A light vinyl tile floor and a white lay-in ceiling at 3.0 m with two rows of troffers. White walls. A stockroom door with an exit sign at the back right.
- **Registers (left, Steven).** A white counter with a red band, 3 m long, parallel to the left wall from d 1.4, with two beige registers. Behind it on the wall: a dark panel with the TICKETS board (2 m × 1 m: invented acts, 1995 dates, a seating chart), and a back counter of cassettes behind glass.
- **By the door.** Two white islands of new-release CDs with NEW RELEASES and TOP 30 cards on stems (commercial).
- **CD walls.** White wall racks of CDs face-out, nine rows to about 2 m with a cassette row at the bottom. They run along the left wall past the counter and the whole right wall, with radiused end caps. A lit header box hangs over every other bay. Cassette racks fill the back wall.
- **Middle.** Two runs of waist-high CD browser bins (six bins each), with cassettes in the kick and a NEW RELEASES card at each run's front.
- **Posters.** Two strips of four invented album posters, hung from the ceiling over the browser runs (commercial: big posters high up).

## Files
- `prototypes/godot-mall/project/tools/stores/media/sound_shop.gd` (geometry), `kit.gd`, `paint.py`, `make_letters.py` → `ss_letters.json`.
- Hooks: `tools/build_mall.gd` and `tools/open_interiors.py` (s19).
