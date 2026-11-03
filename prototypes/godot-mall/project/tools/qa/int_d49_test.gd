## Headless integration checks for Demo 49 (the INT session, Nov 2 2026): the merged systems working
## together in the real wing scenes.
##   godot --headless --path . --script res://tools/qa/int_d49_test.gd
## 1. wing 2 (1995) at Pocket Change: the attendant (PLACEHOLDER) opens the redemption screen
##    (workstream R through Q's attendant hook); the screen closes.
## 2. wing 1 (1995) at the Sound Shop: the PLACEHOLDER attendant starts a conversation (Q).
## 3. the menu (M): opens on INVENTORY, a tab change to CONTROLS (the tilt row is listed), YEAR, close.
## 4. wing 2 (2026): Games, Inc. loads; Story makes no attendant there (GI's "spots" place no NPC).
## Prints one line per check, then "INT D49 TEST OK" or "INT D49 TEST FAILED".
extends SceneTree

var steps: Array = []
var si := -1
var t := 0
var fails := 0

func _initialize() -> void:
	Engine.set_meta("mall_flags", "")
	steps = [
		["load", "res://wing2.tscn", -104.0, 68.9, 90.0],
		["redemption"],
		["load", "res://wing1.tscn", -12.9, -60.35, 180.0],
		["talk"],
		["menu"],
		["load", "res://wing2_2026.tscn", -111.0, 62.0, 180.0],
		["gi"],
	]
	_next()

func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func _pl():
	return current_scene.get_node_or_null("Player") if current_scene else null

func _next() -> void:
	si += 1
	t = 0
	if si >= steps.size():
		print("INT D49 TEST OK" if fails == 0 else "INT D49 TEST FAILED (%d)" % fails)
		quit(0 if fails == 0 else 1)
		return
	var s: Array = steps[si]
	if s[0] == "load":
		Engine.set_meta("mall_xfer", {"x": s[2], "z": s[3], "yaw": deg_to_rad(s[4]), "pitch": 0.0})
		change_scene_to_file(s[1])

func _attendant(id: String):
	var st = _pl().get_node_or_null("Story")
	if st == null:
		return null
	for a in st.attendants:
		if is_instance_valid(a) and str(a.entry.get("id", "")) == id:
			return a
	return null

func _process(_dt: float) -> bool:
	t += 1
	if si >= steps.size():
		return false
	var s: Array = steps[si]
	var p = _pl()
	match s[0]:
		"load":
			if t > 30 and p:
				_check(true, "loaded " + str(s[1]).get_file())
				_next()
		"redemption":
			var a = _attendant("pocket_change")
			if t == 5:
				_check(a != null and str(a.entry.get("name", "")).begins_with("PLACEHOLDER"), "Pocket Change attendant is there, a PLACEHOLDER")
				if a:
					a.interact(p)
			elif t == 15:
				var r = p.mall.redemption
				_check(r != null and r.is_open, "the attendant opens the redemption screen")
				if r:
					r.close()
			elif t == 25:
				_check(not p.mall.redemption.is_open, "the redemption screen closes")
				_next()
		"talk":
			var a = _attendant("sound_shop")
			var st = p.get_node_or_null("Story")
			if t == 5:
				_check(a != null and str(a.dialogue).contains("PLACEHOLDER"), "Sound Shop attendant with a PLACEHOLDER dialogue")
				if a:
					a.interact(p)
			elif t == 20:
				_check(st and st.ui and st.ui.active, "talking: the conversation screen is up")
				if st and st.ui and st.ui.has_method("_end"):
					st.ui._end()
			elif t == 30:
				_next()
		"menu":
			var m = p.get("menu")
			if t == 90:
				_check(not p.frozen, "after the talk: walking again")
				m.open_tab("inventory")
			elif t == 96:
				_check(m.is_open and m.tab == "inventory" and p.frozen, "the menu opens on INVENTORY")
				m.open_tab("controls")
			elif t == 102:
				_check(m.is_open and m.tab == "controls", "tab change to CONTROLS")
				_check(m.controls != null and m.controls.by_id.has("tilt"), "CONTROLS lists the tilt row")
				m.open_tab("year")
			elif t == 108:
				_check(m.tab == "year", "tab change to YEAR")
				m.close()
			elif t == 114:
				_check(not m.is_open and not p.frozen, "the menu closes, walking again")
				_next()
		"gi":
			if t == 10:
				var st = p.get_node_or_null("Story")
				_check(int(p.year) == 2026 and int(p.wing) == 2, "wing 2, 2026")
				_check(st != null and st.attendants.is_empty(), "no attendant made in wing 2 2026 (%d)" % (st.attendants.size() if st else -1))
				var near := 0
				for n in current_scene.find_children("*", "Node3D", true, false):
					if n.get_script() and str(n.get_script().resource_path).contains("attendant") and n.global_position.distance_to(Vector3(-111.1, 0, 66.3)) < 3.0:
						near += 1
				_check(near == 0, "nothing standing at the games_inc_counter spot")
				_check(current_scene.find_children("gi*_mach*", "", true, false).size() > 0 or current_scene.find_children("*gi*", "", true, false).size() > 0, "the Games, Inc. machines are in the scene")
				_next()
	return false
