## DEVICE-BAKEOFF test shots (design/godot-device-bakeoff.md): one Pocket Pal test model held in front of
## the camera inside a baked wing, lit only by the scene (the lightmap's probes, the reflection probes, the
## wing's own lights). No menu, no HUD: this script is the only thing that ever loads the test models.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/blender/assets_src/pocket_pal_shots/device_shot.gd -- \
##     --wing=1 --mode=day --glb=res://models/hud/pocket_pal_a.glb --out=/tmp/dir \
##     --cams="x,z,yaw,pitch:name:view;..."     view = held (default) | keys (close on the keys and legends)
## The LCD surface (material name ending in _lcd) gets a flat test card with no text; --light=1 adds the
## teal backlight glow.
extends SceneTree
var frames := 0
var out := "/tmp"
var vp: SubViewport
var cam: Camera3D
var dev: Node3D
var cams := []
var i := 0
var settle := 24

func _initialize() -> void:
	var wing := 1
	var mode := "day"
	var glb := ""
	var light := 0.0
	var size := Vector2i(1920, 1080)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wing="): wing = int(a.substr(7))
		elif a.begins_with("--mode="): mode = a.substr(7)
		elif a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--glb="): glb = a.substr(6)
		elif a.begins_with("--light="): light = float(a.substr(8))
		elif a.begins_with("--cams="):
			for c in a.substr(7).split(";"):
				var kv = c.split(":")
				if kv.size() >= 2:
					cams.append([kv[0].split(","), kv[1], kv[2] if kv.size() > 2 else "held"])
	var scn = load("res://wing%d.tscn" % wing).instantiate()
	var pl = scn.get_node_or_null("Player")
	if pl:
		scn.remove_child(pl); pl.free()
	root.add_child(scn)
	current_scene = scn
	load("res://scripts/time_of_day.gd").apply(scn, mode)
	vp = SubViewport.new(); vp.size = size; vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_4X
	cam = Camera3D.new(); cam.fov = 70.0; cam.near = 0.02
	vp.add_child(cam); root.add_child(vp); cam.current = true
	if glb != "":
		dev = load(glb).instantiate()
		cam.add_child(dev)
		for mi in dev.find_children("*", "MeshInstance3D", true, false):
			for s in mi.mesh.get_surface_count():
				var m = mi.mesh.surface_get_material(s)
				if m and m.resource_name.ends_with("_lcd"):
					mi.set_surface_override_material(s, lcd_material(light))
	_place()

## A flat test card: olive LCD ground, a border, a grey ramp, a checker block, a few bars. No text.
func lcd_material(light: float) -> StandardMaterial3D:
	var w := 480; var h := 144
	var bg := Color("#7d8a68"); var ink := Color("#20281c")
	var im := Image.create(w, h, false, Image.FORMAT_RGB8)
	im.fill(bg)
	for x in w:
		for y in h:
			var c := bg
			if x < 3 or y < 3 or x >= w - 3 or y >= h - 3: c = ink
			elif y >= 14 and y < 44 and x >= 16 and x < 464: c = bg.lerp(ink, floor((x - 16) / 56.0) / 7.0)
			elif y >= 56 and y < 130 and x >= 16 and x < 90: c = ink if (((x - 16) / 6) + ((y - 56) / 6)) % 2 == 0 else bg
			elif y >= 56 and y < 130 and x >= 110 and x < 464 and ((x - 110) / 8) % 4 < (1 + (x - 110) / 120): c = ink if (y - 56) / 12 % 2 == 0 else bg
			im.set_pixel(x, y, c)
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(im)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.roughness = 0.22
	if light > 0.0:
		m.emission_enabled = true
		m.emission = Color("#5fd8c8")
		m.emission_texture = m.albedo_texture
		m.emission_energy_multiplier = light
	return m

func _place() -> void:
	var v = cams[i][0]
	cam.rotation = Vector3(deg_to_rad(float(v[3])), deg_to_rad(float(v[2])), 0)
	cam.position = Vector3(float(v[0]), 1.62, float(v[1]))
	if dev:
		if cams[i][2] == "keys":
			dev.position = Vector3(0.012, -0.050, -0.135); dev.rotation_degrees = Vector3(62, 0, 0)
		else:
			dev.position = Vector3(0.0, -0.095, -0.265); dev.rotation_degrees = Vector3(48, -6, 0)
	frames = 0

func _process(_d) -> bool:
	frames += 1
	if frames < settle: return false
	var img = vp.get_texture().get_image()
	img.save_png(out + "/" + cams[i][1] + ".png")
	print("wrote ", cams[i][1])
	i += 1
	if i >= cams.size():
		return true
	_place()
	return false
