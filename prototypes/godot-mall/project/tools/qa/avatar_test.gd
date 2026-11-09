## Workstream V (design/godot-avatar.md): the avatar and the first / third person switch, natively,
## unbaked (no lightmap). In one wing:
##   - CHAR-STRIP (Nov 8 2026): the body is the saved cast member (scripts/cast.gd), animated, one of it;
##   - for each spot: third person walking (TP_WALK m/s, the walk clip at ground speed) and running
##     back the way it came (TP_WALK x RUN, the sprint clip at ground speed, the camera pivot on the
##     player, not trailing; WALK, Nov 3 2026) and standing (idle), the camera kept inside the walk
##     grid and off the glass;
##     then first person at the same spot, which must be exactly the old view (player.cam current at
##     eye height, move_scale 1, avatar hidden);
##   - a held item in the avatar's right hand (wing 2: the fuzzy dice);
##   - the fps cost of the avatar: the same third-person view with the body shown and hidden.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/avatar_test.gd -- --wing=2 [--year=2026] --out=/tmp/av/w2 \
##     [--spots="name:x,z,yaw,pitch;..."]
## Prints AVATAR TEST OK (n checks) or the failures; writes <out>-<name>.png.
extends SceneTree

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
	# the player's record (CHAR-STRIP, scripts/cast.gd): the second cast member, third person
	Cast.save_player({"cast": str(Cast.player_ids()[1]), "view": "third"})
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
	av._pivot = Vector3.INF

func _do(c: Callable, w := 0.0) -> void:
	q.append([c, w])

func _plan() -> void:
	_do(func(): pass, 2.0)
	_do(func():
		av = player.get_node_or_null("Avatar")
		_check(av != null, "player has its Avatar node")
		_check(av.body != null and av.body.is_inside_tree() and av.body.skin != null, "body built (%s)" % (av.body.id if av.body else "-"))
		_check(av.cast_id == str(Cast.player_ids()[1]) and av.body.get_meta("cast", "") == av.cast_id, "the body is the saved cast member (%s)" % av.cast_id)
		_check(get_nodes_in_group("mall_player_body").size() == 1, "exactly one player body")
		_check(av.third, "saved view third person is read"), 0.5)
	_do(func():
		var b = av.body
		_check(b.ap != null and b.ap.is_playing() and str(b.ap.current_animation) != "", "the body is animated, not in its T-pose (%s: %s)" % [b.id, b.ap.current_animation if b.ap else "-"]), 0.0)
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
			_check(av._free(cp.x, cp.z) or av._boom < 0.05, "%s: camera clear of walls and glass (boom %.2f m, side %d)" % [nm, av._boom, av._side])
			_check(cp.y <= av.CAM_TOP + 0.01 and cp.y >= av.CAM_LOW - 0.01, "%s: camera under the hanging signs (%.2f m)" % [nm, cp.y])
			_shot("tp-walk-" + nm), 0.0)
		# WALK: running (the run action held with the stick) is TP_WALK x RUN = 6.6 m/s on the sprint clip,
		# played at ground speed; the camera's pivot sits on the player (it used to trail at speed)
		_do(func():
			# back the way it came (the walk just proved that floor; 6.6 m on could be a prize counter's
			# closer look, which freezes the player: Pocket Change)
			player.yaw += PI; player._apply_rot()
			if not InputMap.has_action("mall_run"): InputMap.add_action("mall_run")
			Input.action_press("mall_run"), 1.0)
		_do(func():
			var b = av.body
			var own := float(NpcBody.meta().clips.get(b.clip, {}).get("mps", 1.0))
			var want_s: float = av.TP_WALK * player.RUN
			_check(str(b.clip) == "sprint" or str(b.clip) == "run", "%s: running plays a run clip (%s)" % [nm, b.clip])
			_check(absf(b.ap.speed_scale - av._speed / own) < 0.05 and absf(av._speed - want_s) < 0.35 and b.ap.speed_scale <= av.GAIT_MAX,
				"%s: run at ground speed: %.2f m/s (want %.1f) / %.3f = x%.2f (playing x%.2f)" % [nm, av._speed, want_s, own, av._speed / own, b.ap.speed_scale])
			var cp: Vector3 = av.tp_cam.global_position
			var pv: Vector3 = player.position + Vector3(0, av.PIVOT_H, 0) + Basis(Vector3.UP, player.yaw) * av._pivot
			var back: float = (cp - pv).dot(player.transform.basis.z)   # along the boom, behind the player
			# the pivot sits on the player (at most a shoulder off; V's glide trailed it by v/6 = 1.1 m here)
			_check(Vector2(pv.x - player.position.x, pv.z - player.position.z).length() <= av.SHOULDER + 0.08,
				"%s: the camera pivot rides the player at speed (%.2f m off, side %d)" % [nm, Vector2(pv.x - player.position.x, pv.z - player.position.z).length(), av._side])
			_check(back >= -0.01 and back <= av.BOOM + 0.01, "%s: camera %.2f m behind the player (boom %.2f; 0 in a tight spot)" % [nm, back, av._boom])
			_check(av._free(cp.x, cp.z) or av._boom < 0.05, "%s: running camera clear of walls and glass" % nm)
			_check(player._free(player.position.x, player.position.z), "%s: the runner stands on free floor (walls and glass held)" % nm)
			_shot("tp-run-" + nm), 0.0)
		_do(func(): Input.action_release("mall_run"); Input.action_release("ui_up"), 1.2)
		_do(func():
			_check(not str(av.body.clip).begins_with("walk") and not str(av.body.clip) in ["sprint", "run", "jog"], "%s: standing plays idle (%s)" % [nm, av.body.clip])
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
			_check(player.interact.hand_item.get_parent() == player.interact.hand_root, "first person: the item is back in the first-person hand")
			# the "You received" card (scripts/received_popup.gd, after V) froze the player on take():
			# dismiss it, as a tap would, or VR below finds the player frozen
			for c in player.interact.get_children():
				if c.has_method("is_showing") and c.has_method("dismiss") and c.is_showing():
					c.dismiss(), 0.0)
	# VR: always first person, whatever is saved (vr.gd sets player.vr_on; its own XR camera then)
	if not spots.is_empty():
		_do(func(): av.third = true; _at(spots[0][1]); player.vr_on = true, 0.5)
		_do(func():
			var was: bool = av.third
			av.toggle_view()
			_check(not av.body.visible and not av.tp_cam.current and not av.view_btn.visible and av.third == was
				and is_equal_approx(player.move_scale, 1.0), "VR: no avatar, no third-person camera, V ignored, buttons hidden, speed x1")
			player.vr_on = false, 0.5)
		_do(func():
			_check(av.tp_cam.current and av.body.visible, "leaving VR: back to the saved third person (cam %s, body %s, boom %.2f, leaving %s, frozen %s)" % [av.tp_cam.current, av.body.visible, av._boom, player.leaving, player.frozen]), 0.0)
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
