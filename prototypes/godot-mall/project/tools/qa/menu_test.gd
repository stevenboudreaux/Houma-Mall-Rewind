## Workstream M (design/godot-menu.md): the menu, the opening, the remap layer, HELD / PUT AWAY, the
## time-travel transition and 2026's shoppers, natively and unbaked (no lightmap).
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
	Engine.set_meta("menu_opening", true)       # a first start
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
	# ---- the opening
	_do(func():
		menu = player.get_node_or_null("Menu")
		_check(menu != null, "player has its Menu node")
		_check(menu.opening != null and player.frozen, "a first start shows the opening, the player frozen")
		var t: String = menu.opening.words.text
		_check(t.begins_with("PLACEHOLDER"), "the opening's words come from data/story/opening.json (%s)" % t.left(30))
		_shot("opening-1280x720"), 0.3)
	_do(func(): _size(Vector2i(390, 844)), 0.6)
	_do(func(): _shot("opening-390x844"), 0.1)
	_do(func(): _size(Vector2i(1280, 720)), 0.6)
	_do(func(): _key(KEY_ENTER); _key(KEY_ENTER, false), 0.6)
	_do(func():
		_check(menu.opening == null and menu.is_open and menu.tab == "avatar", "START opens the menu on AVATAR")
		_check(menu._typing, "the NAME field is focused")
		_check(menu._creator != null and menu._creator.visible, "the creator is inside the tab"), 0.1)
	_do(func():
		for ch in "TESTER":
			_key(OS.find_keycode_from_string(ch), true, ch.unicode_at(0)); _key(OS.find_keycode_from_string(ch), false)
		, 0.3)
	_do(func(): _shot("avatar-typing-1280x720"); _key(KEY_ENTER); _key(KEY_ENTER, false), 0.3)
	_do(func():
		_check(player.mall.player_name == "TESTER", "the name is mall.player_name (%s)" % player.mall.player_name)
		_check(str(Engine.get_meta("mall_player_name", "")) == "TESTER", "the name is saved"), 0.1)
	# ---- every tab at three sizes
	for s in sizes:
		var sz: Vector2i = s
		for t in ["avatar", "controls", "inventory", "year"]:
			var tt: String = t
			_do(func(): _size(sz); menu.open_tab(tt), 0.7)
			_do(func():
				_check(menu.is_open and menu.tab == tt, "tab %s open at %dx%d" % [tt, sz.x, sz.y])
				_check(_on_screen(sz), "every %s control on screen at %dx%d" % [tt, sz.x, sz.y])
				if tt == "avatar" and menu._creator:
					var over := false
					for h in menu._creator.hits:
						var r: Rect2 = (h[0] as Control).get_global_rect()
						if r.end.x > sz.x + 1 or r.end.y > sz.y + 1: over = true
					_check(not over, "the creator fits the tab at %dx%d" % [sz.x, sz.y])
				_shot("%s-%dx%d" % [tt, sz.x, sz.y]), 0.1)
	_do(func(): _size(Vector2i(1280, 720)); menu.open_tab("avatar"), 0.5)
	# ---- tab switching keys
	_do(func(): _key(KEY_E); _key(KEY_E, false), 0.3)
	_do(func(): _check(menu.tab == "controls", "E: next tab"); _key(KEY_Q); _key(KEY_Q, false), 0.3)
	_do(func(): _check(menu.tab == "avatar", "Q: previous tab"); _key(KEY_TAB); _key(KEY_TAB, false), 0.4)
	_do(func(): _check(not menu.is_open and not player.frozen, "Tab closes the menu, the player free"), 0.2)
	_do(func(): _key(KEY_I); _key(KEY_I, false), 0.4)
	_do(func(): _check(menu.is_open and menu.tab == "inventory", "I opens the INVENTORY tab"); menu.close(), 0.2)
	_do(func(): _key(KEY_C); _key(KEY_C, false), 0.4)
	_do(func(): _check(menu.is_open and menu.tab == "avatar", "C opens the AVATAR tab"); menu.close(), 0.2)
	_do(func(): _key(KEY_Y); _key(KEY_Y, false), 0.4)
	_do(func(): _check(menu.is_open and menu.tab == "year", "Y opens the YEAR tab"); menu.close(), 0.2)
	# ---- remap: Action (E) to F, then F works as E and E does nothing
	_do(func():
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
		m.take("dice", true); m.add("pogs"); m.tickets = 140; m.save()
		menu.open_tab("inventory"), 0.6)
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
	# ---- the opening again (owner) and its skip
	_do(func():
		Engine.set_meta("mall_owner", true)
		menu.open_tab("controls"), 0.4)
	_do(func():
		var found := false
		for h in menu._hits:
			if h[0] is Button and h[0].text == "Show the opening again": found = true
		_check(found, "the owner's Show the opening again")
		menu._owner_opening(), 0.4)
	_do(func(): _check(menu.opening != null, "the opening again"); _key(KEY_ESCAPE); _key(KEY_ESCAPE, false), 0.4)
	_do(func(): _check(menu.opening == null and not player.frozen, "Esc skips it"); Engine.set_meta("mall_owner", false), 0.2)
	# ---- the year: the transition mid-flash, then 2026
	_do(func(): menu.open_tab("year"), 0.5)
	_do(func(): _shot("year-1280x720"); menu._go_year(2026), 0.75)
	_do(func():
		var tt = player.get_node_or_null("TimeTravel")
		_check(tt != null, "the time-travel transition plays")
		if tt: tt.hold(0.36)
		, 0.15)
	_do(func(): _shot("timetravel-flash"); var tt = player.get_node_or_null("TimeTravel"); if tt: tt.hold(0.5), 0.15)
	_do(func(): _shot("timetravel-mid"); var tt = player.get_node_or_null("TimeTravel"); if tt: tt._playing = true; tt._t = tt.duration * 0.5, 3.0)
	_do(func():
		scn = current_scene
		_check(scn != null and int(scn.get_meta("year", 0)) == 2026, "after the transition: 2026 (%s)" % (scn.scene_file_path if scn else "-"))
		_unbake(scn)
		player = scn.get_node("Player")
		menu = player.get_node("Menu"), 25.0)
	_do(func():
		var sh = scn.get_node_or_null("Shoppers")
		var n := 0
		var ids := []
		if sh:
			for s in sh.shoppers:
				if s.role == "": n += 1; ids.append(s.body.id if s.body else "?")
		_check(sh != null and n == 3, "2026: 3 shoppers (%d: %s)" % [n, ids])
		_check(player.mall.player_name == "TESTER", "the name crosses into 2026")
		_check(menu.opening == null, "no opening once named")
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
