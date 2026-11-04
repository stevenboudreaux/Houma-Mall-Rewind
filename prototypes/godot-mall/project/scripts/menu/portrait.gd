## MENU2 (design/godot-menu.md "MAIN"): the current character, turning slowly, for the menu's MAIN
## tab. The same lit stage as the creator's preview (scripts/avatar_creator.gd _make_preview), in a
## SubViewport shown by a SubViewportContainer (this node). wear(look, year) dresses it.
extends SubViewportContainer

const AvatarBody = preload("res://scripts/avatar_body.gd")

var vp: SubViewport
var body: NpcBody          # CHAR-EDITOR: an AvatarChar (the player's preset) when the pack ships the bodies, else V's AvatarBody
var cam: Camera3D
var yaw := 0.4

func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.size = Vector2i(240, 320)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var w := Node3D.new()
	vp.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.16, 0.13, 0.11)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(1.0, 0.95, 0.88)
	e.ambient_light_energy = 0.75
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 1.1
	w.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 200, 0)
	fill.light_energy = 0.35
	w.add_child(fill)
	var fl := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.75; cyl.bottom_radius = 0.75; cyl.height = 0.04
	fl.mesh = cyl
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.55, 0.47, 0.38)
	fl.material_override = fm
	fl.position.y = -0.02
	w.add_child(fl)
	cam = Camera3D.new()
	cam.fov = 30.0
	w.add_child(cam)
	cam.current = true
	# CHAR-EDITOR (Nov 4, the "default bald avatar" bug): MAIN showed V's body in V's look (Ch01, bald,
	# by default) whatever the player had made in the character editor. Now it is the same body the
	# mall shows: the player's preset on a B1 body when this pack ships them.
	body = AvatarChar.new() if AvatarChar.available() else AvatarBody.new()
	body.name = "PortraitBody"
	w.add_child(body)

func wear(look: Dictionary, year: int) -> void:
	if body is AvatarChar:
		(body as AvatarChar).wear_look(look, year)
	else:
		(body as AvatarBody).wear(look, year)
	body.clip = ""
	body.play("idle", 0.0, false)
	_frame()

func _frame() -> void:
	var h := float(body.info.get("height_m", 1.7))
	var asp := float(vp.size.x) / maxf(float(vp.size.y), 1.0)
	var need := (h * 1.12) * 0.5 / tan(deg_to_rad(cam.fov * 0.5))
	if asp < 0.55: need /= asp / 0.55
	cam.position = Vector3(0, h * 0.53, need)

func fit(sz: Vector2) -> void:
	size = sz
	vp.size = Vector2i(maxi(64, int(sz.x)), maxi(64, int(sz.y)))
	_frame()

func _process(dt: float) -> void:
	yaw += dt * 0.5
	if body:
		body.rotation.y = yaw
