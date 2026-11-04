## B-FIX evidence: the repo's presets, FULLY CLOTHED ADULTS only, baked as NPCs and standing in the
## mall (native opengl3 under xvfb, unbaked lights), side by side 3.2 m in front of the player.
## Refuses any child preset or any body that isn't clothed (no evidence of either is ever written).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/char_clothed_shot.gd -- --wing=1 --cam=x,z,yaw,pitch --out=<prefix>
extends SceneTree

var out := "/tmp/bfix"
var frames := 0
var shots := [["desk", Vector2i(1280, 720)], ["phone", Vector2i(390, 844)]]
var shot := 0

func _initialize() -> void:
	var wing := 1
	var cam := "-4,-91,90,0"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wing="): wing = int(a.substr(7))
		elif a.begins_with("--cam="): cam = a.substr(6)
		elif a.begins_with("--out="): out = a.substr(6)
	root.size = shots[0][1]
	var scn = load("res://wing%d.tscn" % wing).instantiate()
	root.add_child(scn)
	current_scene = scn
	load("res://scripts/time_of_day.gd").apply(scn, "day")
	var pl = scn.get_node("Player")
	await process_frame
	var v = cam.split(",")
	pl.position = Vector3(float(v[0]), 0, float(v[1]))
	pl.yaw = deg_to_rad(float(v[2])); pl.pitch = deg_to_rad(float(v[3]))
	pl._apply_rot()
	var sh = scn.get_node_or_null("Shoppers")
	if sh: sh.queue_free()
	await process_frame
	await process_frame
	var c: Camera3D = pl.cam
	var fwd := -c.global_basis.z; fwd.y = 0; fwd = fwd.normalized()
	var side := fwd.cross(Vector3.UP).normalized()
	var at := Vector3(pl.position.x, 0, pl.position.z) + fwd * 3.2
	var ids := CharPreset.list_ids()
	var i := 0
	for id in ids:
		var p := CharPreset.get_preset(id, false)
		if CharBody.is_child(p.keys):
			print("skip %s: a child preset is never shot" % id); continue
		var cb := CharPreset.body_for(p, true)
		if not cb.is_clothed():
			push_error("refusing to shoot %s: not clothed" % id); quit(1); return
		scn.add_child(cb)
		cb.position = at + side * (float(i) - float(ids.size() - 1) * 0.5) * 0.75
		cb.face(-fwd)
		cb.play("idle", 0.0)
		print("CLOTHED %s %s" % [id, cb.pieces.keys()])
		i += 1

func _process(_dt: float) -> bool:
	frames += 1
	if frames < 20: return false
	var path := "%s-%s.png" % [out, shots[shot][0]]
	root.get_texture().get_image().save_png(path)
	print("wrote ", path)
	shot += 1
	if shot >= shots.size(): return true
	root.size = shots[shot][1]
	DisplayServer.window_set_size(shots[shot][1])
	frames = 0
	return false
