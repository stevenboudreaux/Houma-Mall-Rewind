## The mall directory kiosks (design/godot-directory.md), modelled from the Oct 23 2026 footage:
## IMG_4408 50-72 s (straight on, t050_017-027; in the hall, t050_011), IMG_4461 t008_010 (the
## second kiosk, at the top of H6), IMG_4484 f068 and IMG_4459 f006 (the plain cream backs),
## IMG_4455 (the panel). A single-sided totem: a stepped grey plinth, a grey cabinet with a satin
## aluminium frame round the lit panel, a thin pink stripe at its top and bottom edges, an arched
## crown and a champagne-silver Art-Deco fan finial (the mall's fan motif) on a ball.
## The 1995 kiosks are the same cabinet with the 1994 Merchant List & Map art (Steven, Nov 1:
## "pretty similar to the current one, just less modern").
##
## Colours: sampled from the footage and corrected for the camera's exposure against the white
## floor and ceiling tiles in the same frames (Nov 1): cabinet and crown #a7b1b3, plinth #858c8f,
## aluminium frame #b3babc, pinstripes #b5676d.
##
## Built dynamic (probe-lit, like the info desk) so placing or changing a kiosk needs no rebake.
## Materials "dir_<key>" (fill_mat). Each kiosk is also a node in group "interactable"
## (scripts/directory_kiosk.gd) that opens the map (scripts/directory_ui.gd).
##
## Measurements (metres; against the 12" floor tiles in t050_011 and the panel's proportions in
## t050_021, so +-10%): plinth 1.26 wide x 0.52 deep x 0.46 high (a 0.10 toe under a 0.36 block
## with a chamfered top); cabinet 1.20 x 0.30 x 1.38 (top at 1.84); lit art 1.02 x 1.14 in a
## 0.09 / 0.12 frame; crown 0.98 wide, 0.06 shoulders and a 0.13 segmental rise (top 2.03);
## finial: five pleated diamond blades fanned over 84 degrees, 0.22 across, tip at about 2.10,
## on a 0.036 ball at the cabinet's top edge.
extends RefCounted

const G := "directory"
const DATA := "res://tools/stores/directory/directory_data.json"

const PLINTH_W := 1.26
const PLINTH_D := 0.52
const TOE_H := 0.10
const PLINTH_H := 0.46
const CAB_W := 1.20
const CAB_D := 0.30
const CAB_H := 1.38
const ART_W := 1.02
const ART_H := 1.14
const CROWN_W := 0.98
const CROWN_SH := 0.06
const CROWN_RISE := 0.13
const CROWN_D := 0.10

## Called once per wing build (tools/build_mall.gd, after the halls): builds this year's kiosks that
## stand in this wing, Mr. Silverman's island in 1995, and writes GEN/directory.json for the map.
## Returns the centres to keep the benches and planters away from.
static func place(b) -> Array:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var y := str(b.YEAR)
	var centers := []
	var k := 0
	for kd in data.get(y, {}).get("kiosks", []):
		var c := Vector3(float(kd.x), 0, float(kd.z))
		var zid = b.zone_at(c.x, c.z)
		if zid == "misc" or not b.in_wing(b.wing_of_zone(zid)):
			continue
		var f := Vector3(float(kd.face[0]), 0, float(kd.face[1])).normalized()
		build(b, c, f, y)
		var node := Node3D.new()
		node.name = "DirectoryKiosk%d" % k
		node.set_script(load("res://scripts/directory_kiosk.gd"))
		node.position = c
		node.set_meta("face", Vector2(f.x, f.z))
		node.set_meta("where", kd.get("where", ""))
		node.add_to_group("interactable", true)
		b.mall.add_child(node)
		node.owner = b.mall
		centers.append(c)
		k += 1
	# Mr. Silverman's jewelry island, back in 1995 (it was taken out Oct 16 when the island under
	# the lit ring became the info desk). The 1994 Merchant List & Map puts #91, "Mr. Goldman",
	# just east of E = Information in the concourse: that spot (design/godot-directory.md).
	if b.YEAR != 2026:
		for x in data.get(y, {}).get("extras", []):
			if not x.get("kiosk", false):
				continue
			var c := Vector3(float(x.x), 0, float(x.z))
			var zid = b.zone_at(c.x, c.z)
			if zid == "misc" or not b.in_wing(b.wing_of_zone(zid)):
				continue
			b.force_dyn = true
			b.island_kiosk("silverman", c)
			b.force_dyn = false
			centers.append(c)
	# the map's data, both years, from the layout files (map_data.gd)
	var md: Dictionary = load("res://tools/stores/directory/map_data.gd").compute()
	DirAccess.make_dir_recursive_absolute(b.GEN)
	var f2 = FileAccess.open(b.GEN + "directory.json", FileAccess.WRITE)
	f2.store_string(JSON.stringify(md))
	f2.close()
	print("directory: ", k, " kiosks in this wing, ", b.GEN + "directory.json")
	return centers

## tools/qa/preview.sh: one kiosk at the origin facing +z (the camera side), opts {"year": "1995"},
## or {"pair": true} for both years side by side (2026 left).
static func preview(b, g, c: Vector3, fwd: Vector3, opts: Dictionary) -> void:
	if opts.get("pair", false):
		build(b, c + Vector3(-0.85, 0, 0), Vector3.BACK, "2026")
		build(b, c + Vector3(0.85, 0, 0), Vector3.BACK, "1995")
	else:
		build(b, c, Vector3.BACK, str(opts.get("year", "2026")))

## One kiosk at c (floor), its lit face toward f.
static func build(b, c: Vector3, f: Vector3, year: String) -> void:
	var r := (-f).cross(Vector3.UP).normalized()   # the viewer's right, facing the panel
	var xf := Transform3D(Basis(r, Vector3.UP, f), c)
	b.force_dyn = true
	# the plinth: a toe, then a block with a chamfered top (t050_021: a reveal line low down)
	b.box(G, "dir_base", Vector3(0, TOE_H * 0.5, 0), Vector3(PLINTH_W - 0.03, TOE_H, PLINTH_D - 0.03), xf, ["-y"])
	var bh := PLINTH_H - TOE_H - 0.045
	b.box(G, "dir_base", Vector3(0, TOE_H + bh * 0.5, 0), Vector3(PLINTH_W, bh, PLINTH_D), xf, ["-y", "+y"])
	_frustum(b, "dir_base", xf, TOE_H + bh, 0.045, PLINTH_W, PLINTH_D, CAB_W + 0.03, CAB_D + 0.05)
	b.box(G, "dir_shadow", Vector3(0, TOE_H + 0.004, 0), Vector3(PLINTH_W + 0.002, 0.008, PLINTH_D + 0.002), xf, ["-y", "+y"])
	# the cabinet: grey sides and top, the cream back (IMG_4484 f068)
	var y0 := PLINTH_H
	var cy := y0 + CAB_H * 0.5
	b.box(G, "dir_cabinet", Vector3(0, cy, 0), Vector3(CAB_W, CAB_H, CAB_D), xf, ["+z", "-z", "-y"])
	_face(b, "dir_back", xf, Vector3(0, cy, -CAB_D * 0.5), Vector3(CAB_W, CAB_H, 0), -1.0, true)
	# the red pinstripes: a cap band round the cabinet's top edge, above the aluminium frame, seen
	# from the front and sides (t050_021, t050_011); at the back also a band along the bottom edge
	# (IMG_4484 f068). Colour sampled from the footage: #b5676d.
	b.box(G, "dir_pink", Vector3(0, y0 + CAB_H + 0.011, 0), Vector3(CAB_W + 0.02, 0.022, CAB_D + 0.02), xf, ["-y"])
	b.box(G, "dir_pink", Vector3(0, y0 + 0.014, -CAB_D * 0.5 - 0.002), Vector3(CAB_W + 0.004, 0.018, 0.006), xf, ["+z"])
	for sd in [-1.0, 1.0]:
		b.box(G, "dir_pink", Vector3(sd * (CAB_W * 0.5 + 0.002), y0 + 0.014, 0), Vector3(0.006, 0.018, CAB_D), xf, ["-x" if sd > 0 else "+x"])
	# the front: an aluminium frame round the recessed lit art, a dark gasket, two lock barrels
	var fz := CAB_D * 0.5
	var fw := (CAB_W - ART_W) * 0.5
	var fh := (CAB_H - ART_H) * 0.5
	var ay := y0 + fh + ART_H * 0.5
	b.box(G, "dir_frame", Vector3(0, y0 + CAB_H - fh * 0.5, fz + 0.008), Vector3(CAB_W, fh, 0.016), xf, ["-z"])
	b.box(G, "dir_frame", Vector3(0, y0 + fh * 0.5, fz + 0.008), Vector3(CAB_W, fh, 0.016), xf, ["-z"])
	b.box(G, "dir_frame", Vector3(-(CAB_W - fw) * 0.5, ay, fz + 0.008), Vector3(fw, ART_H, 0.016), xf, ["-z", "+y", "-y"])
	b.box(G, "dir_frame", Vector3((CAB_W - fw) * 0.5, ay, fz + 0.008), Vector3(fw, ART_H, 0.016), xf, ["-z", "+y", "-y"])
	# the frame's inner bevel (a lighter lip) and the gasket line round the art
	for sd in [-1.0, 1.0]:
		b.box(G, "dir_lip", Vector3(sd * (ART_W * 0.5 + 0.009), ay, fz + 0.018), Vector3(0.018, ART_H + 0.036, 0.006), xf, ["-z"])
		b.box(G, "dir_lip", Vector3(0, ay + sd * (ART_H * 0.5 + 0.009), fz + 0.018), Vector3(ART_W + 0.036, 0.018, 0.006), xf, ["-z"])
	_face(b, "dir_gasket", xf, Vector3(0, ay, fz + 0.001), Vector3(ART_W + 0.004, ART_H + 0.004, 0), 1.0, false)
	_face(b, "dir_panel_" + year, xf, Vector3(0, ay, fz + 0.003), Vector3(ART_W, ART_H, 0), 1.0, true)
	for ly in [ay + ART_H * 0.36, ay - ART_H * 0.40]:
		b.box(G, "dir_lock", Vector3(CAB_W * 0.5 - fw * 0.5, ly, fz + 0.019), Vector3(0.022, 0.022, 0.006), xf, ["-z"])
	# the crown: an arched slab over the cabinet, grey in front, cream behind
	var ct := y0 + CAB_H + 0.022   # the crown sits on the pinstripe cap
	var outline := PackedVector2Array()
	var hw := CROWN_W * 0.5
	outline.append(Vector2(-hw, 0)); outline.append(Vector2(hw, 0)); outline.append(Vector2(hw, CROWN_SH))
	var R: float = (hw * hw + CROWN_RISE * CROWN_RISE) / (2.0 * CROWN_RISE)
	var a0 := asin(hw / R)
	for i in range(1, 16):
		var a := a0 - 2.0 * a0 * i / 16.0
		outline.append(Vector2(R * sin(a), CROWN_SH + CROWN_RISE - R + R * cos(a)))
	outline.append(Vector2(-hw, CROWN_SH))
	var o := xf * Vector3(0, ct, 0)
	b.poly(G, "dir_cabinet", outline, o + f * CROWN_D * 0.5, r, Vector3.UP, f)
	b.poly(G, "dir_back", outline, o - f * CROWN_D * 0.5, r, Vector3.UP, -f)
	for i in outline.size():
		var p0: Vector2 = outline[i]
		var p1: Vector2 = outline[(i + 1) % outline.size()]
		if p0.y < 0.001 and p1.y < 0.001:
			continue
		var w0 := o + r * p0.x + Vector3.UP * p0.y
		var w1 := o + r * p1.x + Vector3.UP * p1.y
		var en := r * (p1.y - p0.y) - Vector3.UP * (p1.x - p0.x)
		en = en.normalized() * (1.0 if en.dot((w0 + w1) * 0.5 - (o + Vector3.UP * 0.05)) > 0 else -1.0)
		b.quad(G, "dir_cabinet", [w0 + f * CROWN_D * 0.5, w1 + f * CROWN_D * 0.5, w1 - f * CROWN_D * 0.5, w0 - f * CROWN_D * 0.5], en)
	# the finial: a ball on the cabinet's top edge, a collar, five pleated fan blades
	var fc := xf * Vector3(0, ct + 0.04, CROWN_D * 0.5 + 0.03)
	_ball(b, "dir_finial", fc, 0.036)
	# the dark slot in the crown behind the ball (t050_021)
	b.box(G, "dir_gasket", Vector3(0, ct + 0.05, CROWN_D * 0.5 + 0.002), Vector3(0.075, 0.10, 0.004), xf, ["-z"])
	var hub := fc + Vector3.UP * 0.03
	var lens := [0.15, 0.185, 0.215, 0.185, 0.15]
	for i in 5:
		var ang := deg_to_rad(-42.0 + 21.0 * i)
		var radial := (r * sin(ang) + Vector3.UP * cos(ang)).normalized()
		var across := radial.cross(f).normalized()
		# pleat: each blade turned about its own axis, alternately toward and away from the front
		var tilt := deg_to_rad(16.0 if i % 2 == 0 else -16.0)
		var nrm := f.rotated(radial, tilt).normalized()
		across = radial.cross(nrm).normalized()
		var L: float = lens[i]
		var pts := [Vector2(0.0, -0.008), Vector2(L * 0.58, -0.046), Vector2(L, 0.0), Vector2(L * 0.58, 0.046), Vector2(0.0, 0.008)]
		var pv := PackedVector2Array(pts)
		b.poly(G, "dir_finial", pv, hub + nrm * 0.004, radial, across, nrm)
		b.poly(G, "dir_finial", pv, hub - nrm * 0.004, radial, across, -nrm)
		# the blade's centre rib, a little proud
		b.quad(G, "dir_finial_hi", [hub + nrm * 0.0055 + across * 0.002, hub + radial * L * 0.95 + nrm * 0.0055 + across * 0.002,
			hub + radial * L * 0.95 + nrm * 0.0055 - across * 0.002, hub + nrm * 0.0055 - across * 0.002], nrm)
	b.force_dyn = false
	# collision: the plinth's footprint
	var ext := (r * PLINTH_W * 0.5).abs() + (f * PLINTH_D * 0.5).abs()
	b.obst(["rect", c.x - ext.x - 0.15, c.z - ext.z - 0.15, c.x + ext.x + 0.15, c.z + ext.z + 0.15])

## A flat rectangle centred at local lc, size sz.x by sz.y, facing local +z (side 1) or -z (-1),
## textured 0..1 when uv (mirrored on the back so it reads the right way round).
static func _face(b, mname: String, xf: Transform3D, lc: Vector3, sz: Vector3, side: float, uv: bool) -> void:
	var hx := sz.x * 0.5
	var hy := sz.y * 0.5
	var p := [xf * (lc + Vector3(-hx * side, -hy, 0)), xf * (lc + Vector3(hx * side, -hy, 0)), xf * (lc + Vector3(hx * side, hy, 0)), xf * (lc + Vector3(-hx * side, hy, 0))]
	var n: Vector3 = (xf.basis * Vector3(0, 0, side)).normalized()
	var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)] if uv else []
	b.quad(G, mname, p, n, uvs)

## A sloped band (a chamfer) from a w0 x d0 rectangle at y up h to a w1 x d1 one, with its top.
static func _frustum(b, mname: String, xf: Transform3D, y: float, h: float, w0: float, d0: float, w1: float, d1: float) -> void:
	var lo := [Vector3(-w0 * 0.5, y, d0 * 0.5), Vector3(w0 * 0.5, y, d0 * 0.5), Vector3(w0 * 0.5, y, -d0 * 0.5), Vector3(-w0 * 0.5, y, -d0 * 0.5)]
	var hi := [Vector3(-w1 * 0.5, y + h, d1 * 0.5), Vector3(w1 * 0.5, y + h, d1 * 0.5), Vector3(w1 * 0.5, y + h, -d1 * 0.5), Vector3(-w1 * 0.5, y + h, -d1 * 0.5)]
	for i in 4:
		var j := (i + 1) % 4
		var mid: Vector3 = (lo[i] + lo[j]) * 0.5
		var out := Vector3(mid.x, 0, mid.z).normalized()
		var n: Vector3 = (out * h + Vector3.UP * (Vector3(lo[i].x, 0, lo[i].z).length() - Vector3(hi[i].x, 0, hi[i].z).length())).normalized()
		b.quad(G, mname, [xf * lo[i], xf * lo[j], xf * hi[j], xf * hi[i]], (xf.basis * n).normalized())
	b.quad(G, mname, [xf * hi[0], xf * hi[1], xf * hi[2], xf * hi[3]], Vector3.UP)

static func _ball(b, mname: String, c: Vector3, rad: float) -> void:
	var seg := 10
	var rings := 6
	for i in rings:
		var t0 := PI * i / rings
		var t1 := PI * (i + 1) / rings
		for j in seg:
			var p0 := TAU * j / seg
			var p1 := TAU * (j + 1) / seg
			var v := [Vector3(sin(t0) * cos(p0), cos(t0), sin(t0) * sin(p0)), Vector3(sin(t0) * cos(p1), cos(t0), sin(t0) * sin(p1)),
				Vector3(sin(t1) * cos(p1), cos(t1), sin(t1) * sin(p1)), Vector3(sin(t1) * cos(p0), cos(t1), sin(t1) * sin(p0))]
			var n: Vector3 = (v[0] + v[1] + v[2] + v[3]).normalized()
			b.quad(G, mname, [c + v[0] * rad, c + v[1] * rad, c + v[2] * rad, c + v[3] * rad], n)

## The kiosk's materials (tools/build_mall.gd's mat() hands "dir_<key>" here).
static func fill_mat(m: StandardMaterial3D, key: String, b) -> bool:
	match key:
		"cabinet":
			m.albedo_color = Color("#a7b1b3"); m.roughness = 0.55; m.metallic = 0.1
		"base":
			m.albedo_color = Color("#858c8f"); m.roughness = 0.62; m.metallic = 0.05
		"shadow":
			m.albedo_color = Color("#6d7076"); m.roughness = 0.8
		"frame":
			# satin aluminium (t050_021: a light silver frame with soft highlights)
			m.albedo_color = Color("#b3babc"); m.metallic = 0.5; m.roughness = 0.32
		"lip":
			m.albedo_color = Color("#c6cccd"); m.metallic = 0.5; m.roughness = 0.25
		"gasket":
			m.albedo_color = Color("#1c1d20"); m.roughness = 0.6
		"lock":
			m.albedo_color = Color("#8d9096"); m.metallic = 0.8; m.roughness = 0.3
		"pink":
			m.albedo_color = Color("#b5676d"); m.roughness = 0.5
		"back":
			# the plain cream back (IMG_4484 f068), a faint powder-coat grain
			m.albedo_texture = b.tex("dir/back.png"); m.roughness = 0.7
			m.uv1_scale = Vector3(2, 2, 1)
		"finial":
			# champagne silver, like the court's fan sconces
			m.albedo_color = Color("#cfc8ba"); m.metallic = 0.85; m.roughness = 0.28
		"finial_hi":
			m.albedo_color = Color("#ece7dc"); m.metallic = 0.9; m.roughness = 0.2
		"panel_1995", "panel_2026":
			# the lit panel: the art shows as it is, lit from behind (dynamic, so emission only)
			var t = b.tex("dir/" + key + ".png")
			m.albedo_texture = t
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color(0.93, 0.95, 0.97)
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		_:
			return false
	return true
