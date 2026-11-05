## Workstream EXT-B (Nov 4 2026, design/godot-exterior.md "EXT-B"): the doors between inside and
## outside, headless, for both years.
##   1. Every door of exterior.json, outside (wing 3): its `out` spot is on the grown walk grid (wing
##      3's wing.json with its own origin), clear of every obstacle (collide.json), the player can step
##      2 m away from the doors, and the player standing there finds that door (the prompt
##      "Enter the mall · <door>").
##   2. Every door's inside spot is walkable in the wing it belongs to (gen/w<n>/wing.json).
##   3. The walk (--door, default s39): its wing at the door's inside spot -> "Go outside" -> E -> wing 3 at the out
##      spot facing the palm drive -> "Enter the mall" -> E -> wing 1 at the inside spot. Needs
##      wing1.tscn and wing3.tscn (or the 2026 ones); skipped with a note when wing 1 is not built.
##   godot --headless --path . --script res://tools/qa/ext_door_test.gd -- [--year=2026] [--door=s39]
extends SceneTree

var year := 1995
var door_id := "s39"
var fails := 0
var step := 0
var frames := 0
var door = {}

func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1

func _gen(w: int) -> String:
	return "res://gen/w%d%s/" % [w, "y26" if year == 2026 else ""]

func _walkable(wj: Dictionary, origin: Vector2, x: float, z: float) -> bool:
	var rows: Array = wj.walk
	var tx := int(floor(x / 2.0 + origin.x)); var ty := int(floor(z / 2.0 + origin.y))
	return ty >= 0 and ty < rows.size() and tx >= 0 and tx < str(rows[ty]).length() and str(rows[ty])[tx] == "1"

func _hit(obs: Array, x: float, z: float, r: float) -> bool:
	for o in obs:
		if o is Array and o.size() >= 5 and str(o[0]) == "rect":
			if x + r > float(o[1]) and x - r < float(o[3]) and z + r > float(o[2]) and z - r < float(o[4]):
				return true
	return false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--year="): year = int(a.substr(7))
		elif a.begins_with("--door="): door_id = a.substr(7)
	print("ext_door_test (", year, ")")
	var ex = JSON.parse_string(FileAccess.get_file_as_string("res://exterior.json"))
	var w3 = JSON.parse_string(FileAccess.get_file_as_string(_gen(3) + "wing.json"))
	var col = JSON.parse_string(FileAccess.get_file_as_string(_gen(3) + "collide.json"))
	var o3 := Vector2(float(w3.origin[0]), float(w3.origin[1])) if w3.has("origin") else Vector2(148, 100)
	_check(w3.has("origin"), "wing 3's wing.json carries the grown grid's origin %s" % [o3])
	var lay = JSON.parse_string(FileAccess.get_file_as_string("res://layout_mall.json"))
	var lo := Vector2(float(lay.origin[0]), float(lay.origin[1]))
	for d in ex.doors:
		var o: Array = d.out
		var n := Vector2(float(d.n[0]), float(d.n[1]))
		var x := float(o[0]); var z := float(o[1])
		_check(_walkable(w3, o3, x, z) and not _hit(col.static, x, z, 0.3), "%s: outside spot (%.1f, %.1f) is on the lot, clear" % [d.store, x, z])
		_check(_walkable(w3, o3, x - n.x * 2.0, z - n.y * 2.0) and not _hit(col.static, x - n.x * 2.0, z - n.y * 2.0, 0.3), "%s: 2 m further out is walkable too" % d.store)
		var wpath := _gen(int(d.wing)) + "wing.json"
		if FileAccess.file_exists(wpath):
			var wj = JSON.parse_string(FileAccess.get_file_as_string(wpath))
			_check(_walkable(wj, lo, float(d.inside[0]), float(d.inside[1])), "%s: inside spot walkable in wing %d" % [d.store, int(d.wing)])
		if d.store == door_id:
			door = d
	_check(not door.is_empty(), "door %s is in exterior.json" % door_id)

func _process(_dt: float) -> bool:
	frames += 1
	var dw := int(door.get("wing", 1)) if not door.is_empty() else 1
	var w1 := ("res://wing%d_2026.tscn" if year == 2026 else "res://wing%d.tscn") % dw
	var w3s := "res://wing3_2026.tscn" if year == 2026 else "res://wing3.tscn"
	match step:
		0:
			# outside first: every door's out spot finds its own door
			if not ResourceLoader.exists(w3s):
				_check(false, "%s is built" % w3s)
				return _end()
			Engine.set_meta("mall_xfer", {"x": float(door.out[0]), "z": float(door.out[1]), "yaw": deg_to_rad(float(door.yaw_out)), "pitch": 0.0})
			change_scene_to_file(w3s)
			step = 1; frames = 0
		1:
			if frames < 20:
				return false
			var pl = current_scene.get_node_or_null("Player")
			_check(pl != null and int(pl.wing) == 3, "wing 3 loaded with its player")
			if pl == null:
				return _end()
			var ex = JSON.parse_string(FileAccess.get_file_as_string("res://exterior.json"))
			for d in ex.doors:
				pl.position = Vector3(float(d.out[0]), 0, float(d.out[1]))
				var dn = pl._door_here()
				_check(dn != null and dn.store == d.store, "outside at %s's spot the player finds %s" % [d.store, dn.store if dn else "nothing"])
				_check(pl._free(pl.position.x, pl.position.z), "%s: the player may stand there" % d.store)
			if not ResourceLoader.exists(w1):
				print("  note: %s is not built here; the inside leg of the walk is skipped" % w1)
				return _end()
			Engine.set_meta("mall_xfer", {"x": float(door.inside[0]), "z": float(door.inside[1]), "yaw": deg_to_rad(float(door.yaw_in)), "pitch": 0.0})
			change_scene_to_file(w1)
			step = 2; frames = 0
		2:
			if frames < 20:
				return false
			var pl = current_scene.get_node_or_null("Player")
			pl.position = Vector3(float(door.inside[0]), 0, float(door.inside[1]))
			pl._update_prompt()
			_check(pl.door_near != null and pl.door_near.store == door_id and pl.prompt_text.text.begins_with("Go outside"), "wing %d at %s's inside spot: \"%s\"" % [dw, door_id, pl.prompt_text.text])
			pl._cross()
			step = 3; frames = 0
		3:
			if frames < 60:
				return false
			var pl = current_scene.get_node_or_null("Player")
			_check(pl != null and int(pl.wing) == 3, "E: walked out into wing 3")
			if pl == null:
				return _end()
			_check(Vector2(pl.position.x, pl.position.z).distance_to(Vector2(float(door.out[0]), float(door.out[1]))) < 0.6, "  at the out spot (%.1f, %.1f)" % [pl.position.x, pl.position.z])
			pl._update_prompt()
			_check(pl.prompt_text.text.begins_with("Enter the mall"), "outside: \"%s\"" % pl.prompt_text.text)
			pl._cross()
			step = 4; frames = 0
		4:
			if frames < 60:
				return false
			var pl = current_scene.get_node_or_null("Player")
			_check(pl != null and int(pl.wing) == int(door.wing), "E: walked back into wing %d" % int(door.wing))
			if pl:
				_check(Vector2(pl.position.x, pl.position.z).distance_to(Vector2(float(door.inside[0]), float(door.inside[1]))) < 0.6, "  at the inside spot (%.1f, %.1f)" % [pl.position.x, pl.position.z])
			return _end()
	return false

func _end() -> bool:
	print("ext_door_test: ", "PASS" if fails == 0 else "%d FAIL" % fails)
	quit(1 if fails else 0)
	return true
