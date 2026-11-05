## The old Sears box (store s1; Lynn's Interiors in 2026): the skeleton, walkable, both years.
## Workstream E (Nov 1 2026). Design note and sources: design/godot-sears.md.
##
## Steven (Nov 1): "build the skeleton exactly: walls, partitions, columns, soffit beams; they never
## moved; departments later by me". So this builds the shell, the column grid, the soffit beams, the
## lay-in ceiling with its troffers, the separator partitions and the rooms they make, the side exit
## and the exterior customer storefront. 1995 (Sears) leaves every floor area empty for Steven's
## departments; 2026 (Lynn's) gets a light furniture dressing like the frames.
##
## Sources: refs/new/sears (IMG_4409-4413, Oct 23 2026), refs/notes/notes_A.md ("Old Sears interior"),
## the Morguard site plan (refs/era_1995/layout_screenshot_2026-09-19.jpg) for the depth.
##
## Frame: world metres (the box is axis-aligned): +x east, +z south, y up. The mall front is the
## south wall (z = Z_FRONT); the main aisle runs north from the Sears court (C1) axis, x = AISLE_X.
## Called from build_mall.gd's anchor_front() for the 24 m mall mouth (x -16..8), after the fascia
## and sign; it builds the whole box. Materials "sr_<key>" via fill_mat(); textures tex/sr/ from
## paint.py.

const X0 = -40.0            # west wall (the map rect s1: x 128..163 -> -40..30)
const X1 = 30.0             # east wall
const Z_FRONT = -96.0       # the mall wall
const DEPTH = 50.0          # front to back. The map rect says 38 m; the footage shows ~6 column
                            # bays down the main aisle and the site plan's box scales to ~50 m.
const Z_BACK = Z_FRONT - DEPTH
const WALL_T = 0.3          # inner face of the mall wall: z = Z_FRONT - WALL_T
const CEIL = 3.7            # white 2x2 lay-in (IMG_4409: 3.6-3.8 m)
const BEAM_W = 1.2          # boxed soffit beams along the column lines (IMG_4413 f019)
const BEAM_D = 0.5
const COL = 0.7             # square white columns (0.65-0.75 m)
const AISLE_X = -4.0        # the main aisle's axis: the C1 court / H2 axis (IMG_4413 f037)
const COLS_X = [-35.5, -26.5, -17.5, -8.5, 0.5, 9.5, 18.5, 27.5]   # ~9 m grid, aisle centred
const COLS_Z = [-101.0, -110.0, -119.0, -128.0, -137.0]
const MOUTH = [-16.0, 8.0]  # the mall entrance (anchor_front's 24 m mouth)
const MOUTH_H = 3.4         # anchor_front: OPEN_H + 0.2
# panel walls (separators and perimeter): 1.2 m panels, a reveal at 2.4 m, a soffit ledge at
# ~3.15 m on small triangular corbels every 1.2 m (IMG_4410 f001, IMG_4411 f006, IMG_4412 f004)
const REVEAL_Y = 2.4
const LEDGE_Y = 3.15
const LEDGE_D = 0.3
const CORBEL = 0.24

# The partitioned rooms (Steven assigns the 1995 departments; sizes in design/godot-sears.md).
# [name, x0, z0, x1, z1]
const ROOMS = [
	["R1 northwest (navy back corner)", -40.0, -146.0, -17.5, -128.0],
	["R2 west", -40.0, -128.0, -26.5, -110.0],
	["R3 northeast (mattress gallery, pipe columns)", 9.5, -146.0, 30.0, -128.0],
	["R4 mint-door room", -17.5, -146.0, -8.5, -137.0],
	["R5 back of house (closed)", 0.5, -146.0, 9.5, -137.0],
]
# Separator partitions [x0, z0, x1, z1] (axis-aligned runs on the column lines) with doorway gaps
# [[from, to] along the run]. Their orientation follows the column lines, as Steven said they
# have "always been in the same orientation"; the exact openings are a guess.
const PARTS = [
	[-40.0, -128.0, -17.5, -128.0, [[-31.0, -24.0]]],       # R1 / R2 line (z = -128)
	[-17.5, -146.0, -17.5, -128.0, [[-136.0, -131.0]]],     # R1 east side (x = -17.5)
	[-26.5, -128.0, -26.5, -110.0, [[-122.0, -116.0]]],     # R2 east side
	[-40.0, -110.0, -26.5, -110.0, []],                      # R2 south side
	[-17.5, -137.0, -8.5, -137.0, []],                       # R4 south side
	[-8.5, -146.0, -8.5, -137.0, [[-142.4, -140.6]]],       # R4 east side: the mint door
	[0.5, -146.0, 0.5, -137.0, []],                          # R5 west side (curtain + louvred door)
	[0.5, -137.0, 9.5, -137.0, []],                          # R5 south side
	[9.5, -146.0, 9.5, -128.0, [[-137.0, -131.0]]],          # R3 west side
	[9.5, -128.0, 30.0, -128.0, [[13.0, 21.0]]],             # R3 south side
]
const MINT_DOOR = [-8.5, -142.4, -140.6]
const SIDE_EXIT = [-5.05, -2.95]        # the north wall's glass doors, on the aisle axis (IMG_4413 f001-013)
const SIDE_EXIT_H = 3.0
const STOREFRONT = [-121.0, -115.0]     # the east wall's customer storefront (IMG_4413 f033; notes_A)
const STOREFRONT_H = 3.0
const CHASE = [-17.5, -119.0, 1.4]       # the boxed chase column (IMG_4412 f006), on a grid point
const PIPE_COLS = [[14.0, -133.0], [19.5, -133.0], [25.0, -133.0], [14.0, -140.0], [19.5, -140.0], [25.0, -140.0]]

static func in_r3(x, z):
	return x > 9.5 and z < -128.0

## Entry point (from build_mall.gd anchor_front): the whole box.
static func build(b, g, e, a, bb, n, t, Ln, sd):
	shell(b)
	floors(b)
	ceiling(b)
	columns(b)
	partitions(b)
	side_exit(b)
	storefront(b)
	if b.YEAR == 2026:
		dress_2026(b)
	lights(b)
	var rp = ReflectionProbe.new()
	rp.position = Vector3((X0 + X1) * 0.5, CEIL * 0.5, (Z_FRONT + Z_BACK) * 0.5)
	rp.size = Vector3(X1 - X0, CEIL + 0.2, DEPTH)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.6
	b.light_root.add_child(rp)

## Static group for a point: the box is cut into 18 m chunks so the realtime preview's per-mesh light
## limit is never hit and each lightmap chart stays small.
static func chunk(prefix, x, z):
	return "%s%d_%d" % [prefix, int(floor((x - X0) / 18.0)), int(floor((Z_FRONT - z) / 18.0))]

# ------------------------------------------------------------------ helpers
## A vertical wall quad from p (x,z) to q (x,z), y0..y1, facing nrm; UVs in metres / per.
static func wall(b, G, m, p, q, y0, y1, nrm, per_u = 1.0, per_v = 1.0):
	var A = Vector3(p.x, 0, p.y)
	var B = Vector3(q.x, 0, q.y)
	var L = A.distance_to(B)
	b.quad(G, m, [A + Vector3(0, y0, 0), B + Vector3(0, y0, 0), B + Vector3(0, y1, 0), A + Vector3(0, y1, 0)], nrm,
		[Vector2(0, -y0 / per_v), Vector2(L / per_u, -y0 / per_v), Vector2(L / per_u, -y1 / per_v), Vector2(0, -y1 / per_v)])

## One face of a panel wall: panels to the reveal, the reveal, panels to the ledge, the ledge on
## corbels every 1.2 m, plain wall above to the ceiling. `nrm` points into the room it faces; the
## wall plane is p..q. Trim (reveal, ledge, corbels) is dynamic: small parts, no lightmap charts.
static func panel_face(b, p, q, nrm, top = CEIL, ledge = true):
	var G = chunk("sr_wall", (p.x + q.x) * 0.5, (p.y + q.y) * 0.5)
	var off = Vector2(nrm.x, nrm.z) * 0.001
	wall(b, G, "sr_panel", p + off, q + off, 0.0, REVEAL_Y, nrm, 1.2, 2.4)
	wall(b, G, "sr_panel", p + off, q + off, REVEAL_Y + 0.04, min(LEDGE_Y, top), nrm, 1.2, 2.4)
	if top > LEDGE_Y:
		wall(b, G, "sr_paint", p + off, q + off, LEDGE_Y, top, nrm)
	var A = Vector3(p.x, 0, p.y)
	var B = Vector3(q.x, 0, q.y)
	var tt = (B - A).normalized()
	var L = A.distance_to(B)
	b.cur_color = Color("#b9b6ad")
	b.box("sr_trim", "vcolor_matte", (A + B) * 0.5 + Vector3(0, REVEAL_Y + 0.02, 0) + nrm * 0.004, b.abs_size(tt, L, 0.04, 0.01, nrm), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	if not ledge or top <= LEDGE_Y + 0.05:
		return
	b.box("sr_trim", "sr_paint", (A + B) * 0.5 + Vector3(0, LEDGE_Y + 0.05, 0) + nrm * LEDGE_D * 0.5, b.abs_size(tt, L, 0.1, LEDGE_D, nrm), Transform3D.IDENTITY, [], true)
	var k = 0.6
	while k < L - 0.3:
		corbel(b, A + tt * k, tt, nrm)
		k += 1.2

## A small triangular corbel under the ledge: a wedge 6 cm thick, CORBEL deep and tall.
static func corbel(b, c, tt, nrm):
	var s = b.st("sr_trim", "sr_paint", true)
	var y1 = LEDGE_Y
	var y0 = LEDGE_Y - CORBEL
	var w = tt * 0.03
	var p0 = c + Vector3(0, y1, 0)
	var p1 = c + Vector3(0, y1, 0) + nrm * CORBEL
	var p2 = c + Vector3(0, y0, 0)
	for side in [-1.0, 1.0]:
		b.tri(s, p0 + w * side, p1 + w * side, p2 + w * side, Vector2(0, 0), Vector2(1, 0), Vector2(0, 1), tt * side)
	var sl = ((p1 - p2).cross(tt)).normalized()
	if sl.dot(nrm) < 0:
		sl = -sl
	b.quad("sr_trim", "sr_paint", [p1 - w, p1 + w, p2 + w, p2 - w], sl, [], true)

## An obstacle rectangle (player collision) from two corners, padded.
static func block(b, x0, z0, x1, z1, pad = 0.0):
	b.obst(["rect", min(x0, x1) - pad, min(z0, z1) - pad, max(x0, x1) + pad, max(z0, z1) + pad])

# ------------------------------------------------------------------ shell
## The box's walls (inner faces), the mall wall with its mouth, and their collision.
static func shell(b):
	var zf = Z_FRONT - WALL_T
	# the mall (south) wall: its inside face, the mouth cut out, and the mouth's reveals
	for seg in [[X0, MOUTH[0]], [MOUTH[1], X1]]:
		panel_face(b, Vector2(seg[0], zf), Vector2(seg[1], zf), Vector3(0, 0, -1))
	wall(b, "sr_wall_front", "sr_paint", Vector2(MOUTH[0], zf - 0.001), Vector2(MOUTH[1], zf - 0.001), MOUTH_H, CEIL, Vector3(0, 0, -1))
	for mx in [[MOUTH[0], Vector3(1, 0, 0)], [MOUTH[1], Vector3(-1, 0, 0)]]:
		wall(b, "sr_wall_front", "sr_paint", Vector2(mx[0], Z_FRONT), Vector2(mx[0], zf), 0.0, MOUTH_H, mx[1])
	b.quad("sr_wall_front", "sr_paint", [Vector3(MOUTH[0], MOUTH_H, Z_FRONT), Vector3(MOUTH[1], MOUTH_H, Z_FRONT), Vector3(MOUTH[1], MOUTH_H, zf), Vector3(MOUTH[0], MOUTH_H, zf)], Vector3.DOWN)
	# the hall side's plain walls are build_mall.gd's; the wall's thickness blocks the player
	block(b, X0, Z_FRONT - WALL_T, MOUTH[0], Z_FRONT + 0.05)
	block(b, MOUTH[1], Z_FRONT - WALL_T, X1, Z_FRONT + 0.05)
	# west wall: panels the whole way (the higher west bulkhead of IMG_4409 is left out)
	panel_face(b, Vector2(X0, Z_BACK), Vector2(X0, zf), Vector3(1, 0, 0))
	# north (back) wall, west of R4 and east of R5: panels; R4..R5 is the aisle end with the side
	# exit, cream with picture-frame mouldings (side_exit())
	panel_face(b, Vector2(X0, Z_BACK), Vector2(-17.5, Z_BACK), Vector3(0, 0, 1))
	panel_face(b, Vector2(-17.5, Z_BACK), Vector2(-8.5, Z_BACK), Vector3(0, 0, 1))
	panel_face(b, Vector2(9.5, Z_BACK), Vector2(X1, Z_BACK), Vector3(0, 0, 1), CEIL, false)
	# east wall: panels, with the storefront cut out (storefront()) and R3's window band
	panel_face(b, Vector2(X1, zf), Vector2(X1, STOREFRONT[1]), Vector3(-1, 0, 0))
	panel_face(b, Vector2(X1, STOREFRONT[0]), Vector2(X1, -128.0), Vector3(-1, 0, 0))
	r3_east_wall(b)
	# the navy back corner (IMG_4411 f012): R1's north and west walls to the ledge
	b.cur_color = Color("#1f2b4d")
	for w in [[Vector2(X0, Z_BACK + 0.004), Vector2(-30.0, Z_BACK + 0.004), Vector3(0, 0, 1)], [Vector2(X0 + 0.004, Z_BACK), Vector2(X0 + 0.004, -138.0), Vector3(1, 0, 0)]]:
		wall(b, "sr_wall_navy", "vcolor_matte", w[0], w[1], 0.0, LEDGE_Y - 0.002, w[2])
	b.cur_color = Color.WHITE

## R3's east wall: a band of tall frosted windows (IMG_4412 "the far zone ... a band of tall
## bright windows") between plain panels, under the stepped soffit.
static func r3_east_wall(b):
	var G = "sr_wall_r3"
	var zs = -128.0
	var nrm = Vector3(-1, 0, 0)
	var xw = X1 - 0.002
	wall(b, G, "sr_panel", Vector2(xw, -146.0), Vector2(xw, zs), 0.0, 0.9, nrm, 1.2, 2.4)
	wall(b, G, "sr_paint", Vector2(xw, -146.0), Vector2(xw, zs), 3.0, CEIL, nrm)
	var z = -144.5
	while z < zs - 1.5:
		wall(b, G, "sr_frost", Vector2(xw, z), Vector2(xw, z + 1.6), 0.9, 3.0, nrm, 1.6, 2.1)
		b.cur_color = Color("#d9dadc")
		b.box("sr_trim", "vcolor", Vector3(xw - 0.03, 1.95, z + 1.6 + 0.12), Vector3(0.06, 2.1, 0.24), Transform3D.IDENTITY, [], true)
		b.cur_color = Color.WHITE
		wall(b, G, "sr_paint", Vector2(xw, z + 1.6), Vector2(xw, z + 2.0), 0.9, 3.0, nrm)
		z += 2.0
	wall(b, G, "sr_paint", Vector2(xw, -146.0), Vector2(xw, -144.5), 0.9, 3.0, nrm)
	wall(b, G, "sr_paint", Vector2(xw, z), Vector2(xw, zs), 0.9, 3.0, nrm)

# ------------------------------------------------------------------ floor
## 2026: polished grey concrete with mastic ghosts, the old tile bed at the threshold, R3's taupe
## carpet, one marbled-vinyl alcove. 1995 (a guess, design note): almond 12" vinyl tile aisles and
## blue-grey carpet pads; the rooms carpeted, the main and cross aisles in vinyl.
static func floors(b):
	var zf = Z_FRONT - WALL_T
	# the threshold strip through the mouth's wall thickness: the mall's tile bed
	b.cur_color = Color("#b9b2a4")
	b.quad("sr_floor_front", "vcolor_matte", [Vector3(MOUTH[0], 0, Z_FRONT), Vector3(MOUTH[1], 0, Z_FRONT), Vector3(MOUTH[1], 0, zf), Vector3(MOUTH[0], 0, zf)], Vector3.UP)
	b.cur_color = Color.WHITE
	var pads = []   # [x0, z0, x1, z1, material, uv-per-metre]
	if b.YEAR == 2026:
		pads.append([9.5, -146.0, 30.0, -128.0, "sr_carpet_taupe", 0.5])
		pads.append([-36.0, -108.0, -31.0, -102.0, "sr_marble", 1.0 / 1.22])
	else:
		for r in ROOMS:
			if r[0].begins_with("R5"):
				continue
			pads.append([r[1], r[2], r[3], r[4], "sr_carpet95", 0.5])
		# the open floor's carpet pads between the aisles (a guess): the aisles stay vinyl
		for p in [[-26.5, -128.0, -8.5, -110.0], [0.5, -128.0, 9.5, -101.5], [9.5, -128.0, 27.5, -101.5], [-35.5, -110.0, -8.5, -101.5]]:
			pads.append([p[0] + 1.2, p[1] + 1.2, p[2] - 1.2, p[3] - 1.0, "sr_carpet95", 0.5])
	var base = "sr_concrete" if b.YEAR == 2026 else "sr_vct95"
	var per = 0.25 if b.YEAR == 2026 else 1.0 / 1.22
	# the field in 9 m tiles (lightmap charts stay small), each cut round the pads
	var x = X0
	while x < X1 - 0.01:
		var x2 = min(x + 9.0, X1)
		var z = zf
		while z > Z_BACK + 0.01:
			var z2 = max(z - 9.0, Z_BACK)
			floor_cell(b, x, z2, x2, z, base, per, pads)
			z = z2
		x = x2

## One floor cell [x0..x1] x [z0..z1]: the pads it overlaps in their material, the rest in `base`
## (split into strips round the overlaps).
static func floor_cell(b, x0, z0, x1, z1, base, per, pads):
	var G = chunk("sr_floor", (x0 + x1) * 0.5, (z0 + z1) * 0.5)
	# cut along x at every pad edge, then along z: a small grid of sub-rectangles
	var xs = [x0, x1]
	var zs = [z0, z1]
	for p in pads:
		for v in [p[0], p[2]]:
			if v > x0 and v < x1 and not xs.has(v):
				xs.append(v)
		for v in [p[1], p[3]]:
			if v > z0 and v < z1 and not zs.has(v):
				zs.append(v)
	xs.sort()
	zs.sort()
	for i in xs.size() - 1:
		for j in zs.size() - 1:
			var cx = (xs[i] + xs[i + 1]) * 0.5
			var cz = (zs[j] + zs[j + 1]) * 0.5
			var m = base
			var pp = per
			for p in pads:
				if cx > p[0] and cx < p[2] and cz > p[1] and cz < p[3]:
					m = p[4]
					pp = p[5]
			b.quad(G, m, [Vector3(xs[i], 0, zs[j]), Vector3(xs[i + 1], 0, zs[j]), Vector3(xs[i + 1], 0, zs[j + 1]), Vector3(xs[i], 0, zs[j + 1])], Vector3.UP, [], false, pp)

# ------------------------------------------------------------------ ceiling
## The lay-in ceiling at CEIL in 9 m tiles, the boxed soffit beams along the column lines (not over
## the front bay: IMG_4409 f001 shows a flat ceiling there), R3's stepped double soffit, and the
## 2x4 troffers on a regular grid between the beams.
static func ceiling(b):
	var zf = Z_FRONT - WALL_T
	var x = X0
	while x < X1 - 0.01:
		var x2 = min(x + 9.0, X1)
		var z = zf
		while z > Z_BACK + 0.01:
			var z2 = max(z - 9.0, Z_BACK)
			var G = chunk("sr_ceil", (x + x2) * 0.5, (z + z2) * 0.5)
			var q = [Vector3(x, CEIL, z2), Vector3(x2, CEIL, z2), Vector3(x2, CEIL, z), Vector3(x, CEIL, z)]
			var uv = []
			for p in q:
				uv.append(Vector2(p.x / 0.61, p.z / 0.61))
			b.quad(G, "drop_tile", q, Vector3.DOWN, uv)
			z = z2
		x = x2
	# beams: east-west along the column rows behind the first, north-south along the column lines
	var zb = COLS_Z[1]
	for cz in COLS_Z.slice(1):
		beam(b, Vector3(X0, 0, cz), Vector3(X1, 0, cz), true)
	for cx in COLS_X:
		beam(b, Vector3(cx, 0, Z_BACK), Vector3(cx, 0, zb), false)
	# R3: the stepped double soffit round the mattress gallery (IMG_4412 f011)
	var r = [9.5, -146.0, 30.0, -128.0]
	for k in 2:
		var ins = 0.7 * (k + 1)
		var y = CEIL - 0.25 * (2 - k)
		ring(b, r[0] + ins - 0.7, r[1] + ins - 0.7, r[2] - ins + 0.7, r[3] - ins + 0.7, 0.7, y)
	troffers(b)

## A boxed soffit beam from p to q (on the floor plane), BEAM_W wide, BEAM_D deep under the ceiling.
## `cut_aisle`: leave the main aisle's span over the aisle open (it reads as one long run there).
static func beam(b, p, q, along_x):
	var L = p.distance_to(q)
	var tt = (q - p).normalized()
	var nn = Vector3(tt.z, 0, -tt.x)
	var c = (p + q) * 0.5 + Vector3(0, CEIL - BEAM_D * 0.5, 0)
	var G = chunk("sr_ceil", c.x, c.z) if L < 20.0 else "sr_beams"
	b.box(G, "sr_paint", c, b.abs_size(tt, L, BEAM_D, BEAM_W, nn), Transform3D.IDENTITY, ["+y"])

## A soffit ring (a rectangular frame `w` wide) whose underside is at y, up to the ceiling.
static func ring(b, x0, z0, x1, z1, w, y):
	var G = "sr_ceil_r3"
	var h = CEIL - y
	for s in [[x0, z0, x1, z0 + w], [x0, z1 - w, x1, z1], [x0, z0 + w, x0 + w, z1 - w], [x1 - w, z0 + w, x1, z1 - w]]:
		var c = Vector3((s[0] + s[2]) * 0.5, y + h * 0.5, (s[1] + s[3]) * 0.5)
		b.box(G, "sr_paint", c, Vector3(s[2] - s[0], h, s[3] - s[1]), Transform3D.IDENTITY, ["+y"])

## 2x4 deep-cell parabolic troffers, long side north-south, ~3 m apart in both directions, kept off
## the beams and R3's soffits.
static func troffers(b):
	var zf = Z_FRONT - WALL_T
	var x = X0 + 1.5
	while x < X1 - 1.0:
		var z = zf - 1.8
		while z > Z_BACK + 1.0:
			if near_beam(x, z) or (in_r3(x, z) and (x < 12.4 or x > 27.1 or z > -130.9 or z < -143.1)) or (x > 0.5 and x < 9.5 and z < -137.0):
				z -= 3.0
				continue
			var y = CEIL - 0.004
			var G = chunk("sr_ceil", x, z)
			b.quad(G, "cd7_troffer", [Vector3(x - 0.3, y, z - 0.6), Vector3(x + 0.3, y, z - 0.6), Vector3(x + 0.3, y, z + 0.6), Vector3(x - 0.3, y, z + 0.6)], Vector3.DOWN,
				[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)])
			z -= 3.0
		x += 3.0

static func near_beam(x, z):
	for cx in COLS_X:
		if abs(x - cx) < BEAM_W * 0.5 + 0.35 and z < COLS_Z[1] + 0.7:
			return true
	for cz in COLS_Z.slice(1):
		if abs(z - cz) < BEAM_W * 0.5 + 0.65:
			return true
	return false

# ------------------------------------------------------------------ columns
## Square white columns on the grid (under the beams), the boxed chase, and R3's slender pipe
## columns instead of square ones (IMG_4412: "a different structural bay").
static func columns(b):
	for cx in COLS_X:
		for cz in COLS_Z:
			if in_r3(cx, cz) or on_partition_end(cx, cz):
				continue
			if Vector2(cx, cz).distance_to(Vector2(CHASE[0], CHASE[1])) < 0.1:
				continue
			var top = CEIL - BEAM_D if cz <= COLS_Z[1] else CEIL
			var G = chunk("sr_cols", cx, cz)
			b.box(G, "sr_paint", Vector3(cx, top * 0.5, cz), Vector3(COL, top, COL), Transform3D.IDENTITY, ["+y", "-y"])
			# a slotted standard strip on one face (IMG_4410), and the receptacle
			b.cur_color = Color("#9a9a96")
			b.box("sr_trim", "vcolor", Vector3(cx, 1.4, cz + COL * 0.5 + 0.005), Vector3(0.03, 2.2, 0.01), Transform3D.IDENTITY, [], true)
			b.cur_color = Color.WHITE
			block(b, cx - COL * 0.5, cz - COL * 0.5, cx + COL * 0.5, cz + COL * 0.5, 0.15)
	# the chase: 1.4 m square, panelled, a moulding at 2.4 m
	var s = CHASE[2]
	var G2 = chunk("sr_cols", CHASE[0], CHASE[1])
	var top2 = CEIL - BEAM_D
	for f in [[Vector3(1, 0, 0)], [Vector3(-1, 0, 0)], [Vector3(0, 0, 1)], [Vector3(0, 0, -1)]]:
		var nrm = f[0]
		var tt = Vector3(nrm.z, 0, -nrm.x)
		var c = Vector3(CHASE[0], 0, CHASE[1]) + nrm * s * 0.5
		var p = c - tt * s * 0.5
		var q = c + tt * s * 0.5
		wall(b, G2, "sr_panel", Vector2(p.x, p.z), Vector2(q.x, q.z), 0.0, REVEAL_Y, nrm, 0.7, 2.4)
		wall(b, G2, "sr_paint", Vector2(p.x, p.z), Vector2(q.x, q.z), REVEAL_Y, top2, nrm)
		b.box("sr_trim", "sr_paint", c + Vector3(0, REVEAL_Y + 0.04, 0) + nrm * 0.03, b.abs_size(tt, s + 0.12, 0.08, 0.06, nrm), Transform3D.IDENTITY, [], true)
	block(b, CHASE[0] - s * 0.5, CHASE[1] - s * 0.5, CHASE[0] + s * 0.5, CHASE[1] + s * 0.5, 0.15)
	for pc in PIPE_COLS:
		b.cyl(chunk("sr_cols", pc[0], pc[1]), "sr_paint", Vector3(pc[0], 0, pc[1]), 0.13, 0.13, CEIL, 12, false, false)
		block(b, pc[0] - 0.13, pc[1] - 0.13, pc[0] + 0.13, pc[1] + 0.13, 0.15)

## Grid points that a partition swallows (the partition is built through them).
static func on_partition_end(cx, cz):
	return false

# ------------------------------------------------------------------ partitions
## The white "separator" walls (IMG_4412): full height to the ceiling, panelled both faces with the
## reveal and the corbelled ledge; doorway gaps get a plain head above 2.6 m.
static func partitions(b):
	var T = 0.16
	for pr in PARTS:
		var p = Vector2(pr[0], pr[1])
		var q = Vector2(pr[2], pr[3])
		var along_x = abs(q.x - p.x) > abs(q.y - p.y)
		var lo = p.x if along_x else p.y
		var hi = q.x if along_x else q.y
		var gaps = pr[4].duplicate()
		gaps.sort_custom(func(u, v): return u[0] < v[0])
		var runs = []
		var s = lo
		for gp in gaps:
			runs.append([s, gp[0]])
			s = gp[1]
		runs.append([s, hi])
		for r in runs:
			if r[1] - r[0] < 0.05:
				continue
			var P0 = Vector2(r[0], p.y) if along_x else Vector2(p.x, r[0])
			var P1 = Vector2(r[1], p.y) if along_x else Vector2(p.x, r[1])
			var nrm = Vector3(0, 0, 1) if along_x else Vector3(1, 0, 0)
			var off = Vector2(nrm.x, nrm.z) * T * 0.5
			panel_face(b, P0 + off, P1 + off, nrm)
			panel_face(b, P1 - off, P0 - off, -nrm)
			# end caps
			for e in [[P0, -1.0], [P1, 1.0]]:
				var en = Vector3(1, 0, 0) * e[1] if along_x else Vector3(0, 0, 1) * e[1]
				wall(b, chunk("sr_wall", e[0].x, e[0].y), "sr_paint", e[0] - off, e[0] + off, 0.0, CEIL, en)
			block(b, min(P0.x, P1.x) - (0.0 if along_x else T * 0.5), min(P0.y, P1.y) - (T * 0.5 if along_x else 0.0),
				max(P0.x, P1.x) + (0.0 if along_x else T * 0.5), max(P0.y, P1.y) + (T * 0.5 if along_x else 0.0), 0.12)
		# heads over the doorways (2.7 m), with returns
		for gp in gaps:
			var G0 = Vector2(gp[0], p.y) if along_x else Vector2(p.x, gp[0])
			var G1 = Vector2(gp[1], p.y) if along_x else Vector2(p.x, gp[1])
			var nrm2 = Vector3(0, 0, 1) if along_x else Vector3(1, 0, 0)
			var off2 = Vector2(nrm2.x, nrm2.z) * T * 0.5
			var Gh = chunk("sr_wall", (G0.x + G1.x) * 0.5, (G0.y + G1.y) * 0.5)
			wall(b, Gh, "sr_paint", G0 + off2, G1 + off2, 2.7, CEIL, nrm2)
			wall(b, Gh, "sr_paint", G1 - off2, G0 - off2, 2.7, CEIL, -nrm2)
			var c3 = Vector3((G0.x + G1.x) * 0.5, 2.7, (G0.y + G1.y) * 0.5)
			var tt3 = Vector3(1, 0, 0) if along_x else Vector3(0, 0, 1)
			b.quad(Gh, "sr_paint", [c3 - tt3 * (G1 - G0).length() * 0.5 - nrm2 * T * 0.5, c3 + tt3 * (G1 - G0).length() * 0.5 - nrm2 * T * 0.5,
				c3 + tt3 * (G1 - G0).length() * 0.5 + nrm2 * T * 0.5, c3 - tt3 * (G1 - G0).length() * 0.5 + nrm2 * T * 0.5], Vector3.DOWN)
	mint_door(b)
	back_of_house(b)

## R4's mint/turquoise panelled glazed double door (IMG_4412 f002), standing open into the room.
static func mint_door(b):
	var x = MINT_DOOR[0]
	var z0 = MINT_DOOR[1]
	var z1 = MINT_DOOR[2]
	var w = (z1 - z0) * 0.5
	b.cur_color = Color("#7fcdb8")
	# frame
	for zz in [z0, z1]:
		b.box("sr_trim", "vcolor", Vector3(x, 1.35, zz), Vector3(0.22, 2.7, 0.06), Transform3D.IDENTITY, [], true)
	b.box("sr_trim", "vcolor", Vector3(x, 2.66, (z0 + z1) * 0.5), Vector3(0.22, 0.08, z1 - z0), Transform3D.IDENTITY, [], true)
	# two leaves swung 90 degrees into R4 (west), each a frame with a glass light
	for k in [[z0, 1.0], [z1, -1.0]]:
		var hz = k[0] + k[1] * 0.04
		var c = Vector3(x - w * 0.5 - 0.06, 1.3, hz)
		b.box("sr_trim", "vcolor", c + Vector3(0, -0.85, 0), Vector3(w, 0.9, 0.05), Transform3D.IDENTITY, [], true)
		b.box("sr_trim", "vcolor", c + Vector3(0, 1.15, 0), Vector3(w, 0.1, 0.05), Transform3D.IDENTITY, [], true)
		for ee in [-1.0, 1.0]:
			b.box("sr_trim", "vcolor", c + Vector3(ee * (w * 0.5 - 0.05), 0.35, 0), Vector3(0.1, 1.5, 0.05), Transform3D.IDENTITY, [], true)
		b.quad("glass", "glass", [c + Vector3(-w * 0.5 + 0.1, -0.4, 0), c + Vector3(w * 0.5 - 0.1, -0.4, 0), c + Vector3(w * 0.5 - 0.1, 1.1, 0), c + Vector3(-w * 0.5 + 0.1, 1.1, 0)], Vector3(0, 0, 1), [], true)
		block(b, x - w - 0.1, hz - 0.05, x - 0.05, hz + 0.05)
	b.cur_color = Color.WHITE

## R5, back of house (not walkable): a white louvred door and a beige curtain over a ~3 m opening
## on its aisle side (IMG_4411 f012, IMG_4412 f004), an EXIT sign.
static func back_of_house(b):
	block(b, 0.5, Z_BACK, 9.5, -137.0, 0.1)
	var zf = -137.0 + 0.085
	# the curtain: a gathered beige plane (two folds of triangles)
	var s = b.st("sr_trim", "vcolor_matte", true)
	b.cur_color = Color("#d8c9a8")
	var x = 2.0
	var k = 0
	while x < 5.0:
		var d = 0.06 if k % 2 == 0 else -0.02
		var p0 = Vector3(x, 0.02, zf + d)
		var p1 = Vector3(x + 0.15, 0.02, zf + 0.02 - d)
		b.tri(s, p0, p1, p1 + Vector3(0, 2.7, 0), Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector3(0, 0, 1))
		b.tri(s, p0, p1 + Vector3(0, 2.7, 0), p0 + Vector3(0, 2.7, 0), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1), Vector3(0, 0, 1))
		x += 0.15
		k += 1
	# the louvred door, 0.9 x 2.1 m, white, with horizontal slats
	b.cur_color = Color("#f2f1ec")
	b.box("sr_trim", "vcolor_matte", Vector3(7.4, 1.05, zf), Vector3(0.95, 2.1, 0.04), Transform3D.IDENTITY, [], true)
	b.cur_color = Color("#d4d3cd")
	var y = 0.5
	while y < 1.9:
		b.box("sr_trim", "vcolor_matte", Vector3(7.4, y, zf + 0.025), Vector3(0.75, 0.02, 0.01), Transform3D.IDENTITY, [], true)
		y += 0.06
	b.cur_color = Color.WHITE
	b.box("sr_trim", "exit_sign", Vector3(7.4, 2.4, zf + 0.04), Vector3(0.36, 0.16, 0.06), Transform3D.IDENTITY, [], true)

# ------------------------------------------------------------------ exits
## The side exit at the end of the main aisle (IMG_4413 f001-013): a cream wall with thin applied
## picture-frame mouldings (rails ~1 m and ~3.2 m), a 2.1 m opening with a pair of clear-anodized
## glass doors and a transom, the galvanized roll-up shutter's coil box inside above the transom, a
## red fire pull; outside, the lot in daylight.
static func side_exit(b):
	var G = "sr_wall_exit"
	var z = Z_BACK + 0.002
	var nrm = Vector3(0, 0, 1)
	var e0 = SIDE_EXIT[0]
	var e1 = SIDE_EXIT[1]
	wall(b, G, "sr_cream", Vector2(-8.5, z), Vector2(e0, z), 0.0, CEIL, nrm)
	wall(b, G, "sr_cream", Vector2(e1, z), Vector2(0.5, z), 0.0, CEIL, nrm)
	wall(b, G, "sr_cream", Vector2(e0, z), Vector2(e1, z), SIDE_EXIT_H + 0.4, CEIL, nrm)
	# mouldings: rails and frame panels either side
	b.cur_color = Color("#e3d9c3")
	for ry in [1.0, 3.2]:
		for seg in [[-8.3, e0 - 0.3], [e1 + 0.3, 0.3]]:
			b.box("sr_trim", "vcolor_matte", Vector3((seg[0] + seg[1]) * 0.5, ry, z + 0.01), Vector3(seg[1] - seg[0], 0.04, 0.02), Transform3D.IDENTITY, [], true)
	for seg in [[-8.0, -5.6], [-2.4, 0.0]]:
		for yy in [[0.25, 0.8], [1.25, 3.0]]:
			frame(b, Vector3((seg[0] + seg[1]) * 0.5, (yy[0] + yy[1]) * 0.5, z + 0.012), seg[1] - seg[0], yy[1] - yy[0])
	b.cur_color = Color.WHITE
	# the doors: anodized frame, two leaves, transom
	b.cur_color = Color("#c9ccd0")
	var dw = e1 - e0
	for xx in [e0 + 0.04, (e0 + e1) * 0.5, e1 - 0.04]:
		b.box("sr_trim", "vcolor", Vector3(xx, SIDE_EXIT_H * 0.5 + 0.2, z), Vector3(0.08, SIDE_EXIT_H + 0.4, 0.12), Transform3D.IDENTITY, [], true)
	for yy in [0.05, 2.3, SIDE_EXIT_H + 0.36]:
		b.box("sr_trim", "vcolor", Vector3((e0 + e1) * 0.5, yy, z), Vector3(dw, 0.08, 0.12), Transform3D.IDENTITY, [], true)
	# push bars
	for k in [-1.0, 1.0]:
		b.box("sr_trim", "vcolor", Vector3((e0 + e1) * 0.5 + k * dw * 0.25, 1.0, z + 0.08), Vector3(dw * 0.4, 0.05, 0.05), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	b.quad("glass", "glass", [Vector3(e0, 0.05, z), Vector3(e1, 0.05, z), Vector3(e1, SIDE_EXIT_H + 0.36, z), Vector3(e0, SIDE_EXIT_H + 0.36, z)], nrm, [], true)
	# the roll shutter's coil box over the transom, inside
	b.box("sr_trim", "sr_galv", Vector3((e0 + e1) * 0.5, SIDE_EXIT_H + 0.55, z + 0.18), Vector3(dw + 0.5, 0.35, 0.34), Transform3D.IDENTITY, [], true)
	b.box("sr_trim", "sr_galv", Vector3((e0 + e1) * 0.5, SIDE_EXIT_H + 0.2, z + 0.06), Vector3(dw + 0.2, 0.3, 0.04), Transform3D.IDENTITY, [], true)
	b.box("sr_trim", "exit_sign", Vector3((e0 + e1) * 0.5, CEIL - 0.25, z + 0.05), Vector3(0.36, 0.16, 0.06), Transform3D.IDENTITY, [], true)
	b.cur_color = Color("#c4242c")
	b.box("sr_trim", "vcolor", Vector3(e1 + 0.5, 1.25, z + 0.04), Vector3(0.12, 0.17, 0.06), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	outside_view(b, Vector3((e0 + e1) * 0.5, 0, Z_BACK), Vector3(0, 0, -1), dw + 2.0)
	block(b, e0 - 0.2, Z_BACK - 0.4, e1 + 0.2, Z_BACK + 0.15)

static func frame(b, c, w, h):
	for s in [[Vector3(0, h * 0.5, 0), Vector3(w, 0.03, 0.015)], [Vector3(0, -h * 0.5, 0), Vector3(w, 0.03, 0.015)],
			[Vector3(w * 0.5, 0, 0), Vector3(0.03, h, 0.015)], [Vector3(-w * 0.5, 0, 0), Vector3(0.03, h, 0.015)]]:
		b.box("sr_trim", "vcolor_matte", c + s[0], s[1], Transform3D.IDENTITY, [], true)

## Daylight through glass doors: a strip of lot and a bright sky card, unshaded (the outside is
## wing 3; this is what the glass shows from in here).
static func outside_view(b, at, out, w):
	var tt = Vector3(out.z, 0, -out.x)
	b.quad("sr_out", "outside_ground", [at - tt * w * 0.5, at + tt * w * 0.5, at + tt * w * 0.5 + out * 14.0, at - tt * w * 0.5 + out * 14.0], Vector3.UP, [], true, 0.25)
	var far = at + out * 14.0
	b.quad("sr_out", "sr_sky", [far - tt * w * 2.0, far + tt * w * 2.0, far + tt * w * 2.0 + Vector3(0, 9, 0), far - tt * w * 2.0 + Vector3(0, 9, 0)], -out, [], true)

## The exterior customer storefront on the east wall (IMG_4413 f033-034, notes_A): an aluminium
## curtain wall ~6 x 3 m with a pair of glass doors in the middle and an EXIT sign; two side panes
## backed with white board; the lay-in ceiling continues over it (no lobby height).
static func storefront(b):
	var G = "sr_wall_sf"
	var x = X1 - 0.002
	var nrm = Vector3(-1, 0, 0)
	var z0 = STOREFRONT[0]
	var z1 = STOREFRONT[1]
	wall(b, G, "sr_paint", Vector2(x, z0), Vector2(x, z1), STOREFRONT_H, CEIL, nrm)
	b.cur_color = Color("#c9ccd0")
	var bays = 4
	for i in bays + 1:
		var zz = z0 + (z1 - z0) * i / bays
		b.box("sr_trim", "vcolor", Vector3(x - 0.05, STOREFRONT_H * 0.5, zz), Vector3(0.12, STOREFRONT_H, 0.08), Transform3D.IDENTITY, [], true)
	for yy in [0.04, 2.3, STOREFRONT_H - 0.04]:
		b.box("sr_trim", "vcolor", Vector3(x - 0.05, yy, (z0 + z1) * 0.5), Vector3(0.12, 0.08, z1 - z0), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	b.quad("glass", "glass", [Vector3(x, 0.04, z1), Vector3(x, 0.04, z0), Vector3(x, STOREFRONT_H, z0), Vector3(x, STOREFRONT_H, z1)], nrm, [], true)
	# the white boards behind the two outer bays' lower panes
	for k in [[z0 + 0.06, z0 + (z1 - z0) / bays - 0.06], [z1 - (z1 - z0) / bays + 0.06, z1 - 0.06]]:
		b.quad("sr_trim", "sr_paint", [Vector3(x - 0.08, 0.1, k[1]), Vector3(x - 0.08, 0.1, k[0]), Vector3(x - 0.08, 2.25, k[0]), Vector3(x - 0.08, 2.25, k[1])], nrm, [], true)
	b.box("sr_trim", "exit_sign", Vector3(x - 0.1, STOREFRONT_H + 0.25, (z0 + z1) * 0.5), Vector3(0.06, 0.16, 0.36), Transform3D.IDENTITY, [], true)
	outside_view(b, Vector3(X1, 0, (z0 + z1) * 0.5), Vector3(1, 0, 0), z1 - z0 + 2.0)
	block(b, X1 - 0.15, z0, X1 + 0.4, z1)

# ------------------------------------------------------------------ lights
## One downlight per ~9 m bay at the troffer level (the troffers' glow does most of the bake), a
## cooler daylight spill at each glazed exit.
static func lights(b):
	var zf = Z_FRONT - WALL_T
	var x = X0 + 4.5
	while x < X1:
		var z = zf - 4.5
		while z > Z_BACK:
			var l = b.add_spot(Vector3(x, CEIL - 0.1, z), Vector3.DOWN, 2.4, 7.0, 75.0, Color(1.0, 0.97, 0.92))
			b.tag(l, "", 2.4, 2.4)
			z -= 9.0
		x += 9.0
	for p in [[Vector3((SIDE_EXIT[0] + SIDE_EXIT[1]) * 0.5, 2.2, Z_BACK + 1.5), "day"], [Vector3(X1 - 1.5, 2.2, (STOREFRONT[0] + STOREFRONT[1]) * 0.5), "day"]]:
		b.tag(b.add_omni(p[0], 1.2, 7.0, Color("#dfe9ff")), p[1])

# ------------------------------------------------------------------ 2026 dressing
## Lynn's Interiors, as the frames show it: sofa and sectional groups on the open floor, dining
## sets, bedroom vignettes and mattresses in R3, recliners along a west run, stainless fridges and a
## TV wall in R1's navy corner. Generic shapes in muted fabric colours; dynamic meshes (no lightmap).
static func dress_2026(b):
	# workstream LYNNS: the Blender furniture (design/lynns/layout.md); the boxes below skip its groups
	var LY = load("res://tools/stores/sears/lynns.gd")
	LY.place(b)
	if LY.replaces_boxes():
		r3_slatwall(b)   # the pack furniture fills the floor; only the R3 slatwall stays from the boxes below
		return
	var rng = RandomNumberGenerator.new()
	rng.seed = 4409
	var fab = ["#d9d2c3", "#c9c1b0", "#8b8378", "#5d5852", "#a89c88", "#e6e1d6", "#6f6a62", "#b8a68c"]
	# sofas and sectionals on the open floor, either side of the main aisle
	for cx in [-30.0, -22.0, -13.0, 5.0, 14.0, 23.0]:
		for cz in [-104.5, -114.0, -123.5]:
			if (cx < -26.5 and cz < -110.0) or (cx > 9.5 and cz < -128.0) or LY.claimed(cx, cz, 1.6):
				continue
			var col = Color(fab[rng.randi() % fab.size()])
			var yaw = [0.0, PI * 0.5, PI][rng.randi() % 3]
			sofa(b, Vector3(cx + rng.randf_range(-1.0, 1.0), 0, cz + rng.randf_range(-1.0, 1.0)), yaw, col, rng.randf() < 0.4)
	# dining sets east of the aisle toward the back (IMG_4412 f052-082)
	for cx in [3.5, 7.0]:
		for cz in [-131.0, -134.5]:
			dining(b, Vector3(cx, 0, cz), rng)
	# R3: beds and mattresses on the taupe carpet, white slatwall on the back wall
	for i in 4:
		for j in 2:
			bed(b, Vector3(13.5 + i * 4.3, 0, -143.0 + j * 7.5), Color(["#2b3550", "#e8e6e0", "#3a4566", "#d2d6dc"][(i + j) % 4]))
	r3_slatwall(b)
	# recliners in a row along R2's east side (IMG_4412 f004)
	for k in 10:
		var c = Color(["#3b2e27", "#6a4a34", "#2a2a2c", "#8a7a68"][k % 4])
		chair(b, Vector3(-25.2, 0, -127.0 + k * 1.1), PI * 0.5, c)
	# R1: stainless fridges on the north wall, the TV wall in the navy corner
	b.cur_color = Color("#c3c6ca")
	for k in 8:
		var fx = -37.0 + k * 1.0
		b.box("sr_dress", "sr_steel", Vector3(fx, 0.9, Z_BACK + 0.45), Vector3(0.9, 1.8, 0.75), Transform3D.IDENTITY, [], true)
	block(b, -37.5, Z_BACK, -29.5, Z_BACK + 0.9)
	b.cur_color = Color("#101114")
	for k in 6:
		b.box("sr_dress", "vcolor", Vector3(X0 + 0.08, 1.7, -143.0 + k * 1.15), Vector3(0.06, 0.62, 1.05), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	# rugs under a few groups
	b.cur_color = Color("#bfb5a2")
	for r in [[-31.0, -104.5], [14.0, -114.0], [5.0, -123.5]]:
		if LY.claimed(r[0], r[1]):
			continue
		b.quad("sr_dress", "vcolor_matte", [Vector3(r[0] - 1.8, 0.006, r[1] - 1.3), Vector3(r[0] + 1.8, 0.006, r[1] - 1.3), Vector3(r[0] + 1.8, 0.006, r[1] + 1.3), Vector3(r[0] - 1.8, 0.006, r[1] + 1.3)], Vector3.UP, [], true)
	b.cur_color = Color.WHITE

## R3's white horizontal slatwall on the back wall (the mattress wall, IMG_4412 t042-043).
static func r3_slatwall(b):
	b.cur_color = Color("#f2f1ec")
	var y = 0.3
	while y < 2.6:
		b.box("sr_dress", "vcolor_matte", Vector3(19.5, y, Z_BACK + 0.04), Vector3(18.0, 0.07, 0.03), Transform3D.IDENTITY, [], true)
		y += 0.15
	b.cur_color = Color.WHITE

static func xf(at, yaw):
	return Transform3D(Basis(Vector3.UP, yaw), at)

static func sofa(b, at, yaw, col, sectional):
	var T = xf(at, yaw)
	b.cur_color = col
	var w = 2.3
	b.box("sr_dress", "vcolor_matte", Vector3(0, 0.22, 0), Vector3(w, 0.44, 0.95), T, [], true)
	b.box("sr_dress", "vcolor_matte", Vector3(0, 0.6, 0.38), Vector3(w, 0.5, 0.2), T, [], true)
	for s in [-1.0, 1.0]:
		b.box("sr_dress", "vcolor_matte", Vector3(s * (w * 0.5 - 0.1), 0.32, 0), Vector3(0.2, 0.64, 0.95), T, [], true)
	if sectional:
		b.box("sr_dress", "vcolor_matte", Vector3(w * 0.5 + 0.45, 0.22, -0.4), Vector3(0.9, 0.44, 1.8), T, [], true)
	# an ottoman / coffee table in front
	b.cur_color = col.darkened(0.15) if sectional else Color("#8a6f52")
	b.box("sr_dress", "vcolor_matte", Vector3(0, 0.2, -1.2), Vector3(1.1, 0.4, 0.8), T, [], true)
	b.cur_color = Color.WHITE
	var r = 1.6 if sectional else 1.3
	block(b, at.x - r, at.z - r, at.x + r, at.z + r)

static func chair(b, at, yaw, col):
	var T = xf(at, yaw)
	b.cur_color = col
	b.box("sr_dress", "vcolor", Vector3(0, 0.25, 0), Vector3(0.9, 0.5, 0.9), T, [], true)
	b.box("sr_dress", "vcolor", Vector3(0, 0.75, 0.35), Vector3(0.9, 0.6, 0.2), T, [], true)
	b.cur_color = Color.WHITE
	block(b, at.x - 0.5, at.z - 0.5, at.x + 0.5, at.z + 0.5)

static func dining(b, at, rng):
	b.cur_color = Color(["#5a4030", "#8a6a4a", "#d8d2c4"][rng.randi() % 3])
	b.box("sr_dress", "vcolor_matte", at + Vector3(0, 0.75, 0), Vector3(1.9, 0.05, 0.95), Transform3D.IDENTITY, [], true)
	for s in [Vector3(-0.85, 0.37, -0.4), Vector3(0.85, 0.37, -0.4), Vector3(-0.85, 0.37, 0.4), Vector3(0.85, 0.37, 0.4)]:
		b.box("sr_dress", "vcolor_matte", at + s, Vector3(0.07, 0.74, 0.07), Transform3D.IDENTITY, [], true)
	for k in [-0.5, 0.5]:
		for s in [-0.75, 0.75]:
			b.box("sr_dress", "vcolor_matte", at + Vector3(k, 0.45, s), Vector3(0.45, 0.06, 0.45), Transform3D.IDENTITY, [], true)
			b.box("sr_dress", "vcolor_matte", at + Vector3(k, 0.75, s + sign(s) * 0.21), Vector3(0.45, 0.6, 0.05), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	block(b, at.x - 1.1, at.z - 1.0, at.x + 1.1, at.z + 1.0)

static func bed(b, at, col):
	b.cur_color = Color("#7a6a58")
	b.box("sr_dress", "vcolor_matte", at + Vector3(0, 0.2, 0), Vector3(1.7, 0.4, 2.1), Transform3D.IDENTITY, [], true)
	b.cur_color = col
	b.box("sr_dress", "vcolor_matte", at + Vector3(0, 0.55, 0.05), Vector3(1.6, 0.3, 2.0), Transform3D.IDENTITY, [], true)
	b.cur_color = Color("#d9d4c8")
	b.box("sr_dress", "vcolor_matte", at + Vector3(0, 0.9, -1.08), Vector3(1.75, 1.2, 0.1), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	block(b, at.x - 0.95, at.z - 1.2, at.x + 0.95, at.z + 1.15)

# ------------------------------------------------------------------ materials
static func fill_mat(m, key, b):
	match key:
		"concrete":
			m.albedo_texture = b.tex("sr/concrete.png"); m.roughness = 0.22; m.metallic_specular = 0.6
		"vct95":
			m.albedo_texture = b.tex("sr/vct95.png"); m.roughness = 0.35
		"carpet95":
			m.albedo_texture = b.tex("sr/carpet95.png"); m.roughness = 0.97
		"carpet_taupe":
			m.albedo_texture = b.tex("sr/carpet_taupe.png"); m.roughness = 0.97
		"marble":
			m.albedo_texture = b.tex("sr/marble_vinyl.png"); m.roughness = 0.3
		"panel":
			m.albedo_texture = b.tex("sr/panel.png"); m.roughness = 0.88
		"paint":
			m.albedo_color = Color("#f1f0eb"); m.roughness = 0.9
		"cream":
			m.albedo_color = Color("#ece4d2"); m.roughness = 0.9
		"galv":
			m.albedo_color = Color("#a9adb0"); m.metallic = 0.7; m.roughness = 0.45
		"steel":
			m.albedo_color = Color("#c3c6ca"); m.metallic = 0.8; m.roughness = 0.3
		"frost":
			# frosted/shaded tall windows: bright, a little glow so they read as daylight
			m.albedo_color = Color("#eef2f4"); m.roughness = 0.6
			m.emission_enabled = true; m.emission = Color("#f4f7fa"); m.emission_energy_multiplier = 0.9
			m.set_meta("e_day", 0.9); m.set_meta("e_night", 0.05)
		"sky":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.albedo_color = Color("#bcd6ef")
			m.set_meta("e_day", 1.0)
		_:
			return false
	return true
