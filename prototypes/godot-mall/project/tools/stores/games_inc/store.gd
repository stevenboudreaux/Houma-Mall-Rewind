## games, inc. (2026, store s52: the old Blockbuster Music box, 8 x 40 m, on the Concourse's south side
## between the vacant aqua-tile Pocket Change unit s52b and the food-court wall).
##
## Rebuilt Nov 2, 2026 (workstream GI) from Steven's walkthrough: IMG_4443 (f001-f058), IMG_4444
## (g001-g006) and photo IMG_4445. Steven: Games, Inc. is its own place in 2026, not Pocket Change; the
## Demo 46 build (Pocket Change's 1990s machines thrown in) is replaced by its own machine kit,
## tools/stores/games_inc/machines/ (one file per kind, atlases painted by machines/paint.py, materials
## "gi_m_<kind>_<key>" and "gi_k_<key>"). Every position below comes from the inventory table in
## design/storefronts/games-inc-2026.md (ids F*, P*, Q*, M* refer to its rows).
##
## Frame: u runs along the frontage from the edge's start `a` (the hall viewer's right: the food-court
## side, the right wall walking in) to 8 (the left wall, the s52b side); d runs into the store; y is up.

const UNIT = 8.0
const DEPTH = 40.0
const ROOM_D = 39.0         # the back wall
const SIDE = 0.12           # party walls' inner faces
const WALL_T = 0.45         # the front wall's thickness (the tile returns run back through it)
const CEIL = 3.4            # white lay-in ceiling (F11)
const TILE_TOP = 3.25       # top of the mustard tile frame (F1)
const GB0 = 0.55            # F2 the right glass bay (frameless glass pair)
const GB1 = 2.05
const O0 = 2.4              # F3 the opening
const O1 = 5.05
const SIGN_Y0 = 2.35        # the white sign panel in the opening's top
const SIGN_Y1 = 2.95
const W0 = 5.4              # F4 the plush window
const W1 = 7.45
const GLASS_TOP = 2.95
const SHELF_Y = 2.42        # F8 the wall shelf; the red-orange band above, a mustard band below it
const MUST_Y0 = 2.27
const PC = "res://tools/stores/pocket_change/%s.gd"
const WW_U = 3.5            # PRIZES: the WHIRLWIND's console (front edge) centre, a guess (see machines())
const WW_D = 5.4
const MK = "res://tools/stores/games_inc/machines/"

static func P(a, t, n, u, y, d):
	return a + t * u - n * d + Vector3(0, y, 0)

## A wall-plane quad u0..u1, y0..y1 at depth d facing `nn` (default: the hall), UVs in metres / per.
static func wq(b, g, m, a, t, n, u0, u1, y0, y1, d, per, nn = null):
	var p = [P(a, t, n, u0, y0, d), P(a, t, n, u1, y0, d), P(a, t, n, u1, y1, d), P(a, t, n, u0, y1, d)]
	var uv = [Vector2(-u0 / per, -y0 / per), Vector2(-u1 / per, -y0 / per), Vector2(-u1 / per, -y1 / per), Vector2(-u0 / per, -y1 / per)]
	b.quad(g, m, p, n if nn == null else nn, uv)

## A quad on the side wall at u (facing `nn`), d0..d1 x y0..y1, texture rect r stretched once
## (r.x at d0's end as seen from the room).
static func sq(b, g, m, a, t, n, u, d0, d1, y0, y1, nn, r):
	b.quad(g, m, [P(a, t, n, u, y0, d0), P(a, t, n, u, y0, d1), P(a, t, n, u, y1, d1), P(a, t, n, u, y1, d0)], nn,
		[Vector2(r.x, r.w), Vector2(r.z, r.w), Vector2(r.z, r.y), Vector2(r.x, r.y)])

static func K():
	return load(MK + "kit.gd")

static func build(b, g, e, a, bb, n, t, Ln, sd):
	front(b, "gi_front", a, t, n, sd)
	room(b, "gi_shell", a, t, n)
	lights(b, "gi_shell", a, t, n)
	machines(b, a, t, n)
	var rp = ReflectionProbe.new()
	rp.position = P(a, t, n, UNIT * 0.5, CEIL * 0.5, ROOM_D * 0.5)
	rp.size = (t * UNIT + n * ROOM_D).abs() + Vector3(0.1, CEIL + 0.1, 0.1)
	rp.box_projection = true
	rp.interior = true
	rp.update_mode = ReflectionProbe.UPDATE_ONCE
	rp.intensity = 0.5
	b.light_root.add_child(rp)

# ------------------------------------------------------------------ the front (F1-F6)
static func front(b, g, a, t, n, sd):
	var LH = b.LANE_H
	# the mall's cream wall over the tile frame, white end piers
	wq(b, g, "cream", a, t, n, 0.0, UNIT, TILE_TOP, LH, 0.0, 1.0)
	b.cur_color = Color("#f2efe8")
	for pr in [[0.0, 0.3], [UNIT - 0.3, UNIT]]:
		b.box(g, "vcolor_matte", P(a, t, n, (pr[0] + pr[1]) * 0.5, TILE_TOP * 0.5, 0.0), b.abs_size(t, pr[1] - pr[0], TILE_TOP, 0.06, n))
	b.cur_color = Color.WHITE
	# mustard tile: the piers between the bays, the head over all three, the sill under the window
	for pr in [[0.3, GB0], [GB1, O0], [O1, W0], [W1, UNIT - 0.3]]:
		wq(b, g, "gi_tile", a, t, n, pr[0], pr[1], 0.0, TILE_TOP, -0.02, 0.6)
	wq(b, g, "gi_tile", a, t, n, GB0, W1, GLASS_TOP, TILE_TOP, -0.02, 0.6)
	wq(b, g, "gi_tile", a, t, n, W0, W1, 0.0, 0.08, -0.02, 0.6)
	# F3: the white sign panel filling the opening's top, the lit sign on it (y26/parts/games.json)
	b.cur_color = Color.WHITE
	b.box(g, "gi_panel", P(a, t, n, (O0 + O1) * 0.5, (SIGN_Y0 + SIGN_Y1) * 0.5, 0.02), b.abs_size(t, O1 - O0, SIGN_Y1 - SIGN_Y0, 0.08, n))
	var mid = P(a, t, n, (O0 + O1) * 0.5, 0, -0.03)
	b.sign_2026(g, sd.name, mid - Vector3(0, b.OPEN_H + (b.LANE_H - b.OPEN_H) * 0.5, 0) + Vector3(0, (SIGN_Y0 + SIGN_Y1) * 0.5, 0), n, t, O1 - O0 - 0.1)
	# F2: the frameless glass pair (closed), a floor track and the centre joint
	wq(b, g, "glass", a, t, n, GB0, GB1, 0.0, GLASS_TOP, 0.06, 1.0)
	b.cur_color = Color("#b9b4a8")
	b.box(g, "vcolor", P(a, t, n, (GB0 + GB1) * 0.5, 0.01, 0.06), b.abs_size(t, GB1 - GB0, 0.02, 0.08, n))
	b.box(g, "vcolor", P(a, t, n, (GB0 + GB1) * 0.5, GLASS_TOP * 0.5, 0.06), b.abs_size(t, 0.012, GLASS_TOP, 0.03, n), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	# F4: the plush window: glass in a thin dark frame, a white box behind, giant plush piled in it
	wq(b, g, "glass", a, t, n, W0, W1, 0.08, GLASS_TOP, 0.03, 1.0)
	b.cur_color = Color("#2a2622")
	for fr in [W0 + 0.02, W1 - 0.02]:
		b.box(g, "vcolor", P(a, t, n, fr, (0.08 + GLASS_TOP) * 0.5, 0.03), b.abs_size(t, 0.04, GLASS_TOP - 0.08, 0.05, n))
	b.cur_color = Color("#f2f0ea")
	b.box(g, "vcolor_matte", P(a, t, n, (W0 + W1) * 0.5, (0.08 + GLASS_TOP) * 0.5, WALL_T + 0.12), b.abs_size(t, W1 - W0, GLASS_TOP - 0.08, 0.04, n))
	b.box(g, "vcolor_matte", P(a, t, n, (W0 + W1) * 0.5, 0.06, WALL_T * 0.5 + 0.05), b.abs_size(t, W1 - W0, 0.04, WALL_T + 0.1, n))
	b.cur_color = Color.WHITE
	var rng = RandomNumberGenerator.new(); rng.seed = 4443
	# a jumble of giant plush (f003-f011): yellow, orange, blue, cream and dark slate, of mixed
	# sizes, heaped and overlapping from the sill to the top of the glass (generic figures)
	var cols = ["#f6d23a", "#f08a2a", "#5db5e8", "#f6d23a", "#2a3a4a", "#f3e6c8", "#f6d23a", "#f08a2a", "#5db5e8", "#e8b25a"]
	var k = 0
	for row in 4:
		for col in 4:
			var sc = rng.randf_range(1.0, 1.35)
			var u = W0 + 0.28 + col * (W1 - W0 - 0.56) / 3.0 + rng.randf_range(-0.08, 0.08)
			var y = 0.08 + row * 0.68 + rng.randf_range(-0.05, 0.08)
			K().plush(b, g, P(a, t, n, u, y, rng.randf_range(0.29, 0.33)), sc, cols[(k * 7 + row) % cols.size()], rng)
			k += 1
	# the opening's tile returns and a dark head soffit
	b.quad(g, "gi_tile", [P(a, t, n, O0, 0, 0), P(a, t, n, O0, 0, WALL_T), P(a, t, n, O0, SIGN_Y0, WALL_T), P(a, t, n, O0, SIGN_Y0, 0)], t, [Vector2(0, 0), Vector2(WALL_T / 0.6, 0), Vector2(WALL_T / 0.6, -SIGN_Y0 / 0.6), Vector2(0, -SIGN_Y0 / 0.6)])
	b.quad(g, "gi_tile", [P(a, t, n, O1, 0, WALL_T), P(a, t, n, O1, 0, 0), P(a, t, n, O1, SIGN_Y0, 0), P(a, t, n, O1, SIGN_Y0, WALL_T)], -t, [Vector2(0, 0), Vector2(WALL_T / 0.6, 0), Vector2(WALL_T / 0.6, -SIGN_Y0 / 0.6), Vector2(0, -SIGN_Y0 / 0.6)])
	b.cur_color = Color("#2a2a2e")
	b.box(g, "vcolor_matte", P(a, t, n, (O0 + O1) * 0.5, SIGN_Y0 - 0.02, WALL_T * 0.5 + 0.03), b.abs_size(t, O1 - O0, 0.04, WALL_T - 0.06, n))
	b.cur_color = Color.WHITE
	# the front wall's solid parts and the glass are obstacles (only the opening is walkable)
	for wr in [[0.0, O0], [O1, UNIT]]:
		var w0 = P(a, t, n, wr[0], 0, -0.05)
		var w1 = P(a, t, n, wr[1], 0, WALL_T + 0.2)
		b.obst(["rect", min(w0.x, w1.x), min(w0.z, w1.z), max(w0.x, w1.x), max(w0.z, w1.z)])

# ------------------------------------------------------------------ the room (F7-F15, Q1-Q3)
static func room(b, G, a, t, n):
	var u0 = SIDE
	var u1 = UNIT - SIDE
	var dB = ROOM_D
	var up = Vector3.UP
	var KK = K()
	# F7: plank floor through the opening and over the room (2.4 m repeat)
	b.quad(G, "gi_plank", [P(a, t, n, O0, 0, 0), P(a, t, n, O1, 0, 0), P(a, t, n, O1, 0, WALL_T), P(a, t, n, O0, 0, WALL_T)], up, [], false, 1.0 / 2.4)
	b.quad(G, "gi_plank", [P(a, t, n, u0, 0, WALL_T), P(a, t, n, u1, 0, WALL_T), P(a, t, n, u1, 0, dB), P(a, t, n, u0, 0, dB)], up, [], false, 1.0 / 2.4)
	# F11: white 2x2 lay-in ceiling
	var cq = [P(a, t, n, u0, CEIL, WALL_T), P(a, t, n, u0, CEIL, dB), P(a, t, n, u1, CEIL, dB), P(a, t, n, u1, CEIL, WALL_T)]
	var cuv = []
	for p in cq:
		cuv.append(Vector2(p.x / 0.61, p.z / 0.61))
	b.quad(G, "drop_tile", cq, Vector3.DOWN, cuv)
	# F8-F10: the lower walls. Right wall: plain white to 18 m, tan slatwall behind; left wall: the
	# orange prize-counter wall to 9.4 m, white behind; the back wall: tan slatwall.
	var slat = KK.rg("room", "slat_tan")
	b.cur_color = Color("#f1efea")
	for zone in [[u0, t, WALL_T, 18.0], [u1, -t, 9.4, dB]]:
		b.quad(G, "vcolor_matte", [P(a, t, n, zone[0], 0, zone[2]), P(a, t, n, zone[0], 0, zone[3]), P(a, t, n, zone[0], MUST_Y0, zone[3]), P(a, t, n, zone[0], MUST_Y0, zone[2])], zone[1])
	b.cur_color = Color("#e8732a")
	b.quad(G, "vcolor_matte", [P(a, t, n, u1, 0, WALL_T), P(a, t, n, u1, 0, 9.4), P(a, t, n, u1, SHELF_Y, 9.4), P(a, t, n, u1, SHELF_Y, WALL_T)], -t)
	b.cur_color = Color.WHITE
	var nsl = int(ceil((dB - 18.0) / 2.0))
	for k in nsl:
		var d0 = 18.0 + k * (dB - 18.0) / nsl
		var d1 = 18.0 + (k + 1) * (dB - 18.0) / nsl
		sq(b, G, "gi_rm_body", a, t, n, u0, d0, d1, 0.0, MUST_Y0, t, slat)
	for k in 4:
		var c0 = u1 - k * (u1 - u0) / 4.0
		var c1 = u1 - (k + 1) * (u1 - u0) / 4.0
		b.quad(G, "gi_rm_body", [P(a, t, n, c0, 0, dB), P(a, t, n, c1, 0, dB), P(a, t, n, c1, MUST_Y0, dB), P(a, t, n, c0, MUST_Y0, dB)], n,
			[Vector2(slat.x, slat.w), Vector2(slat.z, slat.w), Vector2(slat.z, slat.y), Vector2(slat.x, slat.y)])
	# the front wall's inside (white), and F6: the CLAW MANIA header over the glass bay
	b.cur_color = Color("#f1efea")
	for fw in [[u0, O0], [O1, u1]]:
		b.quad(G, "vcolor_matte", [P(a, t, n, fw[0], 0, WALL_T), P(a, t, n, fw[1], 0, WALL_T), P(a, t, n, fw[1], MUST_Y0, WALL_T), P(a, t, n, fw[0], MUST_Y0, WALL_T)], -n)
	b.quad(G, "vcolor_matte", [P(a, t, n, O0, SIGN_Y0, WALL_T), P(a, t, n, O1, SIGN_Y0, WALL_T), P(a, t, n, O1, MUST_Y0, WALL_T), P(a, t, n, O0, MUST_Y0, WALL_T)], -n)
	b.cur_color = Color.WHITE
	var hd = KK.rg("room", "header")
	b.quad(G, "gi_rm_lit", [P(a, t, n, GB0 - 0.25, 2.45, WALL_T + 0.02), P(a, t, n, GB1 + 0.3, 2.45, WALL_T + 0.02), P(a, t, n, GB1 + 0.3, 2.95, WALL_T + 0.02), P(a, t, n, GB0 - 0.25, 2.95, WALL_T + 0.02)], -n,
		[Vector2(hd.x, hd.w), Vector2(hd.z, hd.w), Vector2(hd.z, hd.y), Vector2(hd.x, hd.y)])
	# F8: the mustard band, the white shelf and the red-orange band above it, on all four walls
	var walls = [[P(a, t, n, u0, 0, WALL_T), P(a, t, n, u0, 0, dB), t], [P(a, t, n, u1, 0, dB), P(a, t, n, u1, 0, WALL_T), -t],
		[P(a, t, n, u1, 0, dB), P(a, t, n, u0, 0, dB), n], [P(a, t, n, u0, 0, WALL_T), P(a, t, n, u1, 0, WALL_T), -n]]
	for w in walls:
		var p0 = w[0]; var p1 = w[1]; var nn = w[2]
		var Y = Vector3.UP
		b.cur_color = Color("#e0a62c")
		b.quad(G, "vcolor_matte", [p0 + Y * MUST_Y0, p1 + Y * MUST_Y0, p1 + Y * SHELF_Y, p0 + Y * SHELF_Y], nn)
		b.cur_color = Color("#c9472a")
		b.quad(G, "vcolor_matte", [p0 + Y * SHELF_Y, p1 + Y * SHELF_Y, p1 + Y * CEIL, p0 + Y * CEIL], nn)
		b.cur_color = Color("#f4f2ee")
		if nn == -n:
			b.cur_color = Color.WHITE
			continue
		b.box(G, "vcolor_matte", (p0 + p1) * 0.5 + Y * (SHELF_Y + 0.015) + nn * 0.15, ((p1 - p0).abs() + nn.abs() * 0.3 + Vector3(0, 0.03, 0)).max(Vector3(0.001, 0.03, 0.001)))
		b.cur_color = Color.WHITE
	# Q1: the CLAW MANIA mural on the right wall
	sq(b, G, "gi_rm_body", a, t, n, u0 + 0.01, 4.6, 1.3, 0.55, 2.4, t, KK.rg("room", "mural"))   # d reversed: the viewer faces -u
	# F15: plush on the shelves: character-plush colours over the right wall's front half, the big
	# inflatable aliens over the left-wall claws
	var rng = RandomNumberGenerator.new(); rng.seed = 2026
	var dd = 1.0
	while dd < 10.5:
		KK.plush(b, G, P(a, t, n, u0 + 0.16, SHELF_Y + 0.03, dd), rng.randf_range(0.7, 1.2), ["#f6d23a", "#5db5e8", "#f08a2a", "#79c66a", "#f6d23a"][rng.randi() % 5], rng)
		dd += rng.randf_range(0.5, 0.9)
	dd = 11.4
	while dd < 35.8:
		var c = Color(["#8a3bd0", "#3cc84a", "#3b6bff", "#ff4fa8", "#a259ff", "#2fd6c8"][rng.randi() % 6])
		var base = P(a, t, n, u1 - 0.16, SHELF_Y + 0.03, dd)
		b.cur_color = c
		KK.ell(b, G, "vcolor", base + Vector3(0, 0.28, 0), Vector3(0.14, 0.28, 0.14), 8, 5)
		KK.ell(b, G, "vcolor", base + Vector3(0, 0.72, 0), Vector3(0.24, 0.22, 0.2), 10, 6)
		b.cur_color = Color.WHITE
		dd += rng.randf_range(0.55, 0.75)
	# Q2: two white folding tables (8 ft) with benches, lengthwise; Q3 the trash can; F5 two A-frames
	for tu in [0.95, 2.55]:
		party_table(b, G, a, t, n, tu, 2.6)
	b.cur_color = Color("#141416")
	b.cyl(G, "vcolor", P(a, t, n, 3.35, 0, 1.15), 0.22, 0.24, 0.9, 14, true, false, true)
	b.cur_color = Color.WHITE
	var cp = P(a, t, n, 3.35, 0, 1.15)
	b.obst(["rect", cp.x - 0.3, cp.z - 0.3, cp.x + 0.3, cp.z + 0.3])
	aframe(b, G, a, t, n, 2.7, 0.95, 0, 0.35)
	aframe(b, G, a, t, n, 1.5, 0.85, 1, -0.2)
	# F12, F13: the white pipe column and the thin black pole
	b.cur_color = Color("#f4f2ee")
	b.cyl(G, "vcolor", P(a, t, n, 3.3, 0, 20.0), 0.15, 0.15, CEIL, 18, false, false)
	b.cur_color = Color("#15161a")
	b.cyl(G, "vcolor", P(a, t, n, 3.95, 0, 27.6), 0.05, 0.05, CEIL, 12, false, false)
	b.cur_color = Color.WHITE
	for c in [[3.3, 20.0, 0.15], [3.95, 27.6, 0.05]]:
		var q = P(a, t, n, c[0], 0, c[1])
		b.obst(["rect", q.x - c[2] - 0.1, q.z - c[2] - 0.1, q.x + c[2] + 0.1, q.z + c[2] + 0.1])
	# F14: the back door standing open into a lit back room, the EXIT sign over it
	var du0 = 1.4; var du1 = 2.3
	b.cur_color = Color("#f2e6b8")
	b.box(G, "vcolor_matte", P(a, t, n, (du0 + du1) * 0.5, 1.05, dB + 0.9), b.abs_size(t, du1 - du0, 2.1, 0.04, n))
	for su in [du0, du1]:
		b.box(G, "vcolor_matte", P(a, t, n, su, 1.05, dB + 0.45), b.abs_size(t, 0.04, 2.1, 0.9, n))
	b.box(G, "vcolor_matte", P(a, t, n, (du0 + du1) * 0.5, 2.12, dB + 0.45), b.abs_size(t, du1 - du0, 0.04, 0.9, n))
	b.cur_color = Color("#d8c48a")
	b.box(G, "vcolor", P(a, t, n, du1 - 0.02, 1.05, dB + 0.48), b.abs_size(t, 0.04, 2.08, 0.86, n))
	b.cur_color = Color.WHITE
	b.box(G, "exit_sign", P(a, t, n, (du0 + du1) * 0.5, 2.38, dB - 0.05), b.abs_size(t, 0.36, 0.16, 0.06, n))
	var dl = b.add_omni(P(a, t, n, (du0 + du1) * 0.5, 2.0, dB + 0.5), 0.6, 2.5, Color(1.0, 0.92, 0.75))
	b.tag(dl, "", 0.6, 0.6)

## Q2: a white 8 ft folding table with its two benches, the long side along d.
static func party_table(b, G, a, t, n, u, d):
	var L = 2.44
	b.cur_color = Color("#ece8de")
	b.box(G, "vcolor_matte", P(a, t, n, u, 0.74, d), b.abs_size(t, 0.76, 0.04, L, n))
	for s in [-0.6, 0.6]:
		b.box(G, "vcolor_matte", P(a, t, n, u + s, 0.45, d), b.abs_size(t, 0.26, 0.04, L - 0.1, n))
	b.cur_color = Color("#3a3c42")
	for k in [-0.95, 0.95]:
		b.box(G, "vcolor", P(a, t, n, u, 0.37, d + k), b.abs_size(t, 1.4, 0.03, 0.04, n), Transform3D.IDENTITY, [], true)
		for s in [-0.3, 0.3]:
			b.box(G, "vcolor", P(a, t, n, u + s, 0.37, d + k), b.abs_size(t, 0.03, 0.74, 0.04, n), Transform3D.IDENTITY, [], true)
	b.cur_color = Color.WHITE
	var p0 = P(a, t, n, u - 0.75, 0, d - L * 0.5)
	var p1 = P(a, t, n, u + 0.75, 0, d + L * 0.5)
	b.obst(["rect", min(p0.x, p1.x), min(p0.z, p1.z), max(p0.x, p1.x), max(p0.z, p1.z)])

## F5: a black A-frame poster stand, poster `k` (room atlas aframe0/1), turned `rot` radians.
static func aframe(b, G, a, t, n, u, d, k, rot):
	var KK = K()
	var o = P(a, t, n, u, 0, d)
	var f = (-n).rotated(Vector3.UP, rot)
	var xf = KK.X(o, f)
	var r = KK.rg("room", "aframe%d" % k)
	for s in [-1, 1]:
		var z0 = 0.0 if s < 0 else 0.5
		var z1 = 0.25
		KK.face(b, G, "gi_rm_lit", xf, [Vector3(-0.3, 0.0, z0), Vector3(0.3, 0.0, z0), Vector3(0.3, 1.45, z1), Vector3(-0.3, 1.45, z1)] if s < 0 else
			[Vector3(0.3, 0.0, z0), Vector3(-0.3, 0.0, z0), Vector3(-0.3, 1.45, z1), Vector3(0.3, 1.45, z1)], Vector3(0, 0.17, float(s)).normalized(), r, true)
	KK.obst(b, xf, -0.3, 0.3, 0.0, 0.5, 0.1)

# ------------------------------------------------------------------ light (F11)
## 2x2 nine-cell parabolic troffers in two rows about every 3 m (the footage's grid), square diffusers
## and return grilles between them, two black track runs with spot heads along the room.
static func lights(b, G, a, t, n):
	var KK = K()
	var tr = KK.rg("room", "troffer")
	var df = KK.rg("room", "diffuser")
	var gr = KK.rg("room", "grille")
	var d = WALL_T + 1.6
	var k = 0
	while d < ROOM_D - 1.0:
		for u in [2.2, 5.8]:
			var c = P(a, t, n, u, CEIL - 0.004, d)
			b.quad(G, "gi_rm_lit", [c - t * 0.3 - n * 0.3, c - t * 0.3 + n * 0.3, c + t * 0.3 + n * 0.3, c + t * 0.3 - n * 0.3], Vector3.DOWN,
				[Vector2(tr.x, tr.y), Vector2(tr.z, tr.y), Vector2(tr.z, tr.w), Vector2(tr.x, tr.w)])
			var l = b.add_spot(c - Vector3(0, 0.05, 0), Vector3.DOWN, 1.4, 7.0, 70.0, Color(1.0, 0.97, 0.92))
			b.tag(l, "", 1.4, 1.4)
		var c2 = P(a, t, n, 4.0, CEIL - 0.004, d + 1.5)
		var r2 = df if k % 2 == 0 else gr
		b.quad(G, "gi_rm_body", [c2 - t * 0.3 - n * 0.3, c2 - t * 0.3 + n * 0.3, c2 + t * 0.3 + n * 0.3, c2 + t * 0.3 - n * 0.3], Vector3.DOWN,
			[Vector2(r2.x, r2.y), Vector2(r2.z, r2.y), Vector2(r2.z, r2.w), Vector2(r2.x, r2.w)])
		d += 3.05
		k += 1
	# the track runs (black) with a spot head every ~1.8 m (heads are dynamic: small)
	for u in [2.8, 5.3]:
		b.cur_color = Color("#141416")
		b.box(G, "vcolor", P(a, t, n, u, CEIL - 0.02, (WALL_T + ROOM_D) * 0.5), b.abs_size(t, 0.035, 0.03, ROOM_D - WALL_T - 1.0, n))
		var dd = WALL_T + 1.2
		while dd < ROOM_D - 1.0:
			b.box(G, "vcolor", P(a, t, n, u, CEIL - 0.1, dd), Vector3(0.07, 0.12, 0.07), Transform3D.IDENTITY, [], true)
			dd += 1.8
		b.cur_color = Color.WHITE
	# warm spots over the prize counter
	for dd in [3.0, 5.5, 8.0]:
		var l2 = b.add_spot(P(a, t, n, 6.6, CEIL - 0.08, dd), Vector3.DOWN, 1.8, 5.0, 55.0, Color(1.0, 0.94, 0.84))
		b.tag(l2, "", 1.8, 1.8)

# ------------------------------------------------------------------ the machines
## Places one kit piece: `mod` a machines/ file name, front-edge centre at (u, d), the player facing
## `dir` ("+d" into the store, "-d" toward the hall, "+u" toward the left wall, "-u" toward the right).
static func put(b, a, t, n, mod, u, d, dir, opts = {}, pad = 0.12):
	var f = {"+d": -n, "-d": n, "+u": t, "-u": -t}[dir]
	var M = load(MK + mod + ".gd")
	var k0 = b.obstacles.size()
	M.build(b, "gi%d_mach" % int(clamp(d / 10.0, 0, 3)), P(a, t, n, u, 0, d), f, opts)
	for i in range(k0, b.obstacles.size()):
		var o = b.obstacles[i]
		if o[0] is String and o[0] == "rect":
			b.obstacles[i] = ["rect", o[1] - pad, o[2] - pad, o[3] + pad, o[4] + pad]
	return M

static func fp(mod, opts = {}):
	return load(MK + mod + ".gd").footprint(opts)

## Against the right wall (u0, the player faces -u) or the left wall (u1, faces +u), along d from d0.
static func on_wall(b, a, t, n, side, mod, d0, opts = {}):
	var sz = fp(mod, opts)
	var u = (SIDE + sz.y) if side == "R" else (UNIT - SIDE - sz.y)
	put(b, a, t, n, mod, u, d0 + sz.x * 0.5, "-u" if side == "R" else "+u", opts)
	return d0 + sz.x

## Against the back wall, centred at u (the player faces +d).
static func on_back(b, a, t, n, mod, u, opts = {}):
	var sz = fp(mod, opts)
	put(b, a, t, n, mod, u, ROOM_D - sz.y, "+d", opts)

static func machines(b, a, t, n):
	# --- the prize counter (P1-P6), left walking in
	var lw = UNIT - SIDE
	put(b, a, t, n, "counter", lw - 0.45, 5.15, "+u", {"kind": "prizewall", "length": 8.3, "sign_at": -4.15 + 2.4, "tvs": [-4.15 + 4.9, -4.15 + 6.5]}, 0.0)
	put(b, a, t, n, "counter", 5.75, 2.115, "+u", {"kind": "case", "led": "#ff4fa8"}, 0.05)
	put(b, a, t, n, "counter", 5.75, 3.995, "+u", {"kind": "case", "led": "#3b8bff"}, 0.05)
	put(b, a, t, n, "counter", 5.75, 6.36, "+u", {"kind": "counter", "length": 2.8}, 0.05)
	put(b, a, t, n, "counter", 5.75, 8.725, "+u", {"kind": "case", "led": "#f4f8ff"}, 0.05)
	for kd in [9.95, 10.55]:
		on_wall(b, a, t, n, "L", "counter", kd - 0.25, {"kind": "kiosk"})
	# --- left wall: M2 the first two cabinets, then M1 the long LED claw run to the back
	var d = on_wall(b, a, t, n, "L", "merch", 11.0, {"style": "plain", "plush": "#5db5e8"}) + 0.03
	d = on_wall(b, a, t, n, "L", "merch", d, {"style": "yellow"}) + 0.05
	var seq = [0, 5, 2, 3, 0, 1, 2, 4, 3, 0, 5, 2]
	var i = 0
	while d + 0.82 <= 36.2:
		d = on_wall(b, a, t, n, "L", "claw", d, {"color": seq[i % seq.size()]}) + 0.02
		i += 1
	# --- right wall, front to back (M3, M4, M6-M16, M30); 8-11 m and 30-33.8 m are left open (not seen)
	on_wall(b, a, t, n, "R", "claw", 5.0, {"color": 5})
	on_wall(b, a, t, n, "R", "pusher", 6.0, {"style": 0})
	d = on_wall(b, a, t, n, "R", "pusher", 11.0, {"style": 1}) + 0.2
	d = on_wall(b, a, t, n, "R", "gunbig", d) + 0.2
	d = on_wall(b, a, t, n, "R", "racer", d, {"kind": "twin"}) + 0.2
	d = on_wall(b, a, t, n, "R", "upright", d, {"style": "nerf"}) + 0.15
	d = on_wall(b, a, t, n, "R", "deal", d) + 0.15
	d = on_wall(b, a, t, n, "R", "hoop", d) + 0.15
	d = on_wall(b, a, t, n, "R", "ptower", d, {"style": 1}) + 0.1
	d = on_wall(b, a, t, n, "R", "ptower", d, {"style": 0}) + 0.15
	d = on_wall(b, a, t, n, "R", "merch", d, {"style": "push"}) + 0.03
	d = on_wall(b, a, t, n, "R", "merch", d, {"style": "white"}) + 0.03
	for k in 4:
		d = on_wall(b, a, t, n, "R", "merch", d, {"style": "plain"}) + 0.03
	on_wall(b, a, t, n, "R", "merch", d, {"style": "yellow"})
	on_wall(b, a, t, n, "R", "racer", 34.0, {"kind": "bikes"})
	# --- back wall, right to left (M29, the door F14, M28, M27, M26, M25 x 2)
	on_back(b, a, t, n, "upright", 0.75, {"style": "music"})
	on_back(b, a, t, n, "alley", 2.85, {"style": "quik"})
	on_back(b, a, t, n, "alley", 3.7, {"style": "eyes"})
	on_back(b, a, t, n, "merch", 4.6, {"style": "purple"})
	on_back(b, a, t, n, "alley", 5.55, {"style": "alley"})
	on_back(b, a, t, n, "alley", 6.5, {"style": "alley"})
	# --- PRIZES (Nov 3; Steven: "put a clone of the 1995 Whirlwind in the store... literally the same
	# machine", slightly duller and faded): Pocket Change's own cyclone module, built with the 2026 year's
	# faded pictures (cyclone.gd _t) and its own sign id "gi.cyclone.1" (scripts/signs.gd: $2 for four
	# plays, 2026 tickets). Where it stands is a guess (not in the Oct 23 footage): the open floor in the
	# middle front, behind the party tables, its console to the door, across the aisle from the showcases.
	var cyc = load(PC % "cyclone")
	var k0 = b.obstacles.size()
	cyc.build(b, "gi0_mach", P(a, t, n, WW_U, 0, WW_D), -n, {})
	for oi in range(k0, b.obstacles.size()):
		var ob = b.obstacles[oi]
		if ob[0] is String and ob[0] == "rect":
			b.obstacles[oi] = ["rect", ob[1] - 0.2, ob[2] - 0.2, ob[3] + 0.2, ob[4] + 0.2]
	# --- the middle, front to back (M5, M18, M17, M19, M21, M20, M22, M23, M24)
	put(b, a, t, n, "dice", 4.6, 11.55, "+d")
	put(b, a, t, n, "upright", 4.6, 15.8, "+d", {"style": "mascot"})
	put(b, a, t, n, "upright", 4.4, 18.8, "-d", {"style": "crossy"})
	put(b, a, t, n, "dome", 4.72, 19.8, "+u", {"style": 0})
	put(b, a, t, n, "wheel", 4.1, 22.2, "-d")
	put(b, a, t, n, "dome", 4.72, 23.2, "+u", {"style": 1})
	put(b, a, t, n, "dome", 3.0, 25.4, "-d", {"style": "arch"})
	put(b, a, t, n, "hockey", 5.0, 26.4, "+d", {"style": 0})
	put(b, a, t, n, "hockey", 2.9, 26.4, "+d", {"style": 1})

# ------------------------------------------------------------------ materials
## "gi_<key>" (build_mall.gd's mat() calls this).
static func fill_mat(m, key, b):
	# the machine kit (tools/stores/games_inc/machines/): "m_<kind>_<key>" and the kit's own "k_<key>"
	if key.begins_with("k_"):
		return load(MK + "kit.gd").fill_mat(m, key.substr(2), b)
	if key.begins_with("m_"):
		var parts = key.substr(2).split("_", true, 1)
		return parts.size() == 2 and load(MK + parts[0] + ".gd").fill_mat(m, parts[1], b)
	match key:
		"rm_body", "rm_lit":
			# the room atlas (machines/paint.py room(): mural, header, A-frames, troffer, slatwall, diffusers)
			return load(MK + "kit.gd").atlas_mat(m, b, "room", key.substr(3), 0.9, 0.6)
		"plank":
			m.albedo_texture = b.tex("gi/plank.png"); m.roughness = 0.45; m.metallic = 0.0
		"slat":
			m.albedo_texture = b.tex("gi/slat.png"); m.roughness = 0.75
		"band":
			m.albedo_texture = b.tex("gi/band.png"); m.roughness = 0.8
		"tile":
			m.albedo_texture = b.tex("gi/tile.png"); m.roughness = 0.28
		"mural":
			m.albedo_texture = b.tex("gi/mural.png"); m.roughness = 0.7
		"panel":
			m.albedo_texture = b.tex("gi/panel.png"); m.roughness = 0.5
		_:
			return false
	return true
