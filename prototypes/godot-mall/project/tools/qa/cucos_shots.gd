## Workstream CUCOS natively, unbaked, wing 1 1995 (design/godot-cucos.md):
## the bar (taps, bartender, patrons with drinks), the football lady found in the crowd and talked to down
## the coupon path (face camera, each level, the coupon received), the coupon held at the bar (Steven's
## lines, the margarita and the doubloon), the shop (the list, a beer bought with money), the bag.
##   xvfb-run -a -s "-screen 0 1600x1000x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tools/qa/cucos_shots.gd -- --out=/tmp/cu/w1 [--phone] [--day]
## Prints CUCOS SHOTS OK (n checks), or the failed checks; writes <out>-<name>.png.
extends SceneTree

var out := "/tmp/cu/w1"
var phone := false
var mode := "night"
var scn: Node
var player: Node3D
var story: Node
var cu: Node
var ui: Node
var step := 0
var clock := 0.0
var errors := []
var oks := 0
var plan: Array = []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a == "--phone": phone = true
		elif a == "--day": mode = "day"
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_flags", "")
	scn = load("res://wing1.tscn").instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, mode)
	player = scn.get_node("Player")
	plan = _plan()

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

func _face(from: Vector3, to: Vector3, pitch := -6.0) -> void:
	var d := to - from
	_at(from.x, from.z, rad_to_deg(atan2(-d.x, -d.z)), pitch)

func _process(dt: float) -> bool:
	clock += dt
	if story == null:
		story = player.get_node_or_null("Story")
		if story:
			ui = story.ui
			cu = story.get_node_or_null("Cucos")
		clock = 0.0
		return false
	if step >= plan.size():
		printerr("CUCOS SHOTS OK (%d checks)" % oks if errors.is_empty() else "CUCOS SHOTS FAILED: " + str(errors))
		return true
	if clock >= float(plan[step][0]):
		var c: Callable = plan[step][1]
		step += 1
		clock = 0.0
		c.call()
	return false

func _cont() -> void:
	if ui.typing: ui._typed()
	ui._advance()

## Stand ~1.1 m from the lady, on open floor, facing her.
func _to_lady() -> bool:
	var l = cu.lady
	if l == null or l.find() == null: return false
	var s = l.find()
	var crowd = l.crowd
	for k in 16:
		var a := TAU * k / 16.0
		var p: Vector3 = s.pos + Vector3(sin(a), 0, cos(a)) * 1.1
		if crowd._open(p) and crowd._open(s.pos + Vector3(sin(a), 0, cos(a)) * 0.55):
			_face(p, s.pos, -4.0)
			return true
	return false

func _line() -> String:
	return str(ui.line.text) if ui.line else ""

func _plan() -> Array:
	var p := [
		# the bar from the dining room
		[4.0, func():
			_check(cu != null, "Story/Cucos made")
			_check(cu.bartender != null and cu.bartender.body != null, "the bartender is behind the bar")
			_check(cu.patrons.size() == 2 and cu.drinks.size() == 2, "two patrons on stools, two drinks on the counter")
			_face(Vector3(27.6, 0, -73.0), Vector3(23.2, 1.0, -76.0), -8.0)],
		[1.0, func():
			_shot("wsCUCOS-unbaked-bar")
			_face(Vector3(25.3, 0, -76.6), Vector3(23.3, 1.3, -76.0), -16.0)],
		[0.8, func():
			_shot("wsCUCOS-unbaked-taps")
			# the lady: in the crowd (npcs.json "always")
			var s = cu.lady.find() if cu.lady else null
			_check(s != null, "the football lady (Ch02) is in the crowd")
			if s: printerr("lady at ", s.pos, " state ", s.state)
			_check(_to_lady(), "found open floor next to her")],
		[0.3, func():
			_to_lady()
			var r: Array = player.interact.find_target()
			printerr("lady node ", cu.lady.global_position, " vis ", cu.lady.is_visible_in_tree(), " prompt '", cu.lady.interact_prompt(), "' player ", player.position, " target ", r[0])
			_check(r[0] == cu.lady and r[1] == "TALK", "next to her: TALK (%s)" % str(r[1]))
			if not phone: _shot("wsCUCOS-unbaked-lady-approach")
			player.interact.action()],
		[1.8, func():
			_check(ui.active and player.frozen and cu.lady.talking, "talking to her, her shopper held (%s)" % str(cu.lady.s.state if cu.lady.s else "?"))
			_check(_line() == "Oh, hey, did you watch the game last night?", "her first line: " + _line())
			_check(ui.name_l.text == "" or not ui.name_l.visible, "no speaker name over her line")
			_shot("wsCUCOS-unbaked-lady-face")
			if ui.typing: ui._typed()],
		[1.2, func():
			_check(ui.resp_btns.size() == 3, "three answers")
			ui.sel = 1; ui._paint()
			_shot("wsCUCOS-unbaked-lady-q1")
			ui._choose(1)],
		[1.6, func():
			if ui.typing: ui._typed()],
		[0.3, func():
			_check(_line().begins_with("I know, right?"), "B: " + _line())
			if not phone: _shot("wsCUCOS-unbaked-lady-q2")],
		[0.8, func():
			ui.sel = 0; ui._paint()
			ui._choose(0)],
		[1.8, func():
			if ui.typing: ui._typed()],
		[0.3, func():
			_check(_line().begins_with("Ain't that the truth?"), "A: " + _line())],
		[0.8, func():
			ui.sel = 2; ui._paint()
			_shot("wsCUCOS-unbaked-lady-q3")
			ui._choose(2)],
		[2.5, func():
			if ui.typing: ui._typed()],
		[0.6, func():
			_check(_line().begins_with("Hey, well, you're in Cuco's"), "C: the coupon line")
			_check(player.mall.has("cu_coupon") and player.mall.flags.has("cu_coupon_given"), "the coupon is in the bag")
			_shot("wsCUCOS-unbaked-lady-coupon")
			_cont()],
		[1.4, func():
			_check(not ui.active and not player.frozen, "END: control back")
			_check(cu.lady.s != null and str(cu.lady.s.state) != "talk", "she goes on with her day (%s)" % str(cu.lady.s.state if cu.lady.s else "?"))
			# the coupon in the hand, at the bar
			_check(player.mall.hold("cu_coupon"), "hold the coupon")
			var b = cu.bartender
			_face(b.global_position, b.body.global_position, -6.0)],
		[1.0, func():
			var r: Array = player.interact.find_target()
			_check(r[0] == cu.bartender and r[1] == "TALK", "at the bar: TALK (%s)" % str(r[1]))
			_shot("wsCUCOS-unbaked-bar-approach-coupon")
			player.interact.action()],
		[1.8, func():
			if ui.typing: ui._typed()],
		[0.3, func():
			_check(_line().begins_with("Oh, wow, you have a top-shelf margarita coupon."), "the bartender: " + _line())
			_shot("wsCUCOS-unbaked-bar-coupon-line")
			_cont()],
		[1.0, func():
			_check(_line() == "Here you go.", "Here you go.")
			_cont()],
		[1.5, func():
			if ui.typing: ui._typed()],
		[0.4, func():
			_check(player.mall.has("cu_topshelf") and player.mall.has("cu_doubloon") and not player.mall.has("cu_coupon"), "the coupon is used up; margarita and doubloon in the bag")
			_shot("wsCUCOS-unbaked-bar-gift")
			_cont()],
		[1.4, func():
			_check(not ui.active, "END")
			player.interact.action()],     # again, no coupon: the shop
		[1.6, func():
			if ui.typing: ui._typed()],
		[0.4, func():
			_check(_line() == "Welcome to Cuco's. What can I get for you today?", "the shop's greeting: " + _line())],
		[0.6, func():
			_check(ui.resp_btns.size() == 4, "beer, margarita, top-shelf, Back (%d)" % ui.resp_btns.size())
			_shot("wsCUCOS-unbaked-shop-list")
			ui._choose(0)],
		[1.4, func():
			_check(player.mall.money == 9800 and player.mall.has("cu_beer"), "a beer for $2.00 (wallet %s)" % player.mall.money_text(player.mall.money))
			if ui.typing: ui._typed()
			_shot("wsCUCOS-unbaked-shop-bought")
			_cont()],
		[1.4, func():
			_check(not ui.active, "END")
			player.interact.open_panel(true)],
		[0.5, func():
			_shot("wsCUCOS-unbaked-bag")
			player.interact.open_panel(false)],
	]
	return p
