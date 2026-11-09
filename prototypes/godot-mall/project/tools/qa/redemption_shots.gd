## Native, unbaked evidence shots of Pocket Change's redemption (workstream R; design/godot-prize-counter.md):
## the empty floor, the "Redeem tickets" prompt, the screen with 0 and 5,100 tickets, a buy and its pop-up,
## the screen after it, the boom box held in first and third person. Also checks the flow as it goes.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/redemption_shots.gd -- --out=/tmp/rd/desk
## (--resolution 390x844 for iPhone portrait width, 844x390 landscape). Prints REDEMPTION SHOTS OK.
extends SceneTree

var out := "/tmp/rd/shot"
var scn: Node
var player: Node3D
var it: Node
var pz: Node
var rd: Node
var pop: Node
var step := 0
var clock := 0.0
var errors := []
var oks := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	# CHAR-STRIP: the player's record (scripts/cast.gd), first person, the default cast member
	Cast.save_player({"cast": str(Cast.roster().default), "view": "first"})
	Engine.set_meta("mall_xfer", {"x": -108.6, "z": 71.5, "yaw": deg_to_rad(-42.0), "pitch": deg_to_rad(-22.0)})
	scn = load("res://wing2.tscn").instantiate()
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
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])

func _at(x: float, z: float, yaw: float, pitch: float) -> void:
	player.position = Vector3(x, 0, z)
	player.yaw = deg_to_rad(yaw); player.pitch = deg_to_rad(pitch); player._apply_rot()

func _in_pc(x: Node) -> bool:
	if not (x is Node3D and x.name.begins_with("it_")):
		return false
	var p: Vector3 = (x as Node3D).global_position
	return p.x > -113.0 and p.x < -99.0 and p.z > 56.0 and p.z < 78.0

func _process(dt: float) -> bool:
	clock += dt
	if it == null or pz == null:
		it = player.get_node_or_null("Interact")
		pz = scn.get_node_or_null("Prizes")
		clock = 0.0
		return false
	match step:
		0:
			if clock > 2.0:
				rd = player.mall.redemption
				for c in it.get_children():
					if c.has_method("show_item"): pop = c
				_check(rd != null and pop != null, "the redemption screen and the pop-up exist")
				# Pocket Change's shop floor (the other wing 2 items, e.g. B. Dalton's paperbacks, are elsewhere)
				var n := scn.get_tree().get_nodes_in_group("interactable").filter(_in_pc).size()
				_check(n == 0, "nothing to pick up in Pocket Change (%d)" % n)
				_shot("floor-empty")
				_at(-104.8, 64.2, -90.0, -18.0)
				step = 1; clock = 0.0
		1:
			if clock > 0.6:
				_check(pz.prompt.visible, "the counter prompt shows")
				_shot("prompt")
				pz.redeem()
				step = 2; clock = 0.0
		2:
			if clock > 0.6:
				_check(rd.is_open and player.frozen and player.mall.tickets == 0, "the screen opens, 0 tickets")
				var dis := 0
				for c in rd.cards:
					if c.buy.disabled: dis += 1
				_check(dis == rd.cards.size(), "with 0 tickets every BUY is greyed out (%d)" % dis)
				_shot("screen-0")
				rd.close()
				player.mall.tickets = 5100   # ECON: the boom box is 5,000 (was 600 for a 500 boom box)
				rd.open()
				step = 3; clock = 0.0
		3:
			if clock > 0.6:
				var ok := 0
				for c in rd.cards:
					if not c.buy.disabled: ok += 1
				_check(ok == rd.cards.size(), "with 5,100 tickets every prize can be bought (%d of %d)" % [ok, rd.cards.size()])
				for i in rd.stock.size():
					if rd.stock[i].item == "bl_pc_boombox": rd.sel = i
				rd._paint_sel()
				step = 4; clock = 0.0
		4:
			if clock > 0.4:
				_shot("screen-600")
				_check(rd.buy(rd.sel), "buy the boom box")
				step = 5; clock = 0.0
		5:
			if clock > 0.9:
				_check(pop.is_showing() and pop.current == "bl_pc_boombox", "the pop-up shows the boom box")
				_shot("popup")
				var ev := InputEventKey.new()
				ev.pressed = true; ev.physical_keycode = KEY_SPACE
				pop._input(ev)
				step = 6; clock = 0.0
		6:
			if clock > 0.5:
				_check(not pop.is_showing() and rd.is_open and player.mall.tickets == 100, "dismissed; back on the screen with 100 tickets")
				_shot("screen-after-buy")
				rd.close()
				_check(not player.frozen, "closing the screen lets you walk")
				player.mall.hold("bl_pc_boombox")
				_at(-106.0, 66.0, -60.0, -8.0)
				step = 7; clock = 0.0
		7:
			if clock > 0.8:
				_check(it.hand_item != null and player.mall.hand == "bl_pc_boombox", "the boom box is in the hand")
				_shot("held-first")
				var av = player.get("avatar")
				if av and av.has_method("toggle_view"):
					av.toggle_view()
				_at(-9.0, 61.0, 90.0, -12.0)   # the hall: the arcade machines behind you in Pocket Change block the camera boom
				step = 8; clock = 0.0
		8:
			if clock > 2.5:
				_shot("held-third")
				var av = player.get("avatar")
				if av:
					printerr("third: %s body %s vis %s at %s boom %s cam %s item in avatar hand %s" % [av.third, av.body != null,
						av.body.visible if av.body else false, av.body.global_position if av.body else Vector3.ZERO, av.get("_boom"),
						av.tp_cam.current if av.tp_cam else false, it.hand_item != null and it.hand_item.get_parent() != it.hand_root])
				if av and av.get("third"):
					av.toggle_view()   # leave the saved look as it was
				printerr("REDEMPTION SHOTS OK (%d checks)" % oks if errors.is_empty() else "REDEMPTION SHOTS FAILED: " + str(errors))
				return true
	return false
