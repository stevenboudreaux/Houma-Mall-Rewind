## CHARS-UBC (design/godot-ubc-characters.md): the UBC bodies as builds, posed by the shoppers' clips
## through NpcRig (the retarget check), in the editor's studio light. Native, unbaked:
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/ubc_sheet.gd -- --out=<prefix> [--clip=idle] [--t=0.4] [--views=front,side]
## Uses CharBody when the UBC manifest is live (scripts/char_body.gd), else raw blend shapes.
extends SceneTree

var out := "/tmp/ubc"
var clip := "idle"
var t := 0.4
var cell := Vector2i(220, 440)
var views := [0.0, PI * 0.5]
const BUILDS := {
	"female": [["default", {}], ["slim", {"weight": -0.8, "muscle": -0.5}],
		["curvy", {"bust": 0.6, "hips": 0.8, "butt": 0.7, "waist": -0.5, "thigh": 0.4}],
		["plus", {"weight": 0.9, "belly": 0.4, "hips": 0.4, "thigh": 0.5, "arms": 0.4, "bust": 0.4}],
		["tall", {"height": 0.8}], ["kit sculpt", {"muscle": 1.0}]],
	"male": [["default", {}], ["slim", {"weight": -0.8, "muscle": -0.5, "shoulders": -0.4}],
		["athletic", {"muscle": 0.6, "shoulders": 0.5, "chest": 0.5, "waist": -0.3}],
		["big & tall", {"height": 0.6, "weight": 0.9, "belly": 0.6, "waist": 0.5, "chest": 0.3, "shoulders": 0.3}],
		["short", {"height": -0.8}], ["kit sculpt", {"muscle": 1.0}]],
}

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--clip="): clip = a.substr(7)
		elif a.begins_with("--t="): t = float(a.substr(4))
		elif a.begins_with("--views="):
			views = []
			for v in a.substr(8).split(","):
				views.append({"front": 0.0, "34": 0.75, "side": PI * 0.5, "back": PI}[v])
	await process_frame
	var vp := SubViewport.new()
	vp.size = cell * 2
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
	var n := 0
	for sex in BUILDS: n = maxi(n, BUILDS[sex].size())
	var sheet := Image.create(cell.x * n * views.size(), cell.y * 2, false, Image.FORMAT_RGB8)
	sheet.fill(Color(0.9, 0.9, 0.89))
	var row := 0
	for sex in ["female", "male"]:
		var bl: Array = BUILDS[sex]
		for bi in bl.size():
			var keys: Dictionary = bl[bi][1]
			var nb := _body(sex, keys)
			vp.add_child(nb)
			await process_frame
			nb.freeze(clip, t)
			await process_frame
			await process_frame
			var h := 1.75
			for vi in views.size():
				var a: float = views[vi]
				var c := Vector3(0, h * 0.52, 0)
				cam.position = c + Vector3(sin(a), 0.03, cos(a)) * h * 2.2
				cam.look_at(c, Vector3.UP)
				await process_frame
				await process_frame
				await RenderingServer.frame_post_draw
				var img := vp.get_texture().get_image()
				img.resize(cell.x, cell.y, Image.INTERPOLATE_LANCZOS)
				img.convert(Image.FORMAT_RGB8)
				sheet.blit_rect(img, Rect2i(Vector2i.ZERO, cell), Vector2i((bi * views.size() + vi) * cell.x, row * cell.y))
			print("UBC SHEET %s %s %s" % [sex, bl[bi][0], keys])
			nb.queue_free()
			await process_frame
		row += 1
	sheet.save_png(out + ".png")
	print("wrote %s.png" % out)
	quit(0)

func _body(sex: String, keys: Dictionary) -> NpcBody:
	var ubc_live: bool = CharBody.is_ubc()
	if ubc_live:
		var p := CharPreset.blank(sex)
		p.keys = keys
		var cb := CharPreset.body_for(p, false)
		return cb
	var nb := NpcBody.new()
	nb.set_skin({"id": "ubc_" + sex, "scn": "res://models/ubc/body_%s.gltf" % sex, "hips": 0.94, "height_m": 1.8})
	for mi in nb.skin.find_children("*", "MeshInstance3D", true, false):
		var m: Mesh = mi.mesh
		for i in m.get_blend_shape_count():
			var nm := str(m.get_blend_shape_name(i))
			var base := nm.substr(0, nm.length() - 1)
			var sgn := nm.right(1)
			var v := float(keys.get(base, 0.0))
			mi.set_blend_shape_value(i, v if (sgn == "+" and v > 0) else (-v if (sgn == "-" and v < 0) else 0.0))
	return nb
