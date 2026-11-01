## Renders each item's inventory icon (tex/items/<id>.png, 128 x 128, transparent) from its scene,
## for every data/items/*.json entry whose "icon" is under res://tex/items/ (design/godot-interaction.md).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/items/render_icons.gd [-- <id> ...]
extends SceneTree

const ItemDB = preload("res://scripts/items/item_db.gd")
const S := 128

var todo: Array = []
var vp: SubViewport
var cam: Camera3D
var holder: Node3D
var frames := 0
var cur: Dictionary = {}

func _initialize() -> void:
	var db = ItemDB.new().load_dir()
	var only := OS.get_cmdline_user_args()
	for id in db.order:
		var e: Dictionary = db.get_item(id)
		if str(e.icon).begins_with("res://tex/items/") and (only.is_empty() or only.has(id)):
			todo.append(e)
	vp = SubViewport.new()
	vp.size = Vector2i(S * 2, S * 2)
	vp.transparent_bg = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 0.97, 0.92)
	env.ambient_light_energy = 0.75
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 35, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	vp.add_child(cam)
	cam.current = true
	holder = Node3D.new()
	vp.add_child(holder)

func _aabb(n: Node, xf: Transform3D, acc: Array) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh:
		var a: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
		acc[0] = a if acc[0] == null else acc[0].merge(a)
	for c in n.get_children():
		_aabb(c, t, acc)

func _next() -> bool:
	for c in holder.get_children():
		c.free()
	if todo.is_empty():
		return false
	cur = todo.pop_front()
	var inst: Node3D = load(str(cur.scene)).instantiate()
	var wo := inst.get_node_or_null("WorldOnly")
	if wo:
		wo.free()
	holder.add_child(inst)
	# lay long things across the picture: the stick diagonally
	if str(cur.id) == "folse_stick":
		inst.rotation_degrees = Vector3(0, 0, -45)
	var acc := [null]
	_aabb(inst, Transform3D(), acc)
	var a: AABB = acc[0]
	var c: Vector3 = a.get_center()
	cam.global_transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(-35), deg_to_rad(25), 0)), c)
	cam.global_position = c + cam.global_transform.basis.z * 3.0
	cam.size = maxf(a.size.length() * 1.0, 0.05)
	frames = 0
	return true

func _process(_dt: float) -> bool:
	if cur.is_empty():
		return not _next()
	frames += 1
	if frames == 4:
		var im := vp.get_texture().get_image()
		im.resize(S, S, Image.INTERPOLATE_LANCZOS)
		var path := ProjectSettings.globalize_path(str(cur.icon))
		im.save_png(path)
		print("icon ", path)
		return not _next()
	return false
