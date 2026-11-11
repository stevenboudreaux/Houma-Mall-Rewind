## EXT-DOCKS (Nov 11 2026, branch ws/ext-docks): the two loading docks of wing 3, both years.
## design/exterior/docks-2026-11-11.md (the frame study), design/godot-exterior.md "Workstream EXT-DOCKS".
##
## Steven, Demo 53: (A) Dillard's dock, trailer and "green rectangle" stood in front of the long brick wing
## wall; they belong behind it, through an opening "around where the red line is". (B) JCPenney's dock stood on
## the face with the sign; it belongs on the side face, a tree between it and the tank. (C) the green boxes are
## dumpsters / compactors: kept, textured (the Blender model bl_ex_dumpster), placed as filmed.
##
## A. dillards(): the court behind the wing wall's line (wall_fixes.py: the wing fill stops at x -52), x -52..-38,
##    z 100..118: a two-bay dock under a low brown canopy on the court's back wall, a trailer in bay 1, the
##    roll-off beside it, the wood-plank enclosure at the court's mouth, Dillard's white base with its doors and
##    FDC (IMG_4490 f013-f027).
## B. jcpenney(): docks 1-2 on the east face at the NE corner under the red corrugated canopy, the raised dock,
##    steps, man door, the compactor pointing east, the galvanized rail along the apron's north edge, a live oak
##    and hollies in a bed between the apron and the tank yard (IMG_4486 f102-f110).
## Called from exterior.gd (hunks marked EXT-DOCKS). EX is exterior.gd itself (its trailer(), fence(), bollard()).
extends RefCounted

const UP = Vector3.UP
const FL = preload("res://tools/exterior/flora.gd")
const DUMPSTER = "res://models/bl_ex_dumpster/bl_ex_dumpster.glb"

## The court behind the wing wall at Dillard's: x0, z0 (the back wall), x1 (the wing's old end; the 4 m service
## lane runs on to Dillard's west face at x -38), z1 (the wing wall's line).
const COURT = [-52.0, 100.0, -42.0, 118.0]
const DILLARDS_W = -38.0
## JCPenney's NE corner: the docks run south from it on the east face.
const JCP_NE = Vector3(-154.0, 0.0, -14.0)

static var EX = null
static var _mesh = null
static var _saved = {}

## A wall run of the dock court (the wing block's east wall and the court's back wall): exterior.gd skins both
## as the wing wall (5 m, the year's finish) and keeps the sidewalk, curb and fire lane off them.
static func court_wall(seg) -> bool:
	var ax = float(seg.a[0]); var az = float(seg.a[1]); var bx = float(seg.b[0]); var bz = float(seg.b[1])
	return min(ax, bx) >= COURT[0] - 0.01 and max(ax, bx) <= COURT[2] + 0.01 and min(az, bz) >= COURT[1] - 0.01 and max(az, bz) <= COURT[3] + 0.01

## JCPenney's east face (the dock face): no customer walk, curb or fire lane along it.
static func jcp_dock_face(seg) -> bool:
	return seg.name == "JCPENNEY" and seg.side == "E"

static func service_face(seg) -> bool:
	return court_wall(seg) or jcp_dock_face(seg)

static func _run(b, g, mname, a, t, n, u0, u1, y0, y1, out, deep, skip = []):
	var c = a + t * ((u0 + u1) * 0.5) + UP * ((y0 + y1) * 0.5) + n * (out - deep * 0.5)
	b.box(g, mname, c, b.abs_size(t, u1 - u0, y1 - y0, deep, n), Transform3D.IDENTITY, skip)

## The roll-off container (bl_ex_dumpster: 6.4 x 2.3 x 2.1 m, the nose at local +z) on a concrete pad. `nose`
## points from the door end to the nose. A dynamic mesh like the signs (no lightmap of its own).
static func dumpster(b, at: Vector3, nose: Vector3, label: String):
	var z = nose.normalized()
	var x = UP.cross(z).normalized()
	var hx = 3.5 * abs(z.x) + 1.45 * abs(x.x); var hz = 3.5 * abs(z.z) + 1.45 * abs(x.z)
	# the pad: a 10 cm slab, broom-finished, a little wider than the skids
	b.box("ex_entry", "ex_walk", at + UP * 0.03, Vector3(hx * 2.0, 0.06, hz * 2.0), Transform3D.IDENTITY, ["-y"])
	b.obst(["rect", at.x - hx + 0.2, at.z - hz + 0.2, at.x + hx - 0.2, at.z + hz - 0.2])
	if _mesh == null and ResourceLoader.exists(DUMPSTER):
		var root = load(DUMPSTER).instantiate()
		var mis = root.find_children("*", "MeshInstance3D", true, false)
		if not mis.is_empty():
			_mesh = mis[0].mesh.duplicate()
		root.free()
	if _mesh == null or b.mall == null:
		# the model is missing: a plain green box so the build still says where it stands
		b.box("ex_props", "ex_dock_green", at + UP * 1.2, Vector3(hx * 2.0 - 0.6, 2.0, hz * 2.0 - 0.6))
		return
	var gp = String(b.GEN) + "exd_dumpster.res"
	if not _saved.has(gp):
		ResourceSaver.save(_mesh, gp)
		_saved[gp] = true
	var mi = MeshInstance3D.new()
	mi.mesh = load(gp)
	mi.transform = Transform3D(Basis(x, UP, z), at + UP * 0.06)
	mi.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var h = b.mall.get_node_or_null("ExDocks")
	if h == null:
		h = Node3D.new()
		h.name = "ExDocks"
		b.mall.add_child(h)
		h.owner = b.mall
	mi.name = label
	h.add_child(mi)
	mi.owner = b.mall

## One dock position on a wall: a roll-up door (sill `sill`) in a black foam seal (head curtain, side pads with
## yellow guide strips), rubber bumpers under it.
static func dock_door(b, a, t, n, u, w, sill, head, door_mat):
	var g = "ex_entry"
	_run(b, g, door_mat, a, t, n, u - w * 0.5, u + w * 0.5, sill, head, 0.04, 0.04)
	var k = sill + 0.3
	while k < head - 0.05:                                   # the curtain's slats
		_run(b, g, "ex_coping", a, t, n, u - w * 0.5, u + w * 0.5, k - 0.012, k + 0.012, 0.05, 0.015)
		k += 0.3
	_run(b, g, "ex_black_steel", a, t, n, u - w * 0.5 - 0.35, u + w * 0.5 + 0.35, head, head + 0.45, 0.5, 0.5)
	for sd in [-1.0, 1.0]:
		var e = u + sd * (w * 0.5 + 0.175)
		_run(b, g, "ex_black_steel", a, t, n, e - 0.175, e + 0.175, sill, head, 0.45, 0.45)
		_run(b, g, "ex_pipe_yellow", a, t, n, e - sd * 0.1 - 0.05, e - sd * 0.1 + 0.05, sill + 0.1, head - 0.1, 0.47, 0.03)
		_run(b, g, "ex_black_steel", a, t, n, u + sd * (w * 0.5 - 0.3) - 0.15, u + sd * (w * 0.5 - 0.3) + 0.15, sill - 0.5, sill - 0.05, 0.12, 0.12)

# ---------------------------------------------------------------------------------------------- A. Dillard's
static func dillards(b):
	if EX == null:
		EX = load("res://tools/exterior/exterior.gd")
	var g = "ex_entry"
	var x0 = COURT[0]; var z0 = COURT[1]; var x1 = COURT[2]; var z1 = COURT[3]
	var a = Vector3(x0, 0, z0); var t = Vector3(1, 0, 0); var n = Vector3(0, 0, 1)
	var W = x1 - x0
	# the low flat canopy with its brown fascia over both positions (f026: underside ~4.3 m, ~3.5 m out)
	_run(b, g, "ex_canopy_brown", a, t, n, 0.0, W, 4.3, 4.9, 3.6, 3.6, ["-y"])
	b.quad(g, "ex_soffit_white", [a + UP * 4.29, a + t * W + UP * 4.29, a + t * W + n * 3.6 + UP * 4.29, a + n * 3.6 + UP * 4.29], -UP)
	for u in [3.0, 7.0]:
		b.box(g, "ex_lamp", a + t * u + n * 1.8 + UP * 4.26, Vector3(1.2, 0.05, 0.2))
		b.tag(b.add_spot(a + t * u + n * 1.8 + UP * 4.2, -UP, 1.2, 7.0, 70.0, Color("#FFE6C2")), "night")
	# the dock's face: a concrete band to the sill, bay 1 (the trailer backs onto it) and bay 2 (open, f026-f027)
	_run(b, g, "ex_curb", a, t, n, 3.2, W, 0.0, 1.2, 0.1, 0.1)
	dock_door(b, a, t, n, 4.8, 2.6, 1.2, 3.9, "ex_steel")
	dock_door(b, a, t, n, 8.2, 2.6, 1.2, 3.9, "ex_steel")
	for u in [6.5, 9.85]:                                      # the yellow bollards at bay 2 (f027)
		EX.bollard(b, a + t * u + n * 1.0)
		b.obst(["rect", x0 + u - 0.15, z0 + 0.85, x0 + u + 0.15, z0 + 1.15])
	# the trailer in bay 1, nose to the lot (both years; f021-f026)
	EX.trailer(b, a + t * 4.8 + n * 0.55, -n, 13.0)
	# the roll-off left of the trailer, its nose to the lot (f026)
	dumpster(b, Vector3(x0 + 1.75, 0, z0 + 4.2), n, "dumpster_dillards")
	# the wood-plank enclosure at the court's mouth, against the wing block (f017-f021, f026): planks on the lot
	# and court sides on a red curb, a chain-link gate toward the dock
	var ex1 = x0 + 4.0; var ez0 = z1 - 4.4; var ez1 = z1 - 0.4
	EX.fence(b, "ex_fence_wood", [Vector3(x0 + 0.05, 0.15, ez1), Vector3(ex1, 0.15, ez1), Vector3(ex1, 0.15, ez0 + 1.6)], 2.0)
	EX.fence(b, "ex_fence_wood", [Vector3(ex1, 0.15, ez0), Vector3(x0 + 0.05, 0.15, ez0)], 2.0)
	EX.fence(b, "ex_chainlink", [Vector3(ex1, 0.0, ez0 + 1.6), Vector3(ex1, 0.0, ez0)], 2.1)
	b.box(g, "ex_curb_red", Vector3((x0 + ex1) * 0.5, 0.075, ez1 + 0.1), Vector3(ex1 - x0, 0.15, 0.3))
	b.box(g, "ex_curb_red", Vector3(ex1 + 0.1, 0.075, (ez0 + 1.6 + ez1) * 0.5), Vector3(0.3, 0.15, ez1 - ez0 - 1.6))
	b.obst(["rect", x0, ez0 - 0.1, ex1 + 0.2, ez1 + 0.2])
	# a double door in the wing block's east wall (f020)
	var wa = Vector3(x0, 0, z0); var wt = Vector3(0, 0, 1); var wn = Vector3(1, 0, 0)
	_run(b, g, "ex_beige_door", wa, wt, wn, 8.0, 9.8, 0.0, 2.15, 0.03, 0.03)
	_run(b, g, "ex_wall_pack", wa, wt, wn, 8.72, 9.08, 2.6, 2.85, 0.25, 0.25)
	# Dillard's west face from the court to its SW corner: the white base to 4.8 m as on its other faces
	# (f013-f016, f025-f027; exterior.gd keeps the 1.2 m wainscot below), two white man doors, the FDC with its
	# two hose valves, wall packs at the base's top, a chain-link gate panel standing off the base by the dock
	var da = Vector3(DILLARDS_W, 0, 80); var dt = Vector3(0, 0, 1); var dn = Vector3(-1, 0, 0)
	_run(b, "ex_shell", "ex_white_wainscot", da, dt, dn, 20.0, 58.0, 1.2, 4.8, 0.05, 0.05)
	for u in [45.0, 54.5]:
		_run(b, g, "ex_ivory", da, dt, dn, u - 0.5, u + 0.5, 0.0, 2.15, 0.09, 0.04)
		_run(b, g, "ex_coping", da, dt, dn, u - 0.56, u + 0.56, 2.15, 2.21, 0.1, 0.05)
	_run(b, g, "ex_red_arcade", da, dt, dn, 50.6, 51.0, 1.9, 2.2, 0.07, 0.02)             # the FDC plate
	for u in [51.6, 52.5]:
		b.cyl(g, "ex_red_arcade", da + dt * u + dn * 0.06 + UP * 1.75, 0.16, 0.16, 0.08, 10, true, true)
	_run(b, g, "ex_pipe_grey", da, dt, dn, 51.5, 52.6, 1.3, 1.36, 0.12, 0.06)
	for u in [26.0, 36.0, 46.0, 56.0]:
		_run(b, g, "ex_wall_pack", da, dt, dn, u - 0.25, u + 0.25, 4.25, 4.55, 0.3, 0.25)
		b.tag(b.add_spot(da + dt * u + dn * 0.4 + UP * 4.2, (-UP + dn * 0.5).normalized(), 1.0, 9.0, 70.0, Color("#FFE6C2")), "night")
	EX.fence(b, "ex_chainlink", [Vector3(DILLARDS_W - 0.5, 0, 104.0), Vector3(DILLARDS_W - 0.5, 0, 107.0)], 2.0)
	b.obst(["rect", DILLARDS_W - 0.7, 104.0, DILLARDS_W, 107.0])

# ---------------------------------------------------------------------------------------------- B. JCPenney
static func jcpenney(b):
	if EX == null:
		EX = load("res://tools/exterior/exterior.gd")
	var g = "ex_entry"
	var a = JCP_NE; var t = Vector3(0, 0, 1); var n = Vector3(1, 0, 0)      # u runs south from the NE corner
	# the grey concrete pier at the corner (f106, f107, f110)
	_run(b, g, "ex_curb", a, t, n, 0.0, 0.6, 0.0, 4.1, 0.22, 0.22)
	# the red corrugated canopy: a 0.9 m fascia, 2.5 m out, its ribs, a white soffit with two lights (f106, f107)
	_run(b, g, "ex_red_arcade", a, t, n, 0.8, 10.4, 4.2, 5.1, 2.5, 2.5, ["-y"])
	var k = 0.95
	while k < 10.35:
		_run(b, g, "ex_maroon", a, t, n, k - 0.04, k + 0.04, 4.22, 5.08, 2.53, 0.04)
		k += 0.3
	b.quad(g, "ex_soffit_white", [a + t * 0.8 + UP * 4.19, a + t * 10.4 + UP * 4.19, a + t * 10.4 + n * 2.5 + UP * 4.19, a + t * 0.8 + n * 2.5 + UP * 4.19], -UP)
	for u in [3.0, 6.9]:
		b.box(g, "ex_lamp", a + t * u + n * 1.4 + UP * 4.15, Vector3(0.25, 0.08, 0.4))
		b.tag(b.add_spot(a + t * u + n * 1.4 + UP * 4.1, -UP, 1.2, 7.0, 70.0, Color("#FFE6C2")), "night")
	# docks 2 (nearest the corner) and 1: white roll-ups 2.4 x 2.6 m, sill 1.2 m, the red numerals low on the doors
	dock_door(b, a, t, n, 3.0, 2.4, 1.2, 3.8, "ex_tank_white")
	dock_door(b, a, t, n, 6.9, 2.4, 1.2, 3.8, "ex_tank_white")
	b.label("2", "sans", "#c8202e", a + t * 3.6 + UP * 1.75 + n * 0.09, n, 0.5, 0.36)
	b.label("1", "sans", "#c8202e", a + t * 7.5 + UP * 1.75 + n * 0.09, n, 0.5, 0.36)
	# the raised dock, its landing at the man door and the concrete steps down to the apron, east (f107)
	_run(b, g, "ex_curb", a, t, n, 1.0, 10.6, 0.0, 1.2, 1.5, 1.5, ["-y"])
	for i in 5:
		_run(b, g, "ex_curb", a, t, n, 9.0, 10.6, 0.0, 1.2 - (i + 1) * 0.2, 1.5 + (i + 1) * 0.3, 0.3, ["-y"])
	for sd in [9.0, 10.6]:                                      # the steps' pipe rails
		var r0 = a + t * sd + n * 1.5 + UP * 2.1; var r1 = a + t * sd + n * 3.0 + UP * 0.95
		var d = (r1 - r0)
		b.box(g, "ex_pipe_grey", (r0 + r1) * 0.5, Vector3(0.05, 0.05, d.length()), Transform3D(Basis.looking_at(d.normalized(), UP), Vector3.ZERO))
		for p in [r0, r1]:
			b.cyl(g, "ex_pipe_grey", p - UP * 0.9, 0.025, 0.025, 0.9, 6, false)
	_run(b, g, "ex_pipe_grey", a, t, n, 8.45, 9.0, 2.05, 2.1, 1.5, 0.05)                  # the landing's guard to door 1
	_run(b, g, "ex_ivory", a, t, n, 9.3, 10.3, 1.2, 3.3, 0.05, 0.05)                      # the white man door
	_run(b, g, "ex_pipe_yellow", a, t, n, 8.55, 8.95, 2.2, 2.8, 0.14, 0.14)               # the electrical box
	b.obst(["rect", a.x, a.z + 0.9, a.x + 1.6, a.z + 10.7])
	b.obst(["rect", a.x + 1.5, a.z + 8.9, a.x + 3.1, a.z + 10.7])
	# the compactor: its head and hopper on the wall south of the steps, the roll-off pointing east (f107, f108)
	_run(b, g, "ex_dock_green", a, t, n, 11.3, 13.9, 0.0, 2.7, 2.3, 2.3, ["-y"])
	_run(b, g, "ex_dock_green", a, t, n, 11.5, 13.7, 2.7, 3.1, 1.2, 1.2, ["-y"])
	_run(b, g, "ex_black_steel", a, t, n, 11.25, 13.95, 0.0, 0.3, 2.34, 0.06)
	b.obst(["rect", a.x, a.z + 11.2, a.x + 2.4, a.z + 14.0])
	dumpster(b, Vector3(a.x + 2.45 + 3.3, 0, a.z + 12.6), n, "dumpster_jcpenney")
	EX.fence(b, "ex_chainlink", [Vector3(a.x + 0.1, 0, a.z + 15.6), Vector3(a.x + 13.0, 0, a.z + 15.6)], 2.0)   # behind it (f108)
	b.obst(["rect", a.x, a.z + 15.5, a.x + 13.0, a.z + 15.7])
	# the galvanized two-rail guard on its curb along the apron's north edge (f103, f107, f108)
	var ra = Vector3(a.x + 0.3, 0, a.z - 0.1); var rl = 12.0
	b.box(g, "ex_curb", ra + Vector3(rl * 0.5, 0.1, 0), Vector3(rl, 0.2, 0.3))
	for y in [0.62, 1.07]:
		b.box(g, "ex_pipe_grey", ra + Vector3(rl * 0.5, 0.2 + y, 0), Vector3(rl, 0.05, 0.05))
	for i in 6:
		b.cyl(g, "ex_pipe_grey", ra + Vector3(i * 2.4, 0.2, 0), 0.025, 0.025, 1.07, 6, false)
	b.obst(["rect", ra.x, ra.z - 0.2, ra.x + rl, ra.z + 0.2])
	# between the dock and the tank (Steven: "should be a tree in between this area and the big tank"; f102-f106):
	# a curbed bed off the corner with a live oak and clipped hollies
	FL.planter(b, a.x + 3.0, a.z - 8.6, a.x + 11.0, a.z - 1.4, "ex_curb", "ex_mulch", false, false)
	EX.tree_oak(b, Vector3(a.x + 7.2, 0.08, a.z - 5.2), 4.6)
	for p in [Vector3(a.x + 4.4, 0.08, a.z - 2.6), Vector3(a.x + 9.6, 0.08, a.z - 2.8), Vector3(a.x + 4.6, 0.08, a.z - 7.2), Vector3(a.x + 9.8, 0.08, a.z - 7.0)]:
		FL.shrub(b, p, 1.15, Color(0.7, 0.95, 0.72))
