## CHAR-EDITOR: the five proposed looks (tools/qa/fixtures/char_first_five.json), full body, front / 3/4 /
## back, the editor's turntable light, the idle clip. Fully clothed adults only (refuses anything else).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/char_first_five.gd -- --out=<prefix>
extends SceneTree

const CELL := Vector2i(220, 420)
const VIEWS := [0.0, 0.75, PI]
var out := "/tmp/five"

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	await process_frame
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://tools/qa/fixtures/char_first_five.json"))
	var vp := SubViewport.new()
	vp.size = CELL * 2
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.9, 0.9, 0.89)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.62, 0.64)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env
	vp.add_child(we)
	for l in [[Vector3(-35, 30, 0), 1.25], [Vector3(-15, -60, 0), 0.45], [Vector3(-20, 160, 0), 0.6]]:
		var d := DirectionalLight3D.new()
		d.rotation_degrees = l[0]; d.light_energy = l[1]
		vp.add_child(d)
	var cam := Camera3D.new()
	cam.fov = 30
	vp.add_child(cam)
	cam.current = true
	var looks: Array = j.looks
	const PER_ROW := 3
	var sheet := Image.create(CELL.x * VIEWS.size() * PER_ROW, CELL.y * int(ceil(looks.size() / float(PER_ROW))), false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.9, 0.9, 0.89))
	for li in looks.size():
		var L: Dictionary = looks[li]
		var p: Dictionary
		if L.has("from"):
			p = CharPreset.load_repo(str(L.from).get_file().get_basename())
		else:
			p = CharPreset.normalize(L.preset)
		if CharBody.is_child(p.keys):
			push_error("a child preset is never shot"); quit(1); return
		var cb := CharPreset.body_for(p, true)
		vp.add_child(cb)
		cb.play("idle", 0.0)
		if not cb.is_clothed():
			push_error("refusing: not clothed"); quit(1); return
		await process_frame
		cb.freeze("idle", 0.4)
		var h := float(CharBody.cman().bodies[str(p.body)].height_m) * (1.0 + float(p.keys.get("height", 0.0)) * 0.14)
		print("LOOK %s %s hair=%s pieces=%s fit=%s" % [L.id, p.body, p.hair.id, cb.pieces.keys(), CharFit.inside_count(cb)])
		for vi in VIEWS.size():
			var a: float = VIEWS[vi]
			var c := Vector3(0, h * 0.52, 0)
			cam.position = c + Vector3(sin(a), 0.03, cos(a)) * h * 2.3
			cam.look_at(c, Vector3.UP)
			await process_frame
			await process_frame
			await RenderingServer.frame_post_draw
			var img := vp.get_texture().get_image()
			img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
			img.convert(Image.FORMAT_RGB8)
			sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i(((li % PER_ROW) * VIEWS.size() + vi) * CELL.x, (li / PER_ROW) * CELL.y))
		cb.queue_free()
		await process_frame
	sheet.save_png(out + ".png")
	print("wrote %s.png" % out)
	quit(0)
