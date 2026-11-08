## ws/items (design/godot-items.md): unbaked native shots of what changed, 1990s, in a light wing (default
## 6, the cinema lobby placeholder: the box this ran on had no memory for wing 2), with wing 2's directory:
## a first start (no opening), the corn dog bought at Corn Dog 7 (the card: "In your hand"), the corn dog in
## the hand, the bag after putting it away (and a lollipop-like pocket thing), the directory's year labels.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/items_shots.gd -- --out=/tmp/items/w6 [--wing=6]
## Prints ITEMS SHOTS OK (n checks) or the failures; writes <out>-<name>.png.
extends SceneTree

var out := "/tmp/items/w2"
var scn: Node
var player: Node3D
var menu: Node
var errors := []
var oks := 0
var q := []
var qi := 0
var wait := 0.0
var wing := 6

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--wing="): wing = int(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_player_name", "")
	Cast._kv_del(Cast.KEY)                    # a first visit: no character record (CHAR-STRIP), no name
	scn = load("res://wing%d.tscn" % wing).instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "day")
	player = scn.get_node("Player")
	_plan()

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])

func _key(k: Key, down := true) -> void:
	var e := InputEventKey.new()
	e.keycode = k; e.physical_keycode = k; e.pressed = down
	Input.parse_input_event(e)

func _do(c: Callable, w := 0.0) -> void:
	q.append([c, w])

func _plan() -> void:
	_do(func(): pass, 20.0)
	_do(func():
		menu = player.get_node("Menu")
		_check(not menu.is_open and not player.frozen and not ("creator" in player.avatar), "a first visit starts in the mall: no opening, no menu, no creator")
		if wing == 2:   # at Corn Dog 7's counter, looking at it
			player.position = Vector3(-131.2, 0, 74.4); player.yaw = deg_to_rad(90); player.pitch = deg_to_rad(-12); player._apply_rot()
		_shot("start-no-opening"), 2.0)
	_do(func():
		player.mall.add_money(1000, "items_shots")
		_check(player.mall.shop.open("corn_dog_7"), "Corn Dog 7's list opens"), 1.5)
	_do(func():
		var sh = player.mall.shop
		var i := -1
		for k in sh.stock.size():
			if str(sh.stock[k].item) == "bl_cd7_corndog": i = k
		_check(sh.buy(i), "bought the corn dog")
		_check(player.mall.hand == "bl_cd7_corndog", "the corn dog is in the hand"), 1.2)
	_do(func():
		var pop = player.interact.get_children().filter(func(c): return c.get_script() == load("res://scripts/received_popup.gd"))
		_check(not pop.is_empty() and pop[0].current == "bl_cd7_corndog" and pop[0].where_l.text.begins_with("In your hand"), "the card says In your hand")
		_shot("receive-popup-hand")
		_key(KEY_SPACE); _key(KEY_SPACE, false), 0.6)
	_do(func(): player.mall.shop.close(), 1.5)
	_do(func():
		player.pitch = deg_to_rad(-4); player._apply_rot()
		_shot("hand-corndog"), 0.5)
	# a pocket thing (given): into the bag; then R puts the corn dog away
	_do(func():
		player.mall.receive("pc_claw_pogEye", 1, "items_shots"), 1.0)
	_do(func(): _key(KEY_SPACE); _key(KEY_SPACE, false), 0.6)
	_do(func():
		_check(player.mall.hand == "bl_cd7_corndog" and player.mall.count("pc_claw_pogEye") == 1, "the POGs went into the bag, the corn dog stays in the hand")
		_key(KEY_R); _key(KEY_R, false), 0.6)
	_do(func():
		_check(player.mall.hand == "" and player.mall.count("bl_cd7_corndog") == 1, "R puts the corn dog in the bag")
		menu.open_tab("inventory"), 1.0)
	_do(func(): _shot("bag-after-put-away"), 0.2)
	_do(func(): menu.close(), 0.6)
	# the directory: the 1990s (wing 2's map, opened here without its kiosk)
	_do(func():
		var ui := CanvasLayer.new()
		ui.name = "DirectoryUI"
		scn.set_meta("gen", "res://gen/w2/")
		ui.set_script(load("res://scripts/directory_ui.gd"))
		scn.add_child(ui)
		set_meta("dir", ui), 0.5)
	_do(func():
		var ui = get_meta("dir")
		var k := Node3D.new()
		scn.add_child(k)
		ui.open(player, k), 1.5)
	_do(func():
		var ui = get_meta("dir")
		_check(ui.is_open and ui.map_year == "1995", "the directory is open on the 1995 map (shown as 1990s)")
		_shot("directory-year-1990s"), 0.3)
	_do(func():
		printerr("ITEMS SHOTS OK (%d checks)" % oks if errors.is_empty() else "ITEMS SHOTS FAILED: " + str(errors))
		quit(0 if errors.is_empty() else 1), 0.0)

func _process(dt: float) -> bool:
	wait -= dt
	while wait <= 0.0 and qi < q.size():
		var s: Array = q[qi]
		qi += 1
		s[0].call()
		wait = s[1]
	return false
