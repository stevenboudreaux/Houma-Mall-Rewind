## CHAR-STRIP (Nov 8 2026; design/godot-avatar.md "The counting test", design/godot-characters-research.md
## section 3 rule 5): the test that counts. After the load, a menu open / close, a pick in MAIN's Character
## row, a reload, a wing crossing, a year crossing and a time-travel trip there is exactly one Skeleton3D
## under the player group (the player node and the body in "mall_player_body"), its cast id is the saved
## one ("mall-player-2"), and MAIN's portrait shows the same id. A watcher counts every frame in between,
## crossings included: never two bodies, not even for a frame. The old records ("mall-avatar-1",
## "mall-avatar-preset-1") are planted first and must be read for the name and deleted.
## Counter attendants hang under the Player node (Story > Attendant, group "talker") and are not counted.
## Native, unbaked (LightmapGI removed), small scenes (wing 6, the cinema lobby; wing 4, Sears / Lynn's),
## then wing 1 (attendants):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/cast_count_test.gd -- --out=<prefix>
## Prints CAST COUNT OK (n checks) or the failures, and one line per step for wsSTRIP-count-test.md;
## writes <prefix>-<step>.png (third person).
extends SceneTree

var out := "/tmp/castcount/t"
var scn: Node
var player: Node3D
var errors := []
var oks := 0
var steps := []           # [step, skeletons, cast id, saved id, portrait id]
var max_seen := 0         # the most player skeletons the per-frame watcher saw
var frames_watched := 0
var watch_on := false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("menu_opening", false)
	Engine.set_meta("mall_player_name", "")
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_state_2026", "")
	# a returning player from before CHAR-STRIP: both old records, the name only in the preset
	Cast._kv_del(Cast.KEY)
	Engine.set_meta("mall_avatar", JSON.stringify({"v": 1, "done": true, "view": "third", "body": "Ch21"}))
	Engine.set_meta("ls_mall_avatar_preset_1", JSON.stringify({"id": "", "name": "OLDNAME", "body": "female"}))
	process_frame.connect(_watch)
	await process_frame
	await _run()
	_end()

func _end() -> void:
	print("STEPS step | skeletons | world body | saved | portrait")
	for s in steps:
		print("STEP %s | %d | %s | %s | %s" % s)
	print("WATCH %d frames, at most %d player skeleton(s) in any frame" % [frames_watched, max_seen])
	if errors.is_empty() and oks > 0:
		print("CAST COUNT OK (%d checks)" % oks)
	else:
		print("CAST COUNT FAILED (%d of %d): %s" % [errors.size(), errors.size() + oks, ", ".join(errors)])
	quit(0 if errors.is_empty() and oks > 0 else 1)

func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _secs(s: float) -> void:
	await create_timer(s).timeout

func _shot(name: String) -> void:
	for i in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])

func _in_subviewport(n: Node) -> bool:
	var c := n.get_parent()
	while c:
		if c is SubViewport: return true
		c = c.get_parent()
	return false

## A counter attendant's body (Player > Story > Attendant, group "talker"): not the player's.
func _in_attendant(n: Node) -> bool:
	var c := n.get_parent()
	while c:
		if c.is_in_group("talker"): return true
		c = c.get_parent()
	return false

## Skeletons under the player group: under the player node(s) and the player body(ies). world_only: not
## the ones on a SubViewport stage (the open menu's portraits, which live under the player's Menu node).
func _player_skeletons(world_only := false) -> Array:
	var outs := []
	for g in ["mall_player", "mall_player_body"]:
		for n in get_nodes_in_group(g):
			if not n.is_inside_tree() or n.is_queued_for_deletion() or _in_subviewport(n):
				continue
			for sk in n.find_children("*", "Skeleton3D", true, false):
				if world_only and _in_subviewport(sk):
					continue
				if _in_attendant(sk):
					continue
				if not sk.is_queued_for_deletion() and not (sk in outs):
					outs.append(sk)
	return outs

## Every frame: no two player skeletons in the world, ever (a scene change frees the old scene with its body).
func _watch() -> void:
	if not watch_on:
		return
	frames_watched += 1
	max_seen = maxi(max_seen, _player_skeletons(true).size())

func _count(step: String) -> void:
	var sks := _player_skeletons()
	var av = player.avatar
	var body = av.body if av else null
	var bid: String = str(body.get_meta("cast", "")) if body else "-"
	var saved := Cast.player_id()
	var pid := "-"
	var menu = player.get_node("Menu")
	menu.open_tab("main")
	await _secs(0.6)
	var por = menu._root.find_child("MainPortrait", true, false) if menu._root else null
	if por: pid = str(por.cast_id)
	_check(sks.size() == 1, "%s: exactly one Skeleton3D under the player group (%d)" % [step, sks.size()])
	_check(body != null and sks.size() == 1 and body.is_ancestor_of(sks[0]), "%s: it is the avatar's body" % step)
	_check(bid == saved, "%s: its cast id is the saved one (%s / %s)" % [step, bid, saved])
	_check(pid == saved, "%s: MAIN's portrait is the same id (%s)" % [step, pid])
	steps.append([step, sks.size(), bid, saved, pid])
	await _shot(step + "-menu")
	menu.close()
	await _secs(0.4)
	_check(_player_skeletons().size() == 1, "%s: still exactly one after the menu closed (no portrait body left: %d)" % [step, _player_skeletons().size()])
	await _shot(step)

func _after_load() -> void:
	scn = current_scene
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "day")
	player = scn.get_node("Player")
	await _secs(1.5)
	player.avatar.third = true
	player.pitch = deg_to_rad(-8)
	player._apply_rot()
	await _secs(1.0)

func _load(path: String) -> void:
	var old := current_scene
	change_scene_to_file(path)
	await _until_new(old)
	await _after_load()

func _until_new(old: Node) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 120000:
		await process_frame
		if current_scene != null and current_scene != old and current_scene.get_node_or_null("Player") != null:
			return
	_check(false, "a new scene in 120 s")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	watch_on = true
	await _load("res://wing6.tscn")
	# the old records: read once for the name, then gone
	_check(not Engine.has_meta("mall_avatar") and not Engine.has_meta("ls_mall_avatar_preset_1"), "the old avatar records are deleted")
	_check(player.mall.player_name == "OLDNAME", "the name came over from the old preset (%s)" % player.mall.player_name)
	_check(Cast.player_id() == str(Cast.roster().default), "a returning player starts as the default cast member")
	await _count("load")
	# the menu: open, close, open, close
	var menu = player.get_node("Menu")
	for i in 2:
		menu.open_tab("main"); await _secs(0.5); menu.close(); await _secs(0.3)
	await _count("menu-open-close")
	# a pick in the Character row (the third member), through MAIN's own button
	menu.open_tab("main")
	await _secs(0.6)
	var pick := str(Cast.player_ids()[2])
	var btn: Button = menu._root.find_child("Cast_" + pick, true, false)
	_check(btn != null, "MAIN has the Character button for %s" % pick)
	if btn: btn.pressed.emit()
	await _secs(0.8)
	_check(Cast.player_id() == pick, "the pick is saved (%s)" % Cast.player_id())
	menu.close()
	await _secs(0.3)
	await _count("pick")
	# a reload (the same wing again, as a page reload rebuilds it)
	await _load("res://wing6.tscn")
	await _count("reload")
	# a wing crossing, the game's own way (player._go_to_wing: fade, then the other wing's scene)
	var old := current_scene
	player._go_to_wing(4, player.position.x, player.position.z, player.yaw, player.pitch)
	await _until_new(old)
	await _after_load()
	await _count("wing-crossing")
	# a year crossing (the year's own scene, as the ?year=2026 reload loads it)
	await _load("res://wing4_2026.tscn")
	await _count("year-crossing")
	# a time-travel trip back to 1995 (the directory's trip; a stand-in kiosk where the player stands)
	var k := Node3D.new()
	scn.add_child(k)
	k.position = player.position
	old = current_scene
	load("res://scripts/timetravel_trip.gd").begin(player, k)
	await _until_new(old)
	await _after_load()
	await _secs(4.0)       # the vortex's outro
	_check(int(player.year) == 1995, "time travel arrived in 1995")
	await _count("time-travel")
	# a wing with counter attendants (wing 1): they hang under the Player node (Story), and are not the player
	await _load("res://wing1.tscn")
	var att := 0
	for t in get_nodes_in_group("talker"):
		att += t.find_children("*", "Skeleton3D", true, false).size()
	_check(att > 0, "wing 1: the attendants' bodies are there (%d skeletons, not counted as the player's)" % att)
	await _count("wing1-attendants")
	watch_on = false
	_check(max_seen == 1, "the per-frame watcher never saw two player skeletons in the world (%d frames, max %d)" % [frames_watched, max_seen])
