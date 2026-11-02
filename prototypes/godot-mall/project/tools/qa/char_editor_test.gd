## B2 (design/godot-character-editor.md): presets, the base rule, baking, the owner's editor on an
## attendant, the player's editor in the menu's AVATAR tab and the avatar in third person. Native,
## unbaked (LightmapGI removed):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/char_editor_test.gd -- --wing=1 --out=/tmp/b2/w1 [--only=unit]
## Prints CHAR EDITOR OK (n checks) or the failures; writes <out>-<name>.png.
extends SceneTree

const Look = preload("res://scripts/avatar_look.gd")
var out := "/tmp/b2/w1"
var wing := 1
var only := ""
var scn: Node
var player: Node3D
var errors := []
var oks := 0
const DESK := Vector2i(1280, 720)
const PHONE := Vector2i(390, 844)

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--wing="): wing = int(a.substr(7))
		elif a.begins_with("--only="): only = a.substr(7)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	await process_frame
	await _unit()
	if only == "unit":
		_end(); return
	await _mall()
	_end()

func _end() -> void:
	if errors.is_empty() and oks > 0:
		print("CHAR EDITOR OK (%d checks)" % oks)
	else:
		print("CHAR EDITOR FAILED (%d of %d): %s" % [errors.size(), errors.size() + oks, ", ".join(errors)])
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

# ------------------------------------------------------------------ the rules, no scene
func _unit() -> void:
	var host := Node3D.new()
	root.add_child(host)
	# the base rule in normalize()
	var f := CharPreset.normalize({"body": "female", "outfit": {"top": "top_tee"}})
	_check(f.outfit.base_top != "" and f.outfit.base_bottom != "", "female preset missing both base pieces gets a base top and bottom")
	var m := CharPreset.normalize({"body": "male", "outfit": {}})
	_check(m.outfit.base_bottom != "" and m.outfit.base_top == "", "male preset gets a base bottom, base top optional (none)")
	var m2 := CharPreset.normalize({"body": "male", "outfit": {"base_top": "base_tank"}})
	_check(m2.outfit.base_top == "base_tank", "male base top kept when chosen")
	var f2 := CharPreset.normalize({"body": "female", "outfit": {"base_top": "", "base_bottom": ""}})
	_check(f2.outfit.base_top == "base_sportsbra" and f2.outfit.base_bottom == "base_briefs", "female empty base slots -> defaults")
	var one := CharPreset.normalize({"body": "female", "outfit": {"base_bottom": "base_onepiece"}})
	_check(one.outfit.base_top == "base_onepiece" and one.outfit.base_bottom == "base_onepiece", "one-piece fills both base slots")
	var st := CharPreset.stripped(CharPreset.get_preset("pocket_change", false))
	var worn := []
	for e in CharPreset.worn(st): worn.append(str(e.slot))
	worn.sort()
	_check(worn == ["base_bottom", "base_top", "hair"], "strip to base (female) leaves exactly base top + base bottom (+ hair): %s" % [worn])
	var stm := CharPreset.stripped(CharPreset.get_preset("sound_shop", false))
	worn = []
	for e in CharPreset.worn(stm): worn.append(str(e.slot))
	worn.sort()
	_check(worn == ["base_bottom", "hair"], "strip to base (male, no base top) leaves the base bottom (+ hair): %s" % [worn])
	var fu := CharPreset.normalize({"body": "female", "outfit": {"top": "top_tee", "bottom": "bot_jeans", "full": "full_cheer"}})
	_check(fu.outfit.top == "" and fu.outfit.bottom == "" and fu.outfit.full == "full_cheer", "a full outfit replaces top and bottom")
	# the base rule in the loader itself
	var cb := CharBody.new()
	host.add_child(cb)
	cb.make("female")
	var slots := []
	for k in cb.pieces: slots.append(str(cb.pieces[k].slot))
	_check(slots.has("base_top") and slots.has("base_bottom"), "CharBody.make(female) wears a base top and bottom: %s" % [slots])
	var top_id := ""
	for k in cb.pieces:
		if str(cb.pieces[k].slot) == "base_top": top_id = k
	_check(not cb.take_off(top_id), "CharBody.take_off refuses a female base top")
	cb.wear("base_onepiece")
	cb.wear("base_lacebra")
	slots = []
	for k in cb.pieces: slots.append(str(cb.pieces[k].slot))
	_check(slots.has("base_top") and slots.has("base_bottom"), "female: one-piece swapped for a bra keeps a base bottom: %s" % [slots])
	cb.wear("top_tee"); cb.wear("bot_jeans")
	cb.strip_to_base()
	slots = []
	for k in cb.pieces: slots.append(str(cb.pieces[k].slot))
	slots.sort()
	_check(slots == ["base_bottom", "base_top"], "CharBody.strip_to_base (female) leaves base top + bottom: %s" % [slots])
	var cm := CharBody.new()
	host.add_child(cm)
	cm.make("male")
	slots = []
	for k in cm.pieces: slots.append(str(cm.pieces[k].slot))
	_check(slots == ["base_bottom"], "CharBody.make(male) wears only a base bottom: %s" % [slots])
	# presets: each repo file builds, bakes, and the bake keeps the shape
	for id in CharPreset.list_ids():
		var p := CharPreset.get_preset(id, false)
		_check(not p.is_empty() and str(p.name).begins_with("PLACEHOLDER"), "preset %s loads and is a PLACEHOLDER" % id)
		var live := CharPreset.body_for(p, false)
		host.add_child(live)
		var baked := CharPreset.body_for(p, true)
		host.add_child(baked)
		await _wait(2)
		var a := _aabb(live)
		var b := _aabb(baked)
		_check(a.size.distance_to(b.size) < 0.01, "preset %s bake keeps the body's size (%s vs %s)" % [id, a.size, b.size])
		var bs := 0
		for mi in baked.sk.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh: bs += mi.mesh.get_blend_shape_count()
		_check(bs == 0, "preset %s baked: no blend shapes left (%d)" % [id, bs])
		print("preset %s: %d tris, pieces %s" % [id, CharPreset.tris(baked), baked.pieces.keys()])
		live.queue_free(); baked.queue_free()
	# save / download round trip
	var p := CharPreset.get_preset("kay_bee", false)
	p.keys.weight = 0.3
	CharPreset.save_local("kay_bee", p)
	_check(is_equal_approx(float(CharPreset.get_preset("kay_bee").keys.weight), 0.3), "save_local -> get_preset prefers this browser's edit")
	var path := CharPreset.download("kay_bee", p)
	var j = JSON.parse_string(FileAccess.get_file_as_string(path))
	_check(j is Dictionary and is_equal_approx(float(j.keys.weight), 0.3) and j.id == "kay_bee", "download writes the preset JSON (%s)" % path)
	CharPreset.forget_local("kay_bee")
	_check(not CharPreset.has_local("kay_bee"), "forget_local drops the browser edit")
	host.queue_free()

func _aabb(cb: CharBody) -> AABB:
	var a := AABB()
	var first := true
	for mi in cb.sk.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null or str(mi.get_meta("piece", "")) != "": continue
		var bb: AABB = mi.mesh.get_aabb() if mi.mesh.get_blend_shape_count() == 0 else _blended_aabb(mi)
		a = bb if first else a.merge(bb)
		first = false
	return a

func _blended_aabb(mi: MeshInstance3D) -> AABB:
	var tmp := mi.duplicate() as MeshInstance3D
	var m := mi.mesh
	for i in m.get_blend_shape_count(): tmp.set_blend_shape_value(i, mi.get_blend_shape_value(i))
	CharPreset.bake_mesh(tmp)
	var bb := tmp.mesh.get_aabb()
	tmp.free()
	return bb

# ------------------------------------------------------------------ in the mall
func _mall() -> void:
	Engine.set_meta("mall_owner", true)
	Engine.set_meta("menu_opening", false)
	Engine.set_meta("mall_player_name", "TESTER")
	var L := Look.default_look()
	L.done = true; L.view = "first"
	Engine.set_meta("mall_avatar", JSON.stringify(L))
	scn = load("res://wing%d.tscn" % wing).instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "day")
	player = scn.get_node("Player")
	var sh = scn.get_node_or_null("Shoppers")
	if sh: sh.queue_free()
	await _secs(2.0)
	var atts := get_nodes_in_group("talker")
	var mine := []
	for a in atts:
		if a.has_method("preset_id") and a.preset_id() != "": mine.append(a)
	_check(not mine.is_empty(), "attendants in wing %d wear presets: %s" % [wing, mine.map(func(a): return a.preset_id())])
	for a in mine:
		_check(a.body is CharBody and bool(a.body.get_meta("baked", false)), "%s: a baked CharBody (not the Mixamo skin)" % a.preset_id())
	if mine.is_empty(): return
	var att = mine[0]
	var id: String = att.preset_id()
	# stand at the counter, facing the attendant
	_stand_at(att)
	await _secs(1.0)
	var co = player.get_node_or_null("CharOwner")
	_check(co != null and player.get_node_or_null("CharPack") != null, "the player made CharPack and CharOwner")
	if co == null: return
	_check(not co.nearest().is_empty() and co.btn.visible, "owner near %s: the Edit character button shows" % id)
	await _shot("att-%s-before" % id)
	# K opens the editor
	var k := InputEventKey.new(); k.physical_keycode = KEY_K; k.keycode = KEY_K; k.pressed = true
	Input.parse_input_event(k)
	await _wait(6)
	var ed = co.editor
	_check(ed != null, "K opens the editor on %s" % id)
	if ed == null: return
	await _secs(1.5)
	for sz in [DESK, PHONE]:
		await _size(sz)
		var tag := "desk" if sz == DESK else "phone"
		for t in ed.tabs:
			ed._go_tab(t)
			if t == "outfit" and sz == PHONE: ed._scroll = 0.0
			await _secs(0.4)
			await _shot("editor-%s-%s" % [tag, t])
		ed._go_tab("outfit")
		ed._strip()
		await _secs(0.5)
		var slots := []
		for kk in ed.pv.pieces: slots.append(str(ed.pv.pieces[kk].slot))
		slots.sort()
		_check(not slots.has("top") and slots.has("base_top" if ed.preset.body == "female" else "base_bottom"), "strip to base on the turntable (%s): %s" % [tag, slots])
		await _shot("editor-%s-stripped" % tag)
		ed._reset()
		await _secs(0.3)
	await _size(DESK)
	# an edit: heavier, another top colour, dark backdrop, side view, then Save
	ed._go_tab("body")
	ed.preset.keys["weight"] = 0.9
	ed._changed("keys")
	ed._go_tab("outfit")
	var top: String = ed.preset.outfit.top if ed.preset.outfit.top != "" else ed.preset.outfit.under
	ed.preset.outfit.colors[top] = {"main": "#24346b"}
	ed._changed("paint")
	ed.dark = true; ed._backdrop(); ed._face(PI * 0.5)
	await _secs(0.6)
	await _shot("editor-desk-edited-dark-side")
	ed.a_pose = true; ed._pose(); ed._face(0.0); ed.dark = false; ed._backdrop()
	await _secs(0.4)
	await _shot("editor-desk-apose")
	ed.a_pose = false; ed._pose()
	ed._toggle_place()
	await _secs(0.8)
	_check(ed.in_place and att.body is CharBody and not bool(att.body.get_meta("baked", false)), "view in place: the attendant itself is live-edited")
	await _shot("editor-desk-inplace")
	ed._toggle_place()
	ed._save()
	_check(CharPreset.has_local(id), "Save keeps the edit in this browser")
	var path := CharPreset.download(id, ed.preset)
	_check(FileAccess.file_exists(path), "Download writes %s" % path)
	ed._close()
	await _secs(1.0)
	_check(co.editor == null and not player.frozen, "closed, player free")
	_check(att.body is CharBody and is_equal_approx(float(CharPreset.get_preset(id).keys.weight), 0.9) and bool(att.body.get_meta("baked", false)), "the attendant wears the saved edit, baked")
	_stand_at(att)
	await _secs(1.0)
	await _shot("att-%s-after" % id)
	CharPreset.forget_local(id)
	# the player's editor in the menu's AVATAR tab
	var menu = player.get_node("Menu")
	for sz in [DESK, PHONE]:
		await _size(sz)
		menu.open_tab("avatar")
		await _secs(1.2)
		var c = menu._creator
		_check(c != null and c.get_script() != null and str(c.get_script().resource_path).ends_with("char_editor.gd"), "AVATAR tab hosts the character editor (player mode)")
		var tag := "desk" if sz == DESK else "phone"
		await _shot("menu-avatar-%s" % tag)
		if sz == DESK:
			c._go_tab("outfit")
			await _secs(0.3)
			await _shot("menu-avatar-desk-outfit")
			c._toggle_adv()
			await _secs(0.3)
			c._go_tab("body")
			await _secs(0.3)
			await _shot("menu-avatar-desk-advanced")
			c._apply_shape("Curvy Missy" if c.preset.body == "female" else "Athletic")
			c.preset.outfit.colors["top_tee"] = {"main": "#7a1f2b"}
			c._changed("paint")
			await _secs(0.3)
		menu.close()
		await _secs(0.8)
	_check(not CharPreset.player_preset().is_empty(), "closing the menu saves the player's preset")
	# third person with the preset avatar, an item in the right hand if one is there
	var av = player.avatar
	_check(av.body is AvatarChar, "the avatar is an AvatarChar (the player's preset)")
	await _size(DESK)
	av.third = true
	_stand_at(att, 4.2)
	await _secs(3.0)
	await _shot("third-person-avatar")
	Engine.set_meta("mall_owner", false)

func _stand_at(att, back := 2.2) -> void:
	var b: Node3D = att.body
	var to := Vector3(att.global_position.x, 0, att.global_position.z)
	var d := (b.global_position - to); d.y = 0
	var dir := d.normalized() if d.length() > 0.05 else Vector3.FORWARD
	player.position = b.global_position - dir * back
	player.position.y = 0
	player.yaw = atan2(-dir.x, -dir.z)
	player.pitch = deg_to_rad(-6)
	player._apply_rot()
