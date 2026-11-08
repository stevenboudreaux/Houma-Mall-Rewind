## Great American Cookie Co., the 1995 store's finish (workstream FOOD3D item 2, Nov 8 2026). Steven, Nov 7: the
## white tile with scattered red/black/yellow squares is the 2026 look; the 1990s store was "more traditional".
## Steven picked option B (Nov 8): dark oak and brass: an oak raised-panel wainscot with a brass strip in its
## chair rail, cream plaster, a burgundy pinstripe, an oak crown (tex/gac/wall95_b.png, tools/stores/gac/paint95.py).
## Option A (burgundy and checker, from his 1990s photo) was shown and not chosen: its painter is gone too.
## The sign, the case, the record's red check course and the 2026 store are unchanged.

const UP = Vector3.UP

## The material for the 1995 walls (shell, menu wall), in place of the 2026 "gac_tile_sq".
static func wall_mat() -> String:
	return "gac_wall95"

static func fill_mat(m, b):
	m.albedo_texture = b.tex("gac/wall95_b.png")
	m.roughness = 0.6
	# world triplanar, 3.0 m repeat from the floor, so the wainscot sits at the same height on every wall
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE / 3.0
	return true

## The front's trim under the sign box: a brass bar across the opening's head, and the
## opening's side returns in the wainscot's finish. a / t / n / W / head as wave7.gd cookie().
static func trim(b, F, a, t, n, W, head):
	var P = func(u, y, d): return a + t * u - n * d + UP * y
	b.cur_color = Color("#b8913a")
	b.box(F, "vcolor", P.call(W * 0.5, head - 0.03, -0.07), b.abs_size(t, W, 0.05, 0.05, n))
	b.cur_color = Color("#704626")
	for u in [0.06, W - 0.06]:
		b.box(F, "vcolor_matte", P.call(u, 0.5, 0.06), b.abs_size(t, 0.12, 1.0, 0.12, n))
	b.cur_color = Color("#b8913a")
	for u in [0.06, W - 0.06]:
		b.box(F, "vcolor", P.call(u, 1.02, 0.06), b.abs_size(t, 0.13, 0.04, 0.13, n))
	b.cur_color = Color.WHITE
