## games, inc. dome ticket games (design/storefronts/games-inc-2026.md). opts {"style": 0 | 1 | "arch"}:
##  0/1  M19 pink / M20 blue drop-dome game (f040-f058): an octagonal cabinet 1.15 x 1.15 x 1.65 m, a front
##       face with the instructions panel, a yellow push button, the red LED "100" and a TAP reader, grey
##       side panels with a swirl, a yellow rim round a lit playfield of neon rings, a clear dome.
##  "arch" M22 (g001, IMG_4445): a smaller dome game under a neon arch with a green "TICKETS" column behind,
##       1.0 x 1.0 x 2.0 m (name not legible).
## Atlas tex/gi/m_dome.png (paint.py dome()).

const K = preload("res://tools/stores/games_inc/machines/kit.gd")

static func footprint(opts = {}):
	return Vector2(1.0, 1.0) if str(opts.get("style", 0)) == "arch" else Vector2(1.15, 1.15)

static func build(b, g, o, f, opts = {}):
	var xf = K.X(o, f)
	var arch = str(opts.get("style", 0)) == "arch"
	var s = 0 if arch else int(opts.get("style", 0)) % 2
	var body = "gi_m_dome_body"
	var lit = "gi_m_dome_lit"
	var fp = footprint(opts)
	var R = fp.x * 0.5
	var c = Vector3(0, 0, fp.y * 0.5)
	var Y = 0.98 if not arch else 0.9
	# octagonal cabinet: the front face lit (the panel), the rest grey with the swirl
	for k in 8:
		var a0 = TAU * (k + 0.5) / 8.0 + PI * 0.5; var a1 = TAU * (k + 1.5) / 8.0 + PI * 0.5
		var r = R / cos(PI / 8.0)
		var p0 = c + Vector3(cos(a0) * r, 0, sin(a0) * r)
		var p1 = c + Vector3(cos(a1) * r, 0, sin(a1) * r)
		var n = ((p0 + p1) * 0.5 - c).normalized()
		var front = n.z < -0.9
		var tr = K.rg("dome", ("front%d" % s) if front else ("side%d" % s))
		if arch:
			tr = K.rg("dome", "archbase") if front else K.sub(K.rg("dome", "archbase"), 0.0, 0.0, 0.3, 1.0)
		K.face(b, g, lit if front else body, xf, [p0, p1, p1 + Vector3(0, Y, 0), p0 + Vector3(0, Y, 0)], n, tr)
	# the rim (yellow ring) and the lit playfield under the dome
	K.vcyl(b, g, "vcolor", xf, c + Vector3(0, Y, 0), R * 1.04, R * 1.0, 0.06, 16, false, false, Color("#ffd21a"))
	var fr = K.rg("dome", "field")
	var pts = []
	for k in 16:
		var a = TAU * k / 16.0
		pts.append(c + Vector3(cos(a) * R * 0.98, Y + 0.06, sin(a) * R * 0.98))
	for k in 16:
		var p0 = pts[k]; var p1 = pts[(k + 1) % 16]; var cc = c + Vector3(0, Y + 0.06, 0)
		var uv = func(p): return Vector2(lerp(fr.x, fr.z, 0.5 + (p.x - c.x) / (2.0 * R)), lerp(fr.y, fr.w, 0.5 + (p.z - c.z) / (2.0 * R)))
		b.quad(g, lit, [xf * cc, xf * p0, xf * p1, xf * cc], (xf.basis * Vector3.UP).normalized(), [uv.call(cc), uv.call(p0), uv.call(p1), uv.call(cc)])
	# neon rings inside (dynamic) and the red "100" readout post
	var neon = ["#3cff6a", "#ff4fa8", "#3fd0ff", "#ff3a2a"]
	for k in 4:
		var a = TAU * k / 4.0 + 0.4
		K.led(b, g, xf, c + Vector3(cos(a) * R * 0.5 - 0.08, Y + 0.2, sin(a) * R * 0.5), c + Vector3(cos(a) * R * 0.5 + 0.08, Y + 0.2, sin(a) * R * 0.5), neon[k], 0.03, true)
		K.led(b, g, xf, c + Vector3(cos(a) * R * 0.5, Y + 0.06, sin(a) * R * 0.5), c + Vector3(cos(a) * R * 0.5, Y + 0.22, sin(a) * R * 0.5), neon[k], 0.03, true)
	K.cbox(b, g, "gi_k_black", xf, c + Vector3(0, Y + 0.3, 0), Vector3(0.24, 0.12, 0.04), "#ffffff", true)
	K.led(b, g, xf, c + Vector3(-0.09, Y + 0.3, -0.025), c + Vector3(0.09, Y + 0.3, -0.025), "#ff2a2a", 0.05, true)
	# the clear dome (dynamic, half ellipsoid)
	K.ell(b, g, "gi_k_dome", xf * (c + Vector3(0, Y + 0.06, 0)), Vector3(R, R * 0.62, R), 16, 6, true, true)
	if arch:
		# the neon arch over it and the green TICKETS column behind
		var ar = K.rg("dome", "arch")
		K.tbox(b, g, lit, xf, Vector3(0, 1.45, fp.y - 0.06), Vector3(0.9, 1.1, 0.12), {"front": ar, "all": K.sub(ar, 0, 0, 0.1, 1)})
		for k in 9:
			var a0 = PI * k / 9.0; var a1 = PI * (k + 1) / 9.0
			K.led(b, g, xf, c + Vector3(cos(a0) * 0.46, 1.0 + sin(a0) * 0.75, 0), c + Vector3(cos(a1) * 0.46, 1.0 + sin(a1) * 0.75, 0), ["#ff4fa8", "#3fd0ff"][k % 2], 0.035, true)
	K.obst(b, xf, -fp.x * 0.5, fp.x * 0.5, 0, fp.y, 0.12)

static func fill_mat(m, key, b):
	if key in ["body", "lit"]:
		return K.atlas_mat(m, b, "dome", key, 1.3, 0.35)
	return false
