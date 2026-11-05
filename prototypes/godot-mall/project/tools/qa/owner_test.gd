## OWNER (design/godot-owner-mode.md): owner mode vs a visitor, natively, unbaked. A visitor's game
## screen keeps only the menu icon (UI-OFFSCREEN) and the menu has no OWNER tab; the owner gets every
## old corner button back (labelled Menu, Jump to, the year switch, Bag, View, Avatar), the loose owner
## tools tucked into the menu's OWNER tab, the owner directory (store list, jump question, jump, year
## keys) and the tools. Ends with the owner's year switch (Y) loading the other year's scene.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/owner_test.gd -- --wing=6 --out=/tmp/ow/w6
## Prints OWNER TEST OK (n checks) or the failures; writes <out>-<name>.png.
extends SceneTree

const Look = preload("res://scripts/avatar_look.gd")
var out := "/tmp/ow/w"
var wing := 6
var scn: Node
var player: Node3D
var menu: Node
var errors := []
var oks := 0
var q := []
var qi := 0
var wait := 0.0
var jumps: Array = []
var years := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--wing="): wing = int(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_state_2026", "")
	Engine.set_meta("mall_player_name", "TESTER")
	Engine.set_meta("mall_controls", "")
	Engine.set_meta("menu_opening", false)
	Engine.set_meta("mall_owner_hud", true)
	var L := Look.default_look()
	L.done = true; L.body = "Ch21"; L.view = "first"
	Engine.set_meta("mall_avatar", JSON.stringify(L))
	_plan()

func _load(owner: bool, path := "") -> void:
	Engine.set_meta("mall_owner", owner)
	if scn and is_instance_valid(scn):
		scn.queue_free()
	if path == "":
		path = "res://wing%d.tscn" % wing
	scn = load(path).instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "night")
	player = scn.get_node("Player")
	player.position = Vector3(player.position.x, 0, player.position.z)

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

func _do(c: Callable, w := 0.0) -> void:
	q.append([c, w])

func _centre(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func _find(n: String) -> Control:
	return menu._root.find_child(n, true, false) as Control if menu and menu._root else null

func _on_screen(c: Control, s: Vector2i) -> bool:
	if c == null or not c.is_visible_in_tree():
		return false
	var r := c.get_global_rect()
	return r.position.x >= -1 and r.position.y >= -1 and r.end.x <= s.x + 1 and r.end.y <= s.y + 1

func _corner() -> Array:
	var it = player.interact
	var av = player.avatar
	return [["Jump to", player.jump_open_btn], ["year", player.year_btn], ["Bag", it.bag_btn], ["View", av.view_btn], ["Avatar", av.make_btn]]

func _plan() -> void:
	# ------------------------------------------------ a visitor
	_do(func(): _load(false), 3.0)
	_do(func():
		menu = player.get_node("Menu")
		player.hint.visible = false
		var drawn: Array = []
		for c in _corner():
			if c[1].is_visible_in_tree(): drawn.append(c[0])
		_check(drawn.is_empty(), "visitor: no corner buttons drawn (%s)" % [drawn])
		_check(menu._menu_btn.text == "", "visitor: the menu button is the unlabelled icon")
		_check(not player.hud.visible, "visitor: no fps line")
		_check(menu.tabs() == ["main", "inventory", "controls"], "visitor: tabs MAIN, INVENTORY, CONTROLS only (%s)" % [menu.tabs()])
		menu.open_tab("owner"), 0.4)
	_do(func():
		_check(menu.tab != "owner" and _find("OwnerDirectory") == null, "visitor: no OWNER tab, no owner directory")
		menu.close()
		_key(KEY_Y), 0.6)
	_do(func():
		_check(not player.leaving and int(player.year) == 1995, "visitor: Y does nothing (the year changes only at a kiosk)")
		_shot("visitor-game-1280x720"), 0.1)
	# ------------------------------------------------ the owner
	_do(func(): _load(true), 3.5)
	_do(func():
		menu = player.get_node("Menu")
		player.hint.visible = false
		var s := Vector2i(1280, 720)
		var missing: Array = []
		for c in _corner():
			if not _on_screen(c[1], s): missing.append(c[0])
		_check(missing.is_empty(), "owner: every corner button on screen: Jump to, the year, Bag, View, Avatar (missing %s)" % [missing])
		_check(player.year_btn.text.contains("2026"), "owner: the year button reads '%s'" % player.year_btn.text)
		_check(menu._menu_btn.text.begins_with("Menu ("), "owner: the labelled Menu button ('%s')" % menu._menu_btn.text)
		_check(player.hud.visible, "owner: the fps line is shown")
		var loose: Array = []
		for b in menu.owner_tool_buttons():
			if b.is_visible_in_tree(): loose.append(b.text)
		_check(menu.owner_tool_buttons().size() >= 3 and loose.is_empty(), "owner: the loose tool buttons (%d) are tucked into the menu (still drawn: %s)" % [menu.owner_tool_buttons().size(), loose])
		var sg = scn.get_node_or_null("Signs")
		_check(sg != null and sg.is_owner and sg.b_edit != null and not sg.b_edit.is_visible_in_tree(), "owner: Edit signs exists, off the screen")
		_check(menu.tabs() == ["main", "inventory", "controls", "owner"], "owner: OWNER is the last tab (%s)" % [menu.tabs()])
		_shot("owner-game-1280x720"), 0.2)
	for sz in [Vector2i(390, 844), Vector2i(844, 390)]:
		var s: Vector2i = sz
		_do(func(): _size(s), 1.2)
		_do(func():
			var missing: Array = []
			for c in _corner():
				if not _on_screen(c[1], s): missing.append(c[0])
			_check(missing.is_empty(), "owner %dx%d: every corner button on screen (missing %s)" % [s.x, s.y, missing])
			_shot("owner-game-%dx%d" % [s.x, s.y]), 0.1)
	_do(func(): _size(Vector2i(1280, 720)), 1.2)
	# taps on the owner's corner buttons still work
	_do(func(): _tap(_centre(player.jump_open_btn)), 0.4)
	_do(func():
		_check(player.jump_panel.visible, "owner: a tap on Jump to opens the jump panel")
		player._jump_show(false)
		_tap(_centre(player.interact.bag_btn)), 0.5)
	_do(func():
		_check(menu.is_open and menu.tab == "inventory", "owner: a tap on Bag opens INVENTORY")
		menu.close()
		_tap(_centre(menu._menu_btn)), 0.5)
	_do(func():
		_check(menu.is_open and menu.tab == "main", "owner: a tap on the Menu button opens MAIN")
		menu.open_tab("owner"), 0.5)
	# ------------------------------------------------ the owner directory
	_do(func():
		_check(menu.tab == "owner" and _find("OwnerDirectory") != null, "owner: the OWNER tab opens on the directory")
		var ot = menu.owner_tab
		ot.jump_fn = func(w, y, x, z, yaw): jumps.append([w, y, x, z, yaw])
		ot.year_fn = func(): years += 1
		var n: int = ot.stores("1995").size()
		var shown := 0
		for c in menu._root.find_children("OwnerStore_*", "Button", true, false):
			shown += 1
		_check(n > 50 and shown == n, "owner directory 1995: %d stores listed, %d buttons" % [n, shown])
		_check(ot.stores("2026").size() > 30, "owner directory 2026: %d stores" % ot.stores("2026").size())
		var vac := false
		for st in ot.stores("1995") + ot.stores("2026"):
			if bool(st.get("vacant", false)): vac = true
		_check(not vac, "owner directory: no vacant units listed (the sign's stores only)")
		_shot("owner-directory-1995-1280x720"), 0.2)
	_do(func():
		var b := _find("OwnerStore_n10")    # Lane Bryant, wing 1 (gen/*/directory.json)
		_check(b != null, "owner directory: Lane Bryant is listed (%s)" % (b.text if b else "-"))
		if b:
			menu._scroll.ensure_control_visible(b)
		, 0.3)
	_do(func():
		var b := _find("OwnerStore_n10")
		if b: _tap(_centre(b)), 0.4)
	_do(func():
		var dlg := _find("OwnerAsk")
		_check(dlg != null and dlg.is_visible_in_tree(), "a tap on a store asks 'Jump to this store?'")
		var labs: Array = []
		if dlg:
			for l in dlg.get_children():
				if l is Label: labs.append(l.text)
		_check("Jump to this store?" in labs and "26  Lane Bryant" in labs and "Loads Wing 1" in labs, "the question names the store and the wing it loads (%s)" % [labs])
		_shot("owner-directory-ask-1280x720")
		_tap(_centre(_find("OwnerAskNo"))), 0.4)
	_do(func():
		_check(menu.is_open and _find("OwnerAsk") == null and jumps.is_empty(), "No: back to the list, no jump")
		var b := _find("OwnerStore_n10")
		if b: menu._scroll.ensure_control_visible(b), 0.3)
	_do(func():
		var b := _find("OwnerStore_n10")
		if b: _tap(_centre(b)), 0.4)
	_do(func(): _tap(_centre(_find("OwnerAskYes"))), 0.4)
	_do(func():
		var st: Dictionary = {}
		for x in menu.owner_tab.stores("1995"):
			if str(x.id) == "n10": st = x
		_check(not menu.is_open and jumps.size() == 1 and jumps[0] == [int(st.jump[0]), 1995, float(st.jump[1]), float(st.jump[2]), float(st.jump[3])],
			"Yes: the menu closes and jumps to the store's spot (%s)" % [jumps])
		menu.open_tab("owner"), 0.4)
	# the other year's list; keys / pad: Enter on a store asks
	_do(func(): _tap(_centre(_find("OwnerYear2026"))), 0.4)
	_do(func():
		var ot = menu.owner_tab
		var shown: int = menu._root.find_children("OwnerStore_*", "Button", true, false).size()
		_check(ot.list_year == "2026" and shown == ot.stores("2026").size(), "the 2026 key lists 2026's %d stores" % shown)
		_shot("owner-directory-2026-1280x720")
		var first: Dictionary = ot.stores("2026")[0]
		ot.ask_jump(first)
		_check(ot.ask_note(first).begins_with("Travels to 2026"), "a 2026 store from the 1990s travels in time (%s)" % ot.ask_note(first))
		_key(KEY_ENTER), 0.4)
	_do(func():
		_check(jumps.size() == 2 and int(jumps[1][1]) == 2026, "Enter answers Yes: a jump into 2026 (%s)" % [jumps.back()])
		menu.open_tab("owner"), 0.4)
	_do(func(): _tap(_centre(_find("OwnerTravel"))), 0.4)
	_do(func():
		_check(years == 1 and not menu.is_open, "'Travel to 2026 here' closes the menu and switches the year")
		# a real jump in this wing and year: the player moves at once
		var ot = menu.owner_tab
		ot.jump_fn = func(w, y, x, z, yaw): player.jump_to(w, y, x, z, yaw)
		ot.list_year = "1995"
		ot.ask = {"id": "t", "name": "TEST SPOT", "num": 0, "jump": [wing, player.position.x + 1.0, player.position.z, 90.0]}
		menu.open_tab("owner")
		ot.answer(true), 0.4)
	_do(func():
		_check(not player.leaving and absf(player.yaw - deg_to_rad(90.0)) < 0.01, "a jump in this wing moves the player at once (yaw %.1f)" % rad_to_deg(player.yaw))
		_size(Vector2i(390, 844)), 1.2)
	_do(func():
		menu.open_tab("owner")
		menu.owner_tab.show_view("directory"), 0.5)
	_do(func():
		var b := _find("OwnerStore_n10")
		_check(b == null or b.get_global_rect().end.x <= 391, "phone: the store list fits the width")
		_shot("owner-directory-390x844"), 0.1)
	# ------------------------------------------------ the tools
	_do(func():
		menu.owner_tab.show_view("tools"), 0.5)
	_do(func():
		var names: Array = []
		for b in menu._root.find_children("OwnerTool_*", "Button", true, false):
			names.append(b.name)
		print("TOOLS ", names)
		var want := ["OwnerTool_TurnOff", "OwnerTool_Open", "OwnerTool_EditSigns", "OwnerTool_PublishSigns", "OwnerTool_Arcade", "OwnerTool_EditPictures", "OwnerTool_PublishPictures"]   # int-52: no opening (ws/items), so no "Show it again"
		var miss: Array = []
		for w in want:
			if not w in names: miss.append(w)
		_check(miss.is_empty(), "OWNER tools: owner HUD, quick jump, signs, arcade, pictures (missing %s)" % [miss])
		var pb := _find("OwnerTool_PublishSigns") as Button
		_check(pb != null and pb.disabled, "Publish signs is greyed with nothing to publish")
		_shot("owner-tools-390x844"), 0.1)
	_do(func(): _size(Vector2i(1280, 720)), 1.2)
	_do(func():
		menu.open_tab("owner")
		menu.owner_tab.show_view("tools"), 0.5)
	_do(func():
		_shot("owner-tools-1280x720")
		_tap(_centre(_find("OwnerTool_TurnOff"))), 0.4)
	_do(func():
		_check(not player.hud.visible and not player.owner_hud_on, "Owner HUD off: the fps line goes")
		_tap(_centre(_find("OwnerTool_TurnOn"))), 0.4)
	_do(func():
		_check(player.hud.visible, "Owner HUD on: the fps line is back")
		_tap(_centre(_find("OwnerTool_EditSigns"))), 0.4)
	_do(func():
		var sg = scn.get_node("Signs")
		_check(sg.editing and not menu.is_open, "Edit signs: on, and the menu closes to tap a sign")
		menu.open_tab("owner"), 0.4)
	_do(func(): _tap(_centre(_find("OwnerTool_Arcade"))), 0.4)
	_do(func():
		var sg = scn.get_node("Signs")
		_check(sg.arcade_mode and not sg.editing, "Arcade: on (Edit signs goes off)")
		sg.set_arcade(false)
		var pc = scn.get_node_or_null("Pictures")
		_check(pc != null, "the Pictures node is made in every wing")
		menu.open_tab("owner"), 0.4)
	_do(func(): _tap(_centre(_find("OwnerTool_EditPictures"))), 0.4)
	_do(func():
		var pc = scn.get_node_or_null("Pictures")
		_check(pc != null and pc.editing and not menu.is_open, "Edit pictures: on, and the menu closes")
		if pc: pc.set_editing(false)
		var r: bool = player.buttons[0].button_pressed
		menu.open_tab("owner")
		menu.owner_tab._t_toggle(0)
		_check(player.buttons[0].button_pressed != r, "the Reflections toggle works from the menu")
		menu.owner_tab._t_toggle(0)
		menu.close(), 0.4)
	# ------------------------------------------------ the owner's year switch: Y loads the other year
	_do(func(): _key(KEY_Y), 0.3)
	_do(func(): _check(player.leaving, "owner: Y starts the year switch"), 9.0)
	_do(func():
		var cs = current_scene
		var p2 = cs.get_node_or_null("Player") if cs else null
		_check(p2 != null and int(p2.year) == 2026, "owner: the year switch lands in 2026 (%s)" % (cs.scene_file_path if cs else "-"))
		if p2:
			player = p2
			menu = p2.get_node("Menu")
		, 3.0)
	_do(func():
		_check(player.year_btn.is_visible_in_tree() and player.year_btn.text.contains("1990s"), "owner in 2026: the year button reads '%s'" % player.year_btn.text)   # int-52: ws/items names the year "1990s"
		_shot("owner-game-2026-1280x720"), 0.1)
	_do(func():
		if errors.is_empty():
			print("OWNER TEST OK (%d checks)" % oks)
		else:
			print("OWNER TEST FAILED: ", errors)
		quit(0 if errors.is_empty() else 1), 0.0)

func _process(dt: float) -> bool:
	wait -= dt
	while wait <= 0.0 and qi < q.size():
		var s: Array = q[qi]
		qi += 1
		s[0].call()
		wait = s[1]
	return false
