## games, inc.'s prize counter, 2026 (the "GALACTIC PRIZE PORTAL"; workstream PRIZES, Steven Nov 3 2026;
## design/godot-prize-counter.md "games, inc.", design/storefronts/games-inc-2026.md P1-P6).
## Made by player.gd in Wing 2's 2026 scene. The same machinery as Pocket Change's counter (it extends
## scripts/prizes.gd): 3D prizes in the three LED showcases and on the six-shelf black slatwall, green
## price tags, the "Redeem tickets" prompt at the showcases and the register (the redemption screen,
## scripts/redemption.gd, shows 2026's stock and spends 2026's tickets), and the closer look.
##
## Where: the build leaves markers in the wing (tools/stores/games_inc/machines/counter.gd _marker):
## GIPrizeCase0..2 (the showcases, front to back), GIPrizeDesk0 (the register counter), GIPrizeWall0.
## Each marker's frame: origin on the floor at the front edge's centre, +z the way the customer faces.
## What: scripts/prizes_2026.json (keys g_*: the words and prices never mix with 1995's). The prizes
## shared with Pocket Change are drawn by the same code (scripts/prize_units.gd, base names).
extends "res://scripts/prizes.gd"

const CASE_NAMES := ["Pink case, by the door", "Blue case", "White case, the big prizes"]
var wall_shelves: Array = [0.1, 0.42, 0.76, 1.1, 1.44, 1.78]

func _setup() -> bool:
	var p := "res://scripts/prizes_2026.json"
	if not FileAccess.file_exists(p):
		return false
	J = JSON.parse_string(FileAccess.get_file_as_string(p))
	if not (J is Dictionary):
		return false
	card_art = "gtag"
	# the showcases: a white deck at 0.40 m and two glass shelves (counter.gd CASE_SHELVES)
	LY = [0.4, 0.59, 0.78]
	CLEAR = [0.17, 0.17, 0.17]
	D0 = 0.05
	D1 = 0.5
	FR = {}
	look_frames = []
	var scn := get_parent()
	if scn == null:
		return false
	var cases := []
	for m in scn.find_children("GIPrize*", "Node3D", true, false):
		var xf: Transform3D = (m as Node3D).global_transform
		var f := xf.basis.z.normalized()
		var L := float(m.get_meta("length", 1.83))
		if m.name.begins_with("GIPrizeCase"):
			cases.append([m.name, xf.origin, f, L])
		elif m.name.begins_with("GIPrizeDesk"):
			FR["R"] = [xf.origin, f, L, 1]
			look_frames.append("R")
		elif m.name.begins_with("GIPrizeWall"):
			FR["W"] = [xf.origin, f, L, 1]
			wall_shelves = m.get_meta("shelves", wall_shelves)
	cases.sort_custom(func(a, b): return str(a[0]).naturalnocasecmp_to(str(b[0])) < 0)
	for k in cases.size():
		FR["C%d" % k] = [cases[k][1], cases[k][2], cases[k][3], 2]
		look_frames.append("C%d" % k)
	return cases.size() > 0 and FR.has("W")

## Nothing baked to hide: the showcases and the wall carry no painted prizes since PRIZES.
func _hide_generic() -> void:
	pass

func _views() -> void:
	for k in 3:
		var fr := "C%d" % k
		if FR.has(fr):
			views.append({"name": CASE_NAMES[k], "fr": fr, "pos": W(fr, 0, 1.18, -0.86), "tgt": W(fr, 0, 0.6, 0.28)})
	var L: float = FR["W"][2]
	var n := 4
	for i in n:
		var u := -L * 0.5 + (i + 0.5) * L / n
		views.append({"name": "Prize wall, part %d of %d" % [i + 1, n], "fr": "W", "pos": W("W", u, 1.3, -2.45), "tgt": W("W", u, 1.18, 0.3)})

## The wall: J "wall" rows [shelf, u from, u to, item], filled neatly (prize_units.gd), a green tag on
## the shelf's lip under each run. Shelf 6 is the top of the shelving: its plush are the build's own
## (counter.gd), so only their tags are added here.
func _wall(rng: RandomNumberGenerator, cat: Dictionary) -> void:
	var keep := [D0, D1]
	D0 = 0.08
	D1 = 0.42
	var bins := SurfaceTool.new()
	bins.begin(Mesh.PRIMITIVE_TRIANGLES)
	for e in J.get("wall", []):
		var sh := int(e[0])
		var u0 := float(e[1])
		var u1 := float(e[2])
		var it := str(e[3])
		var y: float = wall_shelves[sh] if sh < wall_shelves.size() else 2.1
		rng.seed = 2026 + int(u0 * 100) + sh * 7
		var mid := (u0 + u1) * 0.5
		var anchor := W("W", mid, y + 0.12, 0.25)
		if sh >= wall_shelves.size():
			# the top: tags along the lip, every 2 m, for the build's plush
			var u := u0 + 1.0
			while u < u1:
				_wall_tag(XF("W", u, y - 0.04, 0.045), cat, it, W("W", u, y + 0.3, 0.22))
				u += 2.0
			continue
		match PU.base_of(it):
			"lava":
				var u := u0 + 0.16
				while u < u1 - 0.1:
					_lava(rng, XF("W", u, y, 0.24))
					u += 0.3
				anchor = W("W", mid, y + 0.22, 0.24)
			_:
				if not PU.fill(self, rng, "W", Vector2(u0, u1), y, PU.base_of(it), bins):
					push_warning("prizes_gi: no way to show '%s'" % it)
		_wall_tag(XF("W", mid, y - 0.025, 0.045), cat, it, anchor)
	D0 = keep[0]
	D1 = keep[1]
	# on the register counter (J "desk": [u, item]): the lava lamps, too tall for the wall's shelves
	if FR.has("R"):
		for e in J.get("desk", []):
			var du := float(e[0])
			var dit := str(e[1])
			if PU.base_of(dit) == "lava":
				_lava(rng, XF("R", du, 0.97, 0.3))
			else:
				PU.unit(self, PU.base_of(dit), XF("R", du, 0.97, 0.3), 0, rng)
			_wall_tag(XF("R", du, 0.94, -0.012), cat, dit, W("R", du, 1.2, 0.3))
	var bm := MeshInstance3D.new()
	bm.name = "pz_wall_risers"
	bins.generate_normals()
	bm.mesh = bins.commit()
	bm.material_override = M("", Color(0.86, 0.94, 1.0), 0.15, 0.05, 0.0, 0.22)
	bm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	bm.visibility_range_end = 40.0
	add_child(bm)

func _wall_tag(c: Transform3D, cat: Dictionary, it: String, anchor: Vector3) -> void:
	var tk := int(cat.get(it, {}).get("tickets", 0))
	_card_at(c, it, 1.3)
	items.append({"pos": anchor, "name": str(cat.get(it, {}).get("name", it)), "tickets": tk, "key": it})
