## The outside's road signs (Workstream F, Nov 1 2026; design/godot-exterior.md "Monument signs"):
## a monument sign at each road entrance and the United Artists Southland Cinema roadside marquee.
##
## Steven (Nov 1): "the structure is good to build; no sign face is legible in the footage, and
## that's okay". No monument sign is close or legible anywhere in the Oct 23 footage (refs INDEX
## "Gaps"), so the structure is a plausible one in the mall's own materials (the tan store-back
## brick for the plinth and piers, cream stucco caps like the east facade's cornice), and both
## faces are GUESSES:
##   1995: the fan logo from the mall's own March 1994 "Merchant List & Map" (The Courier, Mar 20
##         1994), dark bronze on cream (the print is black and white: the colours are a guess)
##   2026: the same mark white on navy, like the navy banner on today's main-entrance tower (IMG_4406 f002)
## Placed at the three road entrances of the site plan (design/exterior/morguard-site-plan-2024.png):
## West Park Ave (the palm drive, east), Bayou Gardens Blvd (south, the drive in front of the south
## entrance) and Armour Dr (north, the back lot's drive).
##
## The United Artists marquee (era_1995/other/other_3.jpg) is real, but the photo is summer 1997:
## the structure (two black posts, a black-framed white cabinet) and the "UNITED ARTISTS Theatres /
## SOUTHLAND CINEMA" header are built for 1995 at the cinema side (Armour Dr, north of the cinema
## box); the changeable-letter lines are invented house lines, no film titles (a 1995 board could not
## show the photo's 1997 films; IP rule). Where it stood is a guess (the photo shows grass, a bayou
## and a road). 1995 only: the cinema closed long before 2026.
const UP = Vector3.UP

## The monument: a tan-brick plinth and two brick piers with cream stucco caps, a cream stepped
## cornice over the face panel; the face on both sides (it stands square to the road so both
## directions read it). `at` is the centre on the ground, `n` one face's outward normal.
static func monument(b, at: Vector3, n: Vector3, face: String):
	var g = "ex_signs"
	var t = Vector3(-n.z, 0, n.x)           # along the sign
	var W = 5.0; var D = 0.7
	var xf = Transform3D(Basis(t, UP, n), Vector3.ZERO)
	var c = func(u, y, w): return at + t * u + n * w + UP * y
	# plinth
	b.box(g, "ex_brick_tan", Vector3.ZERO, Vector3(W + 0.6, 0.6, D + 0.3), Transform3D(Basis(t, UP, n), at + UP * 0.3), ["-y"])
	b.box(g, "ex_cream_pier", Vector3.ZERO, Vector3(W + 0.7, 0.08, D + 0.4), Transform3D(Basis(t, UP, n), at + UP * 0.64), ["-y"])
	# the piers
	for s in [-1.0, 1.0]:
		var pc = at + t * (s * (W * 0.5 - 0.35)) + UP * 1.95
		b.box(g, "ex_brick_tan", Vector3.ZERO, Vector3(0.7, 2.6, D + 0.1), Transform3D(Basis(t, UP, n), pc), ["-y"])
		b.box(g, "ex_cream_pier", Vector3.ZERO, Vector3(0.82, 0.16, D + 0.22), Transform3D(Basis(t, UP, n), pc + UP * 1.38), ["-y"])
		b.box(g, "ex_cream_pier", Vector3.ZERO, Vector3(0.5, 0.3, D - 0.1), Transform3D(Basis(t, UP, n), pc + UP * 1.6), ["-y"])
	# the face panel between the piers, and its stepped cornice
	var fw = W - 1.4; var fy0 = 0.85; var fy1 = 2.95
	b.box(g, "ex_cream_pier", Vector3.ZERO, Vector3(fw, fy1 - fy0, D - 0.12), Transform3D(Basis(t, UP, n), at + UP * ((fy0 + fy1) * 0.5)), ["-y"])
	b.box(g, "ex_cream_pier", Vector3.ZERO, Vector3(fw + 0.2, 0.18, D + 0.02), Transform3D(Basis(t, UP, n), at + UP * (fy1 + 0.09)), ["-y"])
	b.box(g, "ex_cream_pier", Vector3.ZERO, Vector3(fw * 0.5, 0.22, D - 0.12), Transform3D(Basis(t, UP, n), at + UP * (fy1 + 0.29)), ["-y"])
	# the face, both sides (u runs left to right as you look at each face)
	for s in [1.0, -1.0]:
		var nn = n * s; var tt = UP.cross(nn)   # the viewer's right
		var o = at + nn * ((D - 0.12) * 0.5 + 0.012)
		var p0 = o - tt * (fw * 0.5 - 0.08) + UP * (fy0 + 0.08)
		var p1 = o + tt * (fw * 0.5 - 0.08) + UP * (fy0 + 0.08)
		b.quad(g, face, [p0, p1, p1 + UP * (fy1 - fy0 - 0.16), p0 + UP * (fy1 - fy0 - 0.16)], nn,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		# a ground uplight on each face for the night
		b.tag(b.add_spot(at + nn * 2.2 + UP * 0.3, (-nn * 2.2 + UP * 1.6).normalized(), 1.2, 6.0, 40.0, Color("#FFE6C2")), "night")
	# the bed round it: liriope and mulch on a grey curb
	var bx = W * 0.5 + 1.2; var bz = D * 0.5 + 1.2
	var corners = [at - t * bx - n * bz, at + t * bx - n * bz, at + t * bx + n * bz, at - t * bx + n * bz]
	b.quad("ex_lot", "ex_mulch", [corners[0] + UP * 0.12, corners[1] + UP * 0.12, corners[2] + UP * 0.12, corners[3] + UP * 0.12], UP, [], false, 0.5)
	b.box("ex_lot", "ex_curb", Vector3.ZERO, Vector3(bx * 2.0, 0.12, bz * 2.0), Transform3D(Basis(t, UP, n), at + UP * 0.059), ["+y", "-y"])
	for s in [-1.0, 1.0]:
		for k in [-1.0, 1.0]:
			b.force_dyn = true
			b.bush(at + t * (s * (W * 0.5 + 0.5)) + n * (k * (D * 0.5 + 0.55)) + UP * 0.12, "leafy", 0.55, 3)
			b.force_dyn = false
	var ext = W * 0.5 + 1.2
	var ex = (t * ext).abs() + (n * bz).abs()
	b.obst(["rect", at.x - ex.x, at.z - ex.z, at.x + ex.x, at.z + ex.z])

## The United Artists Southland Cinema roadside sign (1997 photo): two black square posts ~4.5 m,
## a black-framed white cabinet ~5.6 x 2.9 m: the header panel over a four-line letter board.
static func ua_marquee(b, at: Vector3, n: Vector3):
	var g = "ex_signs"
	var t = Vector3(-n.z, 0, n.x)
	var W = 5.6; var y0 = 2.2; var yh = 1.1; var yl = 1.65; var D = 0.45
	var bs = Basis(t, UP, n)
	for s in [-1.0, 1.0]:
		b.box(g, "ex_fence_black", Vector3.ZERO, Vector3(0.3, y0 + yl + yh + 0.1, 0.3), Transform3D(bs, at + t * (s * 1.7) + UP * ((y0 + yl + yh + 0.1) * 0.5)))
	var top = y0 + yl + yh
	b.box(g, "ex_fence_black", Vector3.ZERO, Vector3(W + 0.16, yl + yh + 0.16, D), Transform3D(bs, at + UP * (y0 + (yl + yh) * 0.5)))
	for s in [1.0, -1.0]:
		var nn = n * s; var tt = UP.cross(nn)   # the viewer's right
		var o = at + nn * (D * 0.5 + 0.01)
		var p0 = o - tt * (W * 0.5 - 0.02); var p1 = o + tt * (W * 0.5 - 0.02)
		b.quad(g, "ex_ua_lines", [p0 + UP * y0, p1 + UP * y0, p1 + UP * (y0 + yl), p0 + UP * (y0 + yl)], nn,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
		b.quad(g, "ex_ua_head", [p0 + UP * (y0 + yl), p1 + UP * (y0 + yl), p1 + UP * top, p0 + UP * top], nn,
			[Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	b.obst(["rect", at.x - 2.0, at.z - 2.0, at.x + 2.0, at.z + 2.0])

## A drive through a frontage island: asphalt from the road into the lot, double yellow line.
static func drive(b, x0: float, x1: float, z0: float, z1: float):
	b.quad("ex_ground", "ex_asphalt", [Vector3(x0, 0.016, z0), Vector3(x1, 0.016, z0), Vector3(x1, 0.016, z1), Vector3(x0, 0.016, z1)], UP, [], false, 0.1)
	var xm = (x0 + x1) * 0.5
	for dx in [-0.12, 0.12]:
		var a = Vector3(xm + dx, 0.02, z0); var e = Vector3(xm + dx, 0.02, z1)
		# worn paint: u across the line, v along it (paint_lot.py ex_paint_worn covers 8 m)
		var L = abs(z1 - z0) / 8.0
		b.quad("ex_paint", "ex_stripe_yellow", [a - Vector3(0.05, 0, 0), e - Vector3(0.05, 0, 0), e + Vector3(0.05, 0, 0), a + Vector3(0.05, 0, 0)], UP,
			[Vector2(0, 0), Vector2(0, L), Vector2(1, L), Vector2(1, 0)], true)

## Everything above, for the year being built. Called from exterior.gd's build().
static func build(b, year: int):
	var face = "ex_mon_2026" if year == 2026 else "ex_mon_1995"
	# West Park Ave: the palm drive's north corner, square to the road
	# EXT-B (Nov 4 2026): at the roads' real places (design/exterior-sequence.md §5 #3, #9)
	monument(b, Vector3(100.0, 0, -11.5), Vector3(0, 0, 1), face)
	# Bayou Gardens Blvd: the drive in front of the south entrance (exterior.gd cuts the palm island
	# there, BAYOU_DRIVE), on its east side, square to the road
	monument(b, Vector3(-127.0, 0, 205.5), Vector3(1, 0, 0), face)
	# Armour Dr: the back lot's drive, west side, square to the road
	monument(b, Vector3(-33.0, 0, -243.0), Vector3(1, 0, 0), face)
	if year != 2026:
		ua_marquee(b, Vector3(-90.0, 0, -243.0), Vector3(1, 0, 0))
	print("monuments: 3 signs", "" if year == 2026 else " + the UA marquee")
