## Framed newspaper ads on the mall's bare walls (Steven, Oct 14 2026): Courier ads he found for
## the mall's stores, hung "like posters around the mall ... in a frame that wraps around the
## dimensions of the actual file", sprinkled on the bare walls of the Sears wing and the side of
## Franks on the east hall.
##
## Each poster: a black anodised frame whose opening is the ad's own aspect (ads.json carries the
## pixel sizes; the longer side of the print is LONG metres), a white mat MAT wide, the print on
## matte paper, hung with its centre at EYE metres. Materials: "black" (the frame), "poster_mat" (the mat),
## "ad_<name>" (the print: tex/ads/<name>.png, build_mall.gd mat()). All of it is dynamic geometry
## (no rebake), group "posters" in the wing that owns the wall.
##
## PLACES names a plain wall by its layout endpoints (layout_mall.json edges of kind "wall") and the
## ads along it as fractions of its length; a wall that is no longer in the layout is skipped with
## a warning, so a layout change never crashes the build.
##
## Not mall tenants: Scatterbar's (1832 West Park) and Radiofone (Houma office). Steven sent them
## with the rest on Oct 14; pull them from PLACES if he says so.

const ADS = "res://tools/stores/posters/ads.json"
const LONG = 1.15      # the print's longer side, metres
const MAT = 0.06       # white mat, metres
const FRAME = 0.045    # frame face, metres
const DEEP = 0.032     # frame depth off the wall
const EYE = 1.55       # centre height
const UP = Vector3.UP

const PLACES = [
	# Sears hall west, the north wall (36 m)
	{"a": [-76.0, -96.0], "b": [-40.0, -96.0], "ads": [[0.22, "gryders"], [0.5, "tgmc"], [0.78, "saadis"]]},
	# Sears hall west, the south wall east of the court (26 m)
	{"a": [-36.0, -86.0], "b": [-10.0, -86.0], "ads": [[0.3, "vision_plaza"], [0.7, "concepts"]]},
	# Sears hall east, the south wall (20 m)
	{"a": [2.0, -86.0], "b": [22.0, -86.0], "ads": [[0.3, "radiofone"], [0.7, "scatterbars"]]},
	# Franks' side wall on the east hall (6 m, z 10..16), under the neon
	{"a": [2.0, 10.0], "b": [2.0, 16.0], "ads": [[0.28, "dippin_dots"], [0.72, "gumballs"]]},
]

static func build(b):
	var sizes = JSON.parse_string(FileAccess.get_file_as_string(ADS))
	var hung = 0
	for pl in PLACES:
		var e = _wall(b, pl.a, pl.b)
		if e == null:
			push_warning("posters: no wall %s-%s in the layout" % [str(pl.a), str(pl.b)])
			continue
		if not b.in_wing(b.edge_wing(e)):
			continue
		var eb = b.edge_basics(e)
		var a = eb[0]; var n = eb[2]; var t = eb[3]; var Ln = eb[4]
		# the print reads left to right for someone facing the wall. The wall's own direction t
		# runs whichever way the layout drew it, and on the south walls of the Sears hall it ran
		# right to left, so those prints came out mirrored (Steven, Oct 15 2026).
		var r: Vector3 = (-n).cross(UP).normalized()
		for ad in pl.ads:
			var px = sizes.get(ad[1])
			if px == null:
				push_warning("posters: no ad " + ad[1]); continue
			var s = LONG / float(max(px[0], px[1]))
			poster(b, "posters", ad[1], a + t * (Ln * float(ad[0])) + UP * EYE, n, r, float(px[0]) * s, float(px[1]) * s)
			hung += 1
	print("posters: ", hung)

## The wall edge with these endpoints (either way round), or null.
static func _wall(b, a, bb):
	for e in b.L.edges:
		if e.kind != "wall":
			continue
		if (_near(e.a, a) and _near(e.b, bb)) or (_near(e.a, bb) and _near(e.b, a)):
			return e
	return null

static func _near(p, q):
	return abs(float(p[0]) - float(q[0])) < 0.01 and abs(float(p[1]) - float(q[1])) < 0.01

## One framed print, w by h metres, centred at c on a wall whose face normal is n; t is the
## viewer's right as they face the wall (the print's left edge is at -t).
static func poster(b, g, name, c, n, t, w, h):
	var hw = w * 0.5 + MAT; var hh = h * 0.5 + MAT       # the opening, with the mat
	var fw = hw + FRAME; var fh = hh + FRAME             # the frame's outside
	# the frame: four rails, DEEP proud of the wall
	var cz = c + n * (DEEP * 0.5)
	var rail_h = Vector3(2.0 * fw, FRAME, DEEP)           # along t, up, out
	var rail_v = Vector3(FRAME, 2.0 * hh, DEEP)
	b.box(g, "black", cz + UP * (fh - FRAME * 0.5), b.abs_size(t, rail_h.x, rail_h.y, rail_h.z, n), Transform3D.IDENTITY, [], true)
	b.box(g, "black", cz - UP * (fh - FRAME * 0.5), b.abs_size(t, rail_h.x, rail_h.y, rail_h.z, n), Transform3D.IDENTITY, [], true)
	b.box(g, "black", cz + t * (fw - FRAME * 0.5), b.abs_size(t, rail_v.x, rail_v.y, rail_v.z, n), Transform3D.IDENTITY, [], true)
	b.box(g, "black", cz - t * (fw - FRAME * 0.5), b.abs_size(t, rail_v.x, rail_v.y, rail_v.z, n), Transform3D.IDENTITY, [], true)
	# the mat, a hair off the wall inside the opening
	var m = c + n * 0.012
	b.quad(g, "poster_mat", [m - t * hw - UP * hh, m + t * hw - UP * hh, m + t * hw + UP * hh, m - t * hw + UP * hh], n, [], true)
	# the print, on the mat: UV (0,0) is the ad's top-left
	var p = c + n * 0.015
	var pw = w * 0.5; var ph = h * 0.5
	b.quad(g, "ad_" + name,
		[p - t * pw + UP * ph, p + t * pw + UP * ph, p + t * pw - UP * ph, p - t * pw - UP * ph], n,
		[Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)], true)
