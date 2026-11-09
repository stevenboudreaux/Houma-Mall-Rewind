## Native: the talk camera on one attendant (workstream TALK, design/godot-dialogue.md "The talk camera").
## Loads the attendant's wing and year with its lightmap (day, as the live game), stands the player at
## the attendant's talk spot, puts the attendant in the middle of its area, starts a PLACEHOLDER
## conversation and saves the frame once the camera has arrived and the line is typed. The same
## script runs on main (before) and on ws/talk (after), so both shots have the game's own framing.
##   xvfb-run -a -s "-screen 0 1600x1000x24" godot --path . --rendering-driver opengl3 \
##     --resolution 1280x720 --script res://tools/qa/talk_shots.gd -- --npc=radioshack --out=/tmp/t/x.png [--unbaked]
## Prints TALK SHOT OK <path> (and the eye / camera numbers), or TALK SHOT FAILED.
extends SceneTree

const LINE := "res://data/story/placeholder/PLACEHOLDER_sound_shop.dialogue"

var npc_id := "radioshack"
var out := "/tmp/talk.png"
var baked := true
var scn: Node
var player: Node3D
var att: Node3D
var t := 0.0
var step := 0

func _entry(id: String) -> Dictionary:
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/attendants.json"))
	for e in j.attendants:
		if str(e.id) == id: return e
	var c = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/cucos/cucos.json"))
	if str(c.get("bartender", {}).get("id", "")) == id: return c.bartender
	return {}

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--npc="): npc_id = a.substr(6)
		elif a.begins_with("--out="): out = a.substr(6)
		elif a == "--unbaked": baked = false
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var e := _entry(npc_id)
	if e.is_empty():
		printerr("TALK SHOT FAILED: no attendant " + npc_id); quit(1); return
	var year := int(e.years[0])
	Engine.set_meta("mall_state_%d" % year, "")
	Engine.set_meta("mall_flags", "")
	var path := "res://wing%d%s.tscn" % [int(e.wing), "_2026" if year == 2026 else ""]
	scn = load(path).instantiate()
	root.add_child(scn)
	current_scene = scn
	if not baked:
		var lm = scn.find_child("LightmapGI", true, false)
		if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "day")
	player = scn.get_node("Player")

func _process(dt: float) -> bool:
	t += dt
	match step:
		0:
			if t < 3.0: return false
			var story = player.get_node("Story")
			for a in story.attendants:
				if is_instance_valid(a) and str(a.entry.get("id", "")) == npc_id: att = a
			if att == null or att.body == null:
				printerr("TALK SHOT FAILED: %s not spawned" % npc_id); quit(1); return true
			var c: Vector2 = att.area.get_center()
			att.body.global_position = Vector3(c.x, 0, c.y)
			att._goal = att.body.global_position
			att._wait = 1e9
			player.position = att.global_position
			var d: Vector3 = att.body.global_position - player.position
			player.yaw = atan2(-d.x, -d.z); player.pitch = deg_to_rad(-8.0); player._apply_rot()
			step = 1; t = 0.0
		1:
			if t < 1.5: return false
			player.get_node("Story").talk(att, LINE)
			step = 2; t = 0.0
		2:
			if t < 3.0: return false
			var ui = player.get_node("Story").ui
			if ui.typing: ui._typed()
			step = 3; t = 0.0
		3:
			if t < 0.4: return false
			var im := root.get_texture().get_image()
			im.convert(Image.FORMAT_RGB8)
			if out.ends_with(".jpg"): im.save_jpg(out, 0.9)
			else: im.save_png(out)
			var cam := root.get_viewport().get_camera_3d()
			var eye: Vector3 = att.face_point()
			printerr("TALK SHOT OK %s  cam %s fov %.1f  eye(face_point) %s  dist %.2f" % [out, cam.global_position, cam.fov, eye, cam.global_position.distance_to(eye)])
			var tcn = scn.get_node_or_null("TalkCamera")      # ws/talk only
			if tcn and tcn.look:
				printerr("  look: head %s eyes %s weight %.2f  eye_point %s  eye shader %s" % [tcn.look.head, tcn.look.eyes, tcn.look.weight, tcn.look.eye_point(att.body), tcn.look._eye_mat != null])
			quit(0)
			return true
	return false
