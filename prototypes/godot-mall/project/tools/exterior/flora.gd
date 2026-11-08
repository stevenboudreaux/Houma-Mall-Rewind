## Workstream LOT (Nov 8 2026): the outside's trees, shrubs and planters (design/godot-exterior.md
## "Workstream LOT"). Replaces the interior's potted-palm and card-bush helpers the outside borrowed
## from build_mall.gd (a 7 cm trunk under 2 m fronds; a bush with a flat square card on top, the
## "dark cap" Steven saw).
##
## Everything leafy uses one 1024 px atlas, tex/ex/ex_foliage.png (tools/exterior/paint_lot.py), drawn
## as dynamic meshes (probe-lit, no lightmap) like the old foliage; trunks and planter curbs stay static
## (baked, they cast the bake's shadows). Per-plant tint goes through the vertex colour.
##
## The far crowns: leaf cards are alpha-tested, and an alpha-tested card's mipmaps average its alpha
## below the threshold at distance, so thin fronds vanished and left bare trunks. The atlas cells have
## solid cores (paint_lot.py) and the foliage material uses alpha-to-coverage with the project's MSAA
## (fill_mat "fol"), which keeps a card's average coverage at every mip.
const UP = Vector3.UP

## The atlas cells [u0, v0, u1, v1] (paint_lot.py FOL)
const FOL = {
	"fan": [0.0, 0.0, 0.5, 0.5],
	"oak": [0.5, 0.0, 1.0, 0.5],
	"shrub": [0.0, 0.5, 0.5, 1.0],
	"grass": [0.5, 0.5, 0.75, 1.0],
	"dead": [0.75, 0.5, 1.0, 1.0],
}

static var rng = RandomNumberGenerator.new()
static var count = {"palm": 0, "oak": 0, "pine": 0, "shrub": 0, "grass": 0, "planter": 0}

static func reset():
	rng.seed = 8111995
	for k in count:
		count[k] = 0

## The flora's own materials (exterior.gd's fill_mat hands over unknown keys here).
static func fill_mat(m, key, b):
	match key:
		"fol":
			m.albedo_texture = b.tex("ex/ex_foliage.png")
			m.vertex_color_use_as_albedo = true
			m.roughness = 0.85; m.metallic = 0.0; m.metallic_specular = 0.3
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.4
			m.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		"bark_palm":
			m.albedo_texture = b.tex("ex/ex_palm_bark.png"); m.roughness = 0.95; m.metallic = 0.0
		"bark":
			m.albedo_color = Color("#5c4e3e"); m.roughness = 0.95; m.metallic = 0.0
		"shrub_core":
			m.vertex_color_use_as_albedo = true; m.albedo_color = Color("#2f4a24")
			m.roughness = 0.95; m.metallic = 0.0; m.metallic_specular = 0.2
		_:
			return false
	return true

# ------------------------------------------------------------------ cards
## One leaf card: four corners (p0 bottom-left, p1 bottom-right, p2 top-right, p3 top-left), the atlas
## cell, the normal each corner carries (foliage reads softer with normals pointing out of the crown).
static func card(b, cell, p, nrm):
	var c = FOL[cell]
	var uv = [Vector2(c[0], c[3]), Vector2(c[2], c[3]), Vector2(c[2], c[1]), Vector2(c[0], c[1])]
	var s = b.st("ex_flora", "ex_fol", true)
	var fn = (p[1] - p[0]).cross(p[3] - p[0]).normalized()
	b._tri_n(s, [p[0], p[1], p[2]], [nrm[0], nrm[1], nrm[2]], [uv[0], uv[1], uv[2]], fn)
	b._tri_n(s, [p[0], p[2], p[3]], [nrm[0], nrm[2], nrm[3]], [uv[0], uv[2], uv[3]], fn)

## A card centred on c, w wide and h high, its plane spanned by unit vectors u (width) and v (height),
## normals pointing away from `from` (the crown's centre).
static func card_at(b, cell, c, u, v, w, h, from):
	var p = [c - u * (w * 0.5) - v * (h * 0.5), c + u * (w * 0.5) - v * (h * 0.5),
		c + u * (w * 0.5) + v * (h * 0.5), c - u * (w * 0.5) + v * (h * 0.5)]
	var nrm = []
	for q in p:
		nrm.append(((q - from).normalized() + UP * 0.35).normalized())
	card(b, cell, p, nrm)

static func tint(base, var_):
	return Color(base.r * (1.0 + rng.randf_range(-var_, var_)), base.g * (1.0 + rng.randf_range(-var_, var_)),
		base.b * (1.0 + rng.randf_range(-var_, var_)))

# ------------------------------------------------------------------ trees
## A sabal (cabbage) palm, Louisiana's: a grey 0.4 m trunk with its boot scars, a round crown of ~26
## stiff costapalmate fans on long petioles, a few hanging dead fronds under it (trimmed palms show
## a short skirt). hgt = the trunk to the crown's base.
static func sabal(b, at, hgt):
	count.palm += 1
	var lean = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() * rng.randf_range(0.0, 0.35)
	var top = at + UP * hgt + lean
	# the trunk in two tapered pieces, bending into the lean
	var mid = at + UP * (hgt * 0.5) + lean * 0.3
	_trunk_seg(b, at, mid, 0.24, 0.21)
	_trunk_seg(b, mid, top, 0.21, 0.19)
	b.cur_color = tint(Color(0.95, 1.0, 0.92), 0.10)
	# the boot under the crown: a short collar of dead leaf bases
	for i in 7:
		var yaw = TAU * i / 7.0 + rng.randf() * 0.4
		var d = Vector3(cos(yaw), 0, sin(yaw))
		card_at(b, "dead", top + UP * -0.45 + d * 0.22, Vector3(-d.z, 0, d.x), (UP * 0.9 + d * 0.3).normalized(), 0.9, 1.3, top)
	# the fans: three tiers, the lowest drooping, the top ones near vertical
	var n = 24 + rng.randi_range(0, 6)
	for i in n:
		var yaw = TAU * i / n * 2.39996 + rng.randf() * 0.2   # golden-angle spiral
		var tier = float(i % 3)
		var elev = deg_to_rad([62.0, 25.0, -12.0][int(tier)] + rng.randf_range(-12, 12))
		var d = Vector3(cos(yaw), 0, sin(yaw))
		var dir = (d * cos(elev) + UP * sin(elev)).normalized()
		var plen = rng.randf_range(0.9, 1.4)                  # the petiole
		var base = top + UP * (0.15 * tier) + dir * plen
		_petiole(b, top + UP * (0.15 * tier), base)
		# the fan: about 1.7 m across, held across the petiole, folded along its rib (two halves)
		var side = Vector3(-d.z, 0, d.x)
		var fw = rng.randf_range(1.5, 1.9)
		var fl = fw * 0.9
		var up_ = (dir + UP * 0.25 * (1.0 - tier * 0.5)).normalized()
		var tilt = side.rotated(dir, rng.randf_range(-0.35, 0.35))
		var tip = base + up_ * fl
		var fold = (up_.cross(tilt)).normalized() * (fw * 0.12)
		var c0 = FOL.fan
		var cm = (c0[0] + c0[2]) * 0.5
		var s = b.st("ex_flora", "ex_fol", true)
		var nA = ((base - top).normalized() + UP * 0.5).normalized()
		# left half: hastula (base), left edge, left top, mid top (raised by the fold)
		var pl = [base, base - tilt * (fw * 0.5), base - tilt * (fw * 0.5) + up_ * fl, tip + fold]
		var pr = [base, tip + fold, base + tilt * (fw * 0.5) + up_ * fl, base + tilt * (fw * 0.5)]
		var ul = [Vector2(cm, c0[3]), Vector2(c0[0], c0[3]), Vector2(c0[0], c0[1]), Vector2(cm, c0[1])]
		var ur = [Vector2(cm, c0[3]), Vector2(cm, c0[1]), Vector2(c0[2], c0[1]), Vector2(c0[2], c0[3])]
		for h in [[pl, ul], [pr, ur]]:
			var P = h[0]; var U = h[1]
			var fn = (P[1] - P[0]).cross(P[2] - P[0]).normalized()
			b._tri_n(s, [P[0], P[1], P[2]], [nA, nA, nA], [U[0], U[1], U[2]], fn)
			b._tri_n(s, [P[0], P[2], P[3]], [nA, nA, nA], [U[0], U[2], U[3]], fn)
	b.cur_color = Color.WHITE
	b.obst(["rect", at.x - 0.35, at.z - 0.35, at.x + 0.35, at.z + 0.35])

static func _trunk_seg(b, a, c, r0, r1):
	# a tapered cylinder from a to c (b.cyl only stands upright)
	var s = b.st("ex_props", "ex_bark_palm")
	var ax = (c - a).normalized()
	var u = ax.cross(Vector3(1, 0, 0)).normalized()
	var w = ax.cross(u)
	var L = a.distance_to(c)
	for i in 10:
		var a0 = TAU * i / 10.0; var a1 = TAU * (i + 1) / 10.0
		var d0 = u * cos(a0) + w * sin(a0); var d1 = u * cos(a1) + w * sin(a1)
		var p = [a + d0 * r0, a + d1 * r0, c + d1 * r1, c + d0 * r1]
		var uv = [Vector2(i / 5.0, L / 2.0), Vector2((i + 1) / 5.0, L / 2.0), Vector2((i + 1) / 5.0, 0), Vector2(i / 5.0, 0)]
		b._tri_n(s, [p[0], p[1], p[2]], [d0, d1, d1], [uv[0], uv[1], uv[2]], (d0 + d1).normalized())
		b._tri_n(s, [p[0], p[2], p[3]], [d0, d1, d0], [uv[0], uv[2], uv[3]], (d0 + d1).normalized())

static func _petiole(b, a, c):
	var s = b.st("ex_flora", "ex_bark", true)
	var ax = (c - a).normalized()
	var side = ax.cross(UP).normalized() * 0.03
	if side.length() < 0.01:
		side = Vector3(0.03, 0, 0)
	var n = ax.cross(side).normalized()
	b._tri_n(s, [a - side, a + side, c + side * 0.5], [n, n, n], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], n)
	b._tri_n(s, [a - side, c + side * 0.5, c - side * 0.5], [n, n, n], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], n)

## A southern live oak: a short thick trunk, three or four limbs spreading low and wide, a broad,
## flattened crown of leaf-cluster cards (no top card: the old bush's flat square was the dark cap).
## size = the crown's radius in metres.
static func live_oak(b, at, size):
	count.oak += 1
	var th = size * 0.45
	b.cyl("ex_props", "ex_bark", at, size * 0.07, size * 0.055, th, 8, false, false, false)
	var top = at + UP * th
	var nl = 3 + rng.randi_range(0, 1)
	var cc = top + UP * (size * 0.55)
	for i in nl:
		var yaw = TAU * i / nl + rng.randf() * 0.6
		var d = Vector3(cos(yaw), 0, sin(yaw))
		_limb(b, top, top + d * (size * 0.55) + UP * (size * 0.45), size * 0.04)
	b.cur_color = tint(Color(1.0, 1.0, 1.0), 0.12)
	# the crown: clusters on a flattened ellipsoid shell, each a crossed pair of cards
	var nc = int(22 + size * 4.0)
	for i in nc:
		var yaw = rng.randf() * TAU
		var el = rng.randf_range(-0.35, 1.0)
		var d = Vector3(cos(yaw) * cos(el), sin(el) * 0.55, sin(yaw) * cos(el))
		var c = cc + Vector3(d.x * size, d.y * size, d.z * size) * rng.randf_range(0.65, 0.95)
		var cs = size * rng.randf_range(0.45, 0.7)
		# each cluster a crossed pair turned at random, so no card faces the eye as a flat disc
		var r1 = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)).normalized()
		var t1 = r1.cross(d).normalized()
		if t1.length() < 0.1:
			t1 = Vector3(-d.z, 0, d.x).normalized()
		var t2 = d.cross(t1).normalized()
		card_at(b, "oak", c, t1, t2, cs, cs * 0.85, cc)
		card_at(b, "oak", c, t1, d, cs, cs * 0.85, cc)
		card_at(b, "oak", c, t2, d, cs * 0.9, cs * 0.8, cc)
	b.cur_color = Color.WHITE
	b.obst(["rect", at.x - 0.5, at.z - 0.5, at.x + 0.5, at.z + 0.5])

static func _limb(b, a, c, r):
	var s = b.st("ex_props", "ex_bark")
	var ax = (c - a).normalized()
	var u = ax.cross(Vector3(0, 0, 1) if abs(ax.z) < 0.9 else Vector3(1, 0, 0)).normalized()
	var w = ax.cross(u)
	for i in 6:
		var a0 = TAU * i / 6.0; var a1 = TAU * (i + 1) / 6.0
		var d0 = u * cos(a0) + w * sin(a0); var d1 = u * cos(a1) + w * sin(a1)
		var p = [a + d0 * r, a + d1 * r, c + d1 * r * 0.5, c + d0 * r * 0.5]
		b._tri_n(s, [p[0], p[1], p[2]], [d0, d1, d1], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], (d0 + d1).normalized())
		b._tri_n(s, [p[0], p[2], p[3]], [d0, d1, d0], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], (d0 + d1).normalized())

## A slash / loblolly pine: a tall bare trunk, a high irregular crown of oak-cell clusters tinted dark.
static func pine(b, at, hgt):
	count.pine += 1
	b.cyl("ex_props", "ex_bark", at, 0.2, 0.12, hgt * 0.85, 8, false, false, false)
	b.cur_color = tint(Color(0.72, 0.85, 0.7), 0.08)
	var cc = at + UP * (hgt * 0.78)
	for i in 14:
		var yaw = rng.randf() * TAU
		var d = Vector3(cos(yaw), 0, sin(yaw))
		var c = cc + d * rng.randf_range(0.6, 2.2) + UP * rng.randf_range(-1.6, 1.8)
		var cs = rng.randf_range(1.6, 2.4)
		card_at(b, "oak", c, Vector3(-d.z, 0, d.x), UP, cs, cs * 0.6, cc)
		card_at(b, "oak", c, Vector3(-d.z, 0, d.x), d, cs, cs * 0.8, cc)
	b.cur_color = Color.WHITE
	b.obst(["rect", at.x - 0.4, at.z - 0.4, at.x + 0.4, at.z + 0.4])

# ------------------------------------------------------------------ shrubs
## A clipped shrub (holly, Indian hawthorn, photinia): a low dome core, leaf cards round it. size =
## the radius (m). No flat card on top.
static func shrub(b, at, size, base = Color(0.85, 1.0, 0.85)):
	count.shrub += 1
	var sx = size * rng.randf_range(0.9, 1.2); var sy = size * rng.randf_range(0.65, 0.9)
	var col = tint(base, 0.12)
	b.cur_color = col * 0.8
	_dome(b, at, sx * 0.85, sy * 0.85)
	b.cur_color = col
	var cc = at + UP * (sy * 0.45)
	for i in 7:
		var yaw = TAU * i / 7.0 + rng.randf() * 0.5
		var d = Vector3(cos(yaw), 0, sin(yaw))
		var c = cc + d * (sx * 0.45) + UP * rng.randf_range(-0.1, 0.25) * sy
		var t = Vector3(-d.z, 0, d.x)
		card_at(b, "shrub", c, t, (UP + d * 0.5).normalized(), sx * 1.1, sy * 1.2, cc - UP * sy)
	b.cur_color = Color.WHITE

## A clipped column (podocarpus / yew pine on JCPenney's west wall, 4488 f020): r wide, h tall.
static func column(b, at, r, h):
	count.shrub += 1
	var col = tint(Color(0.8, 0.95, 0.8), 0.08)
	b.cur_color = col * 0.8
	_dome(b, at, r * 0.85, h * 0.95)
	b.cur_color = col
	var cc = at + UP * (h * 0.5)
	for i in 6:
		var yaw = TAU * i / 6.0 + rng.randf() * 0.4
		var d = Vector3(cos(yaw), 0, sin(yaw))
		card_at(b, "shrub", cc + d * (r * 0.5), Vector3(-d.z, 0, d.x), UP, r * 1.4, h * 1.05, cc - d * r)
	b.cur_color = Color.WHITE
	b.obst(["rect", at.x - r, at.z - r, at.x + r, at.z + r])

static func _dome(b, at, rx, ry):
	var s = b.st("ex_flora", "ex_shrub_core", true)
	var seg = 8; var ring = 3
	for j in ring:
		var e0 = PI * 0.5 * j / ring; var e1 = PI * 0.5 * (j + 1) / ring
		for i in seg:
			var a0 = TAU * i / seg; var a1 = TAU * (i + 1) / seg
			var p = []
			var nn = []
			for q in [[a0, e0], [a1, e0], [a1, e1], [a0, e1]]:
				var d = Vector3(cos(q[0]) * cos(q[1]), sin(q[1]), sin(q[0]) * cos(q[1]))
				p.append(at + Vector3(d.x * rx, d.y * ry, d.z * rx))
				nn.append(d)
			b._tri_n(s, [p[0], p[1], p[2]], [nn[0], nn[1], nn[2]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], nn[0])
			b._tri_n(s, [p[0], p[2], p[3]], [nn[0], nn[2], nn[3]], [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO], nn[0])

## An ornamental grass / liriope clump: three crossed cards.
static func grass(b, at, hgt):
	count.grass += 1
	b.cur_color = tint(Color(0.95, 1.0, 0.85), 0.12)
	var y0 = rng.randf() * PI
	for i in 3:
		var yaw = y0 + PI * i / 3.0
		var t = Vector3(cos(yaw), 0, sin(yaw))
		card_at(b, "grass", at + UP * (hgt * 0.5), t, UP, hgt * 0.7, hgt, at - UP)
	b.cur_color = Color.WHITE

# ------------------------------------------------------------------ planters
## A landscaped planter island [x0, z0, x1, z1]: a low, wide concrete curb (10 cm, 30 cm wide; grey,
## or `curb` when the year's footage shows it painted), a mulch bed, 3-5 plants with variation and,
## in the big ones (`palm`), a sabal. Replaces the tall single-shrub island.
static func planter(b, x0, z0, x1, z1, curb = "ex_curb", top = "ex_mulch", palm = false, plants = true):
	count.planter += 1
	var H = 0.10; var W = 0.30
	var g = "ex_lot"
	# the curb ring: four boxes (the corners overlap), the bed slightly below its top
	b.box(g, curb, Vector3((x0 + x1) * 0.5, H * 0.5, z0 + W * 0.5), Vector3(x1 - x0, H, W), Transform3D.IDENTITY, ["-y"])
	b.box(g, curb, Vector3((x0 + x1) * 0.5, H * 0.5, z1 - W * 0.5), Vector3(x1 - x0, H, W), Transform3D.IDENTITY, ["-y"])
	b.box(g, curb, Vector3(x0 + W * 0.5, H * 0.5, (z0 + z1) * 0.5), Vector3(W, H, z1 - z0 - 2.0 * W), Transform3D.IDENTITY, ["-y", "-z", "+z"])
	b.box(g, curb, Vector3(x1 - W * 0.5, H * 0.5, (z0 + z1) * 0.5), Vector3(W, H, z1 - z0 - 2.0 * W), Transform3D.IDENTITY, ["-y", "-z", "+z"])
	b.quad(g, top, [Vector3(x0 + W, H - 0.02, z0 + W), Vector3(x1 - W, H - 0.02, z0 + W), Vector3(x1 - W, H - 0.02, z1 - W), Vector3(x0 + W, H - 0.02, z1 - W)], UP, [], false, 0.5)
	b.obst(["rect", x0, z0, x1, z1])
	if not plants and not palm:
		return
	var ix0 = x0 + W + 0.35; var ix1 = x1 - W - 0.35
	var iz0 = z0 + W + 0.35; var iz1 = z1 - W - 0.35
	var long_x = (x1 - x0) >= (z1 - z0)
	var L = max(ix1 - ix0, iz1 - iz0)
	var n = clampi(int(L / 0.8), 3, 5) if L < 12.0 else int(L / 1.6)
	var cx = (x0 + x1) * 0.5; var cz = (z0 + z1) * 0.5
	for i in n:
		var f = (i + 0.5) / n + rng.randf_range(-0.12, 0.12) / n
		var p = Vector3(lerp(ix0, ix1, f) if long_x else cx + rng.randf_range(-0.3, 0.3) * (ix1 - ix0) * 0.5,
			H - 0.02, lerp(iz0, iz1, f) if not long_x else cz + rng.randf_range(-0.3, 0.3) * (iz1 - iz0) * 0.5)
		if palm and Vector2(p.x - cx, p.z - cz).length() < 0.6:
			p += (Vector3(1, 0, 0) if long_x else Vector3(0, 0, 1)) * (0.8 if i * 2 < n else -0.8)
		var r = rng.randf()
		if r < 0.55:
			shrub(b, p, rng.randf_range(0.5, 0.8))
		else:
			grass(b, p, rng.randf_range(0.55, 0.9))
	if palm:
		sabal(b, Vector3(cx, H - 0.02, cz), rng.randf_range(5.5, 7.5))
