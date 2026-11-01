## The 2026 store signs (Demo 43, Oct 24 2026): every sign Steven's Oct 23 footage shows, built in
## 3D from tools/stores/signs/y26/signs_2026.json (the spec) and the letters that
## make_signs_2026.py writes from it (y26/<id>_<part>_logo.json, tex/sg/y26/...).
##
## A sign is one or more parts (words or traced shapes) on a fascia, each a run of cans built by
## channel.gd: closed-face channel letters lit from inside, flat cut letters, halo-lit letters
## (dark face, a glow on the wall behind), open neon, or lettering printed on a lit cabinet. Behind
## them, as the frame shows, a backer panel, a cabinet box or a raceway. Colours, depths and the
## letters' height come from the spec; the sign is scaled down if it would not fit the fascia.
##
## Materials are "sg_y26_<id>_<part>_<role>" (channel.gd's fill_mat answers them from the spec):
## role = face, ret, trim, glow, or for the sign itself backer, backer_lit, raceway, mark.

const UP = Vector3.UP
const SPEC_PATH = "res://tools/stores/signs/y26/signs_2026.json"

static var _spec = null
static var _by_store = {}
static var _logo_cache = {}

static func spec():
	if _spec == null:
		_spec = JSON.parse_string(FileAccess.get_file_as_string(SPEC_PATH))
		for s in _spec.signs:
			_by_store[s.store] = s
			for alias in s.get("aliases", []):
				_by_store[alias] = s
	return _spec

static func for_store(name):
	spec()
	return _by_store.get(name)

static func by_id(id):
	spec()
	for s in _spec.signs:
		if s.id == id:
			return s
	return null

static func logo(path):
	if not _logo_cache.has(path):
		# null when the part's letters haven't been generated (make_signs_2026.py failed on it)
		_logo_cache[path] = JSON.parse_string(FileAccess.get_file_as_string(path)) if FileAccess.file_exists(path) else null
	return _logo_cache[path]

## The sign's frame in metres: [x0, y0, x1, y1] round all its parts (part dx/dy are the bottom
## centre of each part's letters from the sign's anchor point).
static func frame(s):
	var x0 = INF
	var y0 = INF
	var x1 = -INF
	var y1 = -INF
	for p in s.parts:
		var J = logo("res://tools/stores/signs/y26/%s_%s_logo.json" % [s.id, p.name])
		if J == null:
			continue
		var w = float(J.width)
		var h = float(J.cap_h)
		var dx = float(p.get("dx", 0.0))
		var dy = float(p.get("dy", -h * 0.5))
		x0 = min(x0, dx - w * 0.5)
		x1 = max(x1, dx + w * 0.5)
		y0 = min(y0, dy)
		y1 = max(y1, dy + h)
	if x0 == INF:
		# no letters (a sign that isn't there in 2026, or only its panel): the frame is the panel's
		x0 = 0.0; x1 = 0.0; y0 = 0.0; y1 = 0.0
	if s.has("backer"):
		var bk = s.backer
		var bw = float(bk.get("w", x1 - x0 + 0.3))
		var bh = float(bk.get("h", y1 - y0 + 0.3))
		var bx = float(bk.get("dx", 0.0))
		var by = float(bk.get("dy", (y0 + y1) * 0.5))
		x0 = min(x0, bx - bw * 0.5)
		x1 = max(x1, bx + bw * 0.5)
		y0 = min(y0, by - bh * 0.5)
		y1 = max(y1, by + bh * 0.5)
	return [x0, y0, x1, y1]

## Builds the sign for store `name` with its anchor point at c (the fascia's face, the sign's
## middle), facing nn, at most max_w wide and max_h tall. Returns true when a sign was built.
static func build(b, g, name, c, nn, max_w, max_h, sign = null):
	var s = sign if sign != null else for_store(name)
	if s == null:
		return false
	var fr = frame(s)
	var fw = fr[2] - fr[0]
	var fh = fr[3] - fr[1]
	# ws/g: an optional "scale" (> 1 enlarges the spec; still capped by max_w/max_h)
	var k = min(float(s.get("scale", 1.0)), max_w / max(fw, 0.01), max_h / max(fh, 0.01))
	var rv = (-nn).cross(UP)
	# centre the frame on c (the spec's dx/dy are already about the sign's middle)
	var cx = (fr[0] + fr[2]) * 0.5
	var cy = (fr[1] + fr[3]) * 0.5
	var base = c - rv * (cx * k) - UP * (cy * k)
	var zoff = 0.0
	var mid = "y26_%s" % s.id
	if s.has("raceway"):
		var rw = s.raceway
		var rh = float(rw.get("h", 0.2)) * k
		var rd = float(rw.get("depth", 0.1))
		var rwid = float(rw.get("w", fw)) * k
		var ry = float(rw.get("dy", cy)) * k
		b.box(g, "sg_%s_raceway" % mid, base + UP * ry + nn * (rd * 0.5), b.abs_size((-nn).cross(UP), rwid, rh, rd, nn), Transform3D.IDENTITY, [], true)
		zoff = rd
	if s.has("backer"):
		var bk = s.backer
		var bw = float(bk.get("w", fw)) * k
		var bh = float(bk.get("h", fh)) * k
		var bd = float(bk.get("depth", 0.06))
		var bx = float(bk.get("dx", cx)) * k
		var by = float(bk.get("dy", cy)) * k
		var bm = "sg_%s_backer" % mid
		var ctr = base + rv * bx + UP * by + nn * (zoff + bd * 0.5)
		match bk.get("shape", "box"):
			"oval":
				_oval(b, g, bm, "sg_%s_backer_side" % mid, ctr, rv, nn, bw, bh, bd)
			"round":
				_oval(b, g, bm, "sg_%s_backer_side" % mid, ctr, rv, nn, bw, bw, bd)
			_:
				b.box(g, bm, ctr, b.abs_size((-nn).cross(UP), bw, bh, bd, nn), Transform3D.IDENTITY, [], true)
				if bk.has("frame"):
					# a thin frame round the panel's edge, standing a little proud
					var fwd = float(bk.get("frame_w", 0.03))
					var fm = "sg_%s_backer_frame" % mid
					for e in [[0.0, bh * 0.5 - fwd * 0.5, bw, fwd], [0.0, -bh * 0.5 + fwd * 0.5, bw, fwd], [bw * 0.5 - fwd * 0.5, 0.0, fwd, bh], [-bw * 0.5 + fwd * 0.5, 0.0, fwd, bh]]:
						b.box(g, fm, ctr + rv * e[0] + UP * e[1] + nn * (bd * 0.5 + 0.006), b.abs_size((-nn).cross(UP), e[2], e[3], 0.012, nn), Transform3D.IDENTITY, [], true)
		zoff += bd
	for p in s.parts:
		var J = logo("res://tools/stores/signs/y26/%s_%s_logo.json" % [s.id, p.name])
		if J == null:
			push_warning("sign_2026: no letters for %s/%s" % [s.id, p.name])
			continue
		var h = float(J.cap_h)
		var dx = float(p.get("dx", 0.0)) * k
		var dy = float(p.get("dy", -h * 0.5)) * k
		var pm = "%s_%s" % [mid, p.name]
		var typ = p.get("type", s.get("type", "channel"))
		var depth = float(p.get("depth", s.get("depth", 0.1)))
		var standoff = float(p.get("standoff", s.get("standoff", 0.02)))
		var trim_w = float(p.get("trim_w", s.get("trim_w", 0.012)))
		var glow = ("sg_%s_glow" % pm) if p.has("glow") else ""
		var trim = ("sg_%s_trim" % pm) if p.has("trim") else ""
		match typ:
			"flat", "vinyl":
				trim_w = 0.0
				if typ == "vinyl":
					depth = 0.003
					standoff = 0.0
			"halo":
				trim_w = 0.0
				standoff = max(standoff, 0.04)
			"neon":
				trim_w = 0.0
		var pz = float(p.get("dz", 0.0))
		load("res://tools/stores/signs/channel.gd").build(b, g, "res://tools/stores/signs/y26/%s_%s_logo.json" % [s.id, p.name],
			base + rv * dx + UP * dy + nn * (zoff + pz), nn, "sg_%s_face" % pm, "sg_%s_ret" % pm, trim,
			standoff, depth, trim_w, glow, true, float(p.get("roll", 0.0)), k)
	return true

## An elliptical backer (a cabinet): the lit face, the rim, as a fan of quads.
static func _oval(b, g, face, side, ctr, rv, nn, w, h, d):
	var n = 48
	var f = b.st(g, face, true)
	var sd = b.st(g, side, true)
	var pts = []
	for i in n:
		var a = TAU * i / n
		pts.append(rv * (cos(a) * w * 0.5) + UP * (sin(a) * h * 0.5))
	var zf = nn * (d * 0.5)
	var zb = -nn * (d * 0.5)
	for i in n:
		var j = (i + 1) % n
		b.tri(f, ctr + zf, ctr + pts[i] + zf, ctr + pts[j] + zf, Vector2(0.5, 0.5), Vector2(0.5 + pts[i].dot(rv) / w, 0.5 - pts[i].dot(UP) / h), Vector2(0.5 + pts[j].dot(rv) / w, 0.5 - pts[j].dot(UP) / h), nn)
		var en = (pts[i] + pts[j]).normalized()
		b.tri(sd, ctr + pts[i] + zb, ctr + pts[j] + zb, ctr + pts[j] + zf, Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), en)
		b.tri(sd, ctr + pts[i] + zb, ctr + pts[j] + zf, ctr + pts[i] + zf, Vector2(0, 1), Vector2(1, 0), Vector2(0, 0), en)

## "y26_<id>_<part>_<role>" → the material from the spec. Called by channel.gd's fill_mat.
static func fill_mat(m, key, b):
	if key == "y26_lease_card":
		# the leasing card in vacant windows (IMG_4440 f013), lit a little by the hall
		m.albedo_texture = b.tex("sg/y26/lease_card.png"); m.roughness = 0.6
		m.emission_enabled = true; m.emission_texture = m.albedo_texture; m.emission = Color.WHITE
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY; m.emission_energy_multiplier = 0.15
		m.set_meta("e_day", 0.12); m.set_meta("e_night", 0.2)
		return true
	var toks = key.split("_")
	if toks.size() < 3:
		return false
	var role = toks[toks.size() - 1]
	var s = null
	var p = null
	if role in ["backer", "side", "frame", "raceway", "mark"] and toks.size() >= 3:
		# y26_<id>_backer | y26_<id>_backer_side | y26_<id>_backer_frame | y26_<id>_raceway
		if role == "side" or role == "frame":
			s = by_id("_".join(toks.slice(1, toks.size() - 2)))
		else:
			s = by_id("_".join(toks.slice(1, toks.size() - 1)))
		if s == null:
			return false
		match role:
			"backer", "side", "frame":
				var bk = s.backer
				var col = bk.get("color", "#ffffff")
				if role == "side":
					col = bk.get("side", bk.get("frame", col))
				if role == "frame":
					col = bk.get("frame", col)
				m.albedo_color = Color(col)
				m.roughness = float(bk.get("rough", 0.4))
				m.metallic = float(bk.get("metal", 0.0))
				m.metallic_specular = 0.5
				var lit = float(bk.get("lit", 0.0)) if role == "backer" else 0.0
				if lit > 0.0:
					m.emission_enabled = true
					m.emission = Color(bk.get("emit", col))
					m.emission_energy_multiplier = lit
					m.set_meta("e_day", lit * 0.8)
					m.set_meta("e_night", lit * 1.2)
			"raceway":
				var rw = s.raceway
				m.albedo_color = Color(rw.get("color", "#2a2a2a"))
				m.roughness = float(rw.get("rough", 0.5))
				m.metallic = float(rw.get("metal", 0.2))
		return true
	# y26_<id>_<part>_<face|ret|trim|glow>
	var pid = toks[toks.size() - 2]
	s = by_id("_".join(toks.slice(1, toks.size() - 2)))
	if s == null:
		return false
	for q in s.parts:
		if q.name == pid:
			p = q
	if p == null:
		return false
	var typ = p.get("type", s.get("type", "channel"))
	var lit = float(p.get("lit", 1.0 if typ in ["channel", "neon", "cabinet"] else 0.0))
	var face = p.get("face", "#ffffff")
	match role:
		"face":
			m.albedo_color = Color(face)
			m.roughness = float(p.get("rough", 0.3 if typ != "flat" else 0.4))
			# metal faces (chrome, brass, nickel) capped: with only the baked light and the hall's
			# probes, a fully metallic face reads near-black from most angles
			m.metallic = min(float(p.get("metal", 0.0)), 0.45)
			m.roughness = max(m.roughness, 0.28)
			m.metallic_specular = 0.5 if m.metallic < 0.1 else 0.7
			if lit > 0.0:
				var tx = b.tex("sg/y26/%s_%s_face.png" % [s.id, pid])
				if tx != null:
					m.albedo_texture = tx
					m.emission_texture = tx
					m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
				m.emission_enabled = true
				m.emission = Color(p.get("emit", face))
				var e = lit * (1.3 if typ != "neon" else 2.2)
				m.emission_energy_multiplier = e
				m.set_meta("e_day", e * 0.85)
				m.set_meta("e_night", e * 1.15)
		"ret":
			m.albedo_color = Color(p.get("ret", "#1e1e1e" if typ != "flat" else face))
			m.roughness = float(p.get("ret_rough", 0.45))
			m.metallic = min(float(p.get("ret_metal", 0.3)), 0.5)
		"trim":
			m.albedo_color = Color(p.get("trim", "#222222"))
			m.roughness = 0.35
			m.metallic_specular = 0.6
			if lit > 0.0:
				m.emission_enabled = true
				m.emission = Color(p.get("emit", face))
				m.emission_energy_multiplier = 0.2 * lit
				m.set_meta("e_day", 0.12 * lit)
				m.set_meta("e_night", 0.25 * lit)
		"glow":
			var gtx = b.tex("sg/y26/%s_%s_glow.png" % [s.id, pid])
			if gtx == null:
				return false
			load("res://tools/stores/signs/channel.gd")._glow(m, gtx, float(p.get("glow_e", 0.45 if typ != "halo" else 0.9)))
		_:
			return false
	return true
