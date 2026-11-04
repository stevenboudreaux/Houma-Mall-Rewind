## CHAR-EDITOR (design/godot-character-editor.md "The one-body bug"): exactly one avatar body after a
## save, a reload, a year change and a time-travel trip; the menu's MAIN portrait is the saved
## character; the creator's flow (Save stays open, Back leaves). Native, unbaked (LightmapGI removed):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/char_avatar_test.gd -- --out=<prefix> [--late=1]
## --late=1 starts the avatar on V's body and mounts the character pack afterwards (what the web does:
## the pack arrives after the loading card), so the swap is tested too.
## Prints CHAR AVATAR OK (n checks) or the failures; writes <prefix>-<name>.png.
extends SceneTree

const Look = preload("res://scripts/avatar_look.gd")
var out := "/tmp/charav/t"
var late := false
var wing := 6         # wing 6 (the cinema lobby) by default: the smallest scene (the shared cloud box runs out of memory on wing 1)
var scn: Node
var player: Node3D
var errors := []
var oks := 0
const DESK := Vector2i(1280, 720)
const PHONE := Vector2i(390, 844)
const SPOT := Vector3(30, 0, 0)        # wing 1's hall (design/godot-avatar.md checks)

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--late="): late = a.substr(7) == "1"
		elif a.begins_with("--wing="): wing = int(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("menu_opening", false)
	Engine.set_meta("mall_player_name", "TESTER")
	var L := Look.default_look()      # V's default: Ch01, bald: the body the bug left standing
	L.done = true; L.view = "third"
	Engine.set_meta("mall_avatar", JSON.stringify(L))
	CharPreset.local_set(CharPreset.PLAYER_KEY, "")
	await process_frame
	await _run()
	_end()

func _end() -> void:
	if errors.is_empty() and oks > 0:
		print("CHAR AVATAR OK (%d checks)" % oks)
	else:
		print("CHAR AVATAR FAILED (%d of %d): %s" % [errors.size(), errors.size() + oks, ", ".join(errors)])
	quit(0 if errors.is_empty() and oks > 0 else 1)

func _check(ok: bool, what: String) -> void:
	print(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _wait(n: int) -> void:
	for i in n: await process_frame

func _secs(s: float) -> void:
	await create_timer(s).timeout

func _shot(name: String) -> void:
	await _wait(3)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])
	print("wrote %s-%s.png" % [out, name])

func _size(s: Vector2i) -> void:
	root.size = s
	DisplayServer.window_set_size(s)
	await _wait(4)

## Load a wing scene as the current scene (unbaked), the player at the hall spot.
func _load(path: String) -> void:
	# as the game does it (the scene is current before its nodes' _ready run)
	var old := current_scene
	change_scene_to_file(path)
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 120000:
		await process_frame
		if current_scene != null and current_scene != old and current_scene.get_node_or_null("Player") != null: break
	scn = current_scene
	await _after_load()

func _after_load() -> void:
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "day")
	player = scn.get_node("Player")
	var sh = scn.get_node_or_null("Shoppers")
	if sh: sh.queue_free()
	await _secs(1.5)
	if wing == 1:
		player.position = SPOT
		player.yaw = deg_to_rad(90)
	player.pitch = deg_to_rad(-8)
	player._apply_rot()
	await _secs(1.0)

## Every avatar body in the mall's world (not inside a SubViewport: the editor's turntable and the
## menu's portrait have their own worlds), shown or hidden.
func _world_bodies() -> Array:
	var outb := []
	for n in current_scene.find_children("*", "NpcBody", true, false):
		if n is AvatarChar or n.get_script() == load("res://scripts/avatar_body.gd"):
			if _in_subviewport(n): continue
			outb.append(n)
	return outb

func _in_subviewport(n: Node) -> bool:
	var c := n.get_parent()
	while c:
		if c is SubViewport: return true
		c = c.get_parent()
	return false

## Visible meshes drawn as the avatar (any body, any skin) in the world at the player's spot.
func _visible_bodies() -> Array:
	return _world_bodies().filter(func(b): return b.is_visible_in_tree())

func _one_body(when: String, want_hair := "") -> void:
	var all := _world_bodies()
	var vis := _visible_bodies()
	var names := all.map(func(b): return "%s(%s)" % [b.name, "AvatarChar" if b is AvatarChar else "AvatarBody"])
	_check(all.size() == 1, "%s: exactly one avatar body in the world: %s" % [when, names])
	_check(vis.size() <= 1, "%s: at most one shown" % when)
	if all.size() == 1:
		_check(all[0] is AvatarChar and all[0] == player.avatar.body, "%s: it is the preset body (AvatarChar) the avatar drives" % when)
		if want_hair != "" and all[0] is AvatarChar:
			var hs := []
			for k in all[0].pieces: if str(all[0].pieces[k].slot) == "hair": hs.append(str(all[0].pieces[k].base_id))
			_check(hs == [want_hair], "%s: wears the saved hair %s: %s" % [when, want_hair, hs])
		# the old skins are gone (no second Skeleton3D drawn under the body)
		var sks: Array = all[0].find_children("*", "Skeleton3D", true, false).filter(func(s): return s.is_inside_tree() and not s.is_queued_for_deletion())
		_check(sks.size() == 1, "%s: one skeleton under the body (%d)" % [when, sks.size()])

func _run() -> void:
	if late: Engine.set_meta("qa_late_chars", true)
	await _load("res://wing%d.tscn" % wing)
	await _size(DESK)
	if late:
		_check(not (player.avatar.body is AvatarChar), "late pack: the avatar starts on V's body")
		Engine.remove_meta("qa_late_chars")
		player.get_node("CharPack")._done()
		await _secs(1.0)
	_one_body("start")
	await _shot("start-third")
	# the menu: MAIN's portrait is the preset body, not V's bald default
	var menu = player.get_node("Menu")
	menu.open_tab("main")
	await _secs(1.0)
	var por = _portrait(menu)
	_check(por != null and por.body is AvatarChar, "MAIN's portrait is the preset body (not V's default)")
	await _shot("menu-main-before")
	# the creator: Edit
	menu.edit_avatar()
	await _secs(1.2)
	var c = menu._creator
	_check(c != null and str(c.get_script().resource_path).ends_with("char_editor.gd"), "Edit opens the character editor")
	_check(c.tabs == ["body", "look", "outfit"], "three tabs: %s" % [c.tabs])
	await _shot("creator-body")
	# an edit on every tab
	var sex: String = c.preset.body
	c._apply_shape("Curvy Missy" if sex == "female" else "Athletic")
	c._set_key(0.4, "shoulders"); c._set_key(-0.3, "waist"); c._set_key(0.3, "head_size")
	await _secs(0.4)
	_check(c.dirty and c._save_btn.text == "Save", "an edit lights Save")
	c._toggle_adv()
	await _secs(0.3)
	await _shot("creator-body-more")
	c._toggle_adv()
	c._go_tab("look")
	var want_hair := "hair_long" if c.preset.hair.id != "hair_long" else "hair_shoulder"
	c._slot_set("hair", want_hair)
	c.preset.hair.color = "#b0502a"; c._changed("paint")
	await _secs(0.5)
	await _shot("creator-look")
	c._go_tab("outfit")
	c.preset.outfit.colors["top_tee"] = {"main": "#1f6f6a"}; c._changed("paint")
	await _secs(0.4)
	await _shot("creator-outfit")
	# Save: stays open, the avatar changes now
	c._save()
	await _secs(1.0)
	_check(menu._creator == c and not c.dirty and c._save_btn.text.begins_with("Saved"), "Save keeps the editor open and shows Saved")
	_check(not CharPreset.player_preset().is_empty() and CharPreset.player_preset().hair.id == want_hair, "Save stores the player's preset")
	_one_body("after Save", want_hair)
	await _shot("creator-saved")
	# Back: to MAIN, the portrait shows the saved character
	c._back()
	await _secs(1.2)
	_check(menu._creator == null and not menu.editing, "Back returns to MAIN")
	por = _portrait(menu)
	var ph := []
	if por and por.body is AvatarChar:
		for k in por.body.pieces: if str(por.body.pieces[k].slot) == "hair": ph.append(str(por.body.pieces[k].base_id))
	_check(ph == [want_hair], "MAIN's portrait wears the saved hair: %s" % [ph])
	await _shot("menu-main-after")
	# Back with unsaved changes asks once
	menu.edit_avatar()
	await _secs(1.0)
	c = menu._creator
	c._set_key(0.8, "weight")
	c._back()
	_check(menu._creator == c, "Back with unsaved changes asks first")
	c._back()
	await _secs(0.8)
	_check(menu._creator == null and is_equal_approx(float(CharPreset.player_preset().keys.get("weight", 0.0)), float(CharPreset.player_preset().keys.get("weight", 0.0))) \
		and float(CharPreset.player_preset().keys.get("weight", 0.0)) < 0.7, "the second Back drops the change")
	# the phone
	await _size(PHONE)
	menu.edit_avatar()
	await _secs(1.2)
	await _shot("creator-phone-body")
	menu._creator._go_tab("look")
	await _secs(0.4)
	await _shot("creator-phone-look")
	menu.close()
	await _secs(0.8)
	await _size(DESK)
	_one_body("after the menu closed", want_hair)
	await _shot("after-save-third")
	# reload (same wing), year change, time travel
	if late: Engine.set_meta("qa_late_chars", true)
	await _load("res://wing%d.tscn" % wing)
	if late:
		Engine.remove_meta("qa_late_chars")
		player.get_node("CharPack")._done()
		await _secs(1.0)
	_one_body("after a reload", want_hair)
	await _shot("reload-third")
	await _load("res://wing%d_2026.tscn" % wing)
	_one_body("in 2026", want_hair)
	await _shot("year-2026-third")
	# time travel from here back to 1995 (the directory's trip; a stand-in kiosk where the player is)
	var k := Node3D.new()
	scn.add_child(k)
	k.position = player.position
	load("res://scripts/timetravel_trip.gd").begin(player, k)
	var t0 := Time.get_ticks_msec()
	var old := scn
	while Time.get_ticks_msec() - t0 < 60000:
		await _secs(0.5)
		if current_scene != old and current_scene != null and current_scene.get_node_or_null("Player") != null: break
	_check(current_scene != old, "time travel changed the scene")
	scn = current_scene
	await _after_load()
	await _secs(4.0)       # the vortex's outro
	_one_body("after time travel", want_hair)
	await _shot("timetravel-third")

func _portrait(menu) -> Node:
	if menu._root == null: return null
	for n in menu._root.find_children("*", "SubViewportContainer", true, false):
		if n.get_script() == load("res://scripts/menu/portrait.gd"): return n
	return null
