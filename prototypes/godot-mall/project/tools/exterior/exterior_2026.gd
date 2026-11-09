## The outside as filmed on Oct 23 2026 (Workstream F, Nov 1 2026; design/godot-exterior.md "The
## 2026 outside"). exterior.gd builds the same shell for both years and calls in here, when
## --year=2026, for what only today has (refs/notes notes_A, notes_D, notes_E):
##   - the main entrance's two-storey porte-cochere (4426 f005-f007, 4492 f052, f067), with the navy
##     fan banner on its pier (4406 f002)
##   - T-Mobile's exterior entrance just south of it (unit 1029, 4492 f070-080) and Shoe Dept.'s
##     white ACM front with three stainless-canopied bays (unit 1003A, 4492 f081-099); in 1995 both
##     were blank wall ("this was all sealed off", Steven)
##   - Hypervelocity on K&B's original folded-plate canopy (4493 f008-023)
##   - the gold fan on the east entrance (4406 f038-040), Lynn's Interiors on the old Sears
##   - the truncated-dome mats at the doors' curb ramps
## exterior.gd itself switches the rest by year: The Red Seal's colours on Cucos, the two-tone EIFS
## wing wall, the south pavilion's EIFS and tile bands, pink fire lanes on red curbs, yellow stall
## lines, the LED twin-arm poles, JCPenney's magenta letters (Unitech unsigned since EXT-LAYOUT); monuments.gd the
## monument faces (and no United Artists marquee).
const UP = Vector3.UP

## A box along a run (as exterior.gd's run_box): u0..u1 along t, y0..y1, standing `out` proud, `deep`.
static func run_box(b, g, mname, a, t, n, u0, u1, y0, y1, out, deep, skip = []):
	var c = a + t * ((u0 + u1) * 0.5) + UP * ((y0 + y1) * 0.5) + n * (out - deep * 0.5)
	b.box(g, mname, c, b.abs_size(t, u1 - u0, y1 - y0, deep, n), Transform3D.IDENTITY, skip)

## The main entrance today: a two-storey portal in tan EIFS (diagonal-scored panels), square
## columns banded in cream and charcoal tile, a black steel beam across, a dark canopy fascia with
## "SOUTHLAND MALL", a black-mullioned clerestory over it with a tan centre panel, a flat tan soffit
## with cans at the top, tan pavers; the sliding doors under a segmental 4-light transom. Then
## T-Mobile and Shoe Dept. down the facade to the south.
static func main_entrance(b):
	var g = "ex_entry"
	var a = Vector3(44, 0, -6); var n = Vector3(1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 12.0
	# the storefront: sliding doors in the middle, swing pairs either side, a segmental transom
	for i in 7:
		run_box(b, g, "ex_mullion", a, t, n, 1.0 + i * (10.0 / 6.0) - 0.05, 1.0 + i * (10.0 / 6.0) + 0.05, 0.0, 3.0, 0.0, 0.14)
	run_box(b, g, "ex_mullion", a, t, n, 1.0, 11.0, 2.95, 3.1, 0.0, 0.14)
	b.quad("ex_glass", "ex_glass", [a + t * 1.0 + n * 0.02, a + t * 11.0 + n * 0.02, a + t * 11.0 + n * 0.02 + UP * 3.0, a + t * 1.0 + n * 0.02 + UP * 3.0], n, [], true)
	var s = b.st(g, "ex_glass_dark")
	var c0 = a + t * 6.0 + UP * 3.1 + n * 0.03
	for k in 12:
		var a0 = PI * k / 12.0; var a1 = PI * (k + 1) / 12.0
		b.tri(s, c0, c0 + t * (cos(a0) * 3.4) + UP * (sin(a0) * 1.1), c0 + t * (cos(a1) * 3.4) + UP * (sin(a1) * 1.1), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n)
	# the portal: two columns out at x 52, a tall tan frame, the canopy fascia, the clerestory
	var X = 52.0; var Z = 7.2; var top = 9.6
	for sz in [-1.0, 1.0]:
		var p = Vector3(X, 0, sz * Z)
		b.box(g, "ex_eifs_tan", p + UP * (top * 0.5), Vector3(1.3, top, 1.3))
		for k in 6:
			b.box(g, "ex_tile_dark" if k % 2 == 0 else "ex_tile_light", p + UP * (0.23 + k * 0.45), Vector3(1.34, 0.45, 1.34))
		b.obst(["rect", p.x - 0.7, p.z - 0.7, p.x + 0.7, p.z + 0.7])
		# the side frames back to the facade, above head height
		b.box(g, "ex_eifs_tan", Vector3((44.0 + X) * 0.5, (5.4 + top) * 0.5, sz * Z), Vector3(X - 44.0, top - 5.4, 1.0))
	# the tan top band and the soffit
	b.box(g, "ex_eifs_tan", Vector3(X, top - 0.8, 0), Vector3(1.3, 1.6, Z * 2.0))
	b.box(g, "ex_eifs_tan", Vector3((44.0 + X) * 0.5, top + 0.15, 0), Vector3(X - 44.0 + 1.4, 0.3, Z * 2.0 + 1.4))
	b.quad(g, "ex_eifs_tan", [Vector3(44.0, top - 0.02, -Z), Vector3(X, top - 0.02, -Z), Vector3(X, top - 0.02, Z), Vector3(44.0, top - 0.02, Z)], -UP, [], false, 0.5)
	for i in 6:
		var cp = Vector3(46.0 + (i % 3) * 2.6, top - 0.04, -2.5 + (i / 3) * 5.0)
		b.cyl(g, "ex_can", cp, 0.12, 0.12, 0.02, 10, false, true)
	for i in 3:
		b.tag(b.add_spot(Vector3(48.0, top - 0.1, -4.0 + i * 4.0), -UP, 2.0, 12.0, 50.0, Color("#FFE6C2")), "night")
	# the black steel beam across, the dark canopy fascia with the letters, the clerestory above
	b.box(g, "ex_black_steel", Vector3(X, 5.0, 0), Vector3(0.6, 0.5, Z * 2.0))
	b.box(g, "ex_navy", Vector3(X + 0.05, 4.45, 0), Vector3(0.5, 0.7, Z * 2.0 - 1.3))
	b.label("SOUTHLAND MALL", "sans", "#f4efe3", Vector3(X + 0.32, 4.45, 0), n, 8.5, 0.42)
	var cy0 = 5.3; var cy1 = top - 1.6
	b.box(g, "ex_glass_dark", Vector3(X - 0.1, (cy0 + cy1) * 0.5, 0), Vector3(0.06, cy1 - cy0, Z * 2.0 - 1.3))
	b.box(g, "ex_eifs_tan", Vector3(X - 0.05, (cy0 + cy1) * 0.5, 0), Vector3(0.1, cy1 - cy0, 3.0))
	for k in 7:
		var zz = -Z + 0.65 + k * ((Z * 2.0 - 1.3) / 6.0)
		b.box(g, "ex_black_steel", Vector3(X, (cy0 + cy1) * 0.5, zz), Vector3(0.12, cy1 - cy0, 0.08))
	b.box(g, "ex_black_steel", Vector3(X, (cy0 + cy1) * 0.5, 0), Vector3(0.12, 0.08, Z * 2.0 - 1.3))
	# the navy banner with the white fan on the north column's lot face
	var bc = Vector3(X + 0.67, 6.2, -Z)
	b.quad(g, "ex_banner_2026", [bc + Vector3(0, -2.0, 0.5), bc + Vector3(0, -2.0, -0.5), bc + Vector3(0, 2.0, -0.5), bc + Vector3(0, 2.0, 0.5)], n,
		[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	# tan 2 ft pavers under the canopy
	b.quad("ex_paint", "ex_eifs_tan", [Vector3(44.2, 0.012, -Z), Vector3(X + 0.6, 0.012, -Z), Vector3(X + 0.6, 0.012, Z), Vector3(44.2, 0.012, Z)], UP, [], true, 0.5)
	tmobile(b)
	shoe_dept(b)

## T-Mobile, unit 1029, just south of the entrance canopy (the 1995 Pups & Pets frontage, x = 44,
## z 6..16): magenta channel letters on a cream parapet band with a cornice, a dark grey metal shed
## awning on black tie-rods, a white-framed storefront with double doors and a transom, a cream
## chamfered wainscot (4492 f070-080). Post-1995, exterior only (Steven).
static func tmobile(b):
	var g = "ex_entry"
	var a = Vector3(44, 0, 6); var n = Vector3(1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 10.0
	run_box(b, g, "ex_ivory", a, t, n, 0.6, Ln - 0.6, 5.0, 6.4, 0.32, 0.12)
	run_box(b, g, "ex_cream_pier", a, t, n, 0.4, Ln - 0.4, 6.4, 6.6, 0.4, 0.2)
	b.label("T-Mobile", "sans", "#e20074", a + t * (Ln * 0.5) + UP * 5.7 + n * 0.34, n, 6.0, 0.8)
	# the storefront: white frame, glass, double doors in the middle, transom
	run_box(b, g, "ex_white_wainscot", a, t, n, 1.5, Ln - 1.5, 0.0, 0.6, 0.3, 0.1)
	for u in [1.5, 3.6, 4.3, 5.7, 6.4, Ln - 1.5]:
		run_box(b, g, "ex_white_wainscot", a, t, n, u - 0.05, u + 0.05, 0.0, 3.4, 0.3, 0.12)
	run_box(b, g, "ex_white_wainscot", a, t, n, 1.5, Ln - 1.5, 2.6, 2.7, 0.3, 0.12)
	b.quad("ex_glass", "ex_glass_dark", [a + t * 1.5 + n * 0.22, a + t * (Ln - 1.5) + n * 0.22, a + t * (Ln - 1.5) + n * 0.22 + UP * 3.4, a + t * 1.5 + n * 0.22 + UP * 3.4], n)
	b.box(g, "ex_magenta", a + t * 2.6 + UP * 1.6 + n * 0.21, Vector3(0.02, 1.8, 1.6))      # the magenta wall behind the glass
	# the shed awning on tie-rods
	b.box(g, "ex_tile_dark", a + t * (Ln * 0.5) + UP * 3.8 + n * 1.2, Vector3(1.9, 0.08, Ln - 2.0), Transform3D(Basis(Vector3(0, 0, 1), 0.18), a + t * (Ln * 0.5) + UP * 3.8 + n * 1.2) * Transform3D(Basis.IDENTITY, -(a + t * (Ln * 0.5) + UP * 3.8 + n * 1.2)))
	for u in [1.6, Ln - 1.6]:
		var p0 = a + t * u + n * 2.1 + UP * 3.65; var p1 = a + t * u + n * 0.2 + UP * 4.9
		var m = (p0 + p1) * 0.5; var dir = (p1 - p0).normalized()
		b.box(g, "ex_black_steel", Vector3.ZERO, Vector3(0.03, p0.distance_to(p1), 0.03), Transform3D(Basis(t, dir, t.cross(dir)), m))

## Shoe Dept. (Encore), unit 1003A: ex-Forever 21 in the merged Coach House / Radio Shack / GNC /
## Avenue box (x = 44, z 16..50); its exterior entrance was cut "within the last 20 years" (Steven).
## A white aluminium-composite front with a tall parapet, three recessed glazed bays framed by
## projecting white ACM boxes each under a brushed-stainless box canopy, black italic capitals
## "SHOE DEPT." on a white panel, then a long blank ACM wall with two narrow glazed slots
## (4492 f081-f099).
static func shoe_dept(b):
	var g = "ex_entry"
	var a = Vector3(44, 0, 16); var n = Vector3(1, 0, 0); var t = Vector3(0, 0, 1); var Ln = 34.0
	var H = 8.2
	# the ACM skin in front of the 1995 pilasters, up to the taller parapet
	b.quad(g, "ex_acm_white", [a + n * 0.32, a + t * Ln + n * 0.32, a + t * Ln + n * 0.32 + UP * H, a + n * 0.32 + UP * H], n, [], false, 1.0 / 3.0)
	run_box(b, g, "ex_acm_white", a, t, n, 0.0, Ln, H - 0.1, H, 0.4, 0.4)
	b.box(g, "ex_acm_white", a + t * (Ln * 0.5) + UP * (H - 0.8) + n * 0.1, Vector3(0.4, 1.6, Ln))
	# the three bays
	for i in 3:
		var u0 = 1.2 + i * 5.4; var u1 = u0 + 4.6
		run_box(b, g, "ex_acm_white", a, t, n, u0 - 0.5, u0, 0.0, 5.4, 1.1, 0.8)
		run_box(b, g, "ex_acm_white", a, t, n, u1, u1 + 0.5, 0.0, 5.4, 1.1, 0.8)
		run_box(b, g, "ex_acm_white", a, t, n, u0 - 0.5, u1 + 0.5, 4.6, 5.4, 1.1, 0.8)
		run_box(b, g, "ex_stainless", a, t, n, u0 - 0.4, u1 + 0.4, 3.7, 4.0, 2.3, 1.2)
		for u in [u0, u0 + 1.15, u0 + 2.3, u0 + 3.45, u1]:
			run_box(b, g, "ex_mullion", a, t, n, u - 0.04, u + 0.04, 0.0, 4.6, 0.36, 0.08)
		run_box(b, g, "ex_mullion", a, t, n, u0, u1, 2.6, 2.68, 0.36, 0.08)
		b.quad("ex_glass", "ex_glass_dark", [a + t * u0 + n * 0.33, a + t * u1 + n * 0.33, a + t * u1 + n * 0.33 + UP * 4.6, a + t * u0 + n * 0.33 + UP * 4.6], n)
		run_box(b, g, "ex_stainless", a, t, n, u0 + 2.1, u0 + 2.2, 0.9, 1.9, 0.42, 0.04)
		run_box(b, g, "ex_stainless", a, t, n, u0 + 2.4, u0 + 2.5, 0.9, 1.9, 0.42, 0.04)
		b.tag(b.add_spot(a + t * ((u0 + u1) * 0.5) + n * 1.8 + UP * 3.6, -UP, 1.2, 6.0, 60.0, Color("#FFF4E6")), "night")
		b.obst(["rect", a.x, a.z + u0 - 0.5, a.x + 1.15, a.z + u0 + 0.0])
		b.obst(["rect", a.x, a.z + u1, a.x + 1.15, a.z + u1 + 0.5])
	# the sign panel over the bays
	run_box(b, g, "ex_white_wainscot", a, t, n, 3.0, 14.0, 5.8, 7.4, 0.5, 0.1)
	b.label("SHOE DEPT.", "sans_italic", "#111111", a + t * 8.5 + UP * 6.6 + n * 0.52, n, 9.6, 1.0)
	# two narrow glazed slots in the blank stretch beyond
	for u in [22.0, 29.0]:
		run_box(b, g, "ex_mullion", a, t, n, u - 0.5, u + 0.5, 0.6, 5.0, 0.36, 0.06)
		b.quad("ex_glass", "ex_glass_dark", [a + t * (u - 0.42) + n * 0.4, a + t * (u + 0.42) + n * 0.4, a + t * (u + 0.42) + n * 0.4 + UP * 4.3, a + t * (u - 0.42) + n * 0.4 + UP * 4.3], n)

## The gold art-deco fan and two small diamonds on the east entrance's peach fascia (4406 f038-040),
## where the 1995 build has the Cucos neon. c: the centre of the fan's base, on the fascia.
static func fan_ornament(b, c, n, t):
	var s = b.st("ex_entry", "ex_gold")
	for i in 7:
		var k = i - 3
		var a0 = deg_to_rad(90.0 + k * 16.0 - 6.0); var a1 = deg_to_rad(90.0 + k * 16.0 + 6.0)
		var L = 1.6 - abs(k) * 0.16
		b.tri(s, c + n * 0.04, c + n * 0.04 + t * (cos(a0) * L) + UP * (sin(a0) * L), c + n * 0.04 + t * (cos(a1) * L) + UP * (sin(a1) * L), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n)
	for sd in [-1.0, 1.0]:
		var d = c + t * (sd * 2.6) + UP * 0.7 + n * 0.04
		b.tri(s, d + UP * 0.3, d + t * 0.22, d - UP * 0.3, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n)
		b.tri(s, d + UP * 0.3, d - UP * 0.3, d - t * 0.22, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, n)

## Hypervelocity Race Track, unit 1043, on K&B's original folded-plate canopy (exterior.gd kb_bay
## builds the canopy and windows for both years): lit cream channel letters with a small red
## "RACE TRACK" on the tan EIFS sign band, the giant black-and-white racing check on the brick
## bulkheads, red-trimmed raked windows (4493 f008-023, 4406 f004).
static func hypervelocity(b, a, t, n, Ln):
	var g = "ex_entry"
	for i in int(Ln / 0.9):
		run_box(b, g, "ex_paint_black" if i % 2 == 0 else "ex_paint_white", a, t, n, i * 0.9, (i + 1) * 0.9, 0.0, 0.45, 0.05, 0.05)
		run_box(b, g, "ex_paint_white" if i % 2 == 0 else "ex_paint_black", a, t, n, i * 0.9, (i + 1) * 0.9, 0.45, 0.9, 0.05, 0.05)
	run_box(b, g, "ex_eifs_tan", a, t, n, 1.0, Ln - 1.0, 4.6, 6.4, 0.1, 0.1)
	b.label("HYPERVELOCITY", "sans", "#f6efd8", a + t * (Ln * 0.5) + UP * 5.75 + n * 0.14, n, 14.0, 1.0)
	b.label("RACE TRACK", "sans", "#c8202c", a + t * (Ln * 0.5) + UP * 5.0 + n * 0.14, n, 4.0, 0.36)

## Lynn's Interiors on the old Sears box (the 2026 directory, IMG_4406 f031-035: the script sign with
## a black awning on the east face).
## EXT-B (Nov 4 2026): the box is flush with the facade (x 44) and runs to z -146 / x -72 (x -84 since EXT-LAYOUT).
static func lynns(b):
	b.label("Lynn's", "script", "#1c1c1e", Vector3(44.08, 6.6, -118.0), Vector3(1, 0, 0), 9.0, 1.6)
	b.label("INTERIORS", "sans", "#1c1c1e", Vector3(44.08, 5.3, -118.0), Vector3(1, 0, 0), 5.0, 0.4)
	b.label("Lynn's", "script", "#1c1c1e", Vector3(-24.0, 6.6, -146.08), Vector3(0, 0, -1), 9.0, 1.6)   # EXT-LAYOUT: over the north entrance (s1n)
	# EXT-LAYOUT (Nov 8 2026): the west face is at x -84 (exterior.gd SEARS_W)
	b.label("Lynn's", "script", "#1c1c1e", Vector3(-84.08, 6.6, -134.0), Vector3(-1, 0, 0), 9.0, 1.6)

## The yellow truncated-dome mats at the curb ramps in front of every door (4492 t104, 4493 f001-004).
static func tactile(b, doors):
	for d in doors:
		var mid = Vector3(d.mid[0], 0, d.mid[1]); var n = Vector3(d.n[0], 0, d.n[1])
		var t = Vector3(-n.z, 0, n.x)
		var c = mid - n * (float(d.depth) + 1.45) + UP * 0.02
		b.quad("ex_paint", "ex_tactile_mat", [c - t * 1.5 - n * 0.3, c + t * 1.5 - n * 0.3, c + t * 1.5 + n * 0.3, c - t * 1.5 + n * 0.3], UP, [], true, 1.6)

static func build(b, doors):
	tactile(b, doors)
