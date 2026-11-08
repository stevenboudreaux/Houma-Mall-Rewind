## The black 3-loop "wave" bike rack beside the cinema-wing exit (Workstream EXT-LAYOUT, Nov 8 2026;
## design/godot-exterior.md "Nov 8 refinements"). Steven: "here since I was a kid". One bent pipe:
## the two end legs go into the slab, three tall inverted-U loops on top, two shallow U bends low down
## between them (4416 f009-f011, 4486 f002-f003).
##   ~1.8 m long, ~0.8 m tall, 48 mm (1.9") pipe, black paint chipped to rust: a vertex-colour mottle.
## A swept tube, 8 sides, ~46 path segments: 736 triangles (budget 800). Baked with the outside's
## props (static, lightmapped): its shadow on the white wall is half of what reads in the frames.
extends RefCounted

const LEN := 1.8          # end leg to end leg, centre lines
const HGT := 0.8          # top of the loops
const R_PIPE := 0.024
const SIDES := 8
const LOW := 0.09         # the underside of the low bends above the slab
const ARC_SEG := 8

## The pipe's centre line in the rack's own plane: (u along the rack, y up).
static func path() -> Array:
	var legs := 6
	var pitch := LEN / (legs - 1)          # 0.36 m between legs
	var r := pitch * 0.5                   # every bend is a half circle between two legs
	var pts := []
	pts.append(Vector2(0.0, -0.05))        # into the slab
	for k in legs - 1:
		var u0 := k * pitch
		var top := k % 2 == 0              # legs 0-1, 2-3, 4-5 meet over the top
		var yc := HGT - r - R_PIPE if top else LOW + r + R_PIPE
		pts.append(Vector2(u0, yc))
		for s in range(1, ARC_SEG):
			var a := PI - PI * s / ARC_SEG
			pts.append(Vector2(u0 + r + r * cos(a), yc + (r * sin(a) if top else -r * sin(a))))
		pts.append(Vector2(u0 + pitch, yc))
	pts.append(Vector2(LEN, -0.05))
	return pts

## Builds the rack standing at `at` (its middle, on the slab), its length along `t`.
static func build(b, at: Vector3, t: Vector3, group := "ex_props") -> void:
	t = t.normalized()
	var side := Vector3(-t.z, 0, t.x)
	var p2 := path()
	var P := []
	for q in p2:
		P.append(at + t * (q.x - LEN * 0.5) + Vector3.UP * q.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4416
	var rings := []
	var cols := []
	for i in P.size():
		var d: Vector3 = (P[min(i + 1, P.size() - 1)] - P[max(i - 1, 0)]).normalized()
		var bn := d.cross(side).normalized()
		var ring := []
		var cr := []
		for k in SIDES:
			var a := TAU * k / SIDES
			var nrm := (side * cos(a) + bn * sin(a)).normalized()
			ring.append([P[i] + nrm * R_PIPE, nrm])
			# chipped black paint: rust on the tops of the bends and low down near the slab
			var rust := rng.randf() < (0.22 if P[i].y - at.y > HGT - 0.2 or P[i].y - at.y < 0.25 else 0.08)
			cr.append(Color("#6b3a1e") if rust else Color("#1b1a19").lerp(Color("#2a2522"), rng.randf()))
		rings.append(ring)
		cols.append(cr)
	var s = b.st(group, "ex_rack")
	for i in P.size() - 1:
		for k in SIDES:
			var k2 := (k + 1) % SIDES
			var quad := [[i, k], [i + 1, k], [i + 1, k2], [i, k2]]
			for tri in [[0, 1, 2], [0, 2, 3]]:
				# build_mall.gd tri()'s winding: (b - a) x (c - a) points away from the outward normal
				var A: Vector3 = rings[quad[tri[0]][0]][quad[tri[0]][1]][0]
				var B: Vector3 = rings[quad[tri[1]][0]][quad[tri[1]][1]][0]
				var C: Vector3 = rings[quad[tri[2]][0]][quad[tri[2]][1]][0]
				var nn: Vector3 = rings[quad[tri[0]][0]][quad[tri[0]][1]][1]
				if (B - A).cross(C - A).dot(nn) > 0.0:
					tri = [tri[0], tri[2], tri[1]]
				for j in tri:
					var ik = quad[j]
					s.set_color(cols[ik[0]][ik[1]])
					s.set_normal(rings[ik[0]][ik[1]][1])
					s.set_uv(Vector2(float(ik[0]) / P.size(), float(ik[1]) / SIDES))
					s.add_vertex(rings[ik[0]][ik[1]][0])
	var p0 := at - t * (LEN * 0.5 + 0.3); var p1 := at + t * (LEN * 0.5 + 0.3)
	b.obst(["rect", min(p0.x, p1.x) - 0.35, min(p0.z, p1.z) - 0.35, max(p0.x, p1.x) + 0.35, max(p0.z, p1.z) + 0.35])

## Triangle count (for the budget line in the design note).
static func tris() -> int:
	return (path().size() - 1) * SIDES * 2

static func fill_mat(m, key, b) -> bool:
	if key != "rack":
		return false
	m.vertex_color_use_as_albedo = true
	m.albedo_color = Color.WHITE
	m.roughness = 0.55
	m.metallic = 0.0
	return true
