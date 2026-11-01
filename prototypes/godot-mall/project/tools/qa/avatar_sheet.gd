## Workstream V (design/godot-avatar.md): every avatar body (scripts/avatar_bodies.json) in its own
## colours (top row) and recoloured with a test look (bottom row), front view, idle; one sheet.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/qa/avatar_sheet.gd -- \
##     --out=/tmp/avatars.png [--year=1995] [--look=skin,hair,top,bottom,words] [--back]
extends SceneTree
const Look = preload("res://scripts/avatar_look.gd")
const AvatarBody = preload("res://scripts/avatar_body.gd")
var out := "/tmp/avatars.png"
var year := 1995
var test := ["#8f5a3a", "#e0c58a", "#1f6f6a", "#e9e4d8", "HOUMA"]
var back := false
var vp: SubViewport
var cam: Camera3D
var w3: Node3D
var ids := []
var k := 0
var frames := 0
var tiles := []
var cur: AvatarBody
const TW := 200
const TH := 360

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--year="): year = int(a.substr(7))
		elif a.begins_with("--look="): test = a.substr(7).split(",")
		elif a == "--back": back = true
	vp = SubViewport.new(); vp.size = Vector2i(TW, TH); vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true
	get_root().add_child(vp)
	w3 = Node3D.new(); vp.add_child(w3)
	var env := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.2, 0.19, 0.18)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(1, 0.96, 0.9); e.ambient_light_energy = 0.75
	env.environment = e; w3.add_child(env)
	var sun := DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 20, 0); sun.light_energy = 1.1; w3.add_child(sun)
	cam = Camera3D.new(); cam.fov = 30; w3.add_child(cam); cam.current = true
	for b in Look.bodies(): ids.append(str(b.id))
	print("bodies: ", ids.size())
	_load()

func _look(i: int) -> Dictionary:
	var L := Look.default_look()
	L.body = ids[i / 2]
	if i % 2 == 1:
		L.skin = test[0]; L.hair = test[1]
		L[Look.year_key(year)] = {"top": test[2], "bottom": test[3], "words": test[4] if test.size() > 4 else ""}
	return L

func _load() -> void:
	if cur: cur.free(); cur = null
	if k >= ids.size() * 2:
		_sheet(); quit(); return
	cur = AvatarBody.new(); w3.add_child(cur)
	cur.wear(_look(k), year)
	cur.freeze("idle", 0.6)
	cur.rotation.y = PI if back else 0.0
	var h := float(cur.info.get("height_m", 1.7))
	cam.position = Vector3(0, h * 0.53, h * 2.05)
	frames = 0

func _process(_dt: float) -> bool:
	frames += 1
	if frames == 5:
		tiles.append(vp.get_texture().get_image())
		k += 1
		_load()
	return false

func _sheet() -> void:
	var cols := ids.size()
	var img := Image.create(cols * TW, 2 * TH, false, tiles[0].get_format())
	for t in tiles.size():
		var i: int = t / 2
		img.blit_rect(tiles[t], Rect2i(0, 0, TW, TH), Vector2i(i * TW, (t % 2) * TH))
	img.save_png(out)
	print("wrote ", out, " ", ids)
