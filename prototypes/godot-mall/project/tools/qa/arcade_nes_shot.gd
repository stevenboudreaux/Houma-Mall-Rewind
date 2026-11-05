## ARCADE-NES (design/godot-arcade-roms.md): an unbaked picture of a playable cabinet, now an NES: the
## PLAYABLE sticker in the NES red and, as the owner sees it in Arcade mode, the system tag.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/arcade_nes_shot.gd -- --id=pc.video.37 --out=/tmp/arc/cab
extends SceneTree

var out := "/tmp/arc/cab"
var id := "pc.video.37"
var t := 0.0
var scn: Node

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--id="): id = a.substr(5)
	Engine.set_meta("mall_player_name", "TESTER")
	Engine.set_meta("menu_opening", false)
	Engine.set_meta("mall_owner", false)
	scn = load("res://wing2.tscn").instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "night")

func _process(dt: float) -> bool:
	t += dt
	if t < 3.0:
		return false
	if t < 100.0:
		t = 100.0
		var sg = scn.get_node("Signs")
		sg._stickers()           # made on the web only; called here for the picture
		sg._show_sys_tags(true)  # the owner's Arcade mode tags
		var f = sg.recs[id].faces[0]
		var c := Vector3.ZERO
		for p in f.p: c += Vector3(p[0], p[1], p[2])
		c *= 0.25
		var n := Vector3(f.n[0], 0, f.n[2]).normalized()
		var pl = scn.get_node("Player")
		pl.hint.visible = false
		var at: Vector3 = c + n * 2.2
		pl.position = Vector3(at.x, 0, at.z)
		pl.yaw = atan2(n.x, n.z)
		pl.pitch = atan2(c.y - 0.15 - pl.cam.position.y, 2.2)
		pl._apply_rot()
		print("ARCADE ", id, " = ", sg.ARCADE[id], " at ", c)
		return false
	if t < 101.5:
		return false
	root.get_texture().get_image().save_png(out + ".png")
	print("ARCADE SHOT OK ", out)
	quit()
	return false
