## Dillard's, level 1 (store s2), walkable, both years. Workstream E (Nov 1 2026).
## Design note and sources: design/godot-dillards.md.
##
## Built from the Oct 23 2026 footage (refs/new/dillards_L1: IMG_4490 110-166 s, IMG_4491) and the
## in-store 3-level directory's first-level plan (refs/new/dillards_directory, IMG_4490 t136): men's
## on the east side, cosmetics, accessories, handbags and women's shoes on the other, the escalators
## (since workstream SMALLFIX, Nov 8 2026) at the south end on the axis of the Bayou Gardens doors,
## between cosmetics and fashion jewelry: a crisscross pair, the up unit's foot facing those doors. The plan is drawn
## with the mall entrance at the bottom; turned to the game's frame (mall entrance north), its
## "WEST ENTRANCE" is the east face (the cast-iron gallery side, the one Steven walked in through)
## and its "NORTH ENTRANCE" is the south face (Bayou Gardens).
##
## Ceiling: 2x4 lay-in with recessed cans; over the aisles, a raised coffer edged by curved white
## gypsum soffit bulkheads lit by cove up-lights. Square mirror-clad columns. Polished beige
## travertine aisles with a black and a brown granite edge band; cherry-plank pads under men's; grey
## carpet in accessories. The escalator bank is built but closed (stanchions and a belt).
##
## Frame: world metres, +x east, +z south; the mall front is the north wall (z = Z_FRONT). Called
## from build_mall.gd's anchor_front() after the fascia and sign; builds the whole level.
## Materials "dl_<key>" via fill_mat(); textures tex/dl/ from paint.py.

const X0 = -38.0            # the map rect s2: x 129..163 -> -38..30, y 140..159 -> z 80..118
const X1 = 30.0
const Z_FRONT = 80.0
const Z_BACK = 118.0
const WALL_T = 0.3
const CEIL = 3.6            # the 2x4 lay-in
const COFFER = 4.2          # the coffers over the aisles
const MOUTH = [-10.0, 2.0]  # the mall opening (H8's width: anchor_front's piers stand in it)
const MOUTH_H = 3.4
const AISLE_X = -4.0
# aisles (travertine) [x0, z0, x1, z1]
const AISLES = [
	[-6.0, 80.3, -2.0, 107.0],      # main aisle from the mall to the ring's south run (SMALLFIX: was to the escalators)
	[-30.0, 86.0, 22.0, 89.0],      # ring, north run
	[-30.0, 107.0, 22.0, 110.0],    # ring, south run
	[-30.0, 89.0, -27.0, 107.0],    # ring, west run
	[19.0, 89.0, 22.0, 107.0],      # ring, east run
	[-2.0, 96.8, 19.0, 99.6],       # men's cross aisle
	[22.0, 96.8, 26.5, 99.6],       # to the east (exterior) entrance
	[-21.0, 110.0, -9.0, 114.5],    # SMALLFIX: the plaza in front of the south doors and the escalators' foot
	[-27.0, 96.8, -6.0, 99.6],      # women's cross aisle (to the main aisle)
]
# coffers over the aisles (curved bulkheads on their long sides)
const COFFERS = [
	[-6.8, 80.3, -1.2, 106.3],
	[-30.7, 85.3, 22.7, 89.7],
	[-30.7, 106.3, 22.7, 110.7],
	[-30.7, 89.7, -26.3, 106.3],
	[18.3, 89.7, 22.7, 106.3],
	[-1.2, 96.1, 18.3, 100.3],
	[-26.3, 96.1, -6.8, 100.3],
]
# floor pads: [x0, z0, x1, z1, kind] kind: "men" (cherry; carpet in 1995), "carpet" (grey)
const PADS = [
	[-2.0, 89.0, 19.0, 96.8, "men"], [-2.0, 99.6, 19.0, 107.0, "men"],
	[22.0, 80.3, 30.0, 96.8, "men"], [22.0, 99.6, 30.0, 110.0, "men"],
	[2.0, 80.3, 22.0, 86.0, "men"], [-2.0, 110.0, 30.0, 118.0, "men"],
	[-27.0, 89.0, -17.0, 96.8, "carpet"], [-27.0, 99.6, -18.6, 107.0, "carpet"],
	[-38.0, 80.3, -30.0, 118.0, "carpet"], [-30.0, 110.0, -21.0, 118.0, "carpet"],
	[-9.0, 110.0, -2.0, 118.0, "carpet"],
	# SMALLFIX: the two corners between the plaza and the south wall, beside the vestibule
	[-21.0, 114.5, -18.0, 118.0, "carpet"], [-12.0, 114.5, -9.0, 118.0, "carpet"],
]
# the departments (directory, first level), for the design note and the fixtures
const DEPTS = [
	["Mens Polo / Mens Fragrances", -2.0, 89.0, 7.5, 96.8],
	["Mens Dress Furnishings / Mens Accessories", 9.5, 89.0, 19.0, 96.8],
	["Mens Sportswear", -2.0, 99.6, 7.5, 107.0],
	["Mens Sportswear", 9.5, 99.6, 19.0, 107.0],
	["Mens Shoes / Mens Sportswear", 22.0, 80.3, 30.0, 96.8],
	["Mens Sportswear", 22.0, 99.6, 30.0, 110.0],
	["Mens Clothing / Mens Sportswear", 2.0, 80.3, 22.0, 86.0],
	["Mens Denim / Cremieux-type collection", -2.0, 110.0, 30.0, 118.0],
	["Cosmetics", -15.0, 89.0, -6.0, 96.8],
	["Cosmetics", -11.4, 99.6, -6.0, 107.0],          # east of the escalators (the plan)
	["Handbags / Womens Accessories", -27.0, 89.0, -17.0, 96.8],
	["Fashion Jewelry", -27.0, 99.6, -18.6, 107.0],   # west of the escalators (the plan)
	["Womens Shoes", -38.0, 80.3, -30.0, 118.0],
	["Handbags / Sunglasses", -30.0, 80.3, -10.0, 86.0],
	["Womens Shoes", -30.0, 110.0, -21.0, 118.0],
	["Cosmetics", -9.0, 110.0, -2.0, 118.0],
]
const COLS_X = [-31.0, -22.0, -13.0, 5.0, 14.0, 25.0]
const COLS_Z = [91.5, 103.0, 113.5]
const COL = 0.8
# the escalator bank (IMG_4490 t110_097-103): two units side by side. SMALLFIX (Nov 8 2026): moved
# from the end of the main aisle to where the directory's first-level plan draws it, in line with the
# plan's NORTH ENTRANCE (the game's south doors, x -17.4..-12.6) between cosmetics and fashion
# jewelry. The plan draws the two units offset, each sticking out at the opposite end (its floor
# landing), so they are a crisscross pair (Steven, Nov 8: one goes up, the other down): the east unit
# (up) has its foot facing the south doors and rises north; the west unit (down) rises south and
# lets out at its north foot onto the women's cross aisle.
const ESC_X = [-17.6, -12.4]
const ESC_UNITS = [   # [x0, x1, the foot's front edge z, the way it rises (+1 south, -1 north)]
	[-14.9, -12.4, 111.0, -1.0],         # up, from the south doors
	[-17.6, -15.1, 99.8, 1.0],           # down, to the cross aisle
]
const ESC_RISE = 5.2
const ESC_RUN = 9.0
const WELL = [-18.2, 98.5, -11.8, 112.3]    # 1.3 m past each foot
const EAST_DOOR = [95.0, 101.4]          # the exterior entrance: vestibule x 26.5..30
const VEST_X = 26.5
const SOUTH_DOOR = [-17.4, -12.6]        # the south entrance: vestibule z 114.5..118
const VEST_Z = 114.5

static func in_rect(x, z, r, pad = 0.0):
	return x > r[0] - pad and x < r[2] + pad and z > r[1] - pad and z < r[3] + pad

static func in_any(x, z, rs, pad = 0.0):
	for r in rs:
		if in_rect(x, z, r, pad):
			return true
	return false

static func block(b, x0, z0, x1, z1, pad = 0.0):
	b.obst(["rect", min(x0, x1) - pad, min(z0, z1) - pad, max(x0, x1) + pad, max(z0, z1) + pad])

static func chunk(prefix, x, z):
	return "%s%d_%d" % [prefix, int(floor((x - X0) / 17.0)), int(floor((z - Z_FRONT) / 19.0))]

static func wall(b, G, m, p, q, y0, y1, nrm, per_u = 1.0, per_v = 1.0):
	var A = Vector3(p.x, 0, p.y)
	var B = Vector3(q.x, 0, q.y)
	var L = A.distance_to(B)
	b.quad(G, m, [A + Vector3(0, y0, 0), B + Vector3(0, y0, 0), B + Vector3(0, y1, 0), A + Vector3(0, y1, 0)], nrm,
		[Vector2(0, -y0 / per_v), Vector2(L / per_u, -y0 / per_v), Vector2(L / per_u, -y1 / per_v), Vector2(0, -y1 / per_v)])

static func build(b, g, e, a, bb, n, t, Ln, sd):
	shell(b)
	floors(b)
	ceiling(b)
	columns(b)
	escalators(b)
	entrances(b)
	fixtures(b)
	lights(b)
	var rp = ReflectionProbe.new()
	rp.position = Vector3((X0 + X1) * 0.5, COFFER * 0.5, (Z_FRONT + Z_BACK) * 0.5)
	rp.size = Vector3(X1 - X0, COFFER + 0.2, Z_BACK - Z_FRONT)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.8
	b.light_root.add_child(rp)

# ------------------------------------------------------------------ shell
static func shell(b):
	var zf = Z_FRONT + WALL_T
	var G = "dl_wall"
	var nn = Vector3(0, 0, 1)
	# mall wall, inside face, the mouth cut out; its reveals and head
	for seg in [[X0, MOUTH[0]], [MOUTH[1], X1]]:
		wall(b, chunk("dl_wall", (seg[0] + seg[1]) * 0.5, zf), "dl_wallpaint", Vector2(seg[0], zf), Vector2(seg[1], zf), 0.0, CEIL, nn)
		block(b, seg[0], Z_FRONT - 0.05, seg[1], zf)
	wall(b, G, "dl_wallpaint", Vector2(MOUTH[0], zf), Vector2(MOUTH[1], zf), MOUTH_H, COFFER, nn)
	for mx in [[MOUTH[0], Vector3(1, 0, 0)], [MOUTH[1], Vector3(-1, 0, 0)]]:
		wall(b, G, "dl_wallpaint", Vector2(mx[0], zf), Vector2(mx[0], Z_FRONT), 0.0, MOUTH_H, mx[1])
	b.quad(G, "dl_wallpaint", [Vector3(MOUTH[0], MOUTH_H, Z_FRONT), Vector3(MOUTH[1], MOUTH_H, Z_FRONT), Vector3(MOUTH[1], MOUTH_H, zf), Vector3(MOUTH[0], MOUTH_H, zf)], Vector3.DOWN)
	# the mall opening's glass sidelights (IMG_4491 f006-008): a pane each side, inside the piers
	for sx in [[MOUTH[0] + 0.6, MOUTH[0] + 2.0], [MOUTH[1] - 2.0, MOUTH[1] - 0.6]]:
		b.quad("glass", "glass", [Vector3(sx[0], 0, zf - 0.1), Vector3(sx[1], 0, zf - 0.1), Vector3(sx[1], MOUTH_H, zf - 0.1), Vector3(sx[0], MOUTH_H, zf - 0.1)], -nn, [], true)
		b.cur_color = Color("#2b2620")
		for xx in sx:
			b.box("dl_trim", "vcolor", Vector3(xx, MOUTH_H * 0.5, zf - 0.1), Vector3(0.06, MOUTH_H, 0.08), Transform3D.IDENTITY, [], true)
		b.cur_color = Color.WHITE
		block(b, sx[0], zf - 0.2, sx[1], zf)
	# west, south, east walls (east and south with the entrances cut out: entrances())
	wall(b, chunk("dl_wall", X0, 99.0), "dl_wallpaint", Vector2(X0, Z_BACK), Vector2(X0, zf), 0.0, CEIL, Vector3(1, 0, 0))
	wall(b, chunk("dl_wall", -27.0, Z_BACK), "dl_wallpaint", Vector2(SOUTH_DOOR[0] - 0.6, Z_BACK), Vector2(X0, Z_BACK), 0.0, CEIL, Vector3(0, 0, -1))
	wall(b, chunk("dl_wall", 10.0, Z_BACK), "dl_wallpaint", Vector2(X1, Z_BACK), Vector2(SOUTH_DOOR[1] + 0.6, Z_BACK), 0.0, CEIL, Vector3(0, 0, -1))
	wall(b, chunk("dl_wall", X1, 88.0), "dl_wallpaint", Vector2(X1, zf), Vector2(X1, EAST_DOOR[0] - 0.6), 0.0, CEIL, Vector3(-1, 0, 0))
	wall(b, chunk("dl_wall", X1, 110.0), "dl_wallpaint", Vector2(X1, EAST_DOOR[1] + 0.6), Vector2(X1, Z_BACK), 0.0, CEIL, Vector3(-1, 0, 0))
	# a dark base band round the perimeter (a 10 cm black base, as the frames show at the walls)
	b.cur_color = Color("#1d1b19")
	for w in [[Vector3(X0 + 0.01, 0.05, 99.0), Vector3(0.02, 0.1, Z_BACK - Z_FRONT)], [Vector3(X1 - 0.01, 0.05, 99.0), Vector3(0.02, 0.1, Z_BACK - Z_FRONT)],
			[Vector3((X0 + X1) * 0.5, 0.05, Z_BACK - 0.01), Vector3(X1 - X0, 0.1, 0.02)]]:
		b.box("dl_trim", "vcolor", w[0], w[1], Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE

# ------------------------------------------------------------------ floor
## Aisles in travertine with a black granite strip and a brown granite band along each edge where
## the aisle meets a pad; pads in cherry (men's; carpet in 1995, a guess) or grey carpet; cosmetics
## stands on travertine like the aisles (IMG_4491).
static func floors(b):
	var zf = Z_FRONT + WALL_T
	# threshold through the wall thickness
	b.quad("dl_floor_front", "dl_trav", [Vector3(MOUTH[0], 0, Z_FRONT), Vector3(MOUTH[1], 0, Z_FRONT), Vector3(MOUTH[1], 0, zf), Vector3(MOUTH[0], 0, zf)], Vector3.UP, [], false, 1.0 / 2.4)
	var men = "dl_cherry" if b.YEAR == 2026 else "dl_carpet95"
	# 1 m cells: each cell takes its pad's material, else travertine
	var x = X0
	while x < X1 - 0.01:
		var z = zf
		while z < Z_BACK - 0.01:
			var x2 = min(x + 1.0, X1)
			var z2 = min(z + 1.0, Z_BACK)
			if z == zf:
				z2 = min(ceil(z) + 1.0, Z_BACK)
			var m = "dl_trav"
			var per = 1.0 / 2.4
			var cx = (x + x2) * 0.5
			var cz = (z + z2) * 0.5
			for p in PADS:
				if in_rect(cx, cz, p):
					m = men if p[4] == "men" else "dl_carpet"
					per = 1.0 / 2.4 if p[4] == "men" else 0.5
			if in_rect(cx, cz, [VEST_X, EAST_DOOR[0], X1, EAST_DOOR[1]]) or in_rect(cx, cz, [SOUTH_DOOR[0], VEST_Z, SOUTH_DOOR[1], Z_BACK]):
				m = "dl_vest"
				per = 1.0 / 1.22
			b.quad(chunk("dl_floor", cx, cz), m, [Vector3(x, 0, z), Vector3(x2, 0, z), Vector3(x2, 0, z2), Vector3(x, 0, z2)], Vector3.UP, [], false, per)
			z = z2
		x += 1.0
	# granite edging: along every aisle side that borders a pad
	for r in AISLES:
		for side in [[r[0], r[1], r[2], r[1], Vector3(0, 0, 1)], [r[0], r[3], r[2], r[3], Vector3(0, 0, -1)],
				[r[0], r[1], r[0], r[3], Vector3(1, 0, 0)], [r[2], r[1], r[2], r[3], Vector3(-1, 0, 0)]]:
			edge_band(b, Vector3(side[0], 0, side[1]), Vector3(side[2], 0, side[3]), side[4])

## The black strip (12 cm) and brown band (30 cm) inside an aisle edge, cut where the far side is
## another aisle (no pad), in 1 m steps.
static func edge_band(b, p, q, inward):
	var L = p.distance_to(q)
	var tt = (q - p).normalized()
	var k = 0.0
	while k < L - 0.01:
		var k2 = min(k + 1.0, L)
		var mid = p + tt * ((k + k2) * 0.5)
		var outside = mid - inward * 0.3
		var pad = false
		for pd in PADS:
			if in_rect(outside.x, outside.z, pd):
				pad = true
		if pad and not in_any(mid.x + inward.x * 0.5, mid.z + inward.z * 0.5, [[VEST_X - 0.1, 0, 99, 999]]):
			for band in [[0.0, 0.12, Color("#1a1a1c")], [0.12, 0.42, Color("#5a3a28")]]:
				b.cur_color = band[2]
				var a0 = p + tt * k + inward * band[0] + Vector3(0, 0.004, 0)
				var a1 = p + tt * k2 + inward * band[0] + Vector3(0, 0.004, 0)
				var a2 = p + tt * k2 + inward * band[1] + Vector3(0, 0.004, 0)
				var a3 = p + tt * k + inward * band[1] + Vector3(0, 0.004, 0)
				b.quad(chunk("dl_floor", mid.x, mid.z), "dl_granite", [a0, a1, a2, a3], Vector3.UP, [], false, 1.0)
			b.cur_color = Color.WHITE
		k = k2

# ------------------------------------------------------------------ ceiling
## 1 m cells: lay-in at CEIL outside the coffers, coffer ceiling at COFFER inside (merged into runs
## along x). The curved bulkheads: along each coffer's long sides a white gypsum lip at CEIL from the
## coffer edge in to a wavy line, and a fascia from the wavy line up to the coffer; the coffer's own
## ceiling carries a faint glow standing in for the cove up-lights (the bake picks it up).
static func ceiling(b):
	var zf = Z_FRONT + WALL_T
	var z = Z_FRONT
	while z < Z_BACK - 0.01:
		var z2 = min(z + 1.0, Z_BACK)
		var x = X0
		while x < X1 - 0.01:
			var cz = (z + z2) * 0.5
			var kind = cell_kind(x + 0.5, cz)
			var x2 = x + 1.0
			while x2 < X1 - 0.01 and cell_kind(x2 + 0.5, cz) == kind and x2 - x < 8.0:
				x2 += 1.0
			x2 = min(x2, X1)
			var zz0 = max(z, zf) if kind != "coffer" else z
			if kind == "low":
				var q = [Vector3(x, CEIL, zz0), Vector3(x2, CEIL, zz0), Vector3(x2, CEIL, z2), Vector3(x, CEIL, z2)]
				var uv = []
				for p in q:
					uv.append(Vector2(p.x / 0.61, p.z / 1.22))
				b.quad(chunk("dl_ceil", (x + x2) * 0.5, cz), "dl_laytile", q, Vector3.DOWN, uv)
			elif kind == "coffer":
				b.quad(chunk("dl_ceil", (x + x2) * 0.5, cz), "dl_coffer", [Vector3(x, COFFER, zz0), Vector3(x2, COFFER, zz0), Vector3(x2, COFFER, z2), Vector3(x, COFFER, z2)], Vector3.DOWN)
			x = x2
		z = z2
	for r in COFFERS:
		bulkheads(b, r)
		end_fascias(b, r)
	# coffer ends against the walls (the main aisle's coffer meets the mall wall over the mouth)
	troffers(b)

static func cell_kind(x, z):
	if in_rect(x, z, WELL):
		return "well"
	if in_any(x, z, COFFERS):
		return "coffer"
	return "low"

## A coffer's curved bulkheads on its two long sides, and straight fascias on short ends that do
## not open into another coffer.
static func bulkheads(b, r):
	var along_x = (r[2] - r[0]) > (r[3] - r[1])
	var sides = []
	if along_x:
		sides = [[Vector3(r[0], 0, r[1]), Vector3(r[2], 0, r[1]), Vector3(0, 0, 1)], [Vector3(r[0], 0, r[3]), Vector3(r[2], 0, r[3]), Vector3(0, 0, -1)]]
	else:
		sides = [[Vector3(r[0], 0, r[1]), Vector3(r[0], 0, r[3]), Vector3(1, 0, 0)], [Vector3(r[2], 0, r[1]), Vector3(r[2], 0, r[3]), Vector3(-1, 0, 0)]]
	for sd in sides:
		var p = sd[0]
		var q = sd[1]
		var inw = sd[2]
		var L = p.distance_to(q)
		var tt = (q - p).normalized()
		var steps = int(ceil(L / 0.5))
		for i in steps:
			var k0 = L * i / steps
			var k1 = L * (i + 1) / steps
			var e0 = p + tt * k0
			var e1 = p + tt * k1
			var mid = (e0 + e1) * 0.5
			var probe = mid - inw * 0.2
			if in_any(probe.x, probe.z, COFFERS) or in_rect(probe.x, probe.z, WELL) or probe.z < Z_FRONT + WALL_T or probe.x < X0 or probe.x > X1 or probe.z > Z_BACK:
				continue
			var w0 = e0 + inw * wave(e0.x + e0.z)
			var w1 = e1 + inw * wave(e1.x + e1.z)
			var G = chunk("dl_ceil", mid.x, mid.z)
			b.quad(G, "dl_gyp", [e0 + Vector3(0, CEIL, 0), e1 + Vector3(0, CEIL, 0), w1 + Vector3(0, CEIL, 0), w0 + Vector3(0, CEIL, 0)], Vector3.DOWN)
			var dv = (w1 - w0)
			var nrm = Vector3(dv.z, 0, -dv.x).normalized()
			if nrm.dot(inw) < 0:
				nrm = -nrm
			b.quad(G, "dl_gyp", [w0 + Vector3(0, CEIL, 0), w1 + Vector3(0, CEIL, 0), w1 + Vector3(0, COFFER, 0), w0 + Vector3(0, COFFER, 0)], nrm)
			# the cove: a warm strip on the fascia's back top edge, seen as the glow line
			b.quad(G, "dl_cove", [w0 + Vector3(0, COFFER - 0.06, 0) + nrm * 0.004, w1 + Vector3(0, COFFER - 0.06, 0) + nrm * 0.004, w1 + Vector3(0, COFFER - 0.01, 0) + nrm * 0.004, w0 + Vector3(0, COFFER - 0.01, 0) + nrm * 0.004], nrm)

## Straight fascias on a coffer's short ends where the cell beyond is the low ceiling.
static func end_fascias(b, r):
	var along_x = (r[2] - r[0]) > (r[3] - r[1])
	var ends = []
	if along_x:
		ends = [[Vector3(r[0], 0, r[1]), Vector3(r[0], 0, r[3]), Vector3(1, 0, 0)], [Vector3(r[2], 0, r[1]), Vector3(r[2], 0, r[3]), Vector3(-1, 0, 0)]]
	else:
		ends = [[Vector3(r[0], 0, r[1]), Vector3(r[2], 0, r[1]), Vector3(0, 0, 1)], [Vector3(r[0], 0, r[3]), Vector3(r[2], 0, r[3]), Vector3(0, 0, -1)]]
	for en in ends:
		var p = en[0]
		var q = en[1]
		var inw = en[2]
		var L = p.distance_to(q)
		var tt = (q - p).normalized()
		var steps = int(ceil(L / 0.5))
		for i in steps:
			var e0 = p + tt * (L * i / steps)
			var e1 = p + tt * (L * (i + 1) / steps)
			var probe = (e0 + e1) * 0.5 - inw * 0.2
			if in_any(probe.x, probe.z, COFFERS) or in_rect(probe.x, probe.z, WELL) or probe.z < Z_FRONT + WALL_T or probe.x < X0 or probe.x > X1 or probe.z > Z_BACK:
				continue
			b.quad(chunk("dl_ceil", probe.x, probe.z), "dl_gyp", [e0 + Vector3(0, CEIL, 0), e1 + Vector3(0, CEIL, 0), e1 + Vector3(0, COFFER, 0), e0 + Vector3(0, COFFER, 0)], inw)

## How far the bulkhead's curved edge stands in from the coffer's straight edge (metres).
static func wave(s):
	return 0.35 + 0.3 * sin(s * TAU / 7.0) + 0.12 * sin(s * TAU / 2.9 + 1.0)

## 2x4 troffers on the lay-in, kept off the coffers; recessed cans down the coffers.
static func troffers(b):
	var x = X0 + 1.5
	while x < X1 - 1.0:
		var z = Z_FRONT + 2.0
		while z < Z_BACK - 1.0:
			if cell_kind(x, z) == "low" and not in_any(x, z, COFFERS, 0.9):
				var y = CEIL - 0.004
				b.quad(chunk("dl_ceil", x, z), "cd7_troffer", [Vector3(x - 0.3, y, z - 0.6), Vector3(x + 0.3, y, z - 0.6), Vector3(x + 0.3, y, z + 0.6), Vector3(x - 0.3, y, z + 0.6)], Vector3.DOWN,
					[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
			z += 3.6
		x += 3.0
	for r in COFFERS:
		var along_x = (r[2] - r[0]) > (r[3] - r[1])
		var c = Vector3((r[0] + r[2]) * 0.5, COFFER - 0.005, (r[1] + r[3]) * 0.5)
		var L = (r[2] - r[0]) if along_x else (r[3] - r[1])
		var k = 1.5
		while k < L - 1.0:
			var p = Vector3(r[0] + k, COFFER - 0.005, c.z) if along_x else Vector3(c.x, COFFER - 0.005, r[1] + k)
			if not in_rect(p.x, p.z, WELL, 0.3):
				b.disc_down(chunk("dl_ceil", p.x, p.z), p, 0.09)
			k += 2.4

# ------------------------------------------------------------------ columns
static func columns(b):
	for cx in COLS_X:
		for cz in COLS_Z:
			if in_any(cx, cz, AISLES, 0.5) or in_rect(cx, cz, WELL, 0.6):   # (SMALLFIX: not in the escalators)
				continue
			var top = COFFER if in_any(cx, cz, COFFERS) else CEIL
			b.box(chunk("dl_cols", cx, cz), "dl_mirror", Vector3(cx, top * 0.5, cz), Vector3(COL, top, COL), Transform3D.IDENTITY, ["+y", "-y"])
			b.cur_color = Color("#1a1a1c")
			b.box("dl_trim", "vcolor", Vector3(cx, 0.06, cz), Vector3(COL + 0.03, 0.12, COL + 0.03), Transform3D.IDENTITY, [], true)
			b.cur_color = Color.WHITE
			block(b, cx - COL * 0.5, cz - COL * 0.5, cx + COL * 0.5, cz + COL * 0.5, 0.15)
	# the drum column by the escalators (notes_E), on their west side (SMALLFIX)
	b.cyl("dl_cols", "dl_gyp", Vector3(-19.8, 0, 104.0), 0.6, 0.6, CEIL, 20, false, false)
	block(b, -20.4, 103.4, -19.2, 104.6, 0.1)

# ------------------------------------------------------------------ escalators
## Two units side by side in a well, a crisscross pair (SMALLFIX, Nov 8 2026: until then both rose
## south from the end of the main aisle); black steps, stainless decking, white glass balustrades
## with black handrails, a white panel closing each truss's top end. Closed: a chrome stanchion line
## with a black belt and a small sign at each foot (Steven: visible, not usable).
static func escalators(b):
	for u in ESC_UNITS:
		esc_unit(b, u[0], u[1], u[2], u[3])
	# the well: white shaft walls from the ceiling up, a lit lid, a downstand over each foot
	var w = WELL
	var top = ESC_RISE + 2.8
	for sd in [[Vector2(w[0], w[1]), Vector2(w[2], w[1]), Vector3(0, 0, 1)], [Vector2(w[2], w[3]), Vector2(w[0], w[3]), Vector3(0, 0, -1)],
			[Vector2(w[0], w[3]), Vector2(w[0], w[1]), Vector3(1, 0, 0)], [Vector2(w[2], w[1]), Vector2(w[2], w[3]), Vector3(-1, 0, 0)]]:
		wall(b, "dl_well", "dl_gyp", sd[0], sd[1], CEIL, top, sd[2])
	b.quad("dl_well", "dl_laytile", [Vector3(w[0], top, w[1]), Vector3(w[2], top, w[1]), Vector3(w[2], top, w[3]), Vector3(w[0], top, w[3])], Vector3.DOWN)
	wall(b, "dl_well", "dl_gyp", Vector2(w[2], w[3] - 0.3), Vector2(w[0], w[3] - 0.3), CEIL - 0.3, CEIL, Vector3(0, 0, 1))
	wall(b, "dl_well", "dl_gyp", Vector2(w[0], w[1] + 0.3), Vector2(w[2], w[1] + 0.3), CEIL - 0.3, CEIL, Vector3(0, 0, -1))
	b.tag(b.add_omni(Vector3((w[0] + w[2]) * 0.5, ESC_RISE + 2.2, (w[1] + w[3]) * 0.5), 1.4, 7.0, Color(1.0, 0.95, 0.88)), "", 1.4, 1.4)

## One escalator: lane x0..x1, its floor landing's front edge at zf, rising toward +z (dz = 1) or -z
## (dz = -1) over ESC_RUN to ESC_RISE.
static func esc_unit(b, x0, x1, zf, dz):
	var G = "dl_esc"
	var slope = ESC_RISE / ESC_RUN
	var F = Vector3(0, 0, -dz)            # the foot's front, away from the incline
	var zl = zf + dz * 1.2                # the landing plate ends
	var zt = zl + dz * ESC_RUN            # the top of the incline
	var xm = (x0 + x1) * 0.5
	var ua = x0 + 0.25
	var ub = x1 - 0.25
	# landing plate (stainless comb plate)
	b.quad(G, "dl_steel", [Vector3(ua, 0.01, zf), Vector3(ub, 0.01, zf), Vector3(ub, 0.01, zl), Vector3(ua, 0.01, zl)], Vector3.UP)
	# steps: a stair-stepped run in black
	var steps = int(ESC_RUN / 0.4)
	for i in steps:
		var za = zl + dz * ESC_RUN * i / steps
		var zb = zl + dz * ESC_RUN * (i + 1) / steps
		var ya = ESC_RISE * i / steps
		var yb = ESC_RISE * (i + 1) / steps
		b.quad(G, "dl_step", [Vector3(ua, ya, za), Vector3(ub, ya, za), Vector3(ub, yb, za), Vector3(ua, yb, za)], F)
		b.quad(G, "dl_step", [Vector3(ua, yb, za), Vector3(ub, yb, za), Vector3(ub, yb, zb), Vector3(ua, yb, zb)], Vector3.UP)
	# skirts, decks and the white glass balustrades on both sides of the lane
	for side in [[x0, ua, Vector3(1, 0, 0)], [x1, ub, Vector3(-1, 0, 0)]]:
		var xs = side[0]
		var xi = side[1]
		b.quad(G, "dl_steel", [Vector3(xi, 0.0, zl), Vector3(xi, ESC_RISE, zt), Vector3(xi, ESC_RISE + 0.12, zt), Vector3(xi, 0.12, zl)], side[2])
		b.quad(G, "dl_steel", [Vector3(xs, 0.12, zf), Vector3(xi, 0.12, zf), Vector3(xi, ESC_RISE + 0.12, zt), Vector3(xs, ESC_RISE + 0.12, zt)], Vector3(0, 1, -dz * slope).normalized())
		var gx = xs + (xi - xs) * 0.5
		b.quad("glass_esc", "dl_balus", [Vector3(gx, 0.12, zf + dz * 0.3), Vector3(gx, ESC_RISE + 0.12, zt), Vector3(gx, ESC_RISE + 1.0, zt), Vector3(gx, 1.0, zf + dz * 0.3)], side[2], [], true)
	# the truss in white cladding, 1 m deep under the incline: its two sides, the sloped soffit under it
	# (open floor below, as under a real crisscross pair) and its top end
	var TD = 1.0
	var zu = zl + dz * TD / slope         # where the soffit meets the floor
	for side in [[x0, Vector3(-1, 0, 0)], [x1, Vector3(1, 0, 0)]]:
		b.quad(G, "dl_gyp", [Vector3(side[0], 0, zl), Vector3(side[0], 0, zu), Vector3(side[0], ESC_RISE - TD, zt), Vector3(side[0], ESC_RISE + 0.12, zt)], side[1])
	b.quad(G, "dl_gyp", [Vector3(x0, 0, zu), Vector3(x1, 0, zu), Vector3(x1, ESC_RISE - TD, zt), Vector3(x0, ESC_RISE - TD, zt)], Vector3(0, -1, dz * slope).normalized())
	b.quad(G, "dl_gyp", [Vector3(x0, ESC_RISE - TD, zt), Vector3(x1, ESC_RISE - TD, zt), Vector3(x1, ESC_RISE + 0.12, zt), Vector3(x0, ESC_RISE + 0.12, zt)], -F)
	# black handrails along each balustrade's top, rotated to the incline, a flat run at the foot
	b.cur_color = Color("#141414")
	var basis = Basis(Vector3.RIGHT, -dz * atan2(ESC_RISE, ESC_RUN))
	for xs in [x0 + 0.125, x1 - 0.125]:
		var p0 = Vector3(xs, 1.0, zl)
		var p1 = Vector3(xs, ESC_RISE + 1.0, zt)
		b.box("dl_trim", "vcolor", Vector3.ZERO, Vector3(0.08, 0.07, p0.distance_to(p1)), Transform3D(basis, (p0 + p1) * 0.5), [], true)
		b.box("dl_trim", "vcolor", Vector3(xs, 1.0, zf + dz * 0.75), Vector3(0.08, 0.07, 0.9), Transform3D.IDENTITY, [], true)
	# closed: stanchions and a belt across the foot, a small sign facing out
	b.cur_color = Color("#c9c9c9")
	var zs = zf - dz * 0.5
	for xx in [x0 - 0.1, xm, x1 + 0.1]:
		b.cyl("dl_trim", "dl_steel", Vector3(xx, 0, zs), 0.17, 0.17, 0.03, 12, true, false, true)
		b.cyl("dl_trim", "dl_steel", Vector3(xx, 0, zs), 0.03, 0.03, 0.95, 8, true, false, true)
	b.cur_color = Color("#151515")
	b.box("dl_trim", "vcolor", Vector3(xm, 0.88, zs), Vector3(x1 - x0 + 0.2, 0.05, 0.01), Transform3D.IDENTITY, [], true)
	b.box("dl_trim", "vcolor", Vector3(xm, 1.15, zs) + F * 0.03, Vector3(0.62, 0.38, 0.02), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	b.label("Escalator closed", "serif", "#f2efe6", Vector3(xm, 1.15, zs) + F * 0.05, F, 0.55, 0.07)
	# the walk grid: the whole unit, from its top end to the stanchion line
	block(b, x0 - 0.3, min(zs, zt) - 0.15, x1 + 0.3, max(zs, zt) + 0.15)

# ------------------------------------------------------------------ entrances
## The exterior entrance on the east face (the gallery side; the one Steven walked in through):
## a vestibule with glass inner doors and dark-bronze outer doors (IMG_4490 t136_007-011,
## t110_058-064), pale grey tile with dark accents, the black-lacquer store directory on its wall.
## The south entrance (Bayou Gardens) gets the same outer doors on a shallower vestibule.
static func entrances(b):
	var z0 = EAST_DOOR[0]
	var z1 = EAST_DOOR[1]
	var G = "dl_vest"
	# vestibule side walls, ceiling, inner glass doors
	for zz in [[z0, Vector3(0, 0, 1)], [z1, Vector3(0, 0, -1)]]:
		wall(b, G, "dl_wallpaint", Vector2(VEST_X, zz[0]), Vector2(X1, zz[0]), 0.0, 3.0, zz[1])
		wall(b, G, "dl_wallpaint", Vector2(X1, zz[0] - zz[1].z * 0.3), Vector2(VEST_X, zz[0] - zz[1].z * 0.3), 0.0, CEIL, -zz[1])
		if zz[1].z < 0:
			block(b, VEST_X, zz[0] - 0.05, X1, zz[0] + 0.3)
		else:
			block(b, VEST_X, zz[0] - 0.3, X1, zz[0] + 0.05)
	b.quad(G, "dl_gyp", [Vector3(VEST_X, 3.0, z0), Vector3(X1, 3.0, z0), Vector3(X1, 3.0, z1), Vector3(VEST_X, 3.0, z1)], Vector3.DOWN)
	wall(b, G, "dl_wallpaint", Vector2(VEST_X, z1), Vector2(VEST_X, z0), 3.0, CEIL, Vector3(-1, 0, 0))
	doors(b, Vector3(VEST_X, 0, (z0 + z1) * 0.5), Vector3(1, 0, 0), z1 - z0 - 0.2, false)
	doors(b, Vector3(X1, 0, (z0 + z1) * 0.5), Vector3(1, 0, 0), z1 - z0 - 0.2, true)
	outside(b, Vector3(X1, 0, (z0 + z1) * 0.5), Vector3(1, 0, 0), z1 - z0 + 4.0)
	directory(b, Vector3(X1 - 1.4, 1.55, z1 - 0.32), Vector3(0, 0, -1))
	block(b, X1 - 0.1, z0, X1 + 0.5, z1)
	# the south entrance: outer bronze doors in the wall, a glass inner screen at VEST_Z
	var x0 = SOUTH_DOOR[0]
	var x1 = SOUTH_DOOR[1]
	for xx in [[x0, Vector3(1, 0, 0)], [x1, Vector3(-1, 0, 0)]]:
		wall(b, G, "dl_wallpaint", Vector2(xx[0], VEST_Z), Vector2(xx[0], Z_BACK), 0.0, 3.0, xx[1])
		wall(b, G, "dl_wallpaint", Vector2(xx[0] - xx[1].x * 0.6, Z_BACK), Vector2(xx[0] - xx[1].x * 0.6, VEST_Z), 0.0, CEIL, -xx[1])
		block(b, min(xx[0], xx[0] - xx[1].x * 0.6), VEST_Z, max(xx[0], xx[0] - xx[1].x * 0.6), Z_BACK)
	b.quad(G, "dl_gyp", [Vector3(x0, 3.0, VEST_Z), Vector3(x1, 3.0, VEST_Z), Vector3(x1, 3.0, Z_BACK), Vector3(x0, 3.0, Z_BACK)], Vector3.DOWN)
	wall(b, G, "dl_wallpaint", Vector2(x0, VEST_Z), Vector2(x1, VEST_Z), 3.0, CEIL, Vector3(0, 0, -1))
	doors(b, Vector3((x0 + x1) * 0.5, 0, VEST_Z), Vector3(0, 0, 1), x1 - x0 - 0.2, false)
	doors(b, Vector3((x0 + x1) * 0.5, 0, Z_BACK), Vector3(0, 0, 1), x1 - x0 - 0.2, true)
	outside(b, Vector3((x0 + x1) * 0.5, 0, Z_BACK), Vector3(0, 0, 1), x1 - x0 + 4.0)
	block(b, x0, Z_BACK - 0.1, x1, Z_BACK + 0.5)

## A run of door pairs across `w` at `c`, facing `out`; bronze frames when `bronze`, else clear
## glass in thin dark frames. Brass pull bars.
static func doors(b, c, out, w, bronze):
	var tt = Vector3(out.z, 0, -out.x)
	var h = 2.75
	var pairs = max(1, int(round(w / 2.6)))
	b.cur_color = Color("#3a2a1c") if bronze else Color("#2c2a28")
	var fw = 0.1 if bronze else 0.05
	var leaves = pairs * 2
	for i in leaves + 1:
		var p = c - tt * w * 0.5 + tt * w * i / leaves
		b.box("dl_trim", "vcolor", p + Vector3(0, h * 0.5, 0), b.abs_size(tt, fw, h, 0.12, out), Transform3D.IDENTITY, [], true)
	for yy in [0.05, h]:
		b.box("dl_trim", "vcolor", c + Vector3(0, yy, 0), b.abs_size(tt, w, fw * 1.2, 0.12, out), Transform3D.IDENTITY, [], true)
	b.cur_color = Color("#a8883e")
	for i in leaves:
		var p = c - tt * w * 0.5 + tt * w * (i + (0.85 if i % 2 == 0 else 0.15)) / leaves
		for s in [-1.0, 1.0]:
			b.box("dl_trim", "vcolor", p + Vector3(0, 1.05, 0) + out * 0.07 * s, Vector3(0.025, 0.32, 0.025), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	var p0 = c - tt * w * 0.5
	var p1 = c + tt * w * 0.5
	b.quad("glass", "glass", [p0, p1, p1 + Vector3(0, h, 0), p0 + Vector3(0, h, 0)], out, [], true)

static func outside(b, at, out, w):
	var tt = Vector3(out.z, 0, -out.x)
	b.quad("dl_out", "outside_ground", [at - tt * w * 0.5, at + tt * w * 0.5, at + tt * w * 0.5 + out * 16.0, at - tt * w * 0.5 + out * 16.0], Vector3.UP, [], true, 0.25)
	var far = at + out * 16.0
	b.quad("dl_out", "sr_sky", [far - tt * w * 2.0, far + tt * w * 2.0, far + tt * w * 2.0 + Vector3(0, 10, 0), far - tt * w * 2.0 + Vector3(0, 10, 0)], -out, [], true)

## The store's own 3-level directory (IMG_4490 t136_015-027): a black lacquer frame with a gold
## header strip, three pastel floor plans on black (blocks only, no text), hand-sanitizer beside it.
static func directory(b, c, face):
	var tt = Vector3(face.z, 0, -face.x)
	b.cur_color = Color("#0d0d0f")
	b.box("dl_trim", "vcolor", c, b.abs_size(tt, 0.95, 1.75, 0.06, face), Transform3D.IDENTITY, [], true)
	b.cur_color = Color("#b8963e")
	b.box("dl_trim", "vcolor", c + Vector3(0, 0.78, 0) + face * 0.035, b.abs_size(tt, 0.7, 0.1, 0.01, face), Transform3D.IDENTITY, [], true)
	var levels = [[0.42, ["#f2c72e", "#e8d8d0"]], [-0.05, ["#e98aa8", "#f0a070"]], [-0.52, ["#a8dbd9", "#c4a6e0", "#9fd46a"]]]
	for lv in levels:
		var k = 0
		for col in lv[1]:
			b.cur_color = Color(col)
			b.box("dl_trim", "vcolor", c + Vector3(0, lv[0], 0) + tt * (-0.22 + k * 0.22) + face * 0.035, b.abs_size(tt, 0.2, 0.3, 0.01, face), Transform3D.IDENTITY, [], true)
			k += 1
	b.cur_color = Color.WHITE

# ------------------------------------------------------------------ fixtures
## Generic department-store fixtures, invented brands only: round racks and four-ways in men's,
## maple nesting tables with folded stacks, cosmetics counters (black bases, lit glass cases, back
## towers), jewelry cases, handbag cubes, shoe walls on the west wall. All dynamic (no lightmap).
static func fixtures(b):
	var rng = RandomNumberGenerator.new()
	rng.seed = 4490
	var cloth = ["#2d3a55", "#8a1e24", "#d8d4cc", "#4b5a3a", "#1f1f22", "#6b7d92", "#b9a07a", "#7a2f3a", "#e6e2da", "#3d4b63"]
	for d in DEPTS:
		var nm = d[0]
		var r = [d[1] + 1.0, d[2] + 1.0, d[3] - 1.0, d[4] - 1.0]
		if r[2] - r[0] < 1.5 or r[3] - r[1] < 1.5:
			continue
		if nm.begins_with("Mens"):
			men_fixtures(b, r, rng, cloth)
		elif nm.begins_with("Cosmetics"):
			cosmetics(b, r, rng)
		elif nm.begins_with("Womens Shoes"):
			shoes(b, r, rng, d)
		elif nm.begins_with("Handbags") or nm.begins_with("Fashion Jewelry"):
			accessories(b, r, rng)

static func men_fixtures(b, r, rng, cloth):
	var x = r[0] + 0.9
	var row = 0
	while x < r[2] - 0.6:
		var z = r[1] + 0.9
		while z < r[3] - 0.6:
			if in_any(x, z, AISLES, 0.9) or near_col(x, z, 1.1) or in_rect(x, z, [VEST_X - 1.5, EAST_DOOR[0] - 1.0, X1, EAST_DOOR[1] + 1.0]) or in_rect(x, z, [SOUTH_DOOR[0] - 1.0, VEST_Z - 1.5, SOUTH_DOOR[1] + 1.0, Z_BACK]):
				z += 2.6
				continue
			var kind = (row + int(z)) % 3
			if kind == 0:
				round_rack(b, Vector3(x, 0, z), Color(cloth[rng.randi() % cloth.size()]))
			elif kind == 1:
				table(b, Vector3(x, 0, z), rng, cloth)
			else:
				four_way(b, Vector3(x, 0, z), rng, cloth)
			z += 2.6
		x += 2.8
		row += 1

static func near_col(x, z, d):
	for cx in COLS_X:
		for cz in COLS_Z:
			if abs(x - cx) < d and abs(z - cz) < d:
				return true
	return false

static func round_rack(b, at, col):
	b.cur_color = Color("#bfc2c5")
	b.cyl("dl_fix", "dl_steel", at, 0.3, 0.3, 0.03, 12, true, false, true)
	b.cyl("dl_fix", "dl_steel", at, 0.025, 0.025, 1.35, 6, false, false, true)
	b.cur_color = col
	b.cyl("dl_fix", "vcolor_matte", at + Vector3(0, 0.45, 0), 0.62, 0.55, 0.9, 14, true, false, true)
	b.cur_color = Color.WHITE
	block(b, at.x - 0.65, at.z - 0.65, at.x + 0.65, at.z + 0.65)

static func four_way(b, at, rng, cloth):
	b.cur_color = Color("#bfc2c5")
	b.cyl("dl_fix", "dl_steel", at, 0.025, 0.025, 1.5, 6, false, false, true)
	for k in 4:
		var d = Vector3(cos(k * PI * 0.5), 0, sin(k * PI * 0.5))
		b.cur_color = Color(cloth[rng.randi() % cloth.size()])
		b.box("dl_fix", "vcolor_matte", at + d * 0.45 + Vector3(0, 0.95, 0), Vector3(0.45 if abs(d.x) > 0.5 else 0.12, 0.75, 0.12 if abs(d.x) > 0.5 else 0.45), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	block(b, at.x - 0.7, at.z - 0.7, at.x + 0.7, at.z + 0.7)

## Maple nesting tables with folded stacks (IMG_4490 t110_037-055).
static func table(b, at, rng, cloth):
	b.cur_color = Color("#d9a35a")
	b.box("dl_fix", "vcolor", at + Vector3(0, 0.72, 0), Vector3(1.4, 0.05, 0.8), Transform3D.IDENTITY, [], true)
	b.box("dl_fix", "vcolor", at + Vector3(0, 0.36, 0), Vector3(1.3, 0.72, 0.04), Transform3D.IDENTITY, [], true)
	b.box("dl_fix", "vcolor", at + Vector3(0.45, 0.95, 0), Vector3(0.6, 0.04, 0.5), Transform3D.IDENTITY, [], true)
	b.box("dl_fix", "vcolor", at + Vector3(0.45, 0.84, 0), Vector3(0.04, 0.2, 0.4), Transform3D.IDENTITY, [], true)
	for k in 3:
		b.cur_color = Color(cloth[rng.randi() % cloth.size()])
		b.box("dl_fix", "vcolor_matte", at + Vector3(-0.45 + k * 0.32, 0.8, 0.1 * (k % 2)), Vector3(0.28, 0.12, 0.32), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	block(b, at.x - 0.8, at.z - 0.5, at.x + 0.8, at.z + 0.5)

## Cosmetics: counters of black bases with lit glass cases in an island ring, a back tower in the
## middle with an abstract colour panel (no brands, no faces).
static func cosmetics(b, r, rng):
	var c = Vector3((r[0] + r[2]) * 0.5, 0, (r[1] + r[3]) * 0.5)
	var w = min(r[2] - r[0], 7.0)
	var d = min(r[3] - r[1], 5.0)
	for s in [[Vector3(0, 0, -d * 0.5), Vector3(w, 0, 0.6)], [Vector3(0, 0, d * 0.5), Vector3(w, 0, 0.6)], [Vector3(-w * 0.5, 0, 0), Vector3(0.6, 0, d - 0.6)], [Vector3(w * 0.5, 0, 0), Vector3(0.6, 0, d - 0.6)]]:
		var p = c + s[0]
		var sz = s[1]
		# leave a gap in the ring for the staff
		if sz.x > 1.0:
			case_run(b, p - Vector3(sz.x * 0.25 + 0.4, 0, 0), Vector3(sz.x * 0.5 - 0.8, 0, sz.z))
			case_run(b, p + Vector3(sz.x * 0.25 + 0.4, 0, 0), Vector3(sz.x * 0.5 - 0.8, 0, sz.z))
		else:
			case_run(b, p, Vector3(sz.x, 0, sz.z))
	# the back tower
	b.cur_color = Color("#141414")
	b.box("dl_fix", "vcolor", c + Vector3(0, 1.1, 0), Vector3(1.6, 2.2, 0.5), Transform3D.IDENTITY, [], true)
	var pals = [["#e9c6c0", "#c98b8b"], ["#d7c4e6", "#8e6bb0"], ["#f0d9b5", "#c99a5a"], ["#c9e0e6", "#5e8ea0"]]
	var pal = pals[rng.randi() % pals.size()]
	for f in [-1.0, 1.0]:
		b.cur_color = Color(pal[0])
		b.box("dl_fix", "dl_lightbox", c + Vector3(0, 1.45, 0.26 * f), Vector3(1.3, 1.2, 0.02), Transform3D.IDENTITY, [], true)
		b.cur_color = Color(pal[1])
		b.box("dl_fix", "vcolor", c + Vector3(-0.2, 1.4, 0.275 * f), Vector3(0.5, 0.8, 0.01), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	block(b, c.x - 0.85, c.z - 0.3, c.x + 0.85, c.z + 0.3)

## A run of counter cases: black base, lit glass case on top (the glass case is a light box).
static func case_run(b, c, sz):
	if sz.x < 0.4 and sz.z < 0.4:
		return
	b.cur_color = Color("#151515")
	b.box("dl_fix", "vcolor", c + Vector3(0, 0.45, 0), Vector3(max(sz.x, 0.6), 0.9, max(sz.z, 0.6)), Transform3D.IDENTITY, [], true)
	b.cur_color = Color("#f4efe6")
	b.box("dl_fix", "dl_lightbox", c + Vector3(0, 0.92, 0), Vector3(max(sz.x, 0.6) - 0.06, 0.04, max(sz.z, 0.6) - 0.06), Transform3D.IDENTITY, [], true)
	b.quad("glass", "glass", [c + Vector3(-sz.x * 0.5, 0.94, -sz.z * 0.5), c + Vector3(sz.x * 0.5, 0.94, -sz.z * 0.5), c + Vector3(sz.x * 0.5, 1.22, -sz.z * 0.5), c + Vector3(-sz.x * 0.5, 1.22, -sz.z * 0.5)], Vector3(0, 0, -1), [], true)
	b.cur_color = Color.WHITE
	block(b, c.x - max(sz.x, 0.6) * 0.5, c.z - max(sz.z, 0.6) * 0.5, c.x + max(sz.x, 0.6) * 0.5, c.z + max(sz.z, 0.6) * 0.5)

## Women's shoes: a shoe wall (shelves with small boxes) on the department's wall side, display
## risers and chairs on the floor.
static func shoes(b, r, rng, d):
	var cols = ["#1b1b1b", "#7a4a2a", "#c8b49a", "#8a1e24", "#d9d4cc", "#2d3a55"]
	if d[1] <= X0 + 0.1:
		var x = X0 + 0.25
		var z = r[1]
		while z < r[3]:
			b.cur_color = Color("#efe9df")
			b.box("dl_fix", "vcolor_matte", Vector3(x, 1.2, z + 1.0), Vector3(0.4, 2.4, 2.0), Transform3D.IDENTITY, [], true)
			for yy in [0.5, 0.9, 1.3, 1.7, 2.1]:
				for k in 5:
					b.cur_color = Color(cols[rng.randi() % cols.size()])
					b.box("dl_fix", "vcolor", Vector3(x + 0.24, yy + 0.06, z + 0.25 + k * 0.38), Vector3(0.12, 0.1, 0.24), Transform3D.IDENTITY, [], true)
			z += 2.2
		block(b, X0, r[1], X0 + 0.5, r[3])
	var zz = r[1] + 1.5
	while zz < r[3] - 1.0:
		var xx = (r[0] + r[2]) * 0.5 + (1.0 if d[1] <= X0 + 0.1 else 0.0)
		if not in_any(xx, zz, AISLES, 1.0) and not in_rect(xx, zz, [SOUTH_DOOR[0] - 1.2, VEST_Z - 1.5, SOUTH_DOOR[1] + 1.2, Z_BACK]) and not near_col(xx, zz, 1.2):
			b.cur_color = Color("#e7e1d6")
			b.box("dl_fix", "vcolor_matte", Vector3(xx, 0.35, zz), Vector3(1.2, 0.7, 0.6), Transform3D.IDENTITY, [], true)
			for k in 3:
				b.cur_color = Color(cols[rng.randi() % cols.size()])
				b.box("dl_fix", "vcolor", Vector3(xx - 0.4 + k * 0.4, 0.76, zz), Vector3(0.12, 0.1, 0.26), Transform3D.IDENTITY, [], true)
			block(b, xx - 0.7, zz - 0.4, xx + 0.7, zz + 0.4)
		zz += 3.0
	b.cur_color = Color.WHITE

## Handbags and jewelry: white cube islands with bags (rounded blocks) and low lit cases.
static func accessories(b, r, rng):
	var cols = ["#1b1b1b", "#7a4a2a", "#c8b49a", "#8a1e24", "#b07a4a", "#2d3a55", "#e3d7c4"]
	var x = r[0] + 1.2
	while x < r[2] - 0.8:
		var z = r[1] + 1.2
		while z < r[3] - 0.8:
			if in_any(x, z, AISLES, 0.9) or near_col(x, z, 1.1):
				z += 2.8
				continue
			b.cur_color = Color("#f2efe9")
			b.box("dl_fix", "vcolor_matte", Vector3(x, 0.55, z), Vector3(1.2, 1.1, 1.2), Transform3D.IDENTITY, [], true)
			for k in 4:
				b.cur_color = Color(cols[rng.randi() % cols.size()])
				var ang = k * PI * 0.5
				b.box("dl_fix", "vcolor", Vector3(x + cos(ang) * 0.35, 1.25, z + sin(ang) * 0.35), Vector3(0.32, 0.26, 0.14) if k % 2 == 0 else Vector3(0.14, 0.26, 0.32), Transform3D.IDENTITY, [], true)
			b.cur_color = Color.WHITE
			block(b, x - 0.65, z - 0.65, x + 0.65, z + 0.65)
			z += 2.8
		x += 2.8

# ------------------------------------------------------------------ lights
## Warm spots down the coffers (the cans), one cooler fill per lay-in bay, cove glow from the
## coffers' emissive ceiling and strip.
static func lights(b):
	for r in COFFERS:
		var along_x = (r[2] - r[0]) > (r[3] - r[1])
		var L = (r[2] - r[0]) if along_x else (r[3] - r[1])
		var k = 3.0
		while k < L - 1.0:
			var p = Vector3(r[0] + k, COFFER - 0.1, (r[1] + r[3]) * 0.5) if along_x else Vector3((r[0] + r[2]) * 0.5, COFFER - 0.1, r[1] + k)
			if not in_rect(p.x, p.z, WELL):
				b.tag(b.add_spot(p, Vector3.DOWN, 2.2, 6.5, 60.0, Color(1.0, 0.92, 0.80)), "", 2.2, 2.2)
			k += 7.2
	var x = X0 + 5.0
	while x < X1:
		var z = Z_FRONT + 5.0
		while z < Z_BACK:
			if not in_any(x, z, COFFERS):
				b.tag(b.add_spot(Vector3(x, CEIL - 0.1, z), Vector3.DOWN, 1.8, 6.0, 75.0, Color(1.0, 0.97, 0.92)), "", 1.8, 1.8)
			z += 9.0
		x += 9.0
	b.tag(b.add_omni(Vector3(X1 - 1.5, 2.2, (EAST_DOOR[0] + EAST_DOOR[1]) * 0.5), 1.2, 7.0, Color("#dfe9ff")), "day")

# ------------------------------------------------------------------ materials
static func fill_mat(m, key, b):
	match key:
		"trav":
			m.albedo_texture = b.tex("dl/trav.png"); m.roughness = 0.12; m.metallic_specular = 0.7
		"granite":
			m.albedo_texture = b.tex("dl/granite.png"); m.vertex_color_use_as_albedo = true; m.roughness = 0.1; m.metallic_specular = 0.7
		"cherry":
			m.albedo_texture = b.tex("dl/cherry.png"); m.roughness = 0.3; m.metallic_specular = 0.55
		"carpet":
			m.albedo_texture = b.tex("dl/carpet.png"); m.roughness = 0.97
		"carpet95":
			m.albedo_texture = b.tex("dl/carpet95.png"); m.roughness = 0.97
		"vest":
			m.albedo_texture = b.tex("dl/vest.png"); m.roughness = 0.35
		"wallpaint":
			m.albedo_color = Color("#efebe3"); m.roughness = 0.9
		"gyp":
			m.albedo_color = Color("#f6f5f1"); m.roughness = 0.9
		"laytile":
			m.albedo_texture = b.tex("kb/ceiling.png"); m.roughness = 0.95
			m.albedo_color = Color(1.0, 0.99, 0.96)
		"coffer":
			# the cove-lit coffer ceiling: a faint warm glow stands in for the cove up-lights
			m.albedo_color = Color("#f7f3ea"); m.roughness = 0.9
			m.emission_enabled = true; m.emission = Color("#ffe8c8"); m.emission_energy_multiplier = 0.35
			m.set_meta("e_day", 0.35); m.set_meta("e_night", 0.35)
		"cove":
			m.albedo_color = Color.WHITE
			m.emission_enabled = true; m.emission = Color("#ffd9a8"); m.emission_energy_multiplier = 3.0
		"mirror":
			m.albedo_color = Color("#dfe3e6"); m.metallic = 0.75; m.roughness = 0.06
		"steel":
			m.albedo_color = Color("#c4c7ca"); m.metallic = 0.85; m.roughness = 0.28
		"step":
			m.albedo_color = Color("#1b1b1d"); m.metallic = 0.5; m.roughness = 0.5
		"balus":
			# white glass balustrade: milky, half transparent
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color = Color(0.95, 0.96, 0.97, 0.75); m.roughness = 0.2
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"lightbox":
			m.vertex_color_use_as_albedo = true; m.roughness = 0.4
			m.emission_enabled = true; m.emission = Color("#fff4e6"); m.emission_energy_multiplier = 0.6
		_:
			return false
	return true
