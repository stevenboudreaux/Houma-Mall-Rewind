## The interaction system natively (scripts/interact.gd; design/godot-interaction.md), unbaked:
##   --wing=2: Pocket Change's prizes (dropped there by the test's saved state; none lie there at first): the prompt in reach, picked up into the hand and
##             the bag, the bag panel, drop and pick up again, owner/visitor HUD.
##   --wing=1: the Stockrooms: Martin Folse's stick in its corner, picked up, held, swung.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/interact_test.gd -- --wing=2 --out=/tmp/it/w2
## Prints INTERACT TEST OK (n checks), or the failed checks; writes <out>-<name>.png.
extends SceneTree

var out := "/tmp/it"
var wing := 2
var scn: Node
var player: Node3D
var it: Node
var step := 0
var clock := 0.0
var errors := []
var oks := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--wing="): wing = int(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")      # start empty
	if wing == 2:
		# R (Nov 2): nothing lies at Pocket Change any more (the prizes are the counter's stock), so
		# the test drops its five prizes where they used to lie: a saved state with them "moved" there
		var mv := {}
		for e in [["spring", -107.6, 63.9, 20], ["dice", -108.8, 67.0, -35], ["pogs", -105.9, 70.4, 70],
				["slap", -105.3, 72.6, 10], ["candy_neck", -109.2, 62.4, 0]]:
			mv[e[0]] = {"wing": 2, "year": 1995, "pos": [e[1], 0.0, e[2]], "yaw": e[3]}
		Engine.set_meta("mall_state_1995", JSON.stringify({"v": 1, "year": 1995, "inventory": [], "tickets": 0, "hand": "", "moved": mv}))
	if wing == 2:
		Engine.set_meta("mall_xfer", {"x": -108.6, "z": 71.5, "yaw": deg_to_rad(-42.0), "pitch": deg_to_rad(-20.0)})
	scn = load("res://wing%d.tscn" % wing).instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "night")
	player = scn.get_node("Player")

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _shot(name: String) -> void:
	var im := root.get_texture().get_image()
	im.save_png("%s-%s.png" % [out, name])

func _done() -> bool:
	printerr("INTERACT TEST OK (%d checks)" % oks if errors.is_empty() else "INTERACT TEST FAILED: " + str(errors))
	return true

func _at(x: float, z: float, yaw: float, pitch: float) -> void:
	player.position = Vector3(x, 0, z)
	player.yaw = deg_to_rad(yaw); player.pitch = deg_to_rad(pitch); player._apply_rot()

## Stand 1 m from a pickup, facing it.
func _face(n: Node3D, back := 1.0, pitch := -35.0) -> void:
	var p := n.global_position
	_at(p.x + back, p.z, 90.0, pitch)

func _pick(id: String) -> Node3D:
	for n in scn.get_tree().get_nodes_in_group("interactable"):
		if n.name == "it_" + id:
			return n
	return null

func _process(dt: float) -> bool:
	clock += dt
	if it == null:
		it = player.get_node_or_null("Interact")
		clock = 0.0
		return false
	# R: every pick-up shows the "You received" card (scripts/received_popup.gd), which holds the player;
	# this test is about the pick-ups, so it closes the cards at once (redemption_test checks them)
	_close_cards()
	return _w2() if wing == 2 else _w1()

func _close_cards() -> void:
	for c in it.get_children():
		if c.has_method("dismiss"):
			while c.is_showing():
				c.dismiss()

func _w2() -> bool:
	match step:
		0:
			if clock > 1.5:
				var n := scn.get_tree().get_nodes_in_group("interactable").filter(func(x): return x.name in ["it_spring", "it_dice", "it_pogs", "it_slap", "it_candy_neck"]).size()
				_check(n == 5, "five dropped prizes lie in Pocket Change (%d)" % n)
				_check(player.mall != null and player.mall.inventory.is_empty() and player.mall.hand == "", "player.mall starts empty")
				_check(not player.hud.visible and not player.buttons[0].visible and not player.buttons[1].visible and player.jump_open_btn.visible, "visitor HUD: no fps, no toggles, Jump to shown")
				_shot("hud-visitor")
				_check(it.prompt.visible == false or it.target != null, "no prompt from across the store unless something is in reach")
				_face(_pick("spring"), 1.0)
				step = 1; clock = 0.0
		1:
			if clock > 0.5:
				_check(it.target != null and it.target.name == "it_spring", "the spring is the target 1 m in front")
				_check(it.prompt.visible and it.prompt_text.text == "Pick up Rainbow coil spring", "prompt: " + it.prompt_text.text)
				_shot("prompt")
				# facing away: no target
				player.yaw += PI; player._apply_rot()
				step = 2; clock = 0.0
		2:
			if clock > 0.3:
				_check(it.target == null, "no target behind you")
				player.yaw -= PI; player._apply_rot()
				step = 3; clock = 0.0
		3:
			if clock > 0.3:
				it.action(); _close_cards()
				_check(player.mall.hand == "spring" and (_pick("spring") == null or _pick("spring").is_queued_for_deletion()), "action: the spring is in the hand")
				_check(it.hand_item != null, "the spring is drawn in the hand")
				player.pitch = deg_to_rad(-5.0); player._apply_rot()
				step = 4; clock = 0.0
		4:
			if clock > 0.5:
				_shot("held-spring")
				_face(_pick("pogs"), 1.0)
				step = 5; clock = 0.0
		5:
			if clock > 0.4:
				_check(it.prompt_text.text == "Take Pog pack", "prompt: " + it.prompt_text.text)
				it.action(); _close_cards()
				_check(player.mall.count("pogs") == 1 and player.mall.hand == "spring", "pocket item into the bag, hand unchanged")
				_face(_pick("dice"), 1.0)
				step = 6; clock = 0.0
		6:
			if clock > 0.4:
				it.action(); _close_cards()
				_check(player.mall.hand == "dice" and player.mall.count("spring") == 1, "picking up another hand item puts the first away")
				for id in ["slap", "candy_neck"]:
					var n := _pick(id)
					if n: n.interact(player); _close_cards()
				it.open_panel(true)
				step = 7; clock = 0.0
		7:
			if clock > 0.5:
				_check(it.panel.visible and player.frozen and it.panel_rows.size() == 5, "the bag lists 5 things (%d)" % it.panel_rows.size())
				_shot("bag")
				it.open_panel(false)
				_check(not player.frozen, "closing the bag lets you walk again")
				it.drop("dice")
				step = 8; clock = 0.0
		8:
			if clock > 0.4:
				var d := _pick("dice")
				_check(d != null and player.mall.hand == "" and player.mall.moved.dice.has("pos"), "dropped dice lie in front")
				_check(it.target != null and it.target.name == "it_dice", "and can be picked up again")
				it.action(); _close_cards()
				_check(player.mall.hand == "dice", "picked up again")
				# the saved state, as a wing load would read it
				var saved := str(Engine.get_meta("mall_state_1995", ""))
				_check(saved.find("\"hand\":\"dice\"") > 0 and saved.find("pogs") > 0, "saved after each change")
				Engine.set_meta("mall_owner", true)
				player.owner_hud_sync()
				step = 9; clock = 0.0
		9:
			if clock > 0.6:
				_check(player.hud.visible and player.buttons[0].visible and player.jump_open_btn.offset_top == 168, "owner HUD: fps and toggles back")
				_shot("hud-owner")
				return _done()
	return false

func _w1() -> bool:
	var sr = scn.get_node_or_null("Stockrooms")
	match step:
		0:
			if clock > 1.5 and sr:
				sr.enter(true)
				step = 1; clock = 0.0
		1:
			if clock > 1.5:
				var s := _pick("folse_stick")
				_check(s != null and s.is_visible_in_tree(), "the stick is in the Stockrooms")
				_check(not sr.caption.visible, "the old caption is off")
				if s:
					var p := s.global_position
					_at(p.x - 0.9, p.z - 0.9, 135.0 + 180.0 - 90.0, -25.0)
					# face it exactly
					var d := Vector2(p.x - player.position.x, p.z - player.position.z)
					player.yaw = atan2(-d.x, -d.y); player._apply_rot()
				step = 2; clock = 0.0
		2:
			if clock > 0.6:
				_check(it.target != null and it.prompt_text.text == "Pick up Martin Folse's stick", "prompt: " + it.prompt_text.text)
				_shot("stick-prompt")
				it.action(); _close_cards()
				_check(player.mall.hand == "folse_stick", "the stick is in the hand")
				player.pitch = 0.0; player._apply_rot()
				step = 3; clock = 0.0
		3:
			if clock > 0.5:
				_shot("stick-held")
				_check(it.prompt.visible and it.prompt_text.text.begins_with("Swing"), "nothing in reach: the button swings (" + it.prompt_text.text + ")")
				it.action(); _close_cards()
				_check(it.swinging, "swinging")
				step = 4; clock = 0.0
		4:
			if clock > 0.16:
				_shot("stick-swing")
				step = 5; clock = 0.0
		5:
			if clock > 0.6:
				_check(not it.swinging, "the swing ends")
				sr.leave()
				step = 6; clock = 0.0
		6:
			if clock > 1.6:
				_check(not sr.inside and it.hand_item != null, "back in the mall, still holding the stick")
				player.pitch = 0.0; player._apply_rot()
				step = 7; clock = 0.0
		7:
			if clock > 0.4:
				_shot("stick-in-mall")
				return _done()
	return false
