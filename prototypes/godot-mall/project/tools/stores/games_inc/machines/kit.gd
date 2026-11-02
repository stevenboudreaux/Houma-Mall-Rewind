## games, inc. (2026) machine kit: shared geometry helpers and materials for the machine pieces in
## this folder (one file per machine kind, design/storefronts/games-inc-2026.md "The machines").
## Not Pocket Change's 1990s kit: these are the 2026 cabinets from Steven's walkthrough
## (IMG_4443/IMG_4444/IMG_4445), each with its own atlas painted by paint.py -> tex/gi/m_<kind>.png.
##
## Contract (the same frame as Pocket Change's prop modules, so the store can place either):
##   static func footprint(opts = {}) -> Vector2   # (width along the player's right, depth along f)
##   static func build(b, g, o, f, opts = {})        # one machine; the player stands at o facing f
##   static func fill_mat(m, key, b) -> bool        # material "gi_m_<kind>_<key>"
## Local frame: x = the player's right, y = up, z = into the machine (along f); the machine fills
## x in [-w/2, w/2], z in [0, d]. Materials "gi_k_<key>" are this kit's own (fill_mat below).

const ATW = 1024.0          # every machine atlas is 1024 x 512 (paint.py)
const ATH = 512.0

static func X(o, f):
	return Transform3D(Basis(f.cross(Vector3.UP), Vector3.UP, f), o)

## Pixel rect (x0, y0, x1, y1) of a 1024 x 512 atlas -> normalized UV rect.
static func R(x0, y0, x1, y1):
	return Vector4(x0 / ATW, y0 / ATH, x1 / ATW, y1 / ATH)

## A quad from local points [bl, br, tr, tl] (as seen from outside) with texture rect r.
static func face(b, g, m, xf, p, n, r = Vector4(0, 0, 1, 1), dyn = false):
	var w = []
	for q in p:
		w.append(xf * q)
	b.quad(g, m, w, (xf.basis * n).normalized(),
		[Vector2(r.x, r.w), Vector2(r.z, r.w), Vector2(r.z, r.y), Vector2(r.x, r.y)], dyn)

## A box (local centre c, size s) whose faces map to atlas rects: rects keys "front" (-z, the
## player's side), "back", "left" (-x), "right" (+x), "top", "bottom"; "all" is the default.
## A face whose rect is null (or missing with no "all") is skipped.
static func tbox(b, g, m, xf, c, s, rects, dyn = false):
	var h = s * 0.5
	var x0 = c.x - h.x; var x1 = c.x + h.x
	var y0 = c.y - h.y; var y1 = c.y + h.y
	var z0 = c.z - h.z; var z1 = c.z + h.z
	var dflt = rects.get("all", null)
	var F = {
		"front": [[Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector3(x1, y1, z0), Vector3(x0, y1, z0)], Vector3(0, 0, -1)],
		"back": [[Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector3(x0, y1, z1), Vector3(x1, y1, z1)], Vector3(0, 0, 1)],
		"left": [[Vector3(x0, y0, z1), Vector3(x0, y0, z0), Vector3(x0, y1, z0), Vector3(x0, y1, z1)], Vector3(-1, 0, 0)],
		"right": [[Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector3(x1, y1, z1), Vector3(x1, y1, z0)], Vector3(1, 0, 0)],
		"top": [[Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1)], Vector3(0, 1, 0)],
		"bottom": [[Vector3(x0, y0, z1), Vector3(x1, y0, z1), Vector3(x1, y0, z0), Vector3(x0, y0, z0)], Vector3(0, -1, 0)],
	}
	for k in F:
		var r = rects.get(k, dflt) if rects.has(k) else (dflt if k != "bottom" else null)
		if r == null:
			continue
		face(b, g, m, xf, F[k][0], F[k][1], r, dyn)

## A solid-colour box in the local frame (vertex colour; material vcolor / vcolor_matte or a k_ one).
static func cbox(b, g, m, xf, c, s, col, dyn = false, skip = []):
	b.cur_color = Color(col)
	b.box(g, m, c, s, xf, skip, dyn)
	b.cur_color = Color.WHITE

## An emissive LED strip from local p0 to p1 (axis-aligned), cross-section w x w, colour hex.
static func led(b, g, xf, p0, p1, hexcol, w = 0.025, dyn = false):
	var c = (p0 + p1) * 0.5
	var d = (p1 - p0).abs()
	b.box(g, "gi_k_led_" + hexcol.trim_prefix("#"), c, Vector3(max(d.x, w), max(d.y, w), max(d.z, w)), xf, [], dyn)

## A vertical cylinder in the local frame (base centre p), any material.
static func vcyl(b, g, m, xf, p, r0, r1, h, seg = 16, top = true, dyn = false, col = Color.WHITE):
	b.cur_color = col
	b.cyl(g, m, xf * p, r0, r1, h, seg, top, false, dyn)
	b.cur_color = Color.WHITE

## A chrome bar stool (pedestal, ring, seat), local floor point p. Dynamic (small parts).
static func stool(b, g, xf, p, seat_col = "#2a4fb8", h = 0.76):
	vcyl(b, g, "gi_k_chrome", xf, p, 0.2, 0.2, 0.03, 14, true, true)
	vcyl(b, g, "gi_k_chrome", xf, p + Vector3(0, 0.03, 0), 0.035, 0.035, h - 0.1, 8, false, true)
	vcyl(b, g, "gi_k_chrome", xf, p + Vector3(0, 0.3, 0), 0.19, 0.19, 0.02, 14, false, true)
	vcyl(b, g, "vcolor", xf, p + Vector3(0, h - 0.08, 0), 0.19, 0.2, 0.09, 16, true, true, Color(seat_col))

## Smooth ellipsoid (world centre c, radii rad), low poly; used for plush and domes.
static func ell(b, g, m, c, rad, seg = 10, rings = 6, dyn = true, half = false):
	var s = b.st(g, m, dyn)
	var rows = []
	var jmax = rings
	for j in jmax + 1:
		var t = (PI * 0.5 * j / rings) if half else (PI * j / rings)
		var row = []
		for i in seg + 1:
			var ph = TAU * i / seg
			var dd = Vector3(sin(t) * cos(ph), cos(t), sin(t) * sin(ph))
			var pos = c + Vector3(dd.x * rad.x, dd.y * rad.y, dd.z * rad.z)
			var nr = Vector3(dd.x / rad.x, dd.y / rad.y, dd.z / rad.z).normalized()
			row.append([pos, nr, Vector2(float(i) / seg, float(j) / rings)])
		rows.append(row)
	for j in jmax:
		for i in seg:
			var a = rows[j][i]; var bq = rows[j][i + 1]; var cq = rows[j + 1][i + 1]; var d = rows[j + 1][i]
			for tr in [[a, bq, cq], [a, cq, d]]:
				var fn = tr[0][1] + tr[1][1] + tr[2][1]
				var o = tr
				if (tr[1][0] - tr[0][0]).cross(tr[2][0] - tr[0][0]).dot(fn) < 0.0:
					o = [tr[0], tr[2], tr[1]]
				for v in o:
					s.set_color(b.cur_color); s.set_normal(v[1]); s.set_uv(v[2]); s.add_vertex(v[0])

## A generic plush figure (no character): a body and a head blob, two ear nubs; world point p on
## the surface it sits on, scale k. Colours from the frames' plush piles (yellow, orange, blue, ...).
static func plush(b, g, p, k, col, rng):
	b.cur_color = Color(col)
	ell(b, g, "vcolor_matte", p + Vector3(0, 0.22 * k, 0), Vector3(0.2, 0.22, 0.18) * k, 8, 5)
	ell(b, g, "vcolor_matte", p + Vector3(0, 0.52 * k, 0), Vector3(0.17, 0.15, 0.15) * k, 8, 5)
	if rng.randf() < 0.6:
		for sx in [-1, 1]:
			ell(b, g, "vcolor_matte", p + Vector3(sx * 0.11 * k, 0.66 * k, 0), Vector3(0.05, 0.08, 0.04) * k, 6, 3)
	b.cur_color = Color.WHITE

## Axis-aligned walk obstacle round the local rect x0..x1, z0..z1, padded.
static func obst(b, xf, x0, x1, z0, z1, pad = 0.15):
	var c0 = xf * Vector3(x0, 0, z0)
	var c1 = xf * Vector3(x1, 0, z1)
	b.obst(["rect", min(c0.x, c1.x) - pad, min(c0.z, c1.z) - pad, max(c0.x, c1.x) + pad, max(c0.z, c1.z) + pad])

## The standard atlas materials every machine uses: "body" (painted, satin) and "lit" (the same
## atlas, glowing: marquees, screens, lit panels). e = emission energy.
static func atlas_mat(m, b, kind, key, e = 1.4, rough = 0.45):
	m.albedo_texture = b.tex("gi/m_%s.png" % kind)
	m.roughness = rough
	if key == "lit":
		m.emission_enabled = true
		m.emission_texture = m.albedo_texture
		m.emission = Color.WHITE
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		m.emission_energy_multiplier = e
		m.set_meta("e_day", e); m.set_meta("e_night", e)
	return true

## Materials "gi_k_<key>".
static func fill_mat(m, key, b):
	if key.begins_with("led_"):
		var c = Color("#" + key.substr(4))
		m.albedo_color = c
		m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = 2.4
		m.set_meta("e_day", 2.4); m.set_meta("e_night", 2.4)
		return true
	match key:
		"glass":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.86, 0.92, 0.95, 0.12)
			m.roughness = 0.05; m.metallic_specular = 0.8
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"dome":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.9, 0.95, 1.0, 0.16)
			m.roughness = 0.02; m.metallic_specular = 1.0
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"chrome":
			m.albedo_color = Color("#c9ccd2"); m.metallic = 1.0; m.roughness = 0.18
		"black":
			m.albedo_color = Color("#141418"); m.roughness = 0.4
		"blackmatte":
			m.albedo_color = Color("#1a1a1e"); m.roughness = 0.85
		"screen":
			m.albedo_color = Color("#10131c"); m.roughness = 0.1
			m.emission_enabled = true; m.emission = Color("#3b6bd8"); m.emission_energy_multiplier = 0.9
			m.set_meta("e_day", 0.9); m.set_meta("e_night", 0.9)
		_:
			return false
	return true

## Atlas regions written by paint.py (atlas.json): kind's region `name` as a UV rect.
static var _regions = null
static func rg(kind, name):
	if _regions == null:
		_regions = JSON.parse_string(FileAccess.get_file_as_string("res://tools/stores/games_inc/machines/atlas.json"))
	var r = _regions[kind][name]
	return R(r[0], r[1], r[2], r[3])

## A sub-rect of a region: fractions (fx0, fy0, fx1, fy1) of rect r.
static func sub(r, fx0, fy0, fx1, fy1):
	return Vector4(lerp(r.x, r.z, fx0), lerp(r.y, r.w, fy0), lerp(r.x, r.z, fx1), lerp(r.y, r.w, fy1))
