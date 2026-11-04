## CHAR-EDITOR (design/godot-character-editor.md "Hair fit"): every hair on every adult body, front and
## 3/4, head and shoulders, one sheet per sex. Native, unbaked, neutral studio light (the editor's
## turntable light), the idle clip frozen at one frame so every cell has the same pose.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/char_hair_grid.gd -- --out=<prefix> [--sex=female|male] [--fit=0|1]
## Writes <prefix>-<sex>.png (rows = hairs, columns = body x view) and prints, per cell, how many hair
## vertices sit inside the body (CharFit.inside_count): "HAIR <sex> <body> <hair> inside=<n>/<verts>".
## Bodies: the manifest's shape presets plus two adult extremes (heavy-set 52, skinny 74). Children are
## never shot (the clothed rule's evidence rule). --fit=0 renders without the runtime hair fit (before).
extends SceneTree

var CELL := Vector2i(150, 180)
var VIEWS := [["front", 0.0], ["3/4", 0.75]]
var only_hairs := []
var only_bodies := []
var dist := 0.95
var pose_t := 0.4
const EXTREMES := ["heavy-set 52", "skinny 74"]
var out := "/tmp/hairgrid"
var only_sex := ""
var fit := true

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--sex="): only_sex = a.substr(6)
		elif a.begins_with("--fit="): fit = a.substr(6) != "0"
		elif a.begins_with("--hairs="): only_hairs = a.substr(8).split(",")
		elif a.begins_with("--bodies="): only_bodies = a.substr(9).split(",")
		elif a.begins_with("--big="):      # close-up cells: front, 3/4, side, back
			CELL = Vector2i(300, 360); dist = 1.05
			VIEWS = [["front", 0.0], ["3/4", 0.75], ["side", PI * 0.5], ["back", PI]]
		elif a.begins_with("--pose="): pose_t = float(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("char_hair_fit", fit)
	await process_frame
	for sex in ["female", "male"]:
		if only_sex != "" and sex != only_sex: continue
		await _sheet(sex)
	print("HAIR GRID DONE")
	quit(0)

func _bodies(sex: String) -> Array:
	var out_b := []
	var pres: Dictionary = CharBody.cman().presets
	for k in pres.get(sex, {}): out_b.append([k, pres[sex][k]])
	if not only_bodies.is_empty():
		out_b = out_b.filter(func(b): return only_bodies.has(str(b[0])))
		for k in EXTREMES: if only_bodies.has(k): out_b.append([k, pres.extremes[k]])
		return out_b
	for k in EXTREMES:
		var keys: Dictionary = pres.extremes[k].duplicate()
		if CharBody.is_child(keys): continue
		if sex == "male": for b in CharBody.CHILD_ZERO_KEYS: keys.erase(b)
		out_b.append([k, keys])
	return out_b

func _hairs(sex: String) -> Array:
	var h := []
	for e in CharBody.cman().pieces:
		if str(e.body) == sex and str(e.slot) == "hair" and (only_hairs.is_empty() or only_hairs.has(str(e.base_id))): h.append(str(e.base_id))
	return h

func _sheet(sex: String) -> void:
	var vp := SubViewport.new()
	vp.size = CELL * 2      # rendered at 2x, scaled down (cleaner edges)
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
	cam.fov = 26
	vp.add_child(cam)
	cam.current = true
	var bodies := _bodies(sex)
	var hairs := _hairs(sex)
	var label_w := 0
	var W := bodies.size() * VIEWS.size() * CELL.x
	var H := hairs.size() * CELL.y
	var sheet := Image.create(W, H, false, Image.FORMAT_RGB8)
	sheet.fill(Color(1, 1, 1))
	var cb := CharBody.new()
	vp.add_child(cb)
	for bi in bodies.size():
		var keys: Dictionary = bodies[bi][1]
		for hi in hairs.size():
			var p := CharPreset.blank(sex)
			p.keys = keys.duplicate()
			p.hair = {"id": hairs[hi], "color": "#4a3020"}
			p.skin = "#c99a7c"
			CharPreset.dress(cb, p)
			cb.clip = ""
			if pose_t >= 0.0: cb.freeze("idle", pose_t)
			else: cb.set_animated(false)
			await process_frame
			await process_frame
			_bone_pos(cb, "mixamorig_Head")
			await process_frame
			await process_frame
			var head := _bone_pos(cb, "mixamorig_Head")
			var inside := CharFit.inside_count(cb)
			print("HAIR %s %s %s inside=%d/%d" % [sex, bodies[bi][0], hairs[hi], inside.x, inside.y])
			for vi in VIEWS.size():
				var a: float = VIEWS[vi][1]
				var c := head + Vector3(0, 0.0, 0)
				cam.position = c + Vector3(sin(a), 0.02, cos(a)) * dist
				cam.look_at(c + Vector3(0, -0.06, 0), Vector3.UP)
				await process_frame
				await process_frame
				await RenderingServer.frame_post_draw
				var img := vp.get_texture().get_image()
				img.resize(CELL.x, CELL.y, Image.INTERPOLATE_LANCZOS)
				img.convert(Image.FORMAT_RGB8)
				var x := (bi * VIEWS.size() + vi) * CELL.x
				sheet.blit_rect(img, Rect2i(Vector2i.ZERO, CELL), Vector2i(x, hi * CELL.y))
	var path := "%s-%s.png" % [out, sex]
	sheet.save_png(path)
	# the column / row key (the sheet has no text: Godot can't draw text into an Image)
	var key := []
	for b in bodies: key.append(str(b[0]))
	print("wrote %s  columns (each front, 3/4): %s  rows: %s" % [path, ", ".join(key), ", ".join(hairs)])
	vp.queue_free()

## The bone's final (posed, retargeted) position: a BoneAttachment3D follows what is drawn.
func _bone_pos(cb: CharBody, bn: String) -> Vector3:
	var ba := cb.sk.get_node_or_null("QaHead") as BoneAttachment3D
	if ba == null:
		ba = BoneAttachment3D.new()
		ba.name = "QaHead"
		ba.bone_name = bn
		cb.sk.add_child(ba)
	return ba.global_position + Vector3(0, 0.06, 0)
