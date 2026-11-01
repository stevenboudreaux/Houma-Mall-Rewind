# Cinnamonster (2026 map, store s57: KarmelKorn's corner stall)

**Source (Nov 1, 2026, workstream G).** Steven's photos IMG_4464–4468 (Oct 23 2026), shot upside
down: rotated 180° for reading (`refs/derived/photos/`). Notes: refs notes_B "IMG_4464–4468".
Steven (Oct 28 sprint): the Cinnamonster counter, KarmelKorn's corner.

**Accuracy level:** 3 for the fascia, the counter, the column, the colours and finishes (several
sharp photos); 2 for the stall's depth and the back-counter gear; 1 for anything behind the
west wall.

**Frame.** The 2026 unit is the east 8 m of the 1995 KarmelKorn: the north edge x −28 → −20 at
z = 60 (the Concourse) and the east edge x = −20, z 60 → 70 (the Dillard's court's west side).
Built whole from the north edge's call (`build_mall.gd` skips the east edge's).
`prototypes/godot-mall/project/tools/stores/cinnamonster/store.gd`, textures `cinnamonster/paint.py`
→ `tex/cm/`, materials `cm_*`. Not walk-in: it is a counter stall, so s57 stays shut in the walk
grid (the 1995 KarmelKorn rect is twice as wide and would open the vacant unit next to it).

**Reading the photos.** All five are taken from the Dillard's court looking west (IMG_4466 shows
Dillard's past it to the south; the long vista on the right of IMG_4464 is the Concourse). So the
**long run with the coffee oval is the east face** (on the court) and the **short run under the
red pendants with the bakery case is the north face** (on the Concourse). The brown column stands
at the north-east corner.

## Built
- **Fascia** over both faces: gold/tan (the Demo 43 spec's `#d6b98a`) between burgundy/cream 4"
  checker bands, two courses each, top and bottom; cream mall wall above. The round plaque (Demo 43
  spec `y26/parts/cinnamonster.json`) once on each face: the east one over the coffee end, the north
  one near the corner (IMG_4467).
- **Openings:** the east face open 6.5 m from the corner (then a closed cream wall under the band to
  the end of the frontage); the north face open 4.5 m from the corner (the west 3.5 m closed).
- **Counter:** one curved run, from the back wall along the north face, round a 0.8 m radius corner,
  down the east face, angling back a little at its south end. Mahogany laminate face (1.2 m panels),
  a dark rail, a two-course checker kick, a white top with a lip. Register, cup towers and a tip jar
  on the east run; the glass bakery case with two trays of rolls on the north run.
- **Column:** brown Tuscan (square plinth, torus, tapered shaft, necking, echinus, square abacus) up
  to the fascia's soffit, at the corner; a red sign stand with a black easel just outside it.
- **Inside:** white lay-in ceiling with troffers, cans, track heads, three red cone pendants over the
  north run; burgundy walls with a two-course checker band over white 4" tile; on the back (west)
  wall from south to north the coffee oval on dark planks, "From the Oven" rolls, "Rich & Gooey";
  hanging Bakery/Smoothies menus behind the east run; a back counter along the west wall with a cup
  rack, an espresso machine (orange top), grinders, a black merchandiser, a white freezer and two
  drink dispensers.

## Guessed / left out
- **IP:** the co-branded coffee sign is painted as a plain red oval reading COFFEE (the real coffee
  brand's logo is left out). Posters and menu lines are invented; the brand's name on the plaques is
  the store sign (allowed).
- The stall's depth (back wall 4.5 m behind the east counter) and the length of each opening are
  estimated from perspective. What is behind the west wall (the rest of the 1995 KarmelKorn) is not
  built.
- The mascot drawing on the red stand's box is left off.

## Evidence
`production/qa/evidence/wsG-cinnamonster-court-unbaked.jpg` (IMG_4467 | game),
`wsG-cinnamonster-wide-unbaked.jpg` (IMG_4464 | game), `wsG-cinnamonster-hall-unbaked.jpg` (from the
Concourse). Unbaked preview renders (`MALL_YEAR=2026 tools/qa/preview.sh store:CINNAMONSTER`).
Wing 2 2026 needs a rebake.
