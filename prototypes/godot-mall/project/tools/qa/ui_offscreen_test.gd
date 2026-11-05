## Workstream UI-OFFSCREEN (design/godot-menu.md "The game screen"): no corner buttons on the game
## screen; the way into the menu is the small unlabelled icon top left on a touch device, Tab or Esc
## on a desktop (no icon there; the first-start walk hint names the key), Start on a gamepad; every
## function the corner buttons reached is in the menu, and its key still works. Native, unbaked.
## Starts as a desktop (no touch screen natively), then a first tap makes it a touch device.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/ui_offscreen_test.gd -- --wing=2 --out=/tmp/uo/w2 [--year=2026]
## Prints UI OFFSCREEN TEST OK (n checks) or the failures; writes <out>-<name>.png.
extends SceneTree

const Look = preload("res://scripts/avatar_look.gd")
var out := "/tmp/uo/w"
var wing := 2
var year := 1995
var scn: Node
var player: Node3D
var menu: Node
var errors := []
var oks := 0
var q := []
var qi := 0
var wait := 0.0
var sizes := [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]
var was_third := false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--wing="): wing = int(a.substr(7))
		elif a.begins_with("--year="): year = int(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_state_2026", "")
	Engine.set_meta("mall_player_name", "TESTER")
	Engine.set_meta("mall_controls", "")
	Engine.set_meta("menu_opening", false)
	Engine.set_meta("mall_owner", false)
	var L := Look.default_look()
	L.done = true; L.body = "Ch21"; L.view = "first"
	Engine.set_meta("mall_avatar", JSON.stringify(L))
	scn = load("res://wing%d%s.tscn" % [wing, "_2026" if year == 2026 else ""]).instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "night")
	player = scn.get_node("Player")
	_plan()

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])

func _size(s: Vector2i) -> void:
	DisplayServer.window_set_size(s)
	root.size = s

func _key(k: Key) -> void:
	for d in [true, false]:
		var e := InputEventKey.new()
		e.keycode = k; e.physical_keycode = k; e.pressed = d
		Input.parse_input_event(e)

func _tap(p: Vector2) -> void:
	for d in [true, false]:
		var t := InputEventScreenTouch.new()
		t.index = 0; t.position = p; t.pressed = d
		Input.parse_input_event(t)

func _click(p: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = p; m.global_position = p
	Input.parse_input_event(m)
	for d in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT; e.pressed = d
		e.position = p; e.global_position = p
		Input.parse_input_event(e)

func _pad(b: JoyButton) -> void:
	for d in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = b; e.pressed = d
		Input.parse_input_event(e)

func _do(c: Callable, w := 0.0) -> void:
	q.append([c, w])

func _centre(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

## Every Label / Button with words that is drawn right now, outside the menu's own layers.
func _texts(n: Node, acc: Array) -> Array:
	if n is CanvasItem and not (n as CanvasItem).visible:
		return acc
	if n is CanvasLayer and not (n as CanvasLayer).visible:
		return acc
	if n == menu._layer or (menu._creator != null and n == menu._creator):
		return acc
	if (n is Label or n is Button) and (n as Control).is_visible_in_tree():
		var t: String = n.text
		if t.strip_edges() != "":
			acc.append(n)
	for c in n.get_children():
		_texts(c, acc)
	return acc

## The words that may stay on the game screen (Steven, Nov 4): the walk-up action prompts, the touch
## Use button, the short status line (_say) and the first-start walk hint.
func _allowed(c: Control) -> bool:
	var it = player.interact
	for a in [it.prompt, it.act_btn, player.hint]:
		if a != null and (c == a or a.is_ancestor_of(c)):
			return true
	if player.get("prompt") != null and (c == player.prompt or player.prompt.is_ancestor_of(c)):
		return true      # the wing seam / door prompt
	return false

func _clean_screen(tag: String) -> void:
	var bad: Array = []
	for c in _texts(root, []):
		if not _allowed(c):
			bad.append("%s '%s' %s" % [c.get_path(), String(c.text).left(30), c.get_global_rect()])
	for b in bad:
		printerr("  on screen: ", b)
	_check(bad.is_empty(), "%s: no corner buttons or labels on the game screen (%d left)" % [tag, bad.size()])

func _main_btn(n: String) -> Button:
	return menu._root.find_child(n, true, false) as Button if menu._root else null

func _plan() -> void:
	_do(func(): pass, 3.0)
	_do(func():
		menu = player.get_node("Menu")
		var tucked: Array = menu.corner_buttons()
		_check(tucked.size() >= 5, "five corner buttons found: Jump to, year, Bag, View, Avatar (%d)" % tucked.size())
		var hidden := true
		for b in tucked:
			if b.is_visible_in_tree():
				hidden = false
				printerr("  still drawn: ", b.text)
		_check(hidden, "the corner buttons are tucked away (not drawn)")
		_check(player.jump_open_btn.visible and player.interact.bag_btn.visible, "their own state is untouched (Jump to, Bag still 'visible' for the code that lays out round them)")
		# ---- a desktop: no icon; the walk hint names the menu key; Esc, Tab, Start open MAIN
		_check(not menu.touch_device and not menu._menu_btn.is_visible_in_tree(), "desktop: no menu icon on the game screen")
		player.hint.visible = true
		var ht: String = player.hint.text
		_check("Tab or Esc: menu" in ht, "desktop: the first-start walk hint names the menu key (%s)" % ht)
		_clean_screen("desktop 1280x720")
		_shot("desktop-game-hint-1280x720")
		player.hint.visible = false      # the first-start walk hint (it hides once you move)
		_key(KEY_ESCAPE), 0.5)
	_do(func():
		_check(menu.is_open and menu.tab == "main", "desktop: Esc opens MAIN")
		_key(KEY_ESCAPE), 0.4)
	_do(func():
		_check(not menu.is_open, "desktop: Esc closes it again")
		_key(KEY_TAB), 0.4)
	_do(func(): _check(menu.is_open and menu.tab == "main", "desktop: Tab opens MAIN"); menu.close(), 0.3)
	_do(func(): _pad(JOY_BUTTON_START), 0.4)
	_do(func():
		_check(menu.is_open and menu.tab == "main", "a gamepad's Start opens MAIN"); menu.close()
		_check(not menu._menu_btn.is_visible_in_tree(), "desktop with a pad: still no icon")
		# ---- a touch device: the first touch brings the icon (a phone shows it from the start)
		_tap(Vector2(900, 400)), 0.5)
	_do(func():
		var mb: Button = menu._menu_btn
		_check(menu.touch_device and mb.is_visible_in_tree() and mb.text == "", "touch: the menu icon is shown, with no words")
		_check(mb.get_global_rect().end.x < 60 and mb.get_global_rect().end.y < 60, "the icon sits top left (%s)" % mb.get_global_rect())
		_check(not ("Esc: menu" in String(player.hint.text)), "touch: the walk hint is as it was (%s)" % player.hint.text)
		, 0.2)
	for sz in sizes:
		var s: Vector2i = sz
		_do(func(): _size(s), 1.2)
		_do(func():
			_clean_screen("%dx%d" % [s.x, s.y])
			_shot("game-%dx%d" % [s.x, s.y])
			_tap(_centre(menu._menu_btn)), 0.6)
		_do(func():
			_check(menu.is_open and menu.tab == "main", "%dx%d: a tap on the icon opens MAIN" % [s.x, s.y])
			var ok := true
			for n in ["MainEdit", "MainView", "MainJump"]:
				var b := _main_btn(n)
				if b == null or not b.is_visible_in_tree():
					ok = false; continue
				var r := b.get_global_rect()
				print("RECT %dx%d %s %s centre %s" % [s.x, s.y, n, r, r.get_center()])
				if r.end.x > s.x + 1 or r.end.y > s.y + 1 or r.position.x < -1 or r.position.y < -1:
					ok = false
			_check(ok, "%dx%d: MAIN shows Edit, View and Jump to, on screen" % [s.x, s.y])
			_shot("menu-main-%dx%d" % [s.x, s.y])
			menu.open_tab("inventory"), 0.5)
		_do(func():
			_shot("menu-inventory-%dx%d" % [s.x, s.y])
			menu.close(), 0.4)
	_do(func(): _size(Vector2i(1280, 720)), 1.2)
	# ---- the other ways in
	_do(func(): _click(_centre(menu._menu_btn)), 0.5)
	_do(func(): _check(menu.is_open and menu.tab == "main", "touch device with a mouse / trackpad: a click on the icon opens MAIN"); menu.close(), 0.3)
	# ---- where the corner buttons were, a tap does nothing now
	_do(func():
		for b in menu.corner_buttons():
			if b.get_global_rect().has_area():
				_tap(_centre(b))
		, 0.6)
	_do(func():
		_check(not menu.is_open and not player.jump_panel.visible and not player.interact.panel.visible, "taps where the old corner buttons were open nothing")
		was_third = bool(player.avatar.third)
		menu.open_tab("main"), 0.4)
	# ---- MAIN's View, by touch, by mouse and by the pad; V still works
	_do(func(): _tap(_centre(_main_btn("MainView"))), 0.5)
	_do(func():
		_check(not menu.is_open and bool(player.avatar.third) != was_third, "MAIN's View (tap): the menu closes and the view switches")
		_key(KEY_V), 0.4)
	_do(func():
		_check(bool(player.avatar.third) == was_third, "V still switches the view")
		menu.open_tab("main"), 0.4)
	_do(func(): _click(_centre(_main_btn("MainView"))), 0.5)
	_do(func():
		_check(not menu.is_open and bool(player.avatar.third) != was_third, "MAIN's View (mouse click)")
		_pad(JOY_BUTTON_START), 0.4)
	_do(func(): _pad(JOY_BUTTON_DPAD_RIGHT), 0.2)
	_do(func(): _pad(JOY_BUTTON_A), 0.5)
	_do(func():
		_check(not menu.is_open and bool(player.avatar.third) == was_third, "MAIN's View by the pad (Start, d-pad right, A)")
		menu.open_tab("main"), 0.4)
	# ---- MAIN's Jump to; J still works
	_do(func(): _tap(_centre(_main_btn("MainJump"))), 0.5)
	_do(func():
		_check(not menu.is_open and player.jump_panel.visible, "MAIN's Jump to: the menu closes, the jump panel opens")
		_shot("jump-panel-1280x720")
		_key(KEY_ESCAPE), 0.4)
	_do(func():
		_check(not player.jump_panel.visible and not menu.is_open, "Esc closes the jump panel (and doesn't open the menu)")
		_key(KEY_J), 0.4)
	_do(func():
		_check(player.jump_panel.visible, "J still opens the jump panel")
		_key(KEY_J), 0.4)
	# ---- MAIN's Edit (Avatar); C and I still work
	_do(func(): menu.open_tab("main"), 0.4)
	_do(func(): _tap(_centre(_main_btn("MainEdit"))), 0.6)
	_do(func():
		_check(menu.is_open and menu.editing, "MAIN's Edit opens the avatar editing")
		menu.close(), 0.4)
	_do(func(): _key(KEY_C), 0.5)
	_do(func(): _check(menu.is_open and menu.tab == "main" and menu.editing, "C still opens the avatar editing"); menu.close(), 0.4)
	_do(func(): _key(KEY_I), 0.5)
	_do(func(): _check(menu.is_open and menu.tab == "inventory", "I still opens INVENTORY (the old Bag)"); menu.close(), 0.4)
	# ---- the owner's tools are not part of this change (they stay where they were)
	_do(func():
		if errors.is_empty():
			print("UI OFFSCREEN TEST OK (%d checks)" % oks)
		else:
			print("UI OFFSCREEN TEST FAILED: ", errors)
		quit(0 if errors.is_empty() else 1), 0.0)

func _process(dt: float) -> bool:
	wait -= dt
	while wait <= 0.0 and qi < q.size():
		var s: Array = q[qi]
		qi += 1
		s[0].call()
		wait = s[1]
	return false
