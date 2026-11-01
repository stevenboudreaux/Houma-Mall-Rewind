# Foot Locker: front (1995 map, store n34)

**Sources (Oct 7, 2026).** Steven's photos of a period Foot Locker front: refs/foot-locker-front.jpg (the front used) and refs/foot-locker-2.jpg (the letters close up). Steven: "these should be good enough." Sign pass only: the store is still a shoe store on hold, so the generic interior stays behind the opening.

**Accuracy level:** 2 for the front (the chain's period front, not a Southland photo). The inside is the generic one.

**Front (6 m, facing +z at z = 48, x −68 to −62).**
- Diagonal wood planks over the whole front: the strips beside the portal and the sign band slant one way, a narrow band over the portal the other (tex/sg/fl_wood.png, painted by make_logos.py).
- A white portal 5.6 × 3.3 m, 22 cm deep, with bevelled top corners round a 4.8 × 2.95 m opening.
- "foot Locker" in red letters edged in gold (trim cap), 0.56 m ascenders, 4.0 m across: Fredoka Bold (OFL) glyphs fitted to each letter of the photo (the photo is too soft to trace).
- The oval, 0.86 × 0.58 m: cream face, black rim, the runner traced from the photo.

**Guessed:** the plank size and colour, the band split, the letters' depth (7 cm), the oval's size.

**Files:** `tools/stores/signs/fronts.gd` (foot_locker), `make_logos.py` (fl_*), materials `sg_fl_*` in `channel.gd`.

## Inside (Nov 1, 2026, workstream G)
Steven (Oct 28): "Foot Locker 1995 = its 2026 inside". The generic interior picture is replaced by the
2026 store's inside (`tools/stores/fronts26/store.gd` `footlocker_inside()`, via `build_mall.gd`
`interior()`): black walls of trainers on lit shelves, a referee-stripe header, a pale wood floor, a
bench. Not walk-in. Evidence `wsG-1995-footlocker-unbaked.jpg`.
