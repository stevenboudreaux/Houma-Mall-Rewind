## Wing 6: the Southland Cinema's lobby, a PLACEHOLDER room (workstream S, Nov 2 2026;
## design/godot-wings.md "Wings 4-6"). Steven, Nov 2, 12:38: "just make it a very small room; I want
## to see if the logic works". One dark box behind the cinema's two door arches (the mall-side front
## is tools/stores/cinema/front.gd, in wing 1), a few lights, nothing else: no story, no signage.
##
## The box is build_mall.gd's ROOM_WINGS[6].box (x -66..-54, z -86..-78, 12 x 8 m, 3.2 m high); the
## front wall is the mall wall (z -86) with the two arches' door openings closed by dark doors (the
## threshold back to wing 1 is the whole front, ROOM_WINGS[6].thr). Unlit placeholder, never baked:
## everything is dynamic (probe-lit) and the lights are real-time.
const H := 3.2
const DOORS := [-63.6, -56.0]   # the door arches' centres (front.gd arches v 17.6 / 10.0 from x -46)
const DOOR_W := 2.56            # the glass between the arch's bronze stiles
const DOOR_H := 2.55            # front.gd TRANSOM

static func build(b, R: Dictionary) -> void:
	var bx: Array = R.box
	var x0 := float(bx[0]); var z0 := float(bx[1]); var x1 := float(bx[2]); var z1 := float(bx[3])
	var G := "cin6"
	b.force_dyn = true
	var UP := Vector3.UP
	# floor (the front lobby's carpet), ceiling, back and side walls
	b.quad(G, "cin_carpet", [Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x0, 0, z1)], UP,
		[Vector2(0, 0), Vector2((x1 - x0) / 1.5, 0), Vector2((x1 - x0) / 1.5, (z1 - z0) / 1.5), Vector2(0, (z1 - z0) / 1.5)])
	b.quad(G, "cin_dark", [Vector3(x0, H, z0), Vector3(x1, H, z0), Vector3(x1, H, z1), Vector3(x0, H, z1)], Vector3.DOWN)
	b.quad(G, "cin_wall", [Vector3(x1, 0, z1), Vector3(x0, 0, z1), Vector3(x0, H, z1), Vector3(x1, H, z1)], Vector3(0, 0, -1))
	b.quad(G, "cin_wall", [Vector3(x0, 0, z1), Vector3(x0, 0, z0), Vector3(x0, H, z0), Vector3(x0, H, z1)], Vector3(1, 0, 0))
	b.quad(G, "cin_wall", [Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x1, H, z1), Vector3(x1, H, z0)], Vector3(-1, 0, 0))
	# the front wall (inside face) with the two doors
	var zf := z0 + 0.01
	var cuts := []
	for c in DOORS:
		cuts.append([c - DOOR_W * 0.5, c + DOOR_W * 0.5])
	var xa := x0
	for cut in cuts:
		b.quad(G, "cin_wall", [Vector3(cut[0], 0, zf), Vector3(xa, 0, zf), Vector3(xa, H, zf), Vector3(cut[0], H, zf)], Vector3(0, 0, 1))
		b.quad(G, "cin_wall", [Vector3(cut[1], DOOR_H, zf), Vector3(cut[0], DOOR_H, zf), Vector3(cut[0], H, zf), Vector3(cut[1], H, zf)], Vector3(0, 0, 1))
		# the doors from inside: dark leaves in a bronze frame
		b.quad(G, "cin_black", [Vector3(cut[1], 0, z0), Vector3(cut[0], 0, z0), Vector3(cut[0], DOOR_H, z0), Vector3(cut[1], DOOR_H, z0)], Vector3(0, 0, 1))
		for xx in [cut[0], (cut[0] + cut[1]) * 0.5, cut[1]]:
			b.box(G, "cin_bronze", Vector3(xx, DOOR_H * 0.5, z0 + 0.03), Vector3(0.06, DOOR_H, 0.06))
		b.box(G, "cin_bronze", Vector3((cut[0] + cut[1]) * 0.5, DOOR_H, z0 + 0.03), Vector3(cut[1] - cut[0] + 0.06, 0.08, 0.06))
		xa = cut[1]
	b.quad(G, "cin_wall", [Vector3(x1, 0, zf), Vector3(xa, 0, zf), Vector3(xa, H, zf), Vector3(x1, H, zf)], Vector3(0, 0, 1))
	b.force_dyn = false
	# a few lights: three warm downlights down the middle, real-time (this wing is never baked)
	for k in 3:
		var l = b.add_omni(Vector3(x0 + (x1 - x0) * (k + 1) / 4.0, H - 0.4, (z0 + z1) * 0.5), 0.7, 6.0, Color(1.0, 0.82, 0.6))
		l.light_bake_mode = Light3D.BAKE_DYNAMIC
