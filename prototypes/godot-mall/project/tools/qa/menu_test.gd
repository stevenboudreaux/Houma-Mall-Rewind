## Workstream M (design/godot-menu.md): the menu, a first start straight into the mall (ws/items, Nov 4: no
## opening), the remap layer, HELD / PUT AWAY, the
## time-travel transition and 2026's shoppers, natively and unbaked (no lightmap).
## MENU2 (Nov 3): tabs MAIN / INVENTORY / CONTROLS, Edit inside MAIN, no Y / YEAR, and the trip from
## a mall directory's year toggle (scripts/timetravel_trip.gd) to its twin in 2026 (wing 2's kiosk
## at the JCPenney court, or wing 1's on H2).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/menu_test.gd -- --wing=2 --out=/tmp/m/w2
## Prints MENU TEST OK (n checks) or the failures; writes <out>-<name>.png.
extends SceneTree

const Look = preload("res://scripts/avatar_look.gd")
var out := "/tmp/m"
var wing := 2
var scn: Node
var player: Node3D
var menu: Node
var errors := []
var oks := 0
var q := []
var qi := 0
var wait := 0.0
var sizes := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]
var only := ""      # --only=2026: just 2026's shoppers (loads wing<n>_2026 directly)
var kiosk: Node3D = null
var kiosk_pos := Vector3.ZERO
var start_pos := Vector3.ZERO
var start_yaw := 0.0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--wing="): wing = int(a.substr(7))
		elif a.begins_with("--only="): only = a.substr(7)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_state_2026", "")
	Engine.set_meta("mall_player_name", "")
	Engine.set_meta("mall_controls", "")
	Engine.set_meta("menu_opening", true)       # a first start (ws/items: ignored now; no opening)
	var L := Look.default_look()
	L.done = true; L.body = "Ch21"; L.view = "first"
	Engine.set_meta("mall_avatar", JSON.stringify(L))
	if only == "2026":
		Engine.set_meta("menu_opening", false)
		Engine.set_meta("mall_player_name", "TESTER")
		_load("res://wing%d_2026.tscn" % wing)
		menu = player.get_node("Menu")
		_do(func(): pass, 25.0)
		_plan_2026()
		return
	_load("res://wing%d.tscn" % wing)
	_plan()

func _load(path: String) -> void:
	scn = load(path).instantiate()
	root.add_child(scn)
	current_scene = scn
	_unbake(scn)
	player = scn.get_node("Player")

func _unbake(s: Node) -> void:
	var lm = s.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(s, "night")

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])

func _size(s: Vector2i) -> void:
	DisplayServer.window_set_size(s)
	root.size = s

func _key(k: Key, down := true, uni := 0) -> void:
	var e := InputEventKey.new()
	e.keycode = k; e.physical_keycode = k; e.pressed = down; e.unicode = uni
	Input.parse_input_event(e)

func _tap(p: Vector2) -> void:
	for d in [true, false]:
		var t := InputEventScreenTouch.new()
		t.index = 0; t.position = p; t.pressed = d
		Input.parse_input_event(t)

func _pad(b: JoyButton) -> void:
	for d in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = b; e.pressed = d
		Input.parse_input_event(e)

func _trigger(a: JoyAxis) -> void:
	for v in [1.0, 0.0]:
		var e := InputEventJoypadMotion.new()
		e.axis = a; e.axis_value = v
		Input.parse_input_event(e)

func _find(n: Node, cls: String) -> Node:
	if n == null: return null
	for c in n.get_children():
		if c.is_class(cls): return c
		var f := _find(c, cls)
		if f: return f
	return null

func _do(c: Callable, w := 0.0) -> void:
	q.append([c, w])

## every one of the menu's controls inside the window
func _on_screen(s: Vector2i) -> bool:
	for h in menu._hits:
		var c: Control = h[0]
		if not is_instance_valid(c) or not c.is_visible_in_tree():
			continue
		if menu._scroll and menu._scroll.is_ancestor_of(c):
			continue     # scrolls
		var r := c.get_global_rect()
		if r.end.x > s.x + 1 or r.end.y > s.y + 1 or r.position.x < -1 or r.position.y < -1:
			printerr("  off screen: ", c.get_class(), " ", (c as Button).text if c is Button else "", " ", r)
			return false
	return true

func _plan() -> void:
	_do(func(): pass, 2.0)
	# ---- a first start: straight into the mall (ws/items, Steven Nov 4: the opening is gone)
	_do(func():
		menu = player.get_node_or_null("Menu")
		_check(menu != null, "player has its Menu node")
		_check(not ("opening" in menu) and not menu.is_open and not player.frozen, "a first start is in the mall: no opening, no menu, the player free")
		_shot("first-start-1280x720"), 0.3)
	_do(func(): menu.open_tab("avatar"); menu._sel = Vector2i.ZERO; menu._paint_sel(); menu.start_typing(), 0.6)   # what START did
	_do(func():
		_check(menu.is_open and menu.tab == "main" and menu.editing, "MAIN's Edit opens the avatar editing")
		_check(menu._typing, "the NAME field is focused")
		_check(menu._creator != null and menu._creator.visible, "the creator is inside the tab"), 0.1)
	_do(func():
		for ch in "TESTER":
			_key(OS.find_keycode_from_string(ch), true, ch.unicode_at(0)); _key(OS.find_keycode_from_string(ch), false)
		, 0.3)
	_do(func(): _shot("main-edit-typing-1280x720"); _key(KEY_ENTER); _key(KEY_ENTER, false), 0.3)
	_do(func():
		_check(player.mall.player_name == "TESTER", "the name is mall.player_name (%s)" % player.mall.player_name)
		_check(str(Engine.get_meta("mall_player_name", "")) == "TESTER", "the name is saved"), 0.1)
	# ---- MAIN: the character, money, tickets, Edit inside MAIN
	_do(func():
		menu.close()
		player.mall.tickets = 140; player.mall.save()
		menu.open_tab("main"), 0.6)
	_do(func():
		_check(menu.TABS == ["main", "inventory", "controls"], "tabs: MAIN, INVENTORY, CONTROLS (%s)" % [menu.TABS])
		_check(menu.is_open and menu.tab == "main" and not menu.editing, "MAIN shows the character (not editing)")
		var por := _find(menu._root, "SubViewportContainer")
		_check(por != null, "MAIN has the character's portrait")
		var mn: Label = menu._root.find_child("MainName", true, false)
		var mm: Label = menu._root.find_child("MainMoney", true, false)
		var mt: Label = menu._root.find_child("MainTickets", true, false)
		_check(mn != null and mn.text == "TESTER", "MAIN: the name (%s)" % (mn.text if mn else "-"))
		var mo: Dictionary = menu.money()
		_check(mm != null and mm.text == "$%.2f" % float(mo.value), "MAIN: the money, mall.money%s (%s)" % [" (stub: ECON not merged)" if mo.stub else "", mm.text if mm else "-"])
		_check(mt != null and mt.text == "140", "MAIN: the tickets, mall.tickets (%s)" % (mt.text if mt else "-"))
		_shot("main-1280x720")
		menu._nav[0][0][1].call(), 0.6)      # Edit
	_do(func():
		_check(menu.tab == "main" and menu.editing and menu._creator != null and menu._creator.visible, "Edit opens the avatar editing inside MAIN")
		_check(menu._name_box != null, "the NAME field is in MAIN's editing")
		_shot("main-edit-1280x720")
		menu._creator._done(), 0.6)
	_do(func():
		_check(menu.is_open and menu.tab == "main" and not menu.editing, "Done goes back to MAIN, the menu still open"); menu.close(), 0.2)
	# ---- every tab at three sizes
	for s in sizes:
		var sz: Vector2i = s
		for t in ["main", "edit", "inventory", "controls"]:
			var tt: String = t
			var want := "main" if tt == "edit" else tt
			_do(func(): _size(sz); menu.close(); menu.open_tab("avatar" if tt == "edit" else tt), 0.7)
			_do(func():
				_check(menu.is_open and menu.tab == want and menu.editing == (tt == "edit"), "tab %s open at %dx%d" % [tt, sz.x, sz.y])
				_check(_on_screen(sz), "every %s control on screen at %dx%d" % [tt, sz.x, sz.y])
				if tt == "edit" and menu._creator:
					var over := false
					for h in menu._creator.hits:
						var r: Rect2 = (h[0] as Control).get_global_rect()
						if r.end.x > sz.x + 1 or r.end.y > sz.y + 1: over = true
					_check(not over, "the creator fits the tab at %dx%d" % [sz.x, sz.y])
				_shot("%s-%dx%d" % [tt, sz.x, sz.y]), 0.1)
	_do(func(): _size(Vector2i(1280, 720)); menu.close(); menu.open_tab("main"), 0.5)
	# ---- tab switching keys, buttons and triggers
	_do(func(): _key(KEY_E); _key(KEY_E, false), 0.3)
	_do(func(): _check(menu.tab == "inventory", "E: next tab (MAIN -> INVENTORY)"); _key(KEY_Q); _key(KEY_Q, false), 0.3)
	_do(func(): _check(menu.tab == "main", "Q: previous tab"); _pad(JOY_BUTTON_RIGHT_SHOULDER), 0.3)
	_do(func(): _check(menu.tab == "inventory", "RB: next tab"); _pad(JOY_BUTTON_LEFT_SHOULDER), 0.3)
	_do(func(): _check(menu.tab == "main", "LB: previous tab"); _trigger(JOY_AXIS_TRIGGER_RIGHT), 0.3)
	_do(func(): _check(menu.tab == "inventory", "RT: next tab"); _trigger(JOY_AXIS_TRIGGER_LEFT), 0.3)
	_do(func(): _check(menu.tab == "main", "LT: previous tab"); _key(KEY_TAB); _key(KEY_TAB, false), 0.4)
	_do(func(): _check(not menu.is_open and not player.frozen, "Tab closes the menu, the player free"); _key(KEY_TAB); _key(KEY_TAB, false), 0.4)
	_do(func(): _check(menu.is_open and menu.tab == "main" and menu.TABS[0] == "main", "Tab opens on MAIN, the far-left tab"); _key(KEY_ESCAPE); _key(KEY_ESCAPE, false), 0.4)
	_do(func(): _check(not menu.is_open, "Esc closes the menu"); menu.open_tab("controls"), 0.4)
	_do(func(): _pad(JOY_BUTTON_B), 0.4)
	_do(func(): _check(not menu.is_open, "B closes the menu"); _key(KEY_I); _key(KEY_I, false), 0.4)
	_do(func(): _check(menu.is_open and menu.tab == "inventory", "I opens the INVENTORY tab"); menu.close(), 0.2)
	_do(func(): _key(KEY_C); _key(KEY_C, false), 0.4)
	_do(func(): _check(menu.is_open and menu.tab == "main" and menu.editing, "C opens MAIN's avatar editing"); menu.close(), 0.2)
	_do(func(): _key(KEY_Y); _key(KEY_Y, false), 0.4)
	_do(func():
		_check(not menu.is_open and player.year == 1995 and root.get_node_or_null("TimeTravelTrip") == null, "Y does nothing (no year switch on the player's keys)")
		var has_year := false
		for e in menu.controls.list:
			if str(e.id) == "year": has_year = true
		_check(not has_year, "CONTROLS lists no year action")
		_check(not player.year_btn.visible, "no year button on the HUD"), 0.2)
	# ---- remap: Action (E) to F, then F works as E and E does nothing
	_do(func():
		# away from the Dillard's court directory and the seam, so E (and F as E) reaches nothing
		player.position = Vector3(-20, 0, 54); player.yaw = deg_to_rad(90); player._apply_rot()
		menu.open_tab("controls")
		menu._start_capture("interact", "key"), 0.3)
	_do(func(): _shot("controls-capture-1280x720"); _key(KEY_F); _key(KEY_F, false), 0.3)
	_do(func():
		var evs := InputMap.action_get_events("mall_interact")
		var ks := []
		for ev in evs:
			if ev is InputEventKey: ks.append(ev.physical_keycode)
		_check(ks == [KEY_F], "the InputMap has Action on F")
		_check(menu.controls.key_text("interact") == "F", "the table reads F from the InputMap")
		_check(str(Engine.get_meta("mall_controls", "")).find("interact") >= 0, "the remap is saved")
		_shot("controls-remapped-1280x720")
		menu.close(), 0.3)
	_do(func(): _key(KEY_F), 0.15)
	_do(func(): _check(Input.is_physical_key_pressed(KEY_E), "F is sent on as E (the code's key)"); _key(KEY_F, false), 0.15)
	_do(func(): _check(not Input.is_physical_key_pressed(KEY_E), "F released: E released"), 0.05)
	_do(func():
		var C = load("res://scripts/menu/controls.gd").new()
		C.setup()
		_check(C.keys("interact") == [KEY_F], "a fresh load (a reload) keeps F")
		_check(C.rebind("view", "key", KEY_F) != "", "F can't also be First / third person")
		menu.controls.reset()
		_check(menu.controls.keys("interact") == [KEY_E] and menu.controls.is_default(), "Reset to defaults"), 0.1)
	# ---- inventory: HELD / PUT AWAY
	_do(func():
		var m = player.mall
		m.take("dice", true); m.add("pogs"); m.tickets = 140; m.save(), 0.8)
	# workstream R's "You received" cards (one per item) hold the player: dismiss them first
	for i in 2:
		_do(func(): _key(KEY_ENTER); _key(KEY_ENTER, false), 0.8)
	_do(func(): menu.open_tab("inventory"), 0.6)
	_do(func():
		_check(player.mall.held_id() == "dice", "held_id() is the dice")
		_shot("inventory-held-1280x720")
		menu._nav[0][1][1].call(), 0.4)   # row 0: dice; [HELD, PUT AWAY, Drop]
	_do(func():
		_check(player.mall.held_id() == "", "PUT AWAY: nothing held (held_id \"\")")
		_shot("inventory-putaway-1280x720")
		for r in menu._nav:
			pass, 0.1)
	_do(func():
		# HELD again: find the dice row
		var it = player.interact
		for r in menu._nav:
			for p in r:
				if p[0] is Button and p[0].text == "HELD" and not p[0].disabled:
					p[1].call()
					break
		, 0.5)
	_do(func():
		_check(player.mall.held_id() == "dice" and player.interact.hand_item != null, "HELD: the dice in the hand")
		menu.close()
		player.position = Vector3(-20, 0, 54); player.yaw = deg_to_rad(90); player.pitch = deg_to_rad(-8); player._apply_rot()
		player.avatar.third = false, 0.8)
	_do(func():
		var hi: Node3D = player.interact.hand_item
		_check(hi.is_visible_in_tree() and hi.get_parent() == player.interact.hand_root, "first person: the dice in the hand")
		_shot("hand-first-person"); player.avatar.third = true, 1.5)
	_do(func():
		var hi: Node3D = player.interact.hand_item
		_check(hi.is_visible_in_tree() and hi.get_parent() != player.interact.hand_root, "third person: the dice in the avatar's hand")
		_shot("hand-third-person"); player.avatar.third = false, 0.5)
	# ---- the owner's CONTROLS: no "Show the opening again" any more (ws/items)
	_do(func():
		Engine.set_meta("mall_owner", true)
		menu.open_tab("controls"), 0.4)
	_do(func():
		var found := false
		for h in menu._hits:
			if h[0] is Button and h[0].text == "Show the opening again": found = true
		_check(not found, "no Show the opening again")
		menu.close(); Engine.set_meta("mall_owner", false), 0.4)
	# ---- MENU2: the year toggle on a mall directory: the trip to its twin in 2026
	_do(func():
		# a kiosk with a twin in 2026 (wing 1: H2 north; wing 2: the JCPenney court)
		kiosk = null
		var Trip = load("res://scripts/timetravel_trip.gd")
		for k in get_nodes_in_group("directory_kiosk"):
			if Trip.twin(1995, k.position.x, k.position.z).known:
				kiosk = k
		_check(kiosk != null, "a directory kiosk in wing %d" % wing)
		var f: Vector2 = kiosk.get_meta("face", Vector2(0, 1))
		# stand 1.6 m out from its lit face, a little to one side, looking at it
		var at := Vector2(kiosk.position.x, kiosk.position.z) + f * 1.6 + Vector2(-f.y, f.x) * 0.3
		player.position = Vector3(at.x, 0, at.y)
		player.yaw = atan2(f.x, f.y); player.pitch = deg_to_rad(-4); player._apply_rot()
		start_pos = player.position; start_yaw = player.yaw
		kiosk_pos = kiosk.position
		kiosk.interact(player), 1.0)
	_do(func():
		var ui = kiosk._ui()
		_check(ui.is_open, "the directory is open")
		# ws/directory (Nov 4 2026): the year switch is on the kiosk itself (1990s / 2026 keys)
		var has_toggle: bool = kiosk.get("switch_node") != null and kiosk.switch_node.get_node_or_null("Key1990s") != null
		_check(has_toggle and ui.year == "1995", "the directory shows 1995 with the year switch on the kiosk")
		_shot("directory-1995-toggle")
		_key(KEY_Y); _key(KEY_Y, false), 0.05)
	_do(func():
		var ui = kiosk._ui()
		_check(not ui.is_open, "the toggle closes the directory")
		_check(root.get_node_or_null("TimeTravelTrip") != null, "the trip starts"), 0.0)
	# a frame sequence of the trip (native: the scene changes under the loop, no reload)
	for i in 14:
		var k: int = i
		_do(func(): _shot("trip-1995-2026-%02d" % k), 0.15)
	_do(func(): pass, 2.0)
	_do(func():
		scn = current_scene
		_check(scn != null and int(scn.get_meta("year", 0)) == 2026, "the trip lands in 2026 (%s)" % (scn.scene_file_path if scn else "-"))
		_unbake(scn)
		player = scn.get_node("Player")
		menu = player.get_node("Menu")
		var tw = load("res://scripts/timetravel_trip.gd").twin(1995, kiosk_pos.x, kiosk_pos.z)
		_check(tw.known, "the kiosk has a twin in 2026")
		var ld: Dictionary = load("res://scripts/timetravel_trip.gd").landing(tw, kiosk_pos.x, kiosk_pos.z, start_pos.x, start_pos.z, start_yaw)
		var d := Vector2(player.position.x - ld.x, player.position.z - ld.z).length()
		_check(d < 1.0, "landed within 1 m of the twin spot (%.2f m)" % d)
		_check(absf(angle_difference(player.yaw, ld.yaw)) < 0.02, "same facing"), 0.0)
	for i in 10:
		var k: int = i
		_do(func(): _shot("trip-1995-2026-%02d" % (14 + k)), 0.15)
	_do(func(): pass, 1.0)
	_do(func():
		_check(root.get_node_or_null("TimeTravelTrip") == null and not player.frozen, "the vortex unwinds, the player free in 2026")
		_shot("trip-1995-2026-arrived"), 25.0)
	_do(func():
		var sh = scn.get_node_or_null("Shoppers")
		var n := 0
		var ids := []
		if sh:
			for s in sh.shoppers:
				if s.role == "": n += 1; ids.append(s.body.id if s.body else "?")
		_check(sh != null and n == 3, "2026: 3 shoppers (%d: %s)" % [n, ids])
		_check(player.mall.player_name == "TESTER", "the name crosses into 2026")
		_check(not menu.is_open and not player.frozen, "2026 starts in the mall too")
		player.position = Vector3(-60, 0, 54); player.yaw = deg_to_rad(90); player.pitch = deg_to_rad(-6); player._apply_rot(), 1.0)
	_do(func(): _shot("2026-hall"), 0.1)
	_plan_2026()

## 2026: three shoppers; face the camera toward each in turn and shoot.
func _plan_2026() -> void:
	_do(func():
		var sh = scn.get_node_or_null("Shoppers")
		var n := 0
		if sh:
			for s in sh.shoppers:
				if s.role == "": n += 1
		_check(sh != null and n == 3, "2026: 3 shoppers (%d)" % n), 0.1)
	for i in 3:
		var k: int = i
		_do(func():
			var sh = scn.get_node_or_null("Shoppers")
			var list := []
			if sh:
				for s in sh.shoppers:
					if s.role == "" and s.body: list.append(s)
			if k >= list.size(): return
			var t: Vector3 = list[k].body.global_position
			for d in [Vector2(4, 0), Vector2(-4, 0), Vector2(0, 4), Vector2(0, -4), Vector2(3, 3), Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3)]:
				var p := Vector3(t.x + d.x, 0, t.z + d.y)
				if player._free(p.x, p.z):
					player.position = p
					var dir := t - p
					player.yaw = atan2(-dir.x, -dir.z); player.pitch = deg_to_rad(-6); player._apply_rot()
					break
			, 0.6)
		_do(func(): _shot("2026-shopper-%d" % (k + 1)), 0.1)
	_do(func():
		if errors.is_empty():
			print("MENU TEST OK (%d checks)" % oks)
		else:
			print("MENU TEST FAILED: ", errors)
		quit(0 if errors.is_empty() else 1), 0.0)

func _process(dt: float) -> bool:
	wait -= dt
	while wait <= 0.0 and qi < q.size():
		var s: Array = q[qi]
		qi += 1
		s[0].call()
		wait = s[1]
	return false
