## Woolworth (store s13), the five-and-dime on the east hall, built to
## design/storefronts/woolworth.md.
##
## The front follows Steven's photo of the sign (Oct 7): a dark fascia with WOOLWORTH in lit
## orange-red slab-serif channel letters, cream piers, a wide open front. The inside follows the 1991
## Signal Hill Mall (Statesville, NC) video Steven chose as "the exact Woolworth layout":
## glossy off-white vinyl with a red stripe along the main aisles, a white lay-in ceiling
## with long rows of troffers, plain square columns, a red band of department names high on
## the walls, white gondolas, numbered checkout lanes (at the left front since Nov 11; the customer
## service booth is gone: Steven, WOOL-FRONT), round racks of clothes, and the coffee-shop restaurant. Steven: the restaurant was on the
## RIGHT as you face the store, entered from the store and by its own mall door; there was
## no garden center.
##
## Frame: u runs along the 36 m frontage from the edge's start a (z = -14, the viewer's
## right) to z = 22 (u = 36). d runs into the store (-x); the room is 36 m deep.

const K = preload("res://tools/stores/media/kit.gd")
const CH = preload("res://tools/stores/signs/channel.gd")
const UNIT = 36.0
const DEPTH = 36.0
const SIDE = 0.12
const HEAD = 3.0
const FTOP = 4.4
const PROUD = 0.25
const CEIL = 3.6
const R_U = 9.0           # the restaurant's width (u 0..9) and depth (d 0..14)
const R_D = 14.0
const R_CEIL = 3.0
const WALL_T = 0.6        # the wall between the restaurant and the store (u 9.0..9.6)
const R_DOOR0 = 7.0       # the restaurant's mall door (u 7.0..8.75), at its left end
const R_DOOR1 = 8.75
## The opening between the restaurant and the store (Steven, Nov 1: "only a few feet of wall
## after the restaurant's mall door, then a large opening"; the three left-wall booths sit
## behind it). Was d 9.4..11.2 until Nov 1.
const OP0 = 1.0
const OP1 = 4.6
const BAY = 1.22
const UP = Vector3.UP
const BOARDS = [0.35, 0.72, 1.09, 1.46, 1.83]
const LOW = [0.35, 0.75, 1.15, 1.55]

static func P(a, t, n, u, y, d):
	return a + t * u - n * d + Vector3(0, y, 0)

## Mesh groups by quadrant, so no one group's lightmap unwrap gets too big.
static func grp(kind, u, d):
	return "wl%d%d_%s" % [int(u >= 22.0), int(d >= 18.0), kind]

static func build(b, g, e, a, bb, n, t, Ln, sd):
	var rng = RandomNumberGenerator.new()
	rng.seed = 1991
	front(b, "wlf_props", a, t, n)
	room(b, a, t, n, rng)
	restaurant(b, a, t, n, rng)
	floor_fixtures(b, a, t, n, rng)
	for c in [[22.0, 9.0, 18.0], [22.0, 27.0, 18.0], [4.5, 7.0, 14.0]]:
		var rp = ReflectionProbe.new()
		rp.position = P(a, t, n, c[0], CEIL * 0.5, c[1])
		rp.size = (t * (UNIT if c[0] > 10.0 else R_U) + n * c[2]).abs() + Vector3(0.1, CEIL + 0.1, 0.1)
		rp.box_projection = true
		rp.interior = true
		rp.update_mode = ReflectionProbe.UPDATE_ONCE
		rp.intensity = 0.6
		b.light_root.add_child(rp)

# ------------------------------------------------------------------ the front
static func front(b, G, a, t, n):
	var LH = b.LANE_H
	var o = P(a, t, n, 0, 0, 0)
	# the dark fascia across the whole frontage, standing out over the hall (Steven's photo,
	# Oct 7: design/storefronts/refs/woolworth-front.png)
	K.lbox(b, G, "sg_wl_fascia", o, t, n, 0.0, HEAD, 0.0, UNIT, FTOP - HEAD, PROUD, ["-z"])
	b.quad(G, "md_fascia_white", [P(a, t, n, 0, FTOP, 0), P(a, t, n, UNIT, FTOP, 0), P(a, t, n, UNIT, LH, 0), P(a, t, n, 0, LH, 0)], n)
	# WOOLWORTH in lit channel letters on the fascia, over the middle of the store's opening
	# (tools/stores/signs: the photo's letters, 0.78 m capitals)
	var lc = (R_U + WALL_T + UNIT) * 0.5
	CH.build(b, "wlf_sign", "res://tools/stores/signs/wl_logo.json", P(a, t, n, lc, 3.31, -PROUD), n,
		"sg_wl_face", "sg_wl_return", "sg_wl_trim", 0.02, 0.12, 0.012, "sg_wl_glow")
	# the restaurant's own front (u 0..9): a bulkhead, glass, an open door with an aluminium frame.
	# The door is at the left end, by the store (Steven, Oct 20: "the new opening that i drew"),
	# the window booths along the glass to its right.
	var al = "wl_alum"
	K.lbox(b, G, "md_fascia_white", o, t, n, 0.0, 0.0, -0.12, R_DOOR0, 0.45, 0.12)
	for s in [[0.25, R_DOOR0]]:
		b.quad("glass", "glass", [P(a, t, n, s[0], 0.45, 0.05), P(a, t, n, s[1], 0.45, 0.05), P(a, t, n, s[1], HEAD, 0.05), P(a, t, n, s[0], HEAD, 0.05)], n,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
		K.ob_local(b, o, t, -n, s[0], -0.1, s[1], 0.15, 0.1)
	for u in [0.25, 2.0, 3.7, 5.3, R_DOOR0, R_DOOR1]:
		K.lbox(b, G, al, o, t, n, u - 0.03, 0.0, -0.08, 0.06, HEAD, 0.1)
	K.lbox(b, G, al, o, t, n, 0.0, HEAD - 0.08, -0.08, R_U, 0.08, 0.1)
	K.lbox(b, G, al, o, t, n, R_DOOR0, 2.2, -0.08, R_DOOR1 - R_DOOR0, 0.06, 0.1)
	b.quad("glass", "glass", [P(a, t, n, R_DOOR0, 2.26, 0.05), P(a, t, n, R_DOOR1, 2.26, 0.05), P(a, t, n, R_DOOR1, HEAD - 0.08, 0.05), P(a, t, n, R_DOOR0, HEAD - 0.08, 0.05)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	# the door leaves stand open, inside: the right one back against the end of the first booth,
	# the left one against the pier's return
	for s in [[R_DOOR0, 1.0], [R_DOOR1, -1.0]]:
		var hinge = P(a, t, n, s[0], 0, 0.12)
		K.lbox(b, G, al, hinge, -n, t * s[1], 0.0, 0.0, 0.0, 0.8, 2.2, 0.05)
	# "Restaurant" over its door: red lit channel letters straight on the fascia, no plate behind
	# them (Steven, Oct 8; tools/stores/signs/make_wl_restaurant.py)
	CH.build(b, "wlf_sign", "res://tools/stores/signs/wlr_logo.json", P(a, t, n, 4.5, 3.5, -PROUD), n,
		"sg_wlr_face", "sg_wl_return", "sg_wl_trim", 0.02, 0.09, 0.01, "sg_wlr_glow")
	# the cream pier between the restaurant and the store, and one at the store's far end
	K.lbox(b, G, "sg_wl_cream", o, t, n, R_U, 0.0, -0.05, WALL_T, HEAD, 0.2, ["-y"])
	K.lbox(b, G, "sg_wl_cream", o, t, n, UNIT - 0.45, 0.0, -0.05, 0.45, HEAD, 0.2, ["-y"])
	K.ob_local(b, o, t, -n, UNIT - 0.45, -0.15, UNIT, 0.6)
	K.ob_local(b, o, t, -n, R_U, -0.15, R_U + WALL_T, 0.6)
	# the store's open front: a soffit just inside, a pier at the left end
	b.quad(G, "md_fascia_white", [P(a, t, n, R_U + WALL_T, HEAD, 0), P(a, t, n, UNIT - SIDE, HEAD, 0), P(a, t, n, UNIT - SIDE, HEAD, 0.8), P(a, t, n, R_U + WALL_T, HEAD, 0.8)], Vector3.DOWN)
	b.quad(G, "md_fascia_white", [P(a, t, n, R_U + WALL_T, HEAD, 0.8), P(a, t, n, UNIT - SIDE, HEAD, 0.8), P(a, t, n, UNIT - SIDE, CEIL, 0.8), P(a, t, n, R_U + WALL_T, CEIL, 0.8)], -n)
	for u in [12.0, 16.0, 20.0, 24.0, 28.0, 32.0]:
		b.cyl(G, "md_downlight", P(a, t, n, u, HEAD - 0.004, 0.4), 0.09, 0.09, 0.004, 12, false, true)
	# the clock and the exit sign over the opening, inside (video 5:34)
	b.cur_color = Color("#f4f4f0")
	b.cyl(G, "vcolor", P(a, t, n, 22.5, HEAD + 0.2, 0.84) - n * 0.0, 0.18, 0.18, 0.03, 20, true, false)
	b.cur_color = Color.WHITE
	b.box(G, "exit_sign", P(a, t, n, 26.0, HEAD + 0.25, 0.84), b.abs_size(t, 0.36, 0.16, 0.06, n))

# ------------------------------------------------------------------ the room
static func room(b, a, t, n, rng):
	var G = "wl_shell"
	var u1 = UNIT - SIDE
	var dB = DEPTH - SIDE
	var u9 = R_U + WALL_T
	# floors: the store's glossy vinyl; behind the restaurant too
	K.floor_rect(b, G, "wl_floor", a, t, n, u9, u1, 0.0, dB, 1.22)
	K.floor_rect(b, G, "wl_floor", a, t, n, SIDE, u9, R_D, dB, 1.22)
	# the red stripe inset along the main aisle into the store and the cross aisle (video 2:28, 3:04)
	# Nov 1 (workstream D): widened from 0.15 m to 0.3 m so it reads as the video's stripe
	var stripes = [[20.65, 20.95, 0.9, 33.0], [24.05, 24.35, 0.9, 33.0], [u9, 35.4, 16.65, 16.95], [u9, 35.4, 20.05, 20.35]]
	for s in stripes:
		var q = [P(a, t, n, s[0], 0.003, s[2]), P(a, t, n, s[1], 0.003, s[2]), P(a, t, n, s[1], 0.003, s[3]), P(a, t, n, s[0], 0.003, s[3])]
		b.quad(G, "wl_red", q, UP)
	# the lay-in ceiling at 3.6 m with long rows of troffers; baked spots on a coarse grid
	K.ceiling(b, G, a, t, n, u9, u1, 0.8, dB, CEIL, [11.0, 14.0, 17.0, 20.0, 23.0, 26.0, 29.0, 32.0, 35.0], 2.44, false)
	K.ceiling(b, G, a, t, n, SIDE, u9, R_D + SIDE, dB, CEIL, [2.0, 5.0, 8.0], 2.44, false)
	for u in [3.5, 10.5, 17.5, 24.5, 31.5]:
		for d in [4.0, 10.0, 16.0, 22.0, 28.0, 33.5]:
			if u < R_U and d < R_D:
				continue
			var l = b.add_spot(P(a, t, n, u, CEIL - 0.08, d), Vector3.DOWN, 1.4, 7.0, 70.0, Color(0.96, 0.98, 1.0))
			b.tag(l, "", 1.4, 1.4)
	# walls
	K.wall(b, G, "md_wall", a, t, n, u1, dB, u1, 0.0, 0.0, CEIL, -t)
	K.wall(b, G, "md_wall", a, t, n, u1, dB, SIDE, dB, 0.0, CEIL, n)
	K.wall(b, G, "md_wall", a, t, n, SIDE, R_D, SIDE, dB, 0.0, CEIL, t)
	# the restaurant's walls seen from the store: its back (d 14) and its side (u 9.6), with
	# the wood-framed opening at d OP0..OP1 (video 7:37-7:49)
	K.wall(b, G, "md_wall", a, t, n, u9, R_D, K_U1, R_D, 0.0, CEIL, -n)   # the kitchen (WOOL-FRONT) takes u 0.12..K_U1
	K.wall(b, G, "md_wall", a, t, n, u9, 0.0, u9, OP0, 0.0, CEIL, t)
	K.wall(b, G, "md_wall", a, t, n, u9, OP1, u9, R_D, 0.0, CEIL, t)
	K.wall(b, G, "md_wall", a, t, n, u9, OP0, u9, OP1, 2.4, CEIL, t)
	b.quad(G, "md_wall", [P(a, t, n, R_U - 0.12, 2.4, OP0), P(a, t, n, u9, 2.4, OP0), P(a, t, n, u9, 2.4, OP1), P(a, t, n, R_U - 0.12, 2.4, OP1)], Vector3.DOWN)
	for s in [[OP0, 1.0], [OP1, -1.0]]:
		b.quad(G, "wl_wood", [P(a, t, n, R_U - 0.12, 0, s[0]), P(a, t, n, u9, 0, s[0]), P(a, t, n, u9, 2.4, s[0]), P(a, t, n, R_U - 0.12, 2.4, s[0])], -n * s[1])
	var fr = P(a, t, n, u9, 0, OP0 - 0.1)
	var ow = OP1 - OP0 + 0.2
	for s in [[0.0, 0.1, 0.0, 2.5], [ow - 0.1, ow, 0.0, 2.5], [0.0, ow, 2.4, 2.5]]:
		K.lbox(b, G, "wl_wood", fr, -n, t, s[0], s[2], 0.0, s[1] - s[0], s[3] - s[2], 0.04)
	K.ob_local(b, P(a, t, n, R_U - 0.12, 0, 0), -n, t, 0.0, 0.0, OP0, WALL_T + 0.12, 0.1)
	K.ob_local(b, P(a, t, n, R_U - 0.12, 0, 0), -n, t, OP1, 0.0, R_D, WALL_T + 0.12, 0.1)
	K.ob_local(b, P(a, t, n, SIDE, 0, R_D - 0.1), t, -n, 0.0, 0.0, R_U, 0.2, 0.1)
	# "Restaurant" in red letters on the white wall over the opening (video 7:37-7:49)
	K.fq(b, G, "wl_signs", P(a, t, n, u9, 0, (OP0 + OP1) * 0.5 - 1.8), -n, t, 0.0, 3.6, 2.55, 3.35, 0.02, 0.0, 0.5, 0.5, 1.0)
	# the red band of department names high on the walls: back wall, left wall, right wall
	# left wall (u = 35.88), names over what stands below, front to back
	for s in [[6.0, 3], [12.0, 3], [18.0, 1], [24.0, 2], [30.0, 2]]:
		K.fq(b, G, "wl_dept_band", P(a, t, n, u1, 0, s[0] - 6.0), -n, -t, 0.0, 6.0, 2.65, 3.4, 0.01, 0.0, s[1] / 12.0, 1.0, (s[1] + 1) / 12.0)
	# back wall (d = 35.88), from the left corner to the right
	for s in [[36.0, 2], [30.0, 1], [24.0, 0], [18.0, 0], [12.0, 6], [6.0, 5]]:
		K.fq(b, G, "wl_dept_band", P(a, t, n, s[0], 0, dB), -t, n, 0.0, 6.0, 2.65, 3.4, 0.01, 0.0, s[1] / 12.0, 1.0, (s[1] + 1) / 12.0)
	# right wall behind the restaurant (u = 0.12)
	for s in [[R_D + 7.0, 5], [R_D + 14.0, 6], [dB, 7]]:
		K.fq(b, G, "wl_dept_band", P(a, t, n, SIDE, 0, s[0]), n, t, 0.0, 6.0, 2.65, 3.4, 0.01, 0.0, s[1] / 12.0, 1.0, (s[1] + 1) / 12.0)
	# plain square columns flanking the main aisle (video 2:04, 2:31)
	for u in [20.3, 24.7]:
		for d in [9.0, 18.5, 27.5]:
			var c = P(a, t, n, u, 0, d)
			b.box(G, "md_wall", c + UP * CEIL * 0.5, Vector3(0.5, CEIL, 0.5), Transform3D.IDENTITY, ["-y", "+y"])
			K.ob(b, c - Vector3(0.25, 0, 0.25), c + Vector3(0.25, 0, 0.25), 0.1)
	# the stockroom doors in the back wall, an exit sign over each
	for du in [21.2, 23.8]:
		b.cur_color = Color("#d8d6d0")
		b.box(G, "vcolor", P(a, t, n, du, 1.05, dB - 0.02), b.abs_size(t, 1.2, 2.1, 0.04, n))
		b.cur_color = Color.WHITE
	b.box(G, "exit_sign", P(a, t, n, 22.5, 2.35, dB - 0.05), b.abs_size(t, 0.36, 0.16, 0.06, n))
	tape_frame(b, a, t, n, 34.97, 35.8, 2.06, dB - 0.003)

## Blue painter's tape marking the way into the Stockrooms (Steven, Oct 20: "an outline of blue
## painters tape around the opening to the stockrooms in the back of WOOLWORTH", from his picture):
## two uprights from the floor and a top strip laid across them that runs past both, the uprights
## poking a little above it; each strip a little off true, as if put up by hand. Probe-lit (dyn), so
## it needs no rebake. The opening is scripts/stockrooms.gd's door, z 21.0..21.9 on the back wall.
static func tape_frame(b, a, t, n, u0, u1, top, d):
	var w = 0.048
	var strips = [
		# [u at the floor, u at the top end, y0, y1] for the uprights
		[u0, u0 + 0.012, 0.03, top + 0.07],
		[u1, u1 - 0.01, 0.0, top + 0.05],
	]
	for s in strips:
		var c0 = P(a, t, n, s[0], s[2], d)
		var c1 = P(a, t, n, s[1], s[3], d)
		var side = t * (w * 0.5)
		b.quad("wl_tape", "wl_tape", [c0 - side, c0 + side, c1 + side, c1 - side], n, [], true)
	# the top strip, laid over the uprights, a touch proud of them
	var y0 = top - 0.012
	var y1 = top + 0.018
	var l0 = P(a, t, n, u0 - 0.07, y0, d - 0.0015)
	var l1 = P(a, t, n, u1 + 0.06, y1, d - 0.0015)
	var up = Vector3.UP * (w * 0.5)
	b.quad("wl_tape", "wl_tape", [l0 - up, l1 - up, l1 + up, l0 + up], n, [], true)

# ------------------------------------------------------------------ the restaurant
static func restaurant(b, a, t, n, rng):
	var G = "wl_rest"
	var S = "wl_rest_small"
	var u0 = SIDE
	var u1 = R_U - 0.12
	var dB = R_D - 0.12
	K.floor_rect(b, G, "wl_rest_floor", a, t, n, u0, u1, 0.0, dB, 0.61)
	# a darker beige ceiling with warm downlights (video 5:43, 6:01)
	var P2 = func(u, y, d): return P(a, t, n, u, y, d)
	b.quad(G, "wl_rest_ceiling", [P2.call(u0, R_CEIL, 0.0), P2.call(u1, R_CEIL, 0.0), P2.call(u1, R_CEIL, dB), P2.call(u0, R_CEIL, dB)], Vector3.DOWN)
	for u in [1.6, 4.5, 7.4]:
		for d in [2.0, 5.0, 8.0, 11.0]:
			b.cyl(G, "wl_warm_disc", P2.call(u, R_CEIL - 0.004, d), 0.08, 0.08, 0.004, 12, false, true)
	for c in [[2.5, 4.0], [6.5, 4.0], [2.5, 10.0], [6.5, 10.0]]:
		var l = b.add_omni(P2.call(c[0], R_CEIL - 0.4, c[1]), 0.5, 6.0, Color(1.0, 0.86, 0.66))
		b.tag(l, "", 0.5, 0.6)
	# walls: beige, a wood-slat wainscot, lattice panels in wood frames on the right wall,
	# brass sconces with globe shades, framed food photos (video 5:46-6:25)
	K.wall(b, G, "wl_beige", a, t, n, u0, 0.0, u0, dB, 0.9, R_CEIL, t)
	# the left wall, with the opening into the store at d OP0..OP1
	K.wall(b, G, "wl_beige", a, t, n, u1, OP0, u1, 0.0, 0.9, R_CEIL, -t)
	K.wall(b, G, "wl_beige", a, t, n, u1, dB, u1, OP1, 0.9, R_CEIL, -t)
	K.wall(b, G, "wl_beige", a, t, n, u1, OP1, u1, OP0, 2.4, R_CEIL, -t)
	# the back wall, with the kitchen pass-through cut in it (WOOL-FRONT, Nov 11)
	K.wall(b, G, "wl_beige", a, t, n, u1, dB, PT_U1, dB, 0.9, R_CEIL, n)
	K.wall(b, G, "wl_beige", a, t, n, PT_U1, dB, PT_U0, dB, 0.9, PT_Y0, n)
	K.wall(b, G, "wl_beige", a, t, n, PT_U1, dB, PT_U0, dB, PT_Y1, R_CEIL, n)
	K.wall(b, G, "wl_beige", a, t, n, PT_U0, dB, u0, dB, 0.9, R_CEIL, n)
	for w in [[u0, 0.0, u0, dB, t], [u1, OP0, u1, 0.0, -t], [u1, dB, u1, OP1, -t], [u1, dB, u0, dB, n]]:
		var pa = P2.call(w[0], 0, w[1])
		var pb = P2.call(w[2], 0, w[3])
		var Lw = pa.distance_to(pb)
		b.quad(G, "wl_slats", [pa, pb, pb + UP * 0.9, pa + UP * 0.9], w[4], [Vector2(0, 1.5), Vector2(Lw / 0.6, 1.5), Vector2(Lw / 0.6, 0), Vector2(0, 0)])
		b.cur_color = Color("#6a4424")
		b.box(G, "vcolor", (pa + pb) * 0.5 + UP * 0.92 + w[4] * 0.02, b.abs_size((pb - pa).normalized(), Lw, 0.05, 0.04, w[4]))
		b.cur_color = Color.WHITE
	# Steven (Oct 20): "3 booths lined the front of the restaurant directly to the left of the new
	# opening ... like the image of the booths at the window": benches square to the glass, high
	# channel-tufted backs shared back to back, a table off the window on a pedestal
	for i in 3:
		window_booth(b, G, P2.call(R_DOOR0 - 0.1 - i * 1.75, 0, 0.14), -t, -n)
	# "There were also 3 booths lining the left wall right behind where the opening to the woolworth
	# store is": along the left wall, between the door and the opening into the store
	# Nov 1 (Steven): they sit behind the opening, which moved to the front (d 1.0..4.6)
	# Nov 11 (Steven, WOOL-FRONT): "one more booth along the left wall in the empty stretch before
	# that door": a fourth, at the same spacing (d 11.05..12.95)
	for d in [OP1 + 1.1, OP1 + 3.2, OP1 + 5.3, OP1 + 7.4]:
		booth(b, G, P2.call(u1, 0, d), -n, -t, rng)
	# two free-standing tables with chairs in the middle
	for c in [[5.1, 4.4], [5.1, 7.6]]:
		table(b, G, P2.call(c[0], 0, c[1]))
		for sg in [-1.0, 1.0]:
			chair(b, S, P2.call(c[0], 0, c[1]) + t * 0.62 * sg, -t * sg)
	# "the bar/counter was on the right hand side and wrapped around toward the front. there are
	# barstools lining the bar ... behind the bar all of the typical old drug store lunch counter
	# things": the back bar against the right wall, the counter in front of it, its front end
	# curving round toward the window and back to the wall
	lunch_counter(b, G, S, a, t, n, rng)
	kitchen_wall(b, G, S, a, t, n)

## The restaurant's back wall (Steven, Nov 11, WOOL-FRONT): "add a closed door to the kitchen, and
## beside it, between the door and the back bar, a kitchen pass-through window (a framed opening with
## a stainless shelf, a glimpse of a simple kitchen behind, heat lamps)". From the right wall: the
## back bar, the pass-through behind the counter's back end (u PT_U0..PT_U1), then the door
## (u KD_U0..KD_U1) just left of the counter, where the clerks come round it.
## GUESS (no Southland source): every size, the door's look (wood, a small window, steel kick and
## push plates), and the kitchen: a 1 m deep room behind the wall (u 0.12..K_U1, d 14..15, taken
## from the store's floor behind the restaurant) with a range under a hood, a pot shelf and a
## tall refrigerator. Nothing in it is lettered.
const PT_U0 = 0.9
const PT_U1 = 2.6
const PT_Y0 = 1.05
const PT_Y1 = 1.95
const KD_U0 = 3.2
const KD_U1 = 4.1
const KD_H = 2.05
const K_U1 = 4.4          # the kitchen's outer corner (u), and its depth behind the restaurant
const K_DP = 1.0
static func kitchen_wall(b, G, S, a, t, n):
	var P2 = func(u, y, d): return P(a, t, n, u, y, d)
	var dB = R_D - 0.12
	var o = P2.call(0.0, 0.0, dB)      # the wall's face; r = t along it, f = n out into the room
	# --- the door: a walnut laminate leaf in a dark casing, a small dark window, steel kick and push plates
	b.cur_color = Color("#6a4424")
	for sx in [[KD_U0 - 0.08, 0.08, 0.0, KD_H + 0.08], [KD_U1, 0.08, 0.0, KD_H + 0.08], [KD_U0, KD_U1 - KD_U0, KD_H, 0.08]]:
		K.lbox(b, G, "vcolor", o, t, n, sx[0], sx[2], 0.0, sx[1], sx[3], 0.06, ["-y"])
	b.cur_color = Color.WHITE
	# a plain walnut laminate leaf in one piece (period-art-director, Nov 11: the wood texture's
	# grain read as a loud zigzag with a seam)
	b.cur_color = Color("#7a5230")
	K.lbox(b, G, "vcolor", o, t, n, KD_U0, 0.0, 0.0, KD_U1 - KD_U0, KD_H, 0.04, ["-y"])
	b.cur_color = Color.WHITE
	K.lbox(b, G, "wl_steel", o, t, n, KD_U0 + 0.03, 0.02, 0.04, KD_U1 - KD_U0 - 0.06, 0.26, 0.004, ["-y"])
	K.lbox(b, G, "wl_steel", o, t, n, KD_U0 + 0.08, 1.0, 0.04, 0.1, 0.32, 0.004)
	K.lbox(b, G, "wl_steel", o, t, n, KD_U0 + 0.3, 1.38, 0.04, 0.3, 0.3, 0.006)
	b.cur_color = Color("#1a2226")
	K.lbox(b, G, "vcolor", o, t, n, KD_U0 + 0.325, 1.405, 0.04, 0.25, 0.25, 0.008)
	b.cur_color = Color.WHITE
	# --- the pass-through: a stainless lining through the wall, a frame, the shelf on brackets
	var d1 = R_D                        # the wall's kitchen face
	b.quad(G, "wl_steel", [P2.call(PT_U0, PT_Y0, dB), P2.call(PT_U1, PT_Y0, dB), P2.call(PT_U1, PT_Y0, d1), P2.call(PT_U0, PT_Y0, d1)], UP)
	b.quad(G, "wl_steel", [P2.call(PT_U0, PT_Y1, dB), P2.call(PT_U1, PT_Y1, dB), P2.call(PT_U1, PT_Y1, d1), P2.call(PT_U0, PT_Y1, d1)], Vector3.DOWN)
	b.quad(G, "wl_steel", [P2.call(PT_U0, PT_Y0, dB), P2.call(PT_U0, PT_Y0, d1), P2.call(PT_U0, PT_Y1, d1), P2.call(PT_U0, PT_Y1, dB)], t)
	b.quad(G, "wl_steel", [P2.call(PT_U1, PT_Y0, dB), P2.call(PT_U1, PT_Y0, d1), P2.call(PT_U1, PT_Y1, d1), P2.call(PT_U1, PT_Y1, dB)], -t)
	var pw = PT_U1 - PT_U0
	for sx in [[PT_U0 - 0.05, PT_Y0 - 0.05, 0.05, PT_Y1 - PT_Y0 + 0.1], [PT_U1, PT_Y0 - 0.05, 0.05, PT_Y1 - PT_Y0 + 0.1],
			[PT_U0, PT_Y1, pw, 0.05], [PT_U0, PT_Y0 - 0.05, pw, 0.05]]:
		K.lbox(b, G, "wl_steel", o, t, n, sx[0], sx[1], 0.0, sx[2], sx[3], 0.025)
	K.lbox(b, G, "wl_steel", o, t, n, PT_U0 - 0.05, PT_Y0, -0.24, pw + 0.1, 0.035, 0.52)
	for u in [PT_U0 + 0.15, PT_U1 - 0.15]:
		K.lbox(b, G, "wl_steel", o, t, n, u - 0.015, PT_Y0 - 0.22, 0.0, 0.03, 0.22, 0.2)
	# --- heat lamps over the shelf: three steel shades on stems from a rail in the opening's head
	K.lbox(b, G, "wl_steel", o, t, n, PT_U0, PT_Y1 - 0.05, -0.05, pw, 0.03, 0.03)
	for i in 3:
		var lc = P2.call(PT_U0 + pw * (0.2 + 0.3 * i), 0.0, dB + 0.035)
		b.cyl(S, "wl_steel", lc + UP * (PT_Y1 - 0.14), 0.012, 0.012, 0.1, 8, false, false)
		b.cyl(S, "wl_steel", lc + UP * (PT_Y1 - 0.26), 0.1, 0.035, 0.12, 14, true, false)
		b.cyl(S, "wl_warm_disc", lc + UP * (PT_Y1 - 0.258), 0.085, 0.085, 0.004, 12, false, true)
	K.ob(b, P2.call(PT_U0 - 0.05, 0, dB - 0.3), P2.call(PT_U1 + 0.05, 0, dB), 0.0)
	# --- the kitchen behind: plain cream walls, a tiled band, a range under a hood, a pot shelf, a
	# tall refrigerator. Its outer walls are the store's white wall, to the store's ceiling.
	var KG = "wl_kitchen"
	var kd = R_D + K_DP
	var ki = kd - 0.1                   # the inner face of its back wall
	var ku = K_U1 - 0.1
	K.wall(b, "wl_shell", "md_wall", a, t, n, K_U1, R_D, K_U1, kd, 0.0, CEIL, t)
	K.wall(b, "wl_shell", "md_wall", a, t, n, K_U1, kd, SIDE, kd, 0.0, CEIL, -n)
	K.ob(b, P2.call(SIDE, 0, R_D), P2.call(K_U1, 0, kd), 0.05)
	b.cur_color = Color("#e6dfcc")
	b.quad(KG, "vcolor", [P2.call(SIDE, 0.0, ki), P2.call(ku, 0.0, ki), P2.call(ku, CEIL, ki), P2.call(SIDE, CEIL, ki)], n)
	b.quad(KG, "vcolor", [P2.call(ku, 0.0, ki), P2.call(ku, 0.0, R_D), P2.call(ku, CEIL, R_D), P2.call(ku, CEIL, ki)], -t)
	b.cur_color = Color.WHITE
	b.quad(KG, "wl_tile_stripe", [P2.call(SIDE, 0.9, ki - 0.005), P2.call(ku, 0.9, ki - 0.005), P2.call(ku, 2.0, ki - 0.005), P2.call(SIDE, 2.0, ki - 0.005)], n,
		[Vector2(0.0, 1.1), Vector2(ku - SIDE, 1.1), Vector2(ku - SIDE, 0.0), Vector2(0.0, 0.0)])
	var ko = P2.call(0.0, 0.0, ki)     # the kitchen's back wall; f = n comes toward the pass-through
	# the range: a steel body, a dark cooking top, a low back splash; two pots on it
	K.lbox(b, KG, "wl_steel", ko, t, n, 0.5, 0.0, 0.0, 1.5, 0.88, 0.62, ["-y"])
	b.cur_color = Color("#232325")
	K.lbox(b, KG, "vcolor", ko, t, n, 0.5, 0.88, 0.0, 1.5, 0.03, 0.62, ["-y"])
	b.cur_color = Color.WHITE
	b.cyl(KG, "wl_steel", K.L(ko, t, n, 0.9, 0.91, 0.3), 0.14, 0.14, 0.2, 14, true, false)
	b.cyl(KG, "wl_steel", K.L(ko, t, n, 1.55, 0.91, 0.28), 0.11, 0.11, 0.12, 14, true, false)
	# the hood over it
	K.lbox(b, KG, "wl_steel", ko, t, n, 0.4, 2.0, 0.0, 1.7, 0.45, 0.72)
	# a pot shelf on the wall between the range and the hood
	K.lbox(b, KG, "wl_steel", ko, t, n, 0.5, 1.5, 0.0, 1.5, 0.025, 0.24)
	for u in [0.75, 1.05, 1.6]:
		b.cyl(KG, "wl_steel", K.L(ko, t, n, u, 1.525, 0.12), 0.09, 0.09, 0.13, 12, true, false)
	# the refrigerator: a tall steel cabinet, a door seam and a handle
	K.lbox(b, KG, "wl_steel", ko, t, n, 2.25, 0.0, 0.0, 0.85, 1.95, 0.66, ["-y"])
	b.cur_color = Color("#3a3c3e")
	K.lbox(b, KG, "vcolor", ko, t, n, 2.67, 0.1, 0.66, 0.012, 1.75, 0.004)
	K.lbox(b, KG, "vcolor", ko, t, n, 2.58, 0.95, 0.66, 0.025, 0.3, 0.03)
	b.cur_color = Color.WHITE
	var kl = b.add_omni(P2.call(1.75, 2.5, R_D + 0.5), 0.5, 4.0, Color(0.96, 0.98, 1.0))
	b.tag(kl, "", 0.5, 0.5)

## A window booth (Steven's photo of booths at a window): along r from o (o on the glass line),
## f into the room: a bench, a table square to the glass on a pedestal, a bench facing it; the
## benches' high backs carry vertical channels. 1.65 m along r.
static func window_booth(b, G, o, r, f):
	var bl = 1.2          # bench length, out from the glass
	for s in [[0.0, 1.0], [1.65, -1.0]]:
		var bo = o + r * s[0]
		var face = r * s[1]           # the way the sitter faces
		b.box(G, "wl_booth", bo + face * 0.25 + f * (bl * 0.5) + UP * 0.22, b.abs_size(f, bl, 0.44, 0.48, face))
		b.box(G, "wl_booth", bo + face * 0.06 + f * (bl * 0.5) + UP * 0.78, b.abs_size(f, bl, 0.68, 0.12, face))
		for k in 5:
			b.cur_color = Color("#8a3a22")
			b.box(G, "vcolor", bo + face * 0.121 + f * (0.12 + k * 0.24) + UP * 0.8, b.abs_size(f, 0.012, 0.56, 0.004, face))
		b.cur_color = Color.WHITE
	var tc = o + r * 0.825 + f * 0.5
	b.cur_color = Color("#2a2a2c")
	b.cyl(G, "vcolor", tc + f * 0.15, 0.2, 0.2, 0.03, 12, true, false)
	b.cyl(G, "vcolor", tc + f * 0.15, 0.04, 0.04, 0.72, 8, false, false)
	b.cur_color = Color.WHITE
	b.box(G, "wl_laminate", tc + UP * 0.74, b.abs_size(r, 0.7, 0.035, 0.95, f))
	K.ob(b, o - f * 0.05, o + r * 1.65 + f * (bl + 0.05), 0.05)

## The lunch counter and back bar on the right side (u 0.12): a stainless back bar against a cream
## striped tile wall under a strip of menu cards, a stainless canopy over it; on it a pie case, the
## soda fountain, a soft-serve machine, malt mixers, coffee urns and stacked glasses. The counter
## (wood-grain front between black pilasters, a black top with a steel edge, a chrome foot rail)
## runs from the back to d LC_D0, curves round toward the window and ends at the wall (Steven's
## curved-end photo); chrome stools with coral and teal seats line it and follow the curve.
const LC_U = 2.45         # the counter's customer face
const LC_DP = 0.68        # its depth
const LC_H = 1.0
## Steven, Nov 11 (WOOL-FRONT): "Shorten bar (this area of barstools crowds the booth seat to its
## right)". The straight run is 1.6 m shorter (was LC_D0 = 3.6), so the curved end and its stools
## stand clear of the window booths: the curve meets the wall at d 2.87, the first booth's bench
## ends at d 1.34. The curve keeps his Oct 20 shape; it carries two stools (was three).
const LC_D0 = 5.2         # where the straight run ends and the curve begins
const LC_D1 = 12.8        # its back end
static func lunch_counter(b, G, S, a, t, n, rng):
	var P2 = func(u, y, d): return P(a, t, n, u, y, d)
	var u0 = SIDE
	# --- the back wall of the bar: striped tile, the menu strip, the canopy
	var tw0 = LC_D0 - 1.4     # the back bar's front end, just inside the curve
	var tw1 = R_D - 0.12
	b.quad(G, "wl_tile_stripe", [P2.call(u0 + 0.01, 0.9, tw0), P2.call(u0 + 0.01, 0.9, tw1), P2.call(u0 + 0.01, 2.0, tw1), P2.call(u0 + 0.01, 2.0, tw0)], t,
		[Vector2(tw0, 1.1), Vector2(tw1, 1.1), Vector2(tw1, 0.0), Vector2(tw0, 0.0)])
	K.fq(b, G, "wl_price_strip", P2.call(u0, 0, tw0 + 0.3), -n, t, 0.0, 4.6, 2.32, 2.66, 0.02, 0.0, 0.0, 1.0, 1.0)
	K.fq(b, G, "wl_price_strip", P2.call(u0, 0, tw0 + 5.0), -n, t, 0.0, 4.6, 2.32, 2.66, 0.02, 0.0, 0.0, 1.0, 1.0)
	K.lbox(b, G, "wl_steel", P2.call(u0, 0, tw0), -n, t, 0.0, 2.05, 0.0, tw1 - tw0, 0.08, 0.5, [])
	K.lbox(b, G, "wl_steel", P2.call(u0, 0, tw0), -n, t, 0.0, 2.13, 0.0, tw1 - tw0, 0.16, 0.12, [])
	for d in [4.4, 6.4, 8.4, 10.4]:
		b.cyl(G, "wl_warm_disc", P2.call(u0 + 0.3, 2.045, d), 0.06, 0.06, 0.004, 10, false, true)
	# --- the back bar: stainless cabinets and its top
	K.lbox(b, G, "wl_steel", P2.call(u0, 0, tw0), -n, t, 0.0, 0.0, 0.0, tw1 - tw0, 0.9, 0.6, ["-y"])
	b.cur_color = Color("#1c1c1e")
	K.lbox(b, G, "vcolor", P2.call(u0, 0, tw0), -n, t, 0.0, 0.9, 0.0, tw1 - tw0, 0.03, 0.62, ["-y"])
	b.cur_color = Color.WHITE
	var bb = func(d, x): return P2.call(u0 + x, 0.93, d)
	# the pie case: a steel base, glass sides, pies on two shelves
	var pc = bb.call(4.4, 0.3)
	b.box(S, "wl_steel", pc + UP * 0.03, Vector3(0.45, 0.06, 0.8))
	b.box(S, "wl_steel", pc + UP * 0.5, Vector3(0.45, 0.03, 0.8))
	b.cur_color = Color("#e8d0a0")
	for j in 2:
		for q in 2:
			b.cyl(S, "vcolor", pc + UP * (0.07 + j * 0.2) - n * (-0.2 + q * 0.4), 0.13, 0.13, 0.05, 12, true, false)
	b.cur_color = Color.WHITE
	b.quad("glass", "glass", [pc + t * 0.225 + n * 0.4 + UP * 0.06, pc + t * 0.225 - n * 0.4 + UP * 0.06, pc + t * 0.225 - n * 0.4 + UP * 0.49, pc + t * 0.225 + n * 0.4 + UP * 0.49], t,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)], true)
	# the soda fountain: a chrome tower with a row of taps and a drip tray
	var sf = bb.call(5.4, 0.3)
	K.column(b, S, "wl_steel", sf, 0.09, 0.42, 12)
	b.box(S, "wl_steel", sf + UP * 0.47, b.abs_size(-n, 0.7, 0.12, 0.2, t))
	for j in 5:
		b.box(S, "wl_steel", sf + UP * 0.38 + n * (-0.28 + j * 0.14) + t * 0.11, Vector3(0.03, 0.12, 0.03))
		b.cur_color = [Color("#c81e28"), Color("#f2f0ea"), Color("#3a2416"), Color("#e8c23a"), Color("#2a7a3a")][j]
		b.box(S, "vcolor", sf + UP * 0.56 + n * (-0.28 + j * 0.14) + t * 0.11, Vector3(0.04, 0.07, 0.04))
		b.cur_color = Color.WHITE
	b.box(S, "wl_steel", sf + UP * 0.01 + t * 0.12, b.abs_size(-n, 0.75, 0.02, 0.18, t))
	# the soft-serve machine: a steel cabinet, two spouts with a black handle each, a hopper lid
	var ic = bb.call(7.4, 0.3)
	b.box(S, "wl_steel", ic + UP * 0.38, b.abs_size(-n, 0.6, 0.76, 0.5, t))
	b.cur_color = Color("#1c1c1e")
	for j in 2:
		b.box(S, "vcolor", ic + UP * 0.45 + n * (-0.12 + j * 0.24) + t * 0.27, Vector3(0.06, 0.08, 0.06))
		b.box(S, "vcolor", ic + UP * 0.58 + n * (-0.12 + j * 0.24) + t * 0.29, Vector3(0.025, 0.12, 0.025))
	b.cur_color = Color("#f4ecd8")
	b.cyl(S, "vcolor", ic + UP * 0.32 + t * 0.26, 0.05, 0.03, 0.08, 10, true, false)
	b.cur_color = Color.WHITE
	K.fq(b, S, "wl_red", ic + t * 0.252, -n, t, -0.28, 0.28, 0.66, 0.72, 0.0)
	# three green malt mixers on a stand, metal cups under them
	var mm = bb.call(9.0, 0.25)
	for j in 3:
		var mc = mm + n * (-0.25 + j * 0.25)
		b.cur_color = Color("#5aa080")
		b.box(S, "vcolor", mc + UP * 0.03, Vector3(0.14, 0.06, 0.18))
		b.box(S, "vcolor", mc + UP * 0.25 - t * 0.05, Vector3(0.1, 0.42, 0.08))
		b.box(S, "vcolor", mc + UP * 0.48 + t * 0.02, Vector3(0.12, 0.1, 0.2))
		b.cur_color = Color.WHITE
		b.cyl(S, "wl_steel", mc + UP * 0.06 + t * 0.05, 0.045, 0.04, 0.18, 10, true, false)
	# two coffee urns and a stack of glasses
	for j in 2:
		var uc = bb.call(10.6 + j * 0.55, 0.3)
		K.column(b, S, "wl_steel", uc, 0.17, 0.62, 14)
		b.cyl(S, "wl_steel", uc + UP * 0.62, 0.17, 0.08, 0.08, 14, true, false)
		b.cur_color = Color("#1c1c1e")
		b.box(S, "vcolor", uc + UP * 0.12 + t * 0.18, Vector3(0.05, 0.05, 0.05))
		b.cur_color = Color.WHITE
	b.cur_color = Color("#e8eef0")
	for j in 6:
		b.cyl(S, "vcolor", bb.call(12.0 + (j % 3) * 0.12, 0.25 + (j / 3) * 0.12), 0.04, 0.035, 0.12, 8, true, false)
	b.cur_color = Color.WHITE
	# --- the counter: a straight run, then the curve round to the wall
	var path = counter_path()
	var cu = LC_U
	for i in path.size() - 1:
		var A = path[i]
		var B = path[i + 1]
		counter_seg(b, G, P2.call(A.x, 0, A.y), P2.call(B.x, 0, B.y), A.z, B.z, a, t, n)
	# the top: a black slab with a steel edge, from the curve's segments
	K.ob(b, P2.call(u0, 0, LC_D0), P2.call(cu + 0.05, 0, LC_D1 + 0.05), 0.04)
	for i in path.size() - 1:
		var A2 = path[i]
		var B2 = path[i + 1]
		var mid = (Vector2(A2.x, A2.y) + Vector2(B2.x, B2.y)) * 0.5
		K.ob(b, P2.call(mid.x - 0.4, 0, mid.y - 0.4), P2.call(mid.x + 0.4, 0, mid.y + 0.4), 0.0)
	# the stools: along the run every 0.62 m, then round the curve
	var k = 0
	var d = LC_D1 - 0.45
	while d > LC_D0 + 0.2:
		stool(b, S, P2.call(LC_U + 0.42, 0, d), -t, k)
		d -= 0.62
		k += 1
	for ang in [20.0, 50.0]:
		var th = deg_to_rad(ang)
		var rr = (LC_U - u0) + 0.42
		var su = u0 + rr * cos(th)
		var sd = LC_D0 - rr * sin(th)
		var face = (P2.call(u0, 0, LC_D0) - P2.call(su, 0, sd)).normalized()
		stool(b, S, P2.call(su, 0, sd), face, k)
		k += 1

## The counter's plan: points (u, d, angle) along its customer face, from the back end down the
## run to the curve and round a quarter circle centred on the right wall at LC_D0, to the wall.
static func counter_path():
	var pts = [Vector3(LC_U, LC_D1, 0.0), Vector3(LC_U, LC_D0, 0.0)]
	var R = LC_U - SIDE
	for i in range(1, 9):
		var th = PI * 0.5 * i / 8.0
		pts.append(Vector3(SIDE + R * cos(th), LC_D0 - R * sin(th), th))
	return pts

## One piece of the counter between two points of its customer face (pa, pb on the floor): the
## wood-grain front, the black top with its steel edge, the foot rail; it runs LC_DP back from the
## face toward the curve's centre (the wall at LC_D0) or toward the wall on the straight run.
static func counter_seg(b, G, pa, pb, tha, thb, a, t, n):
	var c0 = P(a, t, n, SIDE, 0, LC_D0)
	var ia = pa - t * LC_DP if tha == 0.0 else pa + (c0 - pa).normalized() * LC_DP
	var ib = pb - t * LC_DP if thb == 0.0 else pb + (c0 - pb).normalized() * LC_DP
	var out = t
	if tha != 0.0 or thb != 0.0:
		out = (pa + pb) * 0.5 - c0
		out.y = 0.0
		out = out.normalized()
	var ln = pa.distance_to(pb)
	b.quad(G, "wl_lunch_front", [pa, pb, pb + UP * (LC_H - 0.04), pa + UP * (LC_H - 0.04)], out,
		[Vector2(0, 1), Vector2(ln / 1.2, 1), Vector2(ln / 1.2, 0.04), Vector2(0, 0.04)])
	var e = out * 0.03
	var top = UP * LC_H
	b.cur_color = Color("#141416")
	b.quad(G, "vcolor", [pa + e + top, pb + e + top, ib + top, ia + top], UP)
	b.cur_color = Color.WHITE
	b.quad(G, "wl_steel", [pa + e + top - UP * 0.04, pb + e + top - UP * 0.04, pb + e + top, pa + e + top], out)
	# the clerks' side of the counter, under the top
	b.cur_color = Color("#d8d6d0")
	b.quad(G, "vcolor", [ib, ia, ia + UP * (LC_H - 0.02), ib + UP * (LC_H - 0.02)], -out)
	b.cur_color = Color.WHITE
	# the chrome foot rail 0.2 m up, on short posts
	var r0 = pa + out * 0.12 + UP * 0.2
	var r1 = pb + out * 0.12 + UP * 0.2
	_rail(b, G, r0, r1)

static func _rail(b, G, r0, r1):
	var along = (r1 - r0).normalized()
	var side = along.cross(UP).normalized()
	b.box(G, "wl_steel", Vector3.ZERO, Vector3(0.035, 0.035, r0.distance_to(r1) + 0.02), Transform3D(Basis(side, UP, along), (r0 + r1) * 0.5))

## A lunch-counter stool at c facing f (Steven's photo): an octagonal black foot, a black pedestal,
## a round seat in coral or teal vinyl with a chrome rim, a chrome back of three bars.
static func stool(b, S, c, f, k):
	var r = f.cross(UP).normalized()
	b.cur_color = Color("#141416")
	b.cyl(S, "vcolor", c, 0.2, 0.2, 0.03, 8, true, false)
	b.cyl(S, "vcolor", c + UP * 0.03, 0.06, 0.045, 0.6, 10, false, false)
	b.cur_color = Color.WHITE
	b.cyl(S, "wl_steel", c + UP * 0.63, 0.205, 0.205, 0.045, 16, false, false)
	b.cur_color = Color("#e07a62") if k % 2 == 0 else Color("#6fb3a8")
	b.cyl(S, "vcolor", c + UP * 0.66, 0.19, 0.19, 0.04, 16, true, false)
	b.cur_color = Color.WHITE
	var bc = c - f * 0.17
	for x in [-0.14, 0.14]:
		b.box(S, "wl_steel", bc + r * x + UP * 0.86, Vector3(0.02, 0.36, 0.02))
	b.box(S, "wl_steel", bc + UP * 1.04, b.abs_size(r, 0.32, 0.03, 0.03, f))
	b.box(S, "wl_steel", bc + UP * 0.86, b.abs_size(r, 0.02, 0.32, 0.02, f))
	for x in [-0.07, 0.07]:
		b.box(S, "wl_steel", bc + r * x + UP * 0.9, Vector3(0.015, 0.26, 0.015))
	K.ob(b, c - Vector3(0.2, 0, 0.2), c + Vector3(0.2, 0, 0.2), 0.02)

## A booth: two orange-red vinyl benches facing each other across a white table, against
## the wall at `o` (`r` along the wall, `f` out into the room).
static func booth(b, G, o, r, f, rng):
	for s in [-1.0, 1.0]:
		var bo = o + r * (0.65 * s)
		var face = -r * s
		var rr = (-face).cross(UP)
		b.box(G, "wl_booth", bo + f * 0.6 + UP * 0.22, b.abs_size(rr, 1.2, 0.44, 0.5, face))
		b.box(G, "wl_booth", bo + f * 0.6 - face * 0.22 + UP * 0.72, b.abs_size(rr, 1.2, 0.56, 0.12, face))
	table(b, G, o + f * 0.6, 0.62, 1.1)
	K.ob(b, o - r * 0.95, o + r * 0.95 + f * 1.25, 0.05)

## A white laminate table on a pedestal (the restaurant's tables, video 6:25).
static func table(b, G, c, w = 0.75, l = 0.75):
	b.cur_color = Color("#2a2a2c")
	b.cyl(G, "vcolor", c, 0.22, 0.22, 0.03, 12, true, false)
	b.cyl(G, "vcolor", c, 0.04, 0.04, 0.72, 8, false, false)
	b.cur_color = Color.WHITE
	b.box(G, "wl_laminate", c + UP * 0.74, Vector3(w, 0.035, l) if true else Vector3.ONE)
	K.ob(b, c - Vector3(w, 0, l) * 0.5, c + Vector3(w, 0, l) * 0.5, 0.15)

## An orange-red vinyl chair facing `f`.
static func chair(b, S, c, f):
	var r = (-f).cross(UP)
	b.cur_color = Color("#2a2a2c")
	for q in [Vector2(-0.18, -0.18), Vector2(0.18, -0.18), Vector2(-0.18, 0.18), Vector2(0.18, 0.18)]:
		b.box(S, "vcolor", c + r * q.x + f * q.y + UP * 0.22, Vector3(0.025, 0.44, 0.025))
	b.cur_color = Color.WHITE
	b.box(S, "wl_booth", c + UP * 0.47, b.abs_size(r, 0.44, 0.07, 0.44, f))
	b.box(S, "wl_booth", c - f * 0.2 + UP * 0.75, b.abs_size(r, 0.42, 0.42, 0.05, f))

# ------------------------------------------------------------------ the sales floor
static func floor_fixtures(b, a, t, n, rng):
	var u1 = UNIT - SIDE
	var dB = DEPTH - SIDE
	var u9 = R_U + WALL_T
	# -- perimeter wall shelving under the red band
	# left wall, front to back: apparel (folded), apparel, housewares, domestics (linens)
	var left = [["linens"], ["boxes"], ["boxes", "hba"], ["linens"], ["boxes"]]
	var d = 1.6
	var k = 0
	while d + BAY <= dB - 1.3:   # the back corner stays bare: the taped Stockrooms opening (Oct 20)
		var sh = [["linens"]] if d < 12.0 else ([["boxes"]] if d < 24.0 else [["linens", "boxes"]])
		K.bay_run(b, grp("fix", 30.0, d), grp("merch", 30.0, d), P(a, t, n, u1, 0, d), -n, -t, BAY, 1, BOARDS, sh, [-1], "", 0.0, rng, 0.4)
		d += BAY
		k += 1
	# back wall, left corner to the right: housewares, toys, the stockroom doors, party goods, cards
	var u = u1 - 0.45 - BAY     # the corner bay gave way to the taped Stockrooms opening (Oct 20)
	while u - BAY >= SIDE + 0.45:
		if u > 20.4 and u - BAY < 24.9:
			u -= BAY
			continue   # the stockroom doors
		var sh = [["boxes"]] if u > 24.0 else ([["kb_action", "kb_vehicles"], ["kb_dolls", "kb_games"]][int(u) % 2] if u > 9.6 else [["party"]])
		K.bay_run(b, grp("fix", u, 30.0), grp("merch", u, 30.0), P(a, t, n, u, 0, dB), -t, n, BAY, 1, BOARDS, [sh] if sh[0] is String else sh, [-1], "", 0.0, rng, 0.4)
		u -= BAY
	# right wall behind the restaurant: greeting cards, then party goods
	d = dB - 0.45
	while d - BAY >= R_D + K_DP + 0.1:   # the bays stop short of the kitchen (WOOL-FRONT, Nov 11)
		var sh = [["gcards"]] if d > 24.0 else [["party"]]
		K.bay_run(b, grp("fix", 2.0, d), grp("merch", 2.0, d), P(a, t, n, SIDE, 0, d), n, t, BAY, 1, BOARDS, sh, [-1], "", 0.0, rng, 0.4)
		d -= BAY
	# -- gondola runs across the store either side of the main aisle
	# right front: health & beauty, candy, cards (u 11.2..19.7)
	for s in [[6.0, ["hba"]], [9.3, ["hba", "candy"]], [12.6, ["candy"]]]:
		K.gondola(b, grp("fix", 15.0, s[0]), grp("merch", 15.0, s[0]), P(a, t, n, 19.7, 0, s[0]), -t, n, BAY, 7, LOW, s[1], rng, 0.32)
	# right back: toys (Kay-Bee's sheets; video 0:00-1:16)
	for s in [[22.6, ["kb_action", "kb_vehicles"]], [25.9, ["kb_dolls", "kb_preschool"]], [29.2, ["kb_games", "kb_sports"]], [32.3, ["kb_vehicles", "kb_action"]]]:
		K.gondola(b, grp("fix", 15.0, s[0]), grp("merch", 15.0, s[0]), P(a, t, n, 19.7, 0, s[0]), -t, n, BAY, 7, LOW, s[1], rng, 0.32)
	# behind the restaurant: cards and party goods
	for s in [[17.8, ["gcards"]], [21.4, ["party"]], [25.0, ["gcards"]], [28.6, ["party", "candy"]]]:
		K.gondola(b, grp("fix", 5.0, s[0]), grp("merch", 5.0, s[0]), P(a, t, n, 8.3, 0, s[0]), -t, n, BAY, 4, LOW, s[1], rng, 0.32)
	# left back: housewares, small appliances, linens (video 4:16-5:22)
	for s in [[22.6, ["boxes"]], [25.9, ["boxes", "linens"]], [29.2, ["linens"]], [32.3, ["boxes"]]]:
		K.gondola(b, grp("fix", 30.0, s[0]), grp("merch", 30.0, s[0]), P(a, t, n, 34.2, 0, s[0]), -t, n, BAY, 7, LOW, s[1], rng, 0.32)
	# left front: round racks and T-stands of clothes (video 1:19-1:58, 2:28)
	for c in [[27.0, 6.5], [30.2, 6.5], [33.2, 7.2], [27.0, 10.0], [30.2, 10.0], [33.2, 10.8], [27.0, 13.5], [30.2, 13.5]]:
		round_rack(b, grp("fix", 30.0, 9.0), P(a, t, n, c[0], 0, c[1]), rng)
	# -- the front end (Steven, Nov 11, WOOL-FRONT: "Remove the customer service desk, move
	# checkouts to left side and the area where they were on the right as open. The checkout
	# counters should be numbered 1,2,3,4."): four checkout lanes at the left front, where the
	# service booth stood, lane lights 1-4 reading left to right from the hall (GUESS: the
	# order); the right front (u 9.6..20) is open floor up to the first gondola. The carts stay
	# by the main aisle (GUESS: his note does not mention them).
	var lanes = 0
	for uu in CHECKOUT_U:
		lanes += 1
		checkout(b, P(a, t, n, uu, 0, CHECKOUT_D), t, n, lanes, rng)
	for j in 3:
		cart(b, "wl00_small", P(a, t, n, 20.2 + j * 0.0, 0, 1.4 + j * 0.42), n)
	K.ob(b, P(a, t, n, 19.8, 0, 1.0), P(a, t, n, 20.6, 0, 3.0), 0.1)

## A round rack of hanging clothes: chrome ring on a pole, a ring of garments.
static func round_rack(b, G, c, rng):
	var rad = 0.55
	b.cyl(G, "md_chrome", c, 0.25, 0.25, 0.02, 16, true, false)
	b.cyl(G, "md_chrome", c, 0.02, 0.02, 1.35, 8, false, false)
	var seg = 14
	var u0 = rng.randf()
	for i in seg:
		var a0 = TAU * i / seg
		var a1 = TAU * (i + 1) / seg
		var d0 = Vector3(cos(a0), 0, sin(a0))
		var d1 = Vector3(cos(a1), 0, sin(a1))
		var nn = (d0 + d1).normalized()
		b.quad(G, "wl_garments", [c + d0 * rad + UP * 0.45, c + d1 * rad + UP * 0.45, c + d1 * rad + UP * 1.32, c + d0 * rad + UP * 1.32], nn,
			[Vector2(u0 + float(i) / seg, 1), Vector2(u0 + float(i + 1) / seg, 1), Vector2(u0 + float(i + 1) / seg, 0.1), Vector2(u0 + float(i) / seg, 0.1)])
	b.cyl(G, "md_chrome", c + UP * 1.32, rad + 0.02, rad + 0.02, 0.025, 20, true, false)
	K.ob(b, c - Vector3(rad, 0, rad), c + Vector3(rad, 0, rad), 0.1)

## The four checkout lanes (WOOL-FRONT, Nov 11): the u of each counter's right edge, lane 1 first
## (the far left as you face the store from the hall), and the d they start at.
const CHECKOUT_U = [33.6, 31.2, 28.8, 26.4]
const CHECKOUT_D = 1.6

## A checkout counter running into the store (customers pass along it toward the hall),
## a register, an impulse rack at its head, and the numbered lane light on a pole.
static func checkout(b, o, t, n, num, rng):
	var G = "wl10_fix"
	var S = "wl10_small"
	var into = -n
	K.lbox(b, G, "wl_laminate", o, into, t, 0.0, 0.0, 0.0, 2.6, 0.9, 0.75, ["-y"])
	K.fq(b, G, "wl_counter", o, into, t, 0.0, 2.6, 0.0, 0.9, 0.752)
	K.fq(b, G, "wl_counter", o + into * 2.6 + t * 0.75, -into, -t, 0.0, 2.6, 0.0, 0.9, 0.752)
	K.register(b, S, K.L(o, into, t, 0.4, 0.9, 0.2), into, -t)
	# the impulse rack: candy and batteries on a low stand at the lane's head
	K.bay(b, G, "wl10_merch", o + into * 2.7, t, into, 0.75, [0.5, 0.85, 1.2], ["candy"], rng, 0.25)
	# the lane light
	var pole = K.L(o, into, t, 0.1, 0.0, 0.65)
	b.cyl(S, "md_chrome", pole, 0.025, 0.025, 2.5, 8, false, false)
	var lc = pole + UP * 2.62
	b.cur_color = Color("#f4f4f0")
	b.box(S, "vcolor", lc, Vector3(0.3, 0.3, 0.3))
	b.cur_color = Color.WHITE
	for f in [n, -n]:
		var r = (-f).cross(UP)
		K.fq(b, S, "wl_lanes", lc - r * 0.14, r, f, 0.0, 0.28, -0.14, 0.14, 0.152, (num - 1) / 8.0, 0.0, num / 8.0, 1.0)
	K.ob_local(b, o, into, t, 0.0, 0.0, 3.0, 0.75)

## A red shopping cart facing `f` (video 0:13): a wire basket, a handle, a frame on casters.
static func cart(b, S, c, f):
	var r = (-f).cross(UP)
	b.cur_color = Color("#b8141c")
	b.box(S, "vcolor", c + UP * 0.72, b.abs_size(r, 0.5, 0.42, 0.85, f), Transform3D.IDENTITY, ["+y"])
	b.box(S, "vcolor", c - f * 0.47 + UP * 1.0, b.abs_size(r, 0.5, 0.04, 0.04, f))
	b.cur_color = Color("#3a3a3c")
	b.box(S, "vcolor", c + UP * 0.25, b.abs_size(r, 0.44, 0.04, 0.8, f))
	for q in [Vector2(-0.2, -0.38), Vector2(0.2, -0.38), Vector2(-0.18, 0.38), Vector2(0.18, 0.38)]:
		b.box(S, "vcolor", c + r * q.x + f * q.y + UP * 0.05, Vector3(0.05, 0.1, 0.05))
	b.cur_color = Color.WHITE

# ------------------------------------------------------------------ materials
## "wl_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	match key:
		"red_panel":
			m.albedo_texture = b.tex("wl/red_panel.png"); m.roughness = 0.35; m.metallic_specular = 0.55
		"lightbox":
			m.albedo_texture = b.tex("wl/lightbox.png"); m.roughness = 0.4
			K.emit_tex(m, 1.1)
		"signs":
			m.albedo_texture = b.tex("wl/signs.png"); m.roughness = 0.5
			K.emit_tex(m, 0.25)
		"dept_band":
			m.albedo_texture = b.tex("wl/dept_band.png"); m.roughness = 0.5
			# Nov 1 (workstream D): a little light of its own so the names read across the floor
			K.emit_tex(m, 0.25)
			K.emit_tex(m, 0.2)
		"floor":
			m.albedo_texture = b.tex("wl/floor.png"); m.roughness = 0.12; m.metallic_specular = 0.7
		"rest_floor":
			m.albedo_texture = b.tex("wl/floor.png"); m.roughness = 0.3; m.metallic_specular = 0.5
			m.albedo_color = Color(0.78, 0.6, 0.46)
		"red":
			m.albedo_color = Color("#c4161f"); m.roughness = 0.2; m.metallic_specular = 0.6
		"alum":
			m.albedo_color = Color("#b8babd"); m.metallic = 0.6; m.roughness = 0.35
			K.emit(m, Color("#707276"), 0.2)
		"wood":
			m.albedo_texture = b.tex("wood_dark.png"); m.roughness = 0.5
			m.albedo_color = Color(1.5, 1.25, 1.0)
		"laminate":
			m.albedo_color = Color("#ecebe6"); m.roughness = 0.3; m.metallic_specular = 0.5
		"counter":
			m.albedo_texture = b.tex("wl/counter.png"); m.roughness = 0.35; m.metallic_specular = 0.45
		"lanes":
			m.albedo_texture = b.tex("wl/lanes.png")
			K.emit_tex(m, 1.2)
		"garments":
			m.albedo_texture = b.tex("wl/garments.png"); m.roughness = 0.9; m.metallic_specular = 0.1
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
		"beige":
			m.albedo_color = Color("#d9c8a4"); m.roughness = 0.9
		"rest_ceiling":
			m.albedo_color = Color("#bfae8e"); m.roughness = 0.95
		"warm_disc":
			m.albedo_color = Color.WHITE
			K.emit(m, Color("#ffd9a0"), 3.0)
		"globe":
			m.albedo_color = Color("#fff0d0")
			K.emit(m, Color("#ffd49a"), 2.0)
		"slats":
			m.albedo_texture = b.tex("wl/slats.png"); m.roughness = 0.6
		"lattice":
			m.albedo_texture = b.tex("wl/lattice.png"); m.roughness = 0.8
		"food_photos":
			m.albedo_texture = b.tex("wl/food_photos.png"); m.roughness = 0.4; m.metallic_specular = 0.5
		"menu":
			m.albedo_texture = b.tex("wl/menu.png")
			K.emit_tex(m, 1.3)
		"rest_counter":
			m.albedo_texture = b.tex("wl/rest_counter.png"); m.roughness = 0.4
		"tape":
			m.albedo_color = Color("#1f6672"); m.roughness = 0.75
		"lunch_front":
			m.albedo_texture = b.tex("wl/lunch_front.png"); m.roughness = 0.4; m.metallic_specular = 0.45
		"tile_stripe":
			m.albedo_texture = b.tex("wl/tile_stripe.png"); m.roughness = 0.25; m.metallic_specular = 0.6
		"price_strip":
			m.albedo_texture = b.tex("wl/price_strip.png"); m.roughness = 0.5
			K.emit_tex(m, 0.5)
		"booth":
			m.albedo_texture = b.tex("wl/vinyl_booth.png"); m.roughness = 0.35; m.metallic_specular = 0.5
		"steel":
			m.albedo_color = Color("#c4c6c8"); m.metallic = 0.5; m.roughness = 0.3
			K.emit(m, Color("#606264"), 0.15)
		_:
			return false
	return true
