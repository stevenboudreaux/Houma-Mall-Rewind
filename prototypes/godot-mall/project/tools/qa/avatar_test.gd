## Workstream V (design/godot-avatar.md): the avatar and the first / third person switch, natively,
## unbaked (no lightmap). In one wing:
##   - the creator: opened, shot at desktop and phone sizes (portrait and landscape), Random, Done;
##   - for each spot: third person walking (the walk clip at ground speed) and standing (idle), the
##     camera kept inside the walk grid and off the glass; then first person at the same spot, which
##     must be exactly the old view (player.cam current at eye height, move_scale 1, avatar hidden);
##   - a held item in the avatar's right hand (wing 2: the fuzzy dice);
##   - the fps cost of the avatar: the same third-person view with the body shown and hidden.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/avatar_test.gd -- --wing=2 [--year=2026] --out=/tmp/av/w2 \
##     [--spots="name:x,z,yaw,pitch;..."]
## Prints AVATAR TEST OK (n checks) or the failures; writes <out>-<name>.png.
extends SceneTree

const Look = preload("res://scripts/avatar_look.gd")
var out := "/tmp/av"
var wing := 2
var year := 1995
var spots := []
var scn: Node
var player: Node3D
var av: Node
var clock := 0.0
var errors := []
var oks := 0
var q := []          # the script: [callable, wait_s]
var qi := 0
var wait := 0.0
var fps_s := {}

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--wing="): wing = int(a.substr(7))
		elif a.begins_with("--year="): year = int(a.substr(7))
		elif a.begins_with("--spots="):
			for c in a.substr(8).split(";"):
				var kv = c.split(":")
				if kv.size() == 2: spots.append([kv[0], kv[1].split(",")])
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_%d" % year, "")
	# a made avatar, so the creator doesn't open by itself; the test opens it
	var L := Look.default_look()
	L.done = true; L.body = "Ch21"; L.skin = "#b47a52"; L.hair = "#151210"
	L.y1995 = {"top": "#1f6f6a", "bottom": "#8fb0d3", "words": "HOUMA"}
	L.y2026 = {"top": "#8fa38a", "bottom": "#151517", "words": "985"}
	L.view = "third"
	Engine.set_meta("mall_avatar", JSON.stringify(L))
	var path := ("res://wing%d_2026.tscn" if year == 2026 else "res://wing%d.tscn") % wing
	scn = load(path).instantiate()
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
	var im := root.get_texture().get_image()
	im.save_png("%s-%s.png" % [out, name])

func _at(v: Array) -> void:
	player.position = Vector3(float(v[0]), 0, float(v[1]))
	player.yaw = deg_to_rad(float(v[2])); player.pitch = deg_to_rad(float(v[3])); player._apply_rot()
	av._last = Vector3.INF
	av._boom = 0.0

func _do(c: Callable, w := 0.0) -> void:
	q.append([c, w])

func _plan() -> void:
	_do(func(): pass, 2.0)
	_do(func():
		av = player.get_node_or_null("Avatar")
		_check(av != null, "player has its Avatar node")
		_check(av.creator == null, "a saved avatar: no creator at start")
		_check(av.body != null and av.body.is_inside_tree() and av.body.skin != null, "avatar body built (%s)" % (av.body.id if av.body else "-"))
		_check(av.third, "saved view third person is read"), 0.5)
	# the creator at three sizes
	for sz in [Vector2i(1280, 720), Vector2i(390, 844), Vector2i(844, 390)]:
		var s: Vector2i = sz
		_do(func():
			DisplayServer.window_set_size(s)
			root.size = s
			if av.creator == null: av.open_creator(), 1.2)
		_do(func():
			_check(av.creator != null and player.frozen, "creator open and the player frozen (%dx%d)" % [s.x, s.y])
			var r: Rect2 = av.creator.root.get_global_rect() if av.creator else Rect2()
			var over := false
			if av.creator:
				for h in av.creator.hits:
					var c: Control = h[0]
					var gr := c.get_global_rect()
					if gr.end.x > s.x + 1 or gr.end.y > s.y + 1 or gr.position.x < -1: over = true
			_check(not over, "every creator control on screen at %dx%d" % [s.x, s.y])
			_shot("creator-%dx%d" % [s.x, s.y]), 0.2)
	_do(func(): av.creator._randomize(), 0.6)
	_do(func(): _shot("creator-random-844x390"); av.creator._done(), 0.6)
	_do(func():
		DisplayServer.window_set_size(Vector2i(1280, 720)); root.size = Vector2i(1280, 720)
		_check(av.creator == null and not player.frozen, "Done closes the creator and frees the player")
		var saved = JSON.parse_string(str(Engine.get_meta("mall_avatar", "")))
		_check(saved is Dictionary and saved.done and str(saved.body) == str(av.look.body), "the look is saved (%s)" % (saved.body if saved is Dictionary else "-"))
		av.third = true, 0.5)
	_do(func():
		var b = av.body
		_check(b.ap != null and b.ap.is_playing() and str(b.ap.current_animation) != "", "the new body is animated, not in its T-pose (%s: %s)" % [b.id, b.ap.current_animation if b.ap else "-"]), 0.0)
	for sp in spots:
		var nm: String = sp[0]
		var v: Array = sp[1]
		_do(func(): av.third = true; _at(v); Input.action_press("ui_up"), 0.9)
		_do(func():
			var b = av.body
			var own := float(NpcBody.meta().clips.get(b.clip, {}).get("mps", 1.0))
			_check(str(b.clip).begins_with("walk"), "%s: walking plays a walk clip (%s)" % [nm, b.clip])
			var want: float = av._speed / own
			_check(absf(b.ap.speed_scale - want) < 0.05 and absf(av._speed - av.TP_WALK) < 0.25,
				"%s: clip at ground speed: %.2f m/s / %.3f = x%.2f (playing x%.2f)" % [nm, av._speed, own, want, b.ap.speed_scale])
			_check(av.tp_cam.current, "%s: the third-person camera is current" % nm)
			var cp: Vector3 = av.tp_cam.global_position
			_check(av._free(cp.x, cp.z, av._high > 0.5) or av._boom < 0.05, "%s: camera clear of walls and glass (boom %.2f m)" % [nm, av._boom])
			_shot("tp-walk-" + nm), 0.0)
		_do(func(): Input.action_release("ui_up"), 1.2)
		_do(func():
			_check(not str(av.body.clip).begins_with("walk"), "%s: standing plays idle (%s)" % [nm, av.body.clip])
			_shot("tp-idle-" + nm), 0.0)
		_do(func(): av.third = false, 0.4)
		_do(func():
			_check(player.cam.current and not av.body.visible and is_equal_approx(player.move_scale, 1.0)
				and is_equal_approx(player.cam.position.y, player.EYE), "%s: first person = the old view (eye camera, speed x1, no body)" % nm)
			_shot("fp-" + nm), 0.0)
	# a held item in the right hand (wing 2, 1995: the fuzzy dice from Pocket Change)
	if wing == 2 and year == 1995 and not spots.is_empty():
		_do(func():
			player.mall.take("dice", true)
			av.third = true
			_at(spots[spots.size() - 1][1])
			player.yaw += PI * 0.75; player._apply_rot(), 1.0)
		_do(func():
			var it = player.interact
			_check(it.hand_item != null and it.hand_item.get_parent() == av._grip(), "the held item is in the avatar's right hand")
			_shot("tp-hand"), 0.0)
		_do(func(): av.third = false, 0.4)
		_do(func():
			_check(player.interact.hand_item.get_parent() == player.interact.hand_root, "first person: the item is back in the first-person hand"), 0.0)
	# fps cost: one view, the avatar shown vs hidden (a debug hide; the view and camera stay)
	if not spots.is_empty():
		_do(func(): av.third = true; _at(spots[0][1]), 1.0)
		_do(func(): fps_s["t0"] = Time.get_ticks_usec(); fps_s["f0"] = Engine.get_frames_drawn(), 4.0)
		_do(func():
			fps_s["shown"] = (Time.get_ticks_usec() - fps_s.t0) / 1000.0 / maxf(1.0, Engine.get_frames_drawn() - fps_s.f0)
			fps_s["prim1"] = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			fps_s["draw1"] = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			av.set_meta("qa_hide", true), 1.0)
		_do(func(): fps_s["t0"] = Time.get_ticks_usec(); fps_s["f0"] = Engine.get_frames_drawn(), 4.0)
		_do(func():
			fps_s["hidden"] = (Time.get_ticks_usec() - fps_s.t0) / 1000.0 / maxf(1.0, Engine.get_frames_drawn() - fps_s.f0)
			var prim0 := Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			var draw0 := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			printerr("FPS avatar adds %d triangles and %d draw calls to %d / %d (body %s)" % [fps_s.prim1 - prim0, fps_s.draw1 - draw0, prim0, draw0, av.body.id])
			av.remove_meta("qa_hide")
			printerr("FPS avatar shown %.2f ms/frame, hidden %.2f ms/frame (native llvmpipe, %s)" % [fps_s.shown, fps_s.hidden, spots[0][0]]), 0.0)

func _process(dt: float) -> bool:
	wait -= dt
	if wait > 0.0:
		return false
	if qi >= q.size():
		printerr("AVATAR TEST OK (%d checks)" % oks if errors.is_empty() else "AVATAR TEST FAILED: " + str(errors))
		return true
	var c: Callable = q[qi][0]
	wait = float(q[qi][1])
	qi += 1
	c.call()
	return false
