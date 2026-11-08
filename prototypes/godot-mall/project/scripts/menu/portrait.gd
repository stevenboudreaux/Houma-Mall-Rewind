## MENU2 (design/godot-menu.md "MAIN"): a cast member, turning slowly, on a small lit stage, for the
## menu's MAIN tab (the player's character) and its Character row (one per cast member), in a
## SubViewport shown by a SubViewportContainer (this node).
## CHAR-STRIP (Nov 8 2026, design/godot-avatar.md): show_cast(id) makes the body through the one loader,
## Cast.body(id) (scripts/cast.gd), the same call the world's body uses; this node never picks a body
## class of its own. A missing cast file leaves the stage empty (Cast logs the error).
extends SubViewportContainer

var vp: SubViewport
var body: NpcBody
var cast_id := ""
var cam: Camera3D
var yaw := 0.4
var spin := true           # false: stands facing the camera (the chooser's thumbnails)
var _w: Node3D

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
	_w = w
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

## Stand cast member `id` on the stage (the loader's body, idle).
func show_cast(id: String) -> void:
	if body != null and is_instance_valid(body):
		body.get_parent().remove_child(body)
		body.queue_free()
	body = null
	cast_id = id
	body = Cast.body(id)
	if body == null:
		return
	body.name = "PortraitBody"
	_w.add_child(body)
	body.rotation.y = yaw if spin else 0.0
	_frame()

func _frame() -> void:
	var h := float(Cast.entry(cast_id).get("height_m", 1.7)) if cast_id != "" else 1.7
	var asp := float(vp.size.x) / maxf(float(vp.size.y), 1.0)
	var need := (h * 1.12) * 0.5 / tan(deg_to_rad(cam.fov * 0.5))
	if asp < 0.55: need /= asp / 0.55
	cam.position = Vector3(0, h * 0.53, need)

func fit(sz: Vector2) -> void:
	size = sz
	vp.size = Vector2i(maxi(64, int(sz.x)), maxi(64, int(sz.y)))
	_frame()

func _process(dt: float) -> void:
	if spin:
		yaw += dt * 0.5
	if body:
		body.rotation.y = yaw if spin else 0.0
