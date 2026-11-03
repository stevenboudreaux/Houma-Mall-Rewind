## Workstream M (design/godot-menu.md): headless checks of the contracts and the remap layer.
##   godot --headless --path . --script res://tools/qa/menu_unit_test.gd
## Prints MENU UNIT OK (n checks) or the failures.
extends SceneTree

const Inventory = preload("res://scripts/inventory.gd")
const Controls = preload("res://scripts/menu/controls.gd")
var oks := 0
var errors := []

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _initialize() -> void:
	# ---- mall.player_name, player_name_changed, held_id()
	var store := {}
	var m = Inventory.new()
	m.backend = store
	var got := []
	m.player_name_changed.connect(func(n: String): got.append(n))
	_check(m.player_name == "", "player_name starts empty")
	m.player_name = "  Ana\u0007 Lee  "
	_check(m.player_name == "Ana Lee", "player_name is cleaned (control chars, trimmed)")
	_check(got == ["Ana Lee"], "player_name_changed emitted once with the name")
	_check(store.get(Inventory.NAME_KEY, "") == "Ana Lee", "saved under %s" % Inventory.NAME_KEY)
	m.player_name = "Ana Lee"
	_check(got.size() == 1, "the same name again: no signal")
	m.player_name = "x".repeat(40)
	_check(m.player_name.length() == Inventory.NAME_MAX, "at most %d characters" % Inventory.NAME_MAX)
	var m2 = Inventory.new()
	m2.backend = store
	m2.year = 2026
	m2.load_saved()
	_check(m2.player_name == "x".repeat(Inventory.NAME_MAX), "the name loads in the other year too")
	_check(m.held_id() == "", "held_id() is \"\" with nothing held")
	m.take("dice", true)
	_check(m.held_id() == "dice", "held_id() is the held item")
	m.put_away()
	_check(m.held_id() == "" and m.has("dice"), "put away: \"\" and still carried")
	# ---- controls
	var cs := {}
	var c = Controls.new()
	c.backend = cs
	c.setup()
	_check(c.list.size() >= 15 and c.by_id.has("interact") and c.by_id.has("menu"), "actions.json read (%d actions)" % c.list.size())
	_check(InputMap.has_action("mall_interact") and InputMap.has_action("mall_forward"), "InputMap actions made")
	_check(c.keys("interact") == [KEY_E] and c.pads("interact") == [JOY_BUTTON_X], "Action defaults E / X")
	_check(c.keys("run") == [KEY_X, KEY_SHIFT], "Run defaults X, Shift")
	_check(c._route(KEY_E, "key") == -2, "defaults: E passes untouched")
	_check(c.rebind("interact", "key", KEY_V) != "", "V is First / third person: refused")
	_check(c.rebind("interact", "key", KEY_ESCAPE) != "", "Esc is reserved: refused")
	_check(c.rebind("look", "key", KEY_K) != "", "Look around isn't remappable")
	_check(c.rebind("forward", "pad", JOY_BUTTON_A) != "", "walking's gamepad (the stick) isn't remappable")
	_check(c.rebind("tab_next", "key", KEY_F) == "", "a menu key may share with the game (tab_next F)")
	_check(c.rebind("interact", "key", KEY_F) == "", "Action to F")
	_check(c._route(KEY_F, "key") == KEY_E, "F is re-sent as E")
	_check(c._route(KEY_E, "key") == -1, "E (moved off) is swallowed")
	_check(c._route(KEY_T, "key") == -2, "an unbound key passes")
	_check(c.rebind("forward", "key", KEY_T) == "", "Walk forward to T")
	_check(c._route(KEY_T, "key") == -2, "a walking key isn't translated (read from the InputMap)")
	_check(c._route(KEY_W, "key") == -2, "W (no longer walking) passes as itself")
	_check(c.rebind("jump", "pad", JOY_BUTTON_LEFT_SHOULDER) == "", "Jump to on LB (game context)")
	_check(c._route(JOY_BUTTON_LEFT_SHOULDER, "pad") == JOY_BUTTON_Y, "LB is re-sent as Y")
	_check(c._route(JOY_BUTTON_Y, "pad") == -1, "Y (moved off) is swallowed")
	var c2 = Controls.new()
	c2.backend = cs
	c2.setup()
	_check(c2.keys("interact") == [KEY_F] and c2.keys("forward") == [KEY_T], "saved and loaded again")
	_check(c2.key_text("interact") == "F", "the table reads the InputMap (F)")
	c2.rebind("interact", "key", KEY_E)
	_check(not c2.saved.has("interact"), "back to the default is no change")
	c2.reset()
	_check(c2.is_default() and c2.keys("forward") == [KEY_W] and cs[Controls.STORE_KEY] == "{}", "Reset to defaults")
	var bad := {Controls.STORE_KEY: "{\"look\": {\"keys\": [75]}, \"forward\": {\"pad\": [0]}, \"zzz\": 1}"}
	var c3 = Controls.new()
	c3.backend = bad
	c3.setup()
	_check(c3.is_default(), "a tampered save can't bind fixed rows or the stick")
	# ---- MENU2: no year on the player's controls; the directory trip's maths
	_check(not c.by_id.has("year"), "no year action in CONTROLS")
	for e in c.list:
		_check(not (KEY_Y in c.keys(str(e.id))), "Y is not a default key of %s" % e.id)
	var c4 = Controls.new()
	c4.backend = {Controls.STORE_KEY: "{\"year\": {\"keys\": [89]}}"}
	c4.setup()
	_check(c4.is_default(), "an old saved remap of the year action is dropped")
	var Trip = load("res://scripts/timetravel_trip.gd")
	var tw: Dictionary = Trip.twin(1995, -142.0, 71.5)
	_check(tw.found and tw.known and int(tw.wing) == 2 and is_equal_approx(tw.x, -142.0), "the JCPenney court kiosk's twin in 2026, wing 2")
	tw = Trip.twin(2026, -3.0, -82.5)
	_check(tw.found and tw.known and int(tw.wing) == 1, "the H2 kiosk's twin in 1995, wing 1")
	tw = Trip.twin(1995, 26.5, 3.2)
	_check(tw.found and not tw.known, "the main entrance kiosk (1995 only) has no twin: the same spot, a guess")
	var ld: Dictionary = Trip.landing(Trip.twin(1995, -142.0, 71.5), -142.0, 71.5, -141.7, 73.1, 0.3)
	_check(is_equal_approx(ld.x, -141.7) and is_equal_approx(ld.z, 73.1) and is_equal_approx(ld.yaw, 0.3), "a twin facing the same way: the same spot and facing")
	var turned := {"known": true, "x": 10.0, "z": 0.0, "face": Vector2(1, 0), "here_face": Vector2(0, 1)}
	var l2: Dictionary = Trip.landing(turned, 0.0, 0.0, 0.0, 2.0, 0.0)   # 2 m out from a south-facing kiosk, looking at it
	_check(Vector2(l2.x, l2.z).distance_to(Vector2(12.0, 0.0)) < 0.001, "a twin turned 90°: 2 m out from its face (%.2f, %.2f)" % [l2.x, l2.z])
	var fwd := Vector2(-sin(l2.yaw), -cos(l2.yaw))
	_check(fwd.distance_to(Vector2(-1, 0)) < 0.001, "and looking at it")
	var TT = load("res://scripts/timetravel.gd")
	var e0: Dictionary = TT.env(3.0, -1.0, false)
	var e1: Dictionary = TT.env(3.0 + 1.0 / 60.0, -1.0, false)
	_check(e0.vort > 0.8 and e0.amt > 0.99 and e0.dark == 0.0, "the loop: the vortex up, never black")
	_check(absf(e1.ph - e0.ph) < 0.02 and absf(e1.flash - e0.flash) < 0.1, "the loop is smooth frame to frame")
	var eo: Dictionary = TT.env(30.0, 1.2, false)
	_check(eo.vort < 0.001 and eo.amt < 0.001 and eo.flash < 0.01, "the outro ends clear")
	if errors.is_empty():
		print("MENU UNIT OK (%d checks)" % oks)
	else:
		print("MENU UNIT FAILED: ", errors)
	quit(0 if errors.is_empty() else 1)
