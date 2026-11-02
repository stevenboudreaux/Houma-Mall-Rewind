## Headless check of the room wings' thresholds and the cinema gate (workstream S, Nov 2 2026;
## design/godot-wings.md "Wings 4-6"). Runs a fixed script of steps, scene changes included, and
## prints one line per check, then "WSS TEST OK" or "WSS TEST FAILED".
##   godot --headless --path . --script res://tools/qa/wsS_thresholds_test.gd [-- 2026]
## Steps (both years unless noted):
##   1. wing 1 at the Sears opening: the prompt names Sears (Lynn's); E -> wing 4, same x, 1.3 m in,
##      same facing; E -> back in wing 1, 1.3 m out
##   2. wing 2 at the Dillard's opening: -> wing 5 and back, the same way
##   3. wing 1 at the cinema doors, empty-handed: E shows the PLACEHOLDER message, stays in wing 1,
##      the flag stays unset, the roll gate stays down
##   4. the same holding folse_stick (1995; in 2026 the flag is set directly, the stick is a 1995
##      item): E sets cinema_unlocked and rolls the gate up; E again -> wing 6; E there -> wing 1
##   5. a reload of wing 1 (a new scene, the flag from the store): the gate starts rolled up
##   6. the directory's jump into wing 4 and 5 (player.jump_to, as directory_ui.gd calls it)
extends SceneTree

var year := 1995
var steps: Array = []
var si := -1
var t := 0
var fails := 0
var pending := {}

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a == "2026":
			year = 2026
	Engine.set_meta("mall_flags", "")       # a fresh flag store (Q's format, scripts/cinema_gate.gd)
	var y := "_2026" if year == 2026 else ""
	steps = [
		["load", "res://wing1%s.tscn" % y, -4.0, -94.6, 0.0],
		["prompt", "Enter " + ("Lynn's" if year == 2026 else "Sears")],
		["cross", 4, -4.0, -97.3],
		["cross", 1, -4.0, -94.7],
		["load", "res://wing2%s.tscn" % y, -4.0, 78.6, 180.0],
		["prompt", "Enter Dillard's"],
		["cross", 5, -4.0, 81.3],
		["cross", 2, -4.0, 78.7],
		["load", "res://wing1%s.tscn" % y, -56.0, -87.0, 180.0],
		["prompt", "Enter Southland Cinema"],
		["locked"],
		["hold"],
		["unlock"],
		["cross", 6, -56.0, -84.7],
		["cross", 1, -56.0, -87.3],
		["load", "res://wing1%s.tscn" % y, -56.0, -87.0, 180.0],
		["gate_open"],
		["jump", 4, -4.0, -98.2, 0.0],
		["load", "res://wing1%s.tscn" % y, -4.0, -90.0, 180.0],
		["jump", 5, -4.0, 82.2, 180.0],
	]

func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if not ok:
		fails += 1

func _pl():
	return current_scene.get_node_or_null("Player") if current_scene else null

func _gate():
	var p = _pl()
	if p == null:
		return null
	for g in get_nodes_in_group("gate"):
		if g.get("to_wing") == 6:
			return g
	return null

func _gm():
	var g = current_scene.get_node_or_null("Dynamic/dyn_cin_gate")
	return g if g else current_scene.get_node_or_null("Static/cin_gate")

func _next() -> void:
	si += 1
	t = 0
	pending = {}

func _process(_dt: float) -> bool:
	t += 1
	if si == -1:
		_next()
	if si >= steps.size():
		print("WSS TEST OK" if fails == 0 else "WSS TEST FAILED (%d)" % fails)
		quit(0 if fails == 0 else 1)
		return true
	var s: Array = steps[si]
	var p = _pl()
	match s[0]:
		"load":
			if t == 1:
				Engine.set_meta("mall_xfer", {"x": s[2], "z": s[3], "yaw": deg_to_rad(s[4]), "pitch": 0.0})
				change_scene_to_file(s[1])
			elif t > 8 and p:
				print("     in ", current_scene.scene_file_path, " at ", Vector2(p.position.x, p.position.z))
				_next()
		"prompt":
			if t > 3:
				_check(p.prompt != null and p.prompt.visible and p.prompt_text.text == s[1], "prompt '%s' (shows '%s')" % [s[1], p.prompt_text.text if p.prompt else "-"])
				_next()
		"cross":
			if t == 1:
				pending = {"yaw": p.yaw, "scene": current_scene.scene_file_path}
				p._cross()
			elif t > 40 and p and current_scene.scene_file_path != pending.scene:
				var w: int = int(p.wing)
				_check(w == int(s[1]) and absf(p.position.x - s[2]) < 0.05 and absf(p.position.z - s[3]) < 0.05 and absf(p.yaw - pending.yaw) < 0.01,
					"cross to wing %d at (%.1f, %.1f): wing %d at (%.2f, %.2f), facing kept %s" % [s[1], s[2], s[3], w, p.position.x, p.position.z, absf(p.yaw - pending.yaw) < 0.01])
				for _k in 3:
					p._update_prompt()
				_next()
			elif t > 200:
				_check(false, "cross to wing %d: no scene change (still %s)" % [s[1], current_scene.scene_file_path])
				_next()
		"locked":
			if t == 1:
				pending = {"scene": current_scene.scene_file_path}
				p.mall.hand = ""
				p._cross()
			elif t == 30:
				var g = _gate()
				var said := false
				var gn = _gate()
				if gn and gn._note and gn._note.modulate.a > 0.5 and str(gn._note.text).begins_with("PLACEHOLDER locked message (Southland Cinema"):
					said = true
				_check(g != null and g.locked() and current_scene.scene_file_path == pending.scene and said,
					"locked without the stick: message shown %s, still in %s, gate locked %s" % [said, current_scene.scene_file_path.get_file(), g.locked() if g else "no gate"])
				var gm = _gm()
				_check(gm != null and gm.visible and gm.transform == Transform3D.IDENTITY, "roll gate down (dyn_cin_gate)")
				_next()
		"hold":
			if year == 1995:
				p.mall.hand = "folse_stick"
				_check(_gate()._held() == "folse_stick", "holding folse_stick")
			else:
				# the stick is a 1995 item (data/items/stockrooms.json): in 2026 the flag store is shared
				_gate()._flag_set("cinema_unlocked", true)
				_gate()._sync(true)
				print("     2026: flag set directly (the stick is a 1995 item; the flags are one store for both years)")
			_next()
		"unlock":
			if t == 1 and year == 1995:
				p._cross()
			elif t == 10:
				var g = _gate()
				_check(not g.locked() and str(Engine.get_meta("mall_flags", "")).contains("cinema_unlocked"), "flag cinema_unlocked set and saved (%s)" % Engine.get_meta("mall_flags", ""))
				pending = {"t0": Time.get_ticks_msec()}
			elif t > 10:
				# the roll-up takes 1.1 s of real time
				var gm = _gm()
				if (gm != null and not gm.visible) or Time.get_ticks_msec() - pending.t0 > 4000:
					_check(gm != null and not gm.visible, "roll gate rolled up (%d ms)" % (Time.get_ticks_msec() - pending.t0))
					_next()
		"gate_open":
			if t > 3:
				var g = _gate()
				var gm = _gm()
				_check(g != null and not g.locked() and gm != null and not gm.visible, "after a reload: still unlocked, gate up")
				_next()
		"jump":
			if t == 1:
				pending = {"scene": current_scene.scene_file_path}
				p.jump_to(int(s[1]), year, s[2], s[3], s[4])
			elif t > 40 and p and current_scene.scene_file_path != pending.scene:
				_check(int(p.wing) == int(s[1]) and absf(p.position.z - s[3]) < 0.05 and absf(rad_to_deg(p.yaw) - s[4]) < 0.5,
					"directory jump into wing %d: wing %d at (%.2f, %.2f) yaw %.0f" % [s[1], p.wing, p.position.x, p.position.z, rad_to_deg(p.yaw)])
				_next()
			elif t > 200:
				_check(false, "jump to wing %d: no scene change" % s[1])
				_next()
	return false
