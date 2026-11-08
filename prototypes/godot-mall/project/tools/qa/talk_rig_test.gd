## Headless: the talk camera's light rig and the NPC look go on and off cleanly (workstream TALK,
## design/godot-dialogue.md "The talk camera"). Wing 1 1995 (RadioShack, a UBC preset body; the Cuco's
## bartender, a Mixamo skin), ten conversations each through the conversation screen and the shop path:
##  - in talk: the camera is current, both lights visible and lighting layer 20 only, the NPC's meshes
##    on that layer and nothing else's, an NpcLook running, the head look set, the UBC eye shader on;
##  - after: the walking camera is current, the lights hidden at 0, no mesh left on the layer, no
##    NpcLook left, the rig's look cleared (weight 1), the eye material the one it had; and the counts
##    of lights, cameras and nodes under the talk camera are the same after 10 cycles as after 1.
##   godot --headless --path . --script res://tools/qa/talk_rig_test.gd
## Prints TALK RIG TEST OK (n checks), or the failed checks. Exit code 0 / 1.
extends SceneTree

var oks := 0
var errors: Array = []
var scn: Node
var player: Node3D

func _check(ok: bool, what: String) -> void:
	if not ok or oks < 40:
		printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _frames(n: int) -> void:
	for i in n:
		await process_frame

func _initialize() -> void:
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_flags", "")
	scn = load("res://wing1.tscn").instantiate()
	root.add_child(scn)
	current_scene = scn
	player = scn.get_node("Player")
	await _frames(20)
	var story = player.get_node("Story")
	var rs: Node3D = null
	var bar: Node3D = null
	for a in story.attendants:
		if str(a.entry.get("id", "")) == "radioshack": rs = a
		if str(a.entry.get("id", "")) == "cucos_bartender": bar = a
	_check(rs != null and rs.body != null, "RadioShack's attendant is here")
	_check(bar != null and bar.body != null, "the Cuco's bartender is here")
	for who in [rs, bar]:
		if who == null or who.body == null: continue
		player.global_position = who.global_position
		await _cycles(who, story)
	printerr("TALK RIG TEST OK (%d checks)" % oks if errors.is_empty() else "TALK RIG TEST FAILED: " + str(errors))
	quit(0 if errors.is_empty() else 1)

func _eye_mats(b: Node) -> Array:
	var out := []
	for mi in b.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null: continue
		for i in range(mi.mesh.get_surface_count()):
			out.append(mi.get_surface_override_material(i))
	return out

func _on_layer(bit: int) -> Array:
	return scn.find_children("*", "GeometryInstance3D", true, false).filter(func(g): return g.layers & bit != 0)

func _cycles(who: Node3D, story) -> void:
	var nm := str(who.entry.id)
	var mats_before := _eye_mats(who.body)
	var walk_cam: Camera3D = root.get_viewport().get_camera_3d()
	var counts := []
	for c in 10:
		var via_ui := c % 2 == 0
		if via_ui:
			story.talk(who, "res://data/story/placeholder/PLACEHOLDER_sound_shop.dialogue")
		else:
			TalkCamera.for_player(player).begin(who)
			who.talk_begin(player)
		await _frames(40)
		var tc: TalkCamera = TalkCamera.for_player(player)
		var bit := 1 << 19
		_check(root.get_viewport().get_camera_3d() == tc.cam, "%s #%d: the talk camera is current" % [nm, c])
		_check(tc.key.visible and tc.fill.visible and tc.key.light_cull_mask == bit and tc.fill.light_cull_mask == bit,
			"%s #%d: both lights on, layer 20 only" % [nm, c])
		var lit := _on_layer(bit)
		var mine := lit.filter(func(g): return who.body.is_ancestor_of(g))
		_check(lit.size() > 0 and lit.size() == mine.size(), "%s #%d: only the NPC is on the light layer (%d of %d)" % [nm, c, mine.size(), lit.size()])
		_check(tc.look != null and is_instance_valid(tc.look), "%s #%d: the look runs" % [nm, c])
		_check(who.body.rig.look != Vector3.INF and who.body.rig.look_weight > 0.5, "%s #%d: the head looks (w %.2f)" % [nm, c, who.body.rig.look_weight])
		if who.body is CharBody:
			_check(tc.look._eye_mat != null, "%s #%d: the eye shader is on" % [nm, c])
		if via_ui:
			story.ui._end()
		else:
			who.talk_end()
			await tc.end()
		await _frames(60)
		_check(root.get_viewport().get_camera_3d() == walk_cam, "%s #%d: the walking camera is back" % [nm, c])
		_check(not tc.key.visible and not tc.fill.visible and tc.key.light_energy == 0.0 and tc.fill.light_energy == 0.0,
			"%s #%d: the lights are off" % [nm, c])
		_check(_on_layer(bit).is_empty(), "%s #%d: nothing left on the light layer" % [nm, c])
		_check(tc.find_children("*", "NpcLook", true, false).is_empty() and tc.look == null, "%s #%d: no look left" % [nm, c])
		_check(who.body.rig.look == Vector3.INF and who.body.rig.look_weight == 1.0, "%s #%d: the head is the clip's again" % [nm, c])
		_check(_eye_mats(who.body) == mats_before, "%s #%d: the eye material is the one it had" % [nm, c])
		counts.append([scn.find_children("*", "Light3D", true, false).size(), scn.find_children("*", "Camera3D", true, false).size(),
			tc.get_child_count(), tc.cam.get_child_count()])
	_check(counts[0] == counts[9], "%s: lights, cameras, talk-camera children after 1 and after 10 cycles: %s / %s" % [nm, counts[0], counts[9]])
