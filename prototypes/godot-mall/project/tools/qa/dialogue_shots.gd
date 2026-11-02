## The dialogue engine, the attendants, the Dillard's gate and the book reader natively, unbaked
## (design/godot-dialogue.md, design/godot-quests.md):
##   --wing=2: Pocket Change's attendant through the right path (approach, face camera, a line, the
##             three choices, the second level, the give, back out), the Dillard's gate (walk-in
##             message, a locked outside door, unlocked), the book reader from the bag.
##   --wing=1: the Sound Shop and Kay-Bee attendants (approach, face camera with a line).
##   --phone: fewer shots, for a phone-sized window (run with --resolution 390x844).
##   xvfb-run -a -s "-screen 0 1600x1000x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tools/qa/dialogue_shots.gd -- --wing=2 --out=/tmp/q/w2
## Prints DIALOGUE SHOTS OK (n checks), or the failed checks; writes <out>-<name>.png.
extends SceneTree

var out := "/tmp/q/w"
var wing := 2
var phone := false
var scn: Node
var player: Node3D
var story: Node
var ui: Node
var step := 0
var clock := 0.0
var errors := []
var oks := 0
var plan: Array = []        # [[wait_s, Callable], ...]

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--wing="): wing = int(a.substr(7))
		elif a == "--phone": phone = true
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")      # start with nothing carried
	Engine.set_meta("mall_flags", "")           # and no flags
	scn = load("res://wing%d.tscn" % wing).instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "night")
	player = scn.get_node("Player")
	plan = _plan_w2() if wing == 2 else _plan_w1()

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _shot(name: String) -> void:
	var im := root.get_texture().get_image()
	im.save_png("%s-%s.png" % [out, name])
	printerr("shot " + name)

func _at(x: float, z: float, yaw: float, pitch: float) -> void:
	player.position = Vector3(x, 0, z)
	player.yaw = deg_to_rad(yaw); player.pitch = deg_to_rad(pitch); player._apply_rot()

func _att(id: String) -> Node3D:
	for a in story.attendants:
		if a.name == "Attendant_" + id:
			return a
	return null

## Stand at an attendant's talk spot facing the body.
func _approach(id: String) -> void:
	var a := _att(id)
	var d: Vector3 = a.body.global_position - a.global_position
	_at(a.global_position.x, a.global_position.z, rad_to_deg(atan2(-d.x, -d.z)), -6.0)

func _process(dt: float) -> bool:
	clock += dt
	if story == null:
		story = player.get_node_or_null("Story")
		if story: ui = story.ui
		clock = 0.0
		return false
	if step >= plan.size():
		printerr("DIALOGUE SHOTS OK (%d checks)" % oks if errors.is_empty() else "DIALOGUE SHOTS FAILED: " + str(errors))
		return true
	if clock >= float(plan[step][0]):
		var c: Callable = plan[step][1]
		step += 1
		clock = 0.0
		c.call()
	return false

## Press "continue" twice: finish the typing, then go on.
func _cont() -> void:
	if ui.typing: ui._typed()
	ui._advance()

func _talk_plan(id: String, tag: String, full: bool) -> Array:
	var p := [
		[2.5, func():
			var a := _att(id)
			_check(a != null and a.body != null, tag + ": attendant made")
			if a == null: return
			_approach(id)
			_check(a.is_in_group("talker") and a.is_in_group("interactable"), tag + ": in groups talker + interactable")],
		[0.6, func():
			var it = player.interact
			var r: Array = it.find_target()
			_check(r[0] == _att(id) and r[1] == "TALK", tag + ": in reach, prompt TALK (%s)" % str(r[1]))
			if not phone: _shot(tag + "-approach")
			it.action()],
		[0.25, func():
			_check(ui.active and player.frozen, tag + ": talking, player frozen")
			if not phone: _shot(tag + "-camera-moving")],
		[1.6, func():
			_check(ui.line != null and str(ui.line.text).begins_with("PLACEHOLDER"), tag + ": first line PLACEHOLDER")
			_check(str(ui.name_l.text).begins_with("PLACEHOLDER"), tag + ": speaker named PLACEHOLDER")
			_shot(tag + "-face-line")
			_cont()],
		[1.6, func():
			_check(ui.resp_btns.size() == 3, tag + ": three responses (%d)" % ui.resp_btns.size())
			_shot(tag + "-three-choices")
			ui._choose(1)],
	]
	if full:
		p += [
			[1.6, func():
				_check(ui.resp_btns.size() == 3 and str(ui.line.text).contains("line 3"), "second level: line 3 and three more responses")
				ui.sel = 1; ui._paint()
				_shot(tag + "-second-level")
				ui._choose(1)],
			[1.6, func():
				_cont()],
			[0.9, func():
				_check(player.mall.has("candy_neck"), "give: the Candy necklace is in the bag")
				_check(player.mall.flags.has("placeholder_pocket_change_done"), "give path sets placeholder_pocket_change_done")
				_shot(tag + "-give")
				_cont()],
			[1.3, func():
				_check(not ui.active and not player.frozen, "END: control back")
				_check(root.get_camera_3d() == player.cam, "END: the walking camera is current again")
				player.interact.open_panel(true)
				_shot(tag + "-bag-after")
				player.interact.open_panel(false)],
		]
	else:
		p += [
			[1.6, func():
				_check(ui.active, tag + ": answered")
				_cont()],
			[1.3, func():
				_check(not ui.active and not player.frozen, tag + ": END, control back")],
		]
	return p

func _plan_w1() -> Array:
	return _talk_plan("sound_shop", "wsQ-soundshop", false) + _talk_plan("kay_bee", "wsQ-kaybee", false)

func _plan_w2() -> Array:
	var p := _talk_plan("pocket_change", "wsQ-pocketchange", not phone)
	if phone:
		return p + _book_plan()
	# Dillard's: walk into the opening
	p += [
		[0.5, func():
			_at(-4.0, 76.5, 180.0, 0.0)
			_check(story.gates.size() == 1 and story.gates[0].locked(), "Dillard's gate made and locked")
			for i in 60:
				player._try_move(Vector3(0, 0, 0.1))
			_check(player.position.z < 80.0 and player.position.z > 79.0, "walking in stops at the opening (z %.2f)" % player.position.z)],
		[0.3, func():
			_shot("wsQ-dillards-locked")
			# an outside door from inside (s2e): locked
			_at(28.4, 98.2, 90.0, 0.0)
			player._update_prompt()
			_check(player.door_near != null and str(player.door_near.store) == "s2e", "at the east entrance door spot")
			player._cross()
			_check(not player.leaving, "the locked door does not open")],
		[0.4, func():
			_shot("wsQ-dillards-door-locked")
			player.mall.flags.set_flag("dillards_unlocked")
			_at(-4.0, 76.5, 180.0, 0.0)
			for i in 60:
				player._try_move(Vector3(0, 0, 0.1))
			_check(player.position.z > 80.5, "unlocked: walking in works (z %.2f)" % player.position.z)
			_check(not story.gates[0].locks_door("s2e"), "unlocked: the door opens")],
	]
	return p + _book_plan()

func _book_plan() -> Array:
	return [
		[0.5, func():
			_at(-104.0, 70.0, 0.0, 0.0)
			player.mall.add("bl_bd_paperback")
			player.interact.open_panel(true)
			var has_read := false
			for r in player.interact.panel_rows:
				if r.id == "bl_bd_paperback":
					for b in r.btns:
						if b[0].text == "Read": has_read = true
			_check(has_read, "the bag's paperback row has Read")
			_shot("wsQ-bag-read")
			player.interact.open_panel(false)
			_check(story.read_item("bl_bd_paperback"), "the book opens")],
		[0.8, func():
			_check(str(story.book.text_l.text) == "PLACEHOLDER page 1.", "page 1")
			_shot("wsQ-book-page")
			story.book._turn()],
		[0.6, func():
			_check(story.book.choice_btns.size() == 2, "branch point: two choices")
			_shot("wsQ-book-choices")
			story.book._choose(1)],
		[0.6, func():
			story.book._turn()],
		[0.6, func():
			story.book._turn()],
		[0.6, func():
			_check(player.mall.flags.has("placeholder_book_finished"), "the ending sets placeholder_book_finished")
			_check(story.book.turn_b.text == "Close the book", "the end: Close the book")
			_shot("wsQ-book-end")
			story.book._turn()],
		[0.4, func():
			_check(not story.book.active and not player.frozen, "the book closes, control back")],
	]
