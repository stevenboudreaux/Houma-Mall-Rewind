# Cuco's back bar kit: placement note for workstream CUCOS

Workstream FOOD, Nov 3 2026. Fixtures, not items: what you see behind a bar in a 1995 Mexican restaurant,
as Blender models (`design/godot-blender-pipeline.md` "Food, drinks and books"). **No prepared drinks** (the
drinks are items: `cu_beer`, `cu_margarita`, `cu_top_shelf_margarita`). Every brand is invented (IP rule);
the restaurant's own sign art appears only on the coaster, coupon and doubloon items.

All paths are under `prototypes/godot-mall/project/`. Each part is one `.glb` with one baked material (plus
its transparent glass materials) and lives in the shared `items` pack (`models/bl_*`), so placing them costs
the wing pack nothing.

## The parts

| Part | What | Size | Tris | Origin |
|---|---|---|---|---|
| `models/bl_cu_bb_bottles_a/bl_cu_bb_bottles_a.glb` | 12 bottles in a row, the working stock: steel pour spouts in rubber collars, mixed fill levels | 1.10 m row, bottles 0.19–0.30 m tall | 7.1k | middle of the row's **front edge**, on the shelf top; bottles stand 30–90 mm behind it |
| `models/bl_cu_bb_bottles_b/bl_cu_bb_bottles_b.glb` | 10 bottles, mostly capped (the upper-shelf reserve and better tequilas), a different order | 1.10 m row | 6.3k | same |
| `models/bl_cu_bb_taps/bl_cu_bb_taps.glb` | chrome T-tower, 3 faucets, tapered handles with LAGER / AMBER / DARK plates, frost band, drip tray with grille on a rubber mat | tower 0.36 m tall (handles to 0.47), 0.46 m across | 4.8k | middle of the drip tray's **back edge**, on the counter top |
| `models/bl_cu_bb_stemrack/bl_cu_bb_stemrack.glb` | hanging rack: 3 dark wood rails with brass runners, 12 house margarita glasses upside down, 4 rods | 0.60 x 0.36 m, hangs 0.30 m + the glasses (~0.47 m in all) | 8.8k | the mounting plates' **top** (fix to a ceiling or canopy underside) |
| `models/bl_cu_bb_glasses/bl_cu_bb_glasses.glb` | ribbed rubber bar mat, 6 beer mugs and 4 pints upside down to drain, 2 stacks of rocks glasses | mat 0.60 x 0.30 m | 6.8k | middle of the mat's **back edge**, on the counter top |
| `models/bl_cu_bb_service/bl_cu_bb_service.glb` | bar mat with a commercial blender (empty jar), Boston shaker, bar spoon, hawthorne strainer, garnish caddy (limes, oranges, cherries), folded bar towel | mat 0.60 x 0.30 m, blender 0.45 m | 9.4k | middle of the mat's **back edge**, on the counter top |

**Facing.** Every part faces Godot **+Z** (labels, faucets, the blender's switches): rotate each so +Z points
at the bartender (for the back bar, away from the wall). The mats' "back edge" origin means a part can be
put flush against the wall at the origin.

## Where they could go (a suggestion; the room is yours)

In `tools/stores/small/wave8.gd cucos()` the bar runs down the right wall at the back, in the store frame
`P(u, y, d)` (u along the front, d into the room): the **back bar** is a dark wood cabinet against the wall at
u = W − SIDE (13.88), from d 6.6 to D − 1.2 (14.8), 0.40 m deep, **top at y 0.90**, under the painted `w8_bar`
quad of bottles (y 0.95–2.15); the **front bar** (counter) runs beside it at u ≈ 12.3, top y 1.10; stools at
u 11.55. The bartender's aisle between them is ~0.6 m.

| Part | Suggested spot | Turn |
|---|---|---|
| Two or three shelves on the wall over the back bar (y ≈ 1.15, 1.50, 1.85, 0.14 m deep: yours to build), replacing or covering the painted `w8_bar` quad | rows of `bottles_a` and `bottles_b` alternating along d (7.2, 8.4, 9.6 … ), A on the lower shelves | labels toward −t (into the room) |
| `taps` | back bar top, y 0.90, d ≈ 7.6, back edge against the wall | faucets toward −t |
| `glasses` | back bar top, d ≈ 9.0 | −t |
| `service` | back bar top, d ≈ 10.6 | −t |
| `stemrack` | under the ceiling (or a canopy) over the front bar, d ≈ 8.5–9.1, rails along d | rails along the bar |

Once they are in, the painted bottle quad can go (or stay as a far-back fill behind the shelves).

## Notes

- **Static parts in a baked wing:** their `.glb.import` files are set to `meshes/light_baking=2`
  (static lightmaps, UV2 from Godot's importer) at a 0.05 m texel, like the lion. Wing 1 (1995) then needs a
  rebake. If you hang them under a `BlenderProps`-style node instead (unbaked, probe-lit), set it back to 1.
- **Collision:** none in the models. The back bar is already an obstacle (`K.ob`), so nothing new is needed
  where the parts sit on it; the stem rack hangs above head height (keep its bottom above ~2.0 m).
- **Glass** is transparent and not baked (its own glTF materials). Many transparent surfaces in one view
  cost some fill rate on phones; if the bar is slow on iPhone, drop the stem rack first.
- **Labels** are invented: CAMINO BLANCO, TÍO RAMÓN, BAYOU AÑEJO, LAS PALMAS (tequila, mezcal), GULFSTAR
  (vodka), OLD PIROGUE (whiskey), PELICAN, ATCHAFALAYA (rum), NARANJA (triple sec), KREWE (gin), SEÑORITA
  (coffee liqueur), BLUE HERON (curaçao). Change the names in `tools/blender/assets_src/_bar.py BOTTLES` and
  rebuild (`tools/blender/run.sh bl_cu_bb_bottles_a`).
- Rebuilding a part keeps its id, origin and facing.
