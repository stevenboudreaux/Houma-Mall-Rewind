## Workstream EXT-DOCKS (Nov 11 2026, design/godot-exterior.md "Workstream EXT-DOCKS"): the two loading docks'
## collision, headless, from the built wing 3 (gen/w3[y26]/wing.json + collide.json), with the player's own rule
## (scripts/player.gd _free: the four corners of a 0.3 m box on the walk grid, clear of every obstacle).
##   1. Dillard's: the wing wall cannot be walked through anywhere along its line (z 118, x -134..-52); the opening
##      (x -47..-39) can; the dock court behind it is reached on foot from the lot, and so is the service lane.
##   2. Where the dock, the trailer and the roll-off used to stand in front of the wall is open lot now.
##   3. JCPenney: the old dock spot on the north face is open walk; the truck apron on the east face is reached
##      on foot from the staff lot; the dock platform, the compactor, the container and the rail block.
##   godot --headless --path . --script res://tools/qa/ext_docks_test.gd -- [--year=2026]
extends SceneTree

const R := 0.3
var year := 1995
var fails := 0
var rows: Array = []
var origin := Vector2(148, 100)
var obs: Array = []

func _check(ok: bool, what: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + what)
	if not ok:
		fails += 1

func _walk(x: float, z: float) -> bool:
	var tx := int(floor(x / 2.0 + origin.x)); var ty := int(floor(z / 2.0 + origin.y))
	return ty >= 0 and ty < rows.size() and tx >= 0 and tx < str(rows[ty]).length() and str(rows[ty])[tx] == "1"

func _free(x: float, z: float) -> bool:
	if not (_walk(x - R, z - R) and _walk(x + R, z - R) and _walk(x - R, z + R) and _walk(x + R, z + R)):
		return false
	for o in obs:
		if o is Array and o.size() == 3 and not (o[0] is String):
			if Vector2(x - float(o[0]), z - float(o[1])).length() < float(o[2]) + R:
				return false
		elif o is Array and o.size() >= 5 and str(o[0]) == "rect":
			if x + R > float(o[1]) and x - R < float(o[3]) and z + R > float(o[2]) and z - R < float(o[4]):
				return false
	return true

## Can the player get from a to b on foot? A flood over a 0.5 m lattice inside `box` [x0, z0, x1, z1].
func _reach(a: Vector2, b: Vector2, box: Array) -> bool:
	var S := 0.5
	var key = func(p: Vector2) -> Vector2i: return Vector2i(roundi(p.x / S), roundi(p.y / S))
	var goal: Vector2i = key.call(b)
	var seen := {key.call(a): true}
	var q: Array = [key.call(a)]
	while not q.is_empty():
		var c: Vector2i = q.pop_back()
		if c == goal:
			return true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var nx: Vector2i = c + d
			var px := nx.x * S; var pz := nx.y * S
			if seen.has(nx) or px < box[0] or px > box[2] or pz < box[1] or pz > box[3] or not _free(px, pz):
				continue
			seen[nx] = true
			q.append(nx)
	return false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--year="): year = int(a.substr(7))
	var gen := "res://gen/w3%s/" % ("y26" if year == 2026 else "")
	print("ext_docks_test (", year, ")")
	var wj = JSON.parse_string(FileAccess.get_file_as_string(gen + "wing.json"))
	var col = JSON.parse_string(FileAccess.get_file_as_string(gen + "collide.json"))
	rows = wj.walk
	if wj.has("origin"):
		origin = Vector2(float(wj.origin[0]), float(wj.origin[1]))
	obs = col.static
	# 1. Dillard's: the wall line and the opening
	var through := 0
	var x := -133.5
	while x <= -52.4:
		for z in [117.0, 117.5]:
			if _free(x, z):
				through += 1
		x += 0.5
	_check(through == 0, "Dillard's: no walkable spot inside the wing wall's line, x -134..-52 (%d found)" % through)
	var lot := Vector2(-60.0, 130.0)
	_check(_free(lot.x, lot.y), "the lot in front of the wall is open at (-60, 130)")
	_check(not _reach(lot, Vector2(-60.0, 110.0), [-134.0, 96.0, -52.6, 150.0]), "the wall cannot be crossed west of the opening")
	var open_ok := true
	x = -47.0
	while x <= -39.0:
		for z in [116.0, 117.0, 118.0, 119.0, 120.0]:
			open_ok = open_ok and _free(x, z)
		x += 0.5
	_check(open_ok, "the opening x -47..-39 is clear across the wall's line (z 116..120)")
	_check(_reach(lot, Vector2(-44.0, 106.0), [-70.0, 98.0, -36.0, 150.0]), "the dock court (-44, 106) is reached on foot from the lot through the opening")
	_check(_reach(lot, Vector2(-40.0, 80.0), [-70.0, 68.0, -36.0, 150.0]), "the service lane (-40, 80) is still reached through the court")
	_check(not _free(-47.0, 106.0), "the trailer in bay 1 blocks")
	_check(not _free(-50.25, 104.0), "the roll-off on its pad blocks")
	_check(not _free(-50.0, 115.5), "the wood enclosure blocks")
	# 2. the old positions in front of the wall
	for p in [Vector2(-42.0, 127.0), Vector2(-58.0, 125.0), Vector2(-58.0, 132.0)]:
		_check(_free(p.x, p.y), "open lot where the old dock / trailer / roll-off stood (%.0f, %.0f)" % [p.x, p.y])
	# 3. JCPenney
	for p in [Vector2(-165.0, -15.2), Vector2(-176.0, -17.0)]:
		_check(_free(p.x, p.y), "JCPenney north face: open where the old dock / compactor stood (%.0f, %.1f)" % [p.x, p.y])
	var staff := Vector2(-130.0, 5.0)
	_check(_free(staff.x, staff.y), "the staff lot is open at (-130, 5)")
	_check(_reach(staff, Vector2(-149.0, -8.0), [-156.0, -34.0, -110.0, 22.0]), "JCPenney's truck apron (-149, -8) is reached on foot from the staff lot")
	_check(not _free(-153.0, -8.0), "the raised dock blocks")
	_check(not _free(-153.0, -1.4), "the compactor head blocks")
	_check(not _free(-148.0, -1.4), "the container on its pad blocks")
	_check(not _free(-147.0, -14.1), "the rail along the apron's north edge blocks")
	_check(not _free(-146.8, -19.2), "the tree bed between the apron and the tank blocks")
	print("ext_docks_test: ", "PASS" if fails == 0 else "FAIL (%d)" % fails)
	quit(1 if fails > 0 else 0)
