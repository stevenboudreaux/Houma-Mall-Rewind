## Wicked Wingz (2026, store s64: the 1995 Chick-fil-A unit). Steven (Oct 28, and again Nov 1):
## "the literal exact layout of Chick-fil-A['s] counter and dining room, it's the literal same
## stall. All that needs to change is branding and menu and signage."
##
## So this builds Chick-fil-A itself (tools/stores/cfa/store.gd, unchanged: the front, the counter,
## the kitchen, the dining room) and re-skins it for 2026 through fill_cf(): build_mall.gd's mat()
## asks fill_cf() first for every "cf_*" material when YEAR == 2026 (the 2026 scene has no other
## Chick-fil-A, so nothing else is affected). Any later change to the 1995 Chick-fil-A's layout
## carries over here by itself.
##
## What changes (Steven's Oct 23 2026 footage, IMG_4441 f003-f006, IMG_4461 f028-f034):
## - signage: Chick-fil-A's script letters are hidden; the Demo 43 Wicked Wingz sign (black panel,
##   yellow letters, y26/parts/wingz.json) hangs on the sign panel where the script was; the fascia,
##   the beam and the awning box take the mall's cream; the red A-frame menu stands at the front.
## - branding: the counter faced in white 4" tile with black accent tiles, a steel top, the printed
##   black sneeze-guard panels (COMBO DEALS, the wordmark, GET WICKED!); white walls and wainscot
##   instead of the striped paper and the maroon; white booths and tables, yellow chair seats; the
##   grey floor tile instead of the red quarry.
## - menu: the five-board Wicked Wingz menu in Chick-fil-A's menu band.
## Notes and guesses: design/storefronts/wicked-wingz-2026.md. Materials "ww_*" (fill_mat), the
## re-skinned "cf_*" (fill_cf), textures tex/ww/ (paint.py).
##
## Frame (Chick-fil-A's): P(u, y, d) = a + t u - n d + y up; u from x -102 (the right hand of
## someone facing the store), d into the store.

const CFA = preload("res://tools/stores/cfa/store.gd")
const K = preload("res://tools/stores/media/kit.gd")
const S26 = preload("res://tools/stores/signs/sign_2026.gd")
const UP = Vector3.UP
const DY = "wwf_dyn"
const SM = "ww_small"

static var a0: Vector3
static var tt: Vector3
static var nn: Vector3
static var bb

static func P(u, y, d):
	return a0 + tt * u - nn * d + UP * y

static func build(b, g, e, a, b2, n, t, Ln, sd):
	CFA.build(b, g, e, a, b2, n, t, Ln, sd)
	bb = b
	a0 = a
	tt = t
	nn = n
	# the sign where the script was: centred on Chick-fil-A's lettering (u 5.3), standing on the
	# sign panel's foot (HEAD) and rising onto the fascia, just in front of the hidden letters
	S26.build(b, "ww_sg26", "WICKED WINGZ", P(5.3, CFA.HEAD + 0.72, -0.23), n, 3.8, 1.5)
	guard()
	aframe(4.0, -0.6)

## The printed sneeze guard (f006) along the counter's long leg, on the customer face (u 2.45,
## facing the dining room): steel posts, the four black panels, glass over them.
static func guard():
	var u = 2.5
	var y0 = 1.07
	var d0 = 1.3
	var d1 = 8.9
	for k in 6:
		var d = d0 + (d1 - d0) * k / 5.0
		bb.cyl(SM, "wl_steel", P(u, 1.06, d), 0.018, 0.018, 0.58, 8, true, false)
	var pq = [P(u + 0.004, y0, d0), P(u + 0.004, y0, d1), P(u + 0.004, y0 + 0.36, d1), P(u + 0.004, y0 + 0.36, d0)]
	bb.quad(DY, "ww_guard", pq, tt, [Vector2(1, 1), Vector2(0, 1), Vector2(0, 0), Vector2(1, 0)], true)
	var gq = [P(u, y0 + 0.36, d0), P(u, y0 + 0.36, d1), P(u - 0.04, y0 + 0.56, d1), P(u - 0.04, y0 + 0.56, d0)]
	bb.quad(DY, "ww_glass", gq, tt, [], true)

## The red sidewalk A-frame with the printed menu (f004-f006), in front of the store.
static func aframe(u, d):
	var c = P(u, 0, d)
	var f = -nn
	var r = tt
	for side in [-1.0, 1.0]:
		var basis = Basis(r, UP, f).rotated(r, -side * 0.2)
		var o = c + f * side * 0.14
		var xf = Transform3D(basis, o)
		bb.cur_color = Color("#8c1c1c")
		bb.box(SM, "vcolor", Vector3(0, 0.55, 0), Vector3(0.62, 1.1, 0.03), xf)
		bb.cur_color = Color.WHITE
		var face = o + basis * Vector3(0, 0, -0.017 * side)
		var nrm = basis * Vector3(0, 0, -side)
		var rr = basis * Vector3(1, 0, 0) * (-side)
		var up = basis * Vector3(0, 1, 0)
		var cc = face + up * 0.62
		bb.quad(SM, "ww_aframe", [cc - rr * 0.24 - up * 0.36, cc + rr * 0.24 - up * 0.36, cc + rr * 0.24 + up * 0.36, cc - rr * 0.24 + up * 0.36], nrm,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	K.ob(bb, P(u - 0.35, 0, d - 0.35), P(u + 0.35, 0, d + 0.35), 0.02)

# ------------------------------------------------------------------ materials
## The 2026 re-skin of Chick-fil-A's "cf_<key>" materials. Returns false for the ones that stay
## as they are (build_mall.gd then asks cfa/store.gd's fill_mat).
static func fill_cf(m, key, b):
	match key:
		"fascia", "maroon", "awning", "awning_edge":
			m.albedo_color = Color("#e6dcc6"); m.roughness = 0.8
		"maroon_wall":
			m.albedo_color = Color("#e9e6dc"); m.roughness = 0.6
		"wallpaper":
			m.albedo_texture = b.tex("ww/wall.png"); m.roughness = 0.85
		"wainscot":
			m.albedo_color = Color("#e4e0d4"); m.roughness = 0.6
		"counter":
			m.albedo_texture = b.tex("ww/counter_tile.png"); m.roughness = 0.2; m.metallic_specular = 0.7
			m.uv1_triplanar = true; m.uv1_scale = Vector3(1.0 / 1.2, 1.0 / 0.9, 1.0 / 1.2)
		"top":
			m.albedo_color = Color("#b8babc"); m.metallic = 0.5; m.roughness = 0.3
		"vinyl":
			m.albedo_color = Color("#ecebe6"); m.roughness = 0.45; m.metallic_specular = 0.55
		"table":
			m.albedo_color = Color("#f0eee8"); m.roughness = 0.35; m.metallic_specular = 0.55
		"white":
			m.albedo_color = Color("#f2c02a"); m.roughness = 0.4; m.metallic_specular = 0.6
		"quarry":
			m.albedo_texture = b.tex("ww/floor.png"); m.roughness = 0.35; m.metallic_specular = 0.55
		"menu":
			m.albedo_texture = b.tex("ww/menu.png"); m.roughness = 0.4
			K.emit_tex(m, 0.9)
		"letter", "letter_ret":
			# Chick-fil-A's script is not on the 2026 front: drawn fully transparent
			m.albedo_color = Color(0, 0, 0, 0)
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_:
			return false
	return true

## "ww_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"aframe":
			m.albedo_texture = b.tex("ww/aframe.png"); m.roughness = 0.5
		"guard":
			m.albedo_texture = b.tex("ww/guard.png"); m.roughness = 0.3; m.metallic_specular = 0.6
		"glass":
			m.albedo_color = Color(0.85, 0.92, 0.92, 0.22); m.roughness = 0.05; m.metallic_specular = 0.9
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_:
			return false
	return true
