## Corn Dog 7 (store s54), built to design/storefronts/corn-dog-7.md from the
## 2024-25 photographs of the unchanged shop: the yellow bullnose sign box with
## its traced lettering, navy tile piers, the checkered tile counter with glass
## cases and hood, the oak-and-glass partition into the kitchen, and a walkable
## dining room with booths and butcher-block tables. Textures: tex/cd7/
## (tools/stores/paint_corn_dog_7.py). Called from build_mall.gd's storefront().
## `b` is the builder (build_mall.gd's SceneTree script); everything goes
## through its quad/box/cyl helpers so it lands in the zone's static mesh.

const OPEN0 = 2.4       # opening along the frontage (metres from the edge's start): the photos give
const OPEN1 = 9.6       # ~7 m between the piers; the unit itself is 12 m and the room uses all of it
const ROOM0 = 0.3       # the room behind the mall wall (the dining room runs left behind it, photo 2)
const ROOM1 = 11.7
const PIER = 0.30
const AWN_Y0 = 2.45     # awning bottom edge (the opening is ~8 ft)
const AWN_FACE = 1.10   # vertical face before the roll: the sign box is ~3/4 of the pier height (photo)
const AWN_R = 0.85      # roll radius; the roll tops out just under the mall ceiling
const AWN_PROJ = 1.00
const AWN_END_R = 0.60  # rounded ends in plan
const PROF_M = 2.435    # profile length painted into awning.png (AWN_FACE + AWN_R * PI / 2)
const PATH_M = 10.1     # sweep length painted into awning.png
const CEIL = 2.9
const DEPTH = 11.0
const COUNTER_D = 3.0
const COUNTER_U0 = 5.2
const COUNTER_H = 1.0
const COUNTER_DEEP = 0.8
const PART_D = 4.5      # oak-and-glass partition into the kitchen
const DINE_U1 = 5.0     # dining room is left of this

const FK = preload("res://tools/stores/food3d/kit.gd")   # FOOD3D (Nov 8 2026): the Blender corn dogs
const CD7_CASE = "res://models/bl_cd7_case/bl_cd7_case.glb"

## FOOD3D (Nov 8 2026; design/godot-blender-pipeline.md "FOOD3D"): one glass case's stock from the bl_cd7_case
## kit: 14 corn dogs standing batter-down in the holder in two rows of seven (a few leaning), and a steel pan of
## cheese on a stick where the yellow block was. Instanced, dynamic: no rebake. cc = the case's centre.
static func case_food(b, cc, t, n, seed):
	var M = FK.meshes(CD7_CASE)
	var rng = RandomNumberGenerator.new()
	rng.seed = 700 + seed
	var dogs = []
	for ri in 2:
		for ci in 7:
			# sunk 35 mm into the holder: they stand in its holes, not on its top
			var dp = cc - t * 0.5 + t * (0.1 * ci) - n * (-0.1 + 0.2 * ri) + Vector3(0, -0.245, 0)
			var bas = Basis(Vector3.UP, rng.randf() * TAU)
			if rng.randf() < 0.25:   # a few lean in their holes
				var ax = Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
				bas = Basis(ax, rng.randf_range(0.12, 0.26)) * bas
			dogs.append(Transform3D(bas, dp + Vector3(rng.randf_range(-0.004, 0.004), 0, rng.randf_range(-0.004, 0.004))))
	FK.multi(b, M.get("dog"), dogs, "cd7_dog", true)
	var pc = cc + Vector3(0, -0.25, 0) + t * 0.42
	var zr = t.cross(Vector3.UP)
	FK.multi(b, M.get("pan"), [Transform3D(Basis(t, Vector3.UP, zr), pc)], "cd7_pan")
	var sticks = []
	for k in 6:
		var flip = 1.0 if k % 2 == 0 else -1.0
		var p = pc + Vector3(0, 0.0016, 0) + n * (-0.112 + 0.045 * k) + t * (0.02 * flip)
		var bas = Basis(t * flip, Vector3.UP, zr * flip).rotated(Vector3.UP, rng.randf_range(-0.08, 0.08))
		sticks.append(Transform3D(bas, p))
	FK.multi(b, M.get("cheese"), sticks, "cd7_cheese")

## Frame helpers: u along the frontage from `a`, d into the store, y up.
static func P(a, t, n, u, y, d):
	return a + t * u - n * d + Vector3(0, y, 0)

static func build(b, g, e, a, bb, n, t, Ln, sd):
	var up = Vector3.UP
	# ---- the mall wall either side of the opening (the mall's own finish), full height
	b.quad(g, "cream", [a, P(a, t, n, OPEN0, 0, 0), P(a, t, n, OPEN0, b.LANE_H, 0), a + Vector3(0, b.LANE_H, 0)], n)
	b.quad(g, "cream", [P(a, t, n, OPEN1, 0, 0), bb, bb + Vector3(0, b.LANE_H, 0), P(a, t, n, OPEN1, b.LANE_H, 0)], n)
	# fire-extinguisher cabinet on the left flank
	b.cur_color = Color("#f2f2ee")
	b.box(g, "vcolor", P(a, t, n, OPEN0 - 0.8, 1.35, -0.04), b.abs_size(t, 0.34, 0.72, 0.08, n))
	b.cur_color = Color("#c8202c")
	b.box(g, "vcolor", P(a, t, n, OPEN0 - 0.8, 1.3, -0.08), b.abs_size(t, 0.1, 0.4, 0.02, n))
	b.cur_color = Color.WHITE
	# ---- piers: navy tile, three faces
	for u0 in [OPEN0, OPEN1 - PIER]:
		var c = P(a, t, n, u0 + PIER * 0.5, AWN_Y0 * 0.5, 0.35 * 0.5 - 0.02)
		b.box(g, "cd7_tile_navy", c, b.abs_size(t, PIER, AWN_Y0, 0.35, n), Transform3D.IDENTITY, ["-y"])
	# ---- oak slats above the awning to the ceiling
	b.quad(g, "cd7_oak_slats", [P(a, t, n, OPEN0, AWN_Y0 + AWN_FACE + AWN_R - 0.02, 0), P(a, t, n, OPEN1, AWN_Y0 + AWN_FACE + AWN_R - 0.02, 0),
		P(a, t, n, OPEN1, b.LANE_H, 0), P(a, t, n, OPEN0, b.LANE_H, 0)], n)
	# ---- the awning
	awning(b, g, a, t, n)
	# ---- the room shell: ceiling, floor, walls (the opening's head above the awning is the oak band)
	var u0 = ROOM0
	var u1 = ROOM1
	# the floor: the opening's threshold, then the whole room
	b.quad(g, "cd7_floor", [P(a, t, n, OPEN0, 0, 0), P(a, t, n, OPEN1, 0, 0), P(a, t, n, OPEN1, 0, 0.3), P(a, t, n, OPEN0, 0, 0.3)], up, [], false, 1.0 / 1.2)
	b.quad(g, "cd7_floor", [P(a, t, n, u0, 0, 0.3), P(a, t, n, u1, 0, 0.3), P(a, t, n, u1, 0, DEPTH), P(a, t, n, u0, 0, DEPTH)], up, [], false, 1.0 / 1.2)
	b.quad(g, "cd7_ceiling", [P(a, t, n, u0, CEIL, 0.3), P(a, t, n, u0, CEIL, DEPTH), P(a, t, n, u1, CEIL, DEPTH), P(a, t, n, u1, CEIL, 0.3)], Vector3.DOWN, [], false, 1.0 / 2.4)
	# soffit under the opening head, and the jambs (the mall wall's thickness) either side
	b.quad(g, "cd7_soffit", [P(a, t, n, OPEN0, AWN_Y0, 0), P(a, t, n, OPEN0, AWN_Y0, 0.3), P(a, t, n, OPEN1, AWN_Y0, 0.3), P(a, t, n, OPEN1, AWN_Y0, 0)], Vector3.DOWN)
	# side and back walls of the room
	b.quad(g, "cd7_wall_yellow", [P(a, t, n, u0, 0, 0.3), P(a, t, n, u0, 0, DEPTH), P(a, t, n, u0, CEIL, DEPTH), P(a, t, n, u0, CEIL, 0.3)], t, [], false, 1.0 / 2.9)
	b.quad(g, "cd7_wall_yellow", [P(a, t, n, u1, 0, DEPTH), P(a, t, n, u1, 0, 0.3), P(a, t, n, u1, CEIL, 0.3), P(a, t, n, u1, CEIL, DEPTH)], -t, [], false, 1.0 / 2.9)
	b.quad(g, "cd7_wall_yellow", [P(a, t, n, u1, 0, DEPTH), P(a, t, n, u0, 0, DEPTH), P(a, t, n, u0, CEIL, DEPTH), P(a, t, n, u1, CEIL, DEPTH)], n, [], false, 1.0 / 2.9)
	# the inside of the front wall either side of the opening, and over it up to the room's ceiling
	b.quad(g, "cd7_wall_yellow", [P(a, t, n, u0, 0, 0.3), P(a, t, n, OPEN0, 0, 0.3), P(a, t, n, OPEN0, CEIL, 0.3), P(a, t, n, u0, CEIL, 0.3)], -n, [], false, 1.0 / 2.9)
	b.quad(g, "cd7_wall_yellow", [P(a, t, n, OPEN1, 0, 0.3), P(a, t, n, u1, 0, 0.3), P(a, t, n, u1, CEIL, 0.3), P(a, t, n, OPEN1, CEIL, 0.3)], -n, [], false, 1.0 / 2.9)
	b.quad(g, "cd7_soffit", [P(a, t, n, OPEN0, AWN_Y0, 0.3), P(a, t, n, OPEN1, AWN_Y0, 0.3), P(a, t, n, OPEN1, CEIL, 0.3), P(a, t, n, OPEN0, CEIL, 0.3)], -n)
	# the walls' ends at the opening (behind the piers)
	b.quad(g, "cd7_soffit", [P(a, t, n, OPEN0, 0, 0), P(a, t, n, OPEN0, 0, 0.3), P(a, t, n, OPEN0, AWN_Y0, 0.3), P(a, t, n, OPEN0, AWN_Y0, 0)], t)
	b.quad(g, "cd7_soffit", [P(a, t, n, OPEN1, 0, 0.3), P(a, t, n, OPEN1, 0, 0), P(a, t, n, OPEN1, AWN_Y0, 0), P(a, t, n, OPEN1, AWN_Y0, 0.3)], -t)
	for wr in [[0.0, OPEN0], [OPEN1, 12.0]]:
		var w0 = P(a, t, n, wr[0], 0, -0.05)
		var w1 = P(a, t, n, wr[1], 0, 0.35)
		b.obst(["rect", min(w0.x, w1.x), min(w0.z, w1.z), max(w0.x, w1.x), max(w0.z, w1.z)])
	# ---- ceiling troffers on a 2.4 m grid, each lit
	var dd = 1.5
	while dd < DEPTH - 0.6:
		var uu = u0 + 1.4
		while uu < u1 - 0.6:
			var c = P(a, t, n, uu, CEIL - 0.01, dd)
			b.quad(g, "cd7_troffer", [c - t * 0.3 - n * 0.6, c - t * 0.3 + n * 0.6, c + t * 0.3 + n * 0.6, c + t * 0.3 - n * 0.6], Vector3.DOWN,
				[Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)])
			var l = b.add_omni(c + Vector3(0, -0.3, 0), 0.3, 4.5, Color(1.0, 0.97, 0.9))
			b.tag(l, "", 0.3, 0.4)
			uu += 2.4
		dd += 2.4
	# ---- the counter: tiled front with a chamfered left end, stainless top, cases, hood
	counter(b, g, a, t, n)
	# ---- the oak-and-glass partition into the kitchen, menu TVs, the kitchen beyond
	partition(b, g, a, t, n)
	# ---- the dining room
	dining(b, g, a, t, n)
	# ---- obstacles (the walk grid itself is opened by tools/open_interiors.py)
	var k0 = P(a, t, n, COUNTER_U0, 0, COUNTER_D)
	var k1 = P(a, t, n, u1, 0, DEPTH)
	b.obst(["rect", min(k0.x, k1.x), min(k0.z, k1.z), max(k0.x, k1.x), max(k0.z, k1.z)])
	var pl = P(a, t, n, DINE_U1, 0, 3.5)
	var pr = P(a, t, n, DINE_U1 + 0.1, 0, 8.0)
	b.obst(["rect", min(pl.x, pr.x), min(pl.z, pr.z), max(pl.x, pr.x), max(pl.z, pr.z)])
	# the store's own reflection probe, so its glazed tile and steel reflect the shop and not the hall
	var rp = ReflectionProbe.new()
	var mid = P(a, t, n, (ROOM0 + ROOM1) * 0.5, CEIL * 0.5, DEPTH * 0.5)
	rp.position = mid
	rp.size = (t * (ROOM1 - ROOM0) + n * DEPTH).abs() + Vector3(0.2, CEIL + 0.1, 0.2)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.8
	b.light_root.add_child(rp)
	# a soft light under the awning
	var sl = b.add_spot(P(a, t, n, (OPEN0 + OPEN1) * 0.5, AWN_Y0 - 0.05, -0.5), Vector3.DOWN, 1.2, 5.0, 80.0, Color(1.0, 0.97, 0.88))
	b.tag(sl, "", 0.6, 1.2)

## The sign box: a profile (vertical face, then a quarter round back to the wall)
## swept along a path with rounded ends; u follows the path, v the profile, to
## match awning.png (u in metres / PATH_M, v = 1 - metres up the profile / PROF_M).
static func awning(b, g, a, t, n):
	var segs_prof = 10
	var prof = []   # [offset out from the wall plane (m), height above AWN_Y0, metres along profile]
	prof.append([AWN_PROJ, 0.0, 0.0])
	prof.append([AWN_PROJ, AWN_FACE, AWN_FACE])
	for i in range(1, segs_prof + 1):
		var ang = PI * 0.5 * i / segs_prof
		var out = AWN_PROJ - AWN_R + AWN_R * cos(ang)
		var hgt = AWN_FACE + AWN_R * sin(ang)
		prof.append([out, hgt, AWN_FACE + AWN_R * ang])
	# the sweep path in plan: left end (quarter arc), the straight front, right end
	var path = []   # [u, out-scale (0..1), metres along path, outward direction]
	var ul = OPEN0 - 0.2 + AWN_END_R
	var ur = OPEN1 + 0.2 - AWN_END_R
	var segs_end = 8
	var s = 0.0
	for i in range(segs_end + 1):
		var ang = PI * 0.5 * (1.0 - float(i) / segs_end)   # from along the wall to straight out
		path.append([ul - AWN_END_R * sin(ang), cos(ang), s, Vector2(-sin(ang), cos(ang))])
		s += PI * 0.5 * AWN_END_R / segs_end
	s -= PI * 0.5 * AWN_END_R / segs_end
	s += (ur - ul)
	path.append([ur, 1.0, s, Vector2(0, 1)])
	for i in range(1, segs_end + 1):
		var ang = PI * 0.5 * float(i) / segs_end
		s += PI * 0.5 * AWN_END_R / segs_end
		path.append([ur + AWN_END_R * sin(ang), cos(ang), s, Vector2(sin(ang), cos(ang))])
	var total = s
	var pts = []
	for k in path.size():
		var row = []
		for q in prof:
			# the rounded ends: the profile's outward offset follows the plan arc (scaled), the height stays
			var dir = path[k][3]
			var out = q[0]
			var pos = a + t * (path[k][0] + dir.x * out) + n * (dir.y * out) + Vector3(0, AWN_Y0 + q[1], 0)
			row.append(pos)
		pts.append(row)
	for k in path.size() - 1:
		for j in prof.size() - 1:
			var u0 = path[k][2] / total * (PATH_M / PATH_M)
			var u1 = path[k + 1][2] / total
			var v0 = 1.0 - prof[j][2] / PROF_M
			var v1 = 1.0 - prof[j + 1][2] / PROF_M
			var p00 = pts[k][j]
			var p10 = pts[k + 1][j]
			var p11 = pts[k + 1][j + 1]
			var p01 = pts[k][j + 1]
			var nn = (p10 - p00).cross(p01 - p00).normalized()
			if nn.dot(n) < 0 and j < 2:
				nn = -nn
			b.quad(g, "cd7_awning", [p00, p10, p11, p01], nn, [Vector2(u0, v0), Vector2(u1, v0), Vector2(u1, v1), Vector2(u0, v1)])
	# the cap from the roll's crest back to the wall
	var last = prof.size() - 1
	for k in path.size() - 1:
		var q0 = pts[k][last]
		var q1 = pts[k + 1][last]
		var w0 = a + t * path[k][0] + Vector3(0, AWN_Y0 + AWN_FACE + AWN_R, 0)
		var w1 = a + t * path[k + 1][0] + Vector3(0, AWN_Y0 + AWN_FACE + AWN_R, 0)
		b.quad(g, "cd7_soffit", [q0, q1, w1, w0], Vector3.UP)
	# underside: white soffit with the recessed strip light, and the aluminium trim along the bottom edge
	var row0 = pts[0]
	var under = []
	for k in path.size():
		under.append(pts[k][0])
	var wall_l = a + t * (OPEN0 - 0.2) + Vector3(0, AWN_Y0, 0)
	var wall_r = a + t * (OPEN1 + 0.2) + Vector3(0, AWN_Y0, 0)
	for k in path.size() - 1:
		var q0 = under[k]
		var q1 = under[k + 1]
		var w0 = a + t * path[k][0] + Vector3(0, AWN_Y0, 0)
		var w1 = a + t * path[k + 1][0] + Vector3(0, AWN_Y0, 0)
		b.quad(g, "cd7_soffit", [q0, w0, w1, q1], Vector3.DOWN)
		# trim strip hanging 4 cm below the edge
		b.quad(g, "cd7_steel", [q0 - Vector3(0, 0.04, 0), q1 - Vector3(0, 0.04, 0), q1, q0], (q1 - q0).cross(Vector3.UP).normalized() * -1.0)
	# the strip light under the awning
	var c = a + t * (OPEN0 + OPEN1) * 0.5 + n * (AWN_PROJ * 0.5) + Vector3(0, AWN_Y0 - 0.005, 0)
	b.quad(g, "cd7_troffer", [c - t * 3.0 - n * 0.12, c - t * 3.0 + n * 0.12, c + t * 3.0 + n * 0.12, c + t * 3.0 - n * 0.12], Vector3.DOWN,
		[Vector2(0, 0), Vector2(0, 1), Vector2(1, 1), Vector2(1, 0)])

static func counter(b, g, a, t, n):
	var u0 = COUNTER_U0
	var u1 = ROOM1
	var ch = 0.5   # chamfer
	var d0 = COUNTER_D
	var d1 = COUNTER_D + COUNTER_DEEP
	# front face (tiled), chamfer, left return
	var f0 = P(a, t, n, u0 + ch, 0, d0)
	var f1 = P(a, t, n, u1, 0, d0)
	b.quad(g, "cd7_counter_front", [f0, f1, f1 + Vector3(0, COUNTER_H, 0), f0 + Vector3(0, COUNTER_H, 0)], n)
	var c0 = P(a, t, n, u0, 0, d0 + ch)
	var cn = (n - t).normalized()
	b.quad(g, "cd7_counter_front", [c0, f0, f0 + Vector3(0, COUNTER_H, 0), c0 + Vector3(0, COUNTER_H, 0)], cn)
	var l0 = P(a, t, n, u0, 0, d1)
	b.quad(g, "cd7_counter_front", [l0, c0, c0 + Vector3(0, COUNTER_H, 0), l0 + Vector3(0, COUNTER_H, 0)], -t)
	# stainless top with a 5 cm overhang
	var top = [P(a, t, n, u0 - 0.05, COUNTER_H, d1), P(a, t, n, u0 - 0.05, COUNTER_H, d0 + ch - 0.05), P(a, t, n, u0 + ch, COUNTER_H, d0 - 0.05),
		P(a, t, n, u1, COUNTER_H, d0 - 0.05), P(a, t, n, u1, COUNTER_H, d1)]
	for i in range(1, top.size() - 1):
		b.quad(g, "cd7_steel", [top[0], top[i], top[i + 1], top[i + 1]], Vector3.UP)
	b.quad(g, "cd7_steel", [top[0] - Vector3(0, 0.04, 0), top[0], top[4], top[4] - Vector3(0, 0.04, 0)], -n)
	b.box(g, "cd7_steel", P(a, t, n, (u0 + ch + u1) * 0.5, COUNTER_H - 0.02, d0 - 0.025), b.abs_size(t, u1 - u0 - ch, 0.04, 0.05, n))
	# glass food cases on the counter, lit inside
	var uu = u0 + 0.8
	while uu + 1.2 <= OPEN1 - 0.4:
		var cc = P(a, t, n, uu + 0.6, COUNTER_H + 0.27, d0 + 0.32)
		b.quad("cd7_glass", "cd7_glass", [cc + t * 0.6 - n * 0.27 - Vector3(0, 0.25, 0), cc - t * 0.6 - n * 0.27 - Vector3(0, 0.25, 0),
			cc - t * 0.6 - n * 0.27 + Vector3(0, 0.25, 0), cc + t * 0.6 - n * 0.27 + Vector3(0, 0.25, 0)], n, [], true)
		b.box(g, "cd7_steel", cc + Vector3(0, 0.26, 0), b.abs_size(t, 1.2, 0.03, 0.55, n))
		b.box(g, "cd7_steel", cc + Vector3(0, -0.26, 0), b.abs_size(t, 1.2, 0.02, 0.55, n))
		for side in [-1.0, 1.0]:
			b.box(g, "cd7_steel", cc + t * (0.6 * side), b.abs_size(t, 0.03, 0.5, 0.55, n))
		# food inside: corn dogs standing in a steel holder, a pan of fries
		b.box(g, "cd7_steel", cc + Vector3(0, -0.23, 0) - t * 0.15, b.abs_size(t, 0.8, 0.04, 0.4, n))
		if FK.meshes(CD7_CASE).is_empty() or b.mall == null:
			for ri in 2:
				for ci in 7:
					var dp = cc - t * 0.5 + t * (0.1 * ci) - n * (-0.1 + 0.2 * ri) + Vector3(0, -0.21, 0)
					b.cur_color = Color("#a8662a")
					b.cyl(g, "vcolor_matte", dp, 0.024, 0.02, 0.15, 8, true)
					b.cur_color = Color("#e8d2a0")
					b.cyl(g, "vcolor_matte", dp + Vector3(0, 0.15, 0), 0.004, 0.004, 0.07, 4, true)
			b.cur_color = Color("#d9a43a")
			b.box(g, "vcolor_matte", cc + Vector3(0, -0.19, 0) + t * 0.42, b.abs_size(t, 0.26, 0.09, 0.32, n))
			b.cur_color = Color.WHITE
		else:
			case_food(b, cc, t, n, int(uu * 10))
		var cl = b.add_omni(cc + Vector3(0, 0.18, 0), 0.25, 1.6, Color(1.0, 0.9, 0.7))
		b.tag(cl, "", 0.25, 0.4)
		uu += 1.3
	# the condiment table on casters against the counter's right end
	b.box(g, "cd7_steel", P(a, t, n, OPEN1 - 0.75, 0.84, d0 - 0.35), b.abs_size(t, 0.7, 0.03, 0.5, n))
	b.box(g, "cd7_steel", P(a, t, n, OPEN1 - 0.75, 0.3, d0 - 0.35), b.abs_size(t, 0.66, 0.02, 0.46, n))
	for q in [[-0.32, -0.22], [0.32, -0.22], [-0.32, 0.22], [0.32, 0.22]]:
		b.box(g, "cd7_steel", P(a, t, n, OPEN1 - 0.75 + q[0], 0.42, d0 - 0.35 + q[1]), b.abs_size(t, 0.03, 0.84, 0.03, n))
	b.cur_color = Color("#e8d24a")
	b.cyl(g, "vcolor", P(a, t, n, OPEN1 - 0.9, 0.86, d0 - 0.3), 0.05, 0.05, 0.22, 10)
	b.cur_color = Color("#b43a2a")
	b.cyl(g, "vcolor", P(a, t, n, OPEN1 - 0.65, 0.86, d0 - 0.3), 0.05, 0.05, 0.22, 10)
	b.cur_color = Color.WHITE
	# stainless hood canopy over the back counter
	b.box(g, "cd7_steel", P(a, t, n, 6.8, 2.3, 4.0), b.abs_size(t, 2.4, 0.6, 0.8, n))
	# the back counter line (worktop) between the counter and the partition
	b.box(g, "cd7_steel", P(a, t, n, (u0 + u1) * 0.5, 0.45, d1 + 0.35), b.abs_size(t, u1 - u0, 0.9, 0.6, n))

static func partition(b, g, a, t, n):
	var u0 = COUNTER_U0
	var u1 = ROOM1
	var d = PART_D
	# solid oak below 1.1 m, glass panels to 2.4 m between oak posts, oak header
	b.quad(g, "cd7_oak_slats", [P(a, t, n, u0, 0, d), P(a, t, n, u1, 0, d), P(a, t, n, u1, 1.1, d), P(a, t, n, u0, 1.1, d)], n)
	b.cur_color = Color("#9a6a3a")
	b.box(g, "vcolor", P(a, t, n, (u0 + u1) * 0.5, 1.12, d), b.abs_size(t, u1 - u0, 0.06, 0.12, n))
	b.box(g, "vcolor", P(a, t, n, (u0 + u1) * 0.5, 2.42, d), b.abs_size(t, u1 - u0, 0.08, 0.12, n))
	var uu = u0
	while uu <= u1 + 0.01:
		b.box(g, "vcolor", P(a, t, n, uu, 1.75, d), b.abs_size(t, 0.08, 1.3, 0.1, n))
		uu += 1.2
	b.cur_color = Color.WHITE
	b.quad("cd7_glass", "cd7_glass", [P(a, t, n, u0, 1.15, d), P(a, t, n, u1, 1.15, d), P(a, t, n, u1, 2.4, d), P(a, t, n, u0, 2.4, d)], n, [], true)
	# two backlit menu boxes hung over the right end of the counter, angled down toward the queue
	for um in [7.9, 8.95]:
		var c = P(a, t, n, um, 2.5, d - 0.35)
		var w = 0.9
		var h = 0.5
		var tilt = Basis(t, 0.3)   # rotate about t so the screen's face turns down toward the queue
		var hv = tilt * Vector3(0, h * 0.5, 0)
		var pA = c - t * (w * 0.5) - hv
		var pB = c + t * (w * 0.5) - hv
		var pC = c + t * (w * 0.5) + hv
		var pD = c - t * (w * 0.5) + hv
		b.quad("cd7_screens", "cd7_menu", [pA, pB, pC, pD], (tilt * n).normalized(), [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
		# the lightbox's brushed aluminium case behind the panel (1995: a backlit menu box, not a TV)
		b.cur_color = Color("#b8bcc2")
		b.box(g, "vcolor", Vector3.ZERO, Vector3(0.96, 0.57, 0.12), Transform3D(Basis.looking_at(-n, Vector3.UP) * Basis(Vector3.RIGHT, 0.3), c - (tilt * n) * 0.065), [], true)
		b.cur_color = Color.WHITE
	# the kitchen beyond: dim walls, stainless shelving, the fryers' glow
	var kd0 = d + 0.1
	b.cur_color = Color("#d8d4c8")
	b.box(g, "vcolor_matte", P(a, t, n, 7.0, 1.0, DEPTH - 0.3), b.abs_size(t, 2.4, 2.0, 0.5, n))
	b.cur_color = Color.WHITE
	b.box(g, "cd7_steel", P(a, t, n, 9.5, 1.0, DEPTH - 0.4), b.abs_size(t, 1.6, 1.8, 0.6, n))
	b.box(g, "cd7_steel", P(a, t, n, 6.0, 0.9, kd0 + 1.2), b.abs_size(t, 1.8, 0.9, 0.8, n))
	var kl = b.add_omni(P(a, t, n, 7.5, 2.5, kd0 + 2.0), 0.35, 5.0, Color(1.0, 0.95, 0.85))
	b.tag(kl, "", 0.35, 0.5)

static func dining(b, g, a, t, n):
	var u0 = ROOM0
	var u1 = DINE_U1
	# the oak half-wall with glass that divides the dining room from the queue, plants on top
	var pd0 = 3.5
	var pd1 = 8.0
	b.cur_color = Color("#9a6a3a")
	b.box(g, "vcolor", P(a, t, n, u1, 0.55, (pd0 + pd1) * 0.5), b.abs_size(t, 0.12, 1.1, pd1 - pd0, n))
	b.box(g, "vcolor", P(a, t, n, u1, 1.12, (pd0 + pd1) * 0.5), b.abs_size(t, 0.16, 0.05, pd1 - pd0, n))
	b.box(g, "vcolor", P(a, t, n, u1, 2.22, (pd0 + pd1) * 0.5), b.abs_size(t, 0.12, 0.06, pd1 - pd0, n))
	var dq = pd0
	while dq <= pd1 + 0.01:
		b.box(g, "vcolor", P(a, t, n, u1, 1.65, dq), b.abs_size(t, 0.1, 1.1, 0.08, n))
		dq += 0.9
	b.cur_color = Color.WHITE
	b.quad("cd7_glass", "cd7_glass", [P(a, t, n, u1, 1.15, pd0), P(a, t, n, u1, 1.15, pd1), P(a, t, n, u1, 2.2, pd1), P(a, t, n, u1, 2.2, pd0)], t, [], true)
	# silk plants trailing from planters along the top of the screen
	for dd in [pd0 + 0.45, pd0 + 1.8, pd1 - 1.8, pd1 - 0.45]:
		b.cur_color = Color("#6b4a2a")
		b.box(g, "vcolor_matte", P(a, t, n, u1, 2.35, dd), b.abs_size(t, 0.3, 0.2, 0.3, n))
		b.cur_color = Color.WHITE
		b.bush(P(a, t, n, u1, 2.42, dd), "leafy", 0.5, 7)
	# three booths along the left wall: oak ends, dark red seats, butcher-block tables
	var dd = 3.0
	for i in 5:
		booth(b, g, a, t, n, u0, dd)
		dd += 1.6
	# two four-tops in the open floor
	for q in [[3.3, 4.4], [3.3, 7.0], [3.3, 9.6]]:
		table(b, g, a, t, n, q[0], q[1])

static func booth(b, g, a, t, n, u0, d0):
	var L = 1.3
	var tw = 1.2   # table + benches across (into the room from the wall)
	# benches at both ends of the table run along u (against the wall the booth's back is the wall)
	b.cur_color = Color("#4e2a22")   # dark oxblood vinyl
	for off in [0.0, L - 0.45]:
		b.box(g, "vcolor_matte", P(a, t, n, u0 + 0.65, 0.42, d0 + off + 0.225), b.abs_size(t, 1.1, 0.12, 0.45, n))     # seat
		b.box(g, "vcolor_matte", P(a, t, n, u0 + 0.65, 0.75, d0 + off + (0.06 if off == 0.0 else 0.39)), b.abs_size(t, 1.1, 0.55, 0.1, n))  # back
	b.cur_color = Color("#9a6a3a")
	for off in [0.0, L - 0.45]:
		b.box(g, "vcolor", P(a, t, n, u0 + 0.65, 0.2, d0 + off + 0.225), b.abs_size(t, 1.1, 0.4, 0.45, n))    # plinth
		b.box(g, "vcolor", P(a, t, n, u0 + 1.2, 0.55, d0 + off + 0.225), b.abs_size(t, 0.06, 1.1, 0.45, n))   # oak end panel
	# the divider between booths rises as an oak frame with glass, a plant on top (photo from the left)
	b.box(g, "vcolor", P(a, t, n, u0 + 0.65, 1.55, d0 + 0.03), b.abs_size(t, 1.2, 0.06, 0.06, n))
	b.box(g, "vcolor", P(a, t, n, u0 + 0.65, 2.0, d0 + 0.03), b.abs_size(t, 1.2, 0.06, 0.08, n))
	b.box(g, "vcolor", P(a, t, n, u0 + 1.22, 1.55, d0 + 0.03), b.abs_size(t, 0.07, 0.95, 0.07, n))
	b.cur_color = Color.WHITE
	b.quad("cd7_glass", "cd7_glass", [P(a, t, n, u0, 1.08, d0 + 0.03), P(a, t, n, u0 + 1.2, 1.08, d0 + 0.03), P(a, t, n, u0 + 1.2, 1.97, d0 + 0.03), P(a, t, n, u0, 1.97, d0 + 0.03)], n, [], true)
	b.cur_color = Color("#6b4a2a")
	b.box(g, "vcolor_matte", P(a, t, n, u0 + 0.9, 2.12, d0 + 0.03), b.abs_size(t, 0.26, 0.18, 0.22, n))
	b.cur_color = Color.WHITE
	b.bush(P(a, t, n, u0 + 0.9, 2.18, d0 + 0.03), "leafy", 0.45, 6)
	b.box(g, "cd7_butcher", P(a, t, n, u0 + 0.62, 0.74, d0 + L * 0.5), b.abs_size(t, 1.05, 0.05, 0.6, n))
	b.cur_color = Color("#2a2a2e")
	b.box(g, "vcolor", P(a, t, n, u0 + 0.9, 0.36, d0 + L * 0.5), b.abs_size(t, 0.08, 0.72, 0.08, n))
	b.cur_color = Color.WHITE
	var p0 = P(a, t, n, u0, 0, d0)
	var p1 = P(a, t, n, u0 + 1.25, 0, d0 + L)
	b.obst(["rect", min(p0.x, p1.x), min(p0.z, p1.z), max(p0.x, p1.x), max(p0.z, p1.z)])

static func table(b, g, a, t, n, u, d):
	var c = P(a, t, n, u, 0, d)
	b.box(g, "cd7_butcher", c + Vector3(0, 0.74, 0), Vector3(0.78, 0.04, 0.78))
	b.cur_color = Color("#202024")
	b.box(g, "vcolor", c + Vector3(0, 0.37, 0), Vector3(0.08, 0.72, 0.08))
	b.box(g, "vcolor", c + Vector3(0, 0.02, 0), Vector3(0.5, 0.04, 0.5))
	for q in [[-0.6, 0.0], [0.6, 0.0], [0.0, -0.6], [0.0, 0.6]]:
		var cc = c + t * q[0] - n * q[1]
		b.box(g, "vcolor", cc + Vector3(0, 0.45, 0), Vector3(0.42, 0.04, 0.42))
		var back_dir = (cc - c).normalized()
		b.box(g, "vcolor", cc + back_dir * 0.2 + Vector3(0, 0.72, 0), Vector3(0.42 if abs(back_dir.z) > 0.5 else 0.04, 0.5, 0.42 if abs(back_dir.x) > 0.5 else 0.04))
		for leg in [[-0.18, -0.18], [0.18, -0.18], [-0.18, 0.18], [0.18, 0.18]]:
			b.box(g, "vcolor", cc + Vector3(leg[0], 0.22, leg[1]), Vector3(0.025, 0.44, 0.025))
	b.cur_color = Color.WHITE
	b.obst([c.x, c.z, 0.85])
