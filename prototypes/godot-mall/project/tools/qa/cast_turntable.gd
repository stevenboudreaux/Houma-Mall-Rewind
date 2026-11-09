## OWNER/DEV ONLY (workstream CHAR-SOURCES, design/godot-characters-sources.md): a turntable and face sheet
## for one cast candidate .glb, in Godot's own renderer (Compatibility / opengl3, as the web build).
## The body is an NpcBody (scripts/npc_body.gd) holding the idle clip through NpcRig, so the sheet also
## proves the Mixamo clips play on it. Lights: a warm key and a cool fill like TALK's talk camera.
##   xvfb-run -a -s "-screen 0 1600x1000x24" godot --path . --rendering-driver opengl3 --resolution 480x720 \
##     --script res://tools/qa/cast_turntable.gd -- --cast=res://cast_preview/x.glb --hips=0.9 --out=/tmp/t/x
##   or --id=<cast id> (CHAR-BUILD): the person through CastGlb.body(id), faces by the cast's morph names.
## Writes <out>-turn<deg>.png and <out>-face-<name>.png; prints TURNTABLE OK.
extends SceneTree

var cast := ""
var hips := 0.95
var out := "/tmp/turn"
var body: NpcBody
var cam: Camera3D
var t := 0.0
var i := 0
var plan: Array = []
const FACES := {
	"neutral": {},
	"talk": {"JawOpen": 0.35, "MouthSmileLeft": 0.5, "MouthSmileRight": 0.5, "viseme_aa": 0.3, "jaw_open": 0.35, "smile": 0.5},
	"smile": {"MouthSmileLeft": 0.9, "MouthSmileRight": 0.9, "CheekSquintLeft": 0.4, "CheekSquintRight": 0.4, "smile": 0.9, "squint_L": 0.25, "squint_R": 0.25},
	"blink": {"EyeBlinkLeft": 1.0, "EyeBlinkRight": 1.0, "blink_L": 1.0, "blink_R": 1.0},
	"oh": {"viseme_O": 0.9, "BrowInnerUp": 0.6, "brow_inner_up": 0.6},
	"look-left": {},
}

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--cast="): cast = a.substr(7)
		elif a.begins_with("--hips="): hips = float(a.substr(7))
		elif a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--id="): cast = "id:" + a.substr(5)
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	var we := WorldEnvironment.new(); var e := Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color(0.36, 0.37, 0.4)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; e.ambient_light_color = Color(0.55, 0.55, 0.58); e.ambient_light_energy = 0.6
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = e; root.add_child(we)
	var key := DirectionalLight3D.new(); key.light_color = Color(1.0, 0.95, 0.87); key.light_energy = 1.1
	root.add_child(key); key.rotation_degrees = Vector3(-35, -30, 0)
	var fill := DirectionalLight3D.new(); fill.light_color = Color(0.92, 0.95, 1.0); fill.light_energy = 0.45
	root.add_child(fill); fill.rotation_degrees = Vector3(-5, 40, 0)
	if cast.begins_with("id:"):
		body = CastGlb.body(cast.substr(3)); root.add_child(body)
	else:
		body = NpcBody.new(); root.add_child(body)
		body.set_skin({"id": "cast_preview", "scn": cast, "hips": hips})
	body.freeze("idle", 0.5)
	cam = Camera3D.new(); root.add_child(cam); cam.current = true
	for deg in [0, 45, 90, 135, 180, 270]:
		plan.append(["turn%03d" % deg, deg, {}, false])
	for f in FACES:
		plan.append(["face-" + f, 0, FACES[f], true])

func _sk() -> Skeleton3D:
	return body.skin.find_child("Skeleton3D", true, false)

func _set_faces(d: Dictionary) -> void:
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		for bi in range(mi.mesh.get_blend_shape_count()):
			mi.set_blend_shape_value(bi, 0.0)
		for k in d:
			var bi: int = mi.find_blend_shape_by_name(k)
			if bi >= 0: mi.set_blend_shape_value(bi, d[k])

func _process(dt: float) -> bool:
	t += dt
	if t < 1.0: return false
	if i >= plan.size() * 2:
		printerr("TURNTABLE OK " + out); quit(); return true
	var p: Array = plan[i / 2]
	if i % 2 == 0:
		body.rotation_degrees.y = float(p[1])
		_set_faces(p[2])
		var sk := _sk()
		var h := sk.global_transform * sk.get_bone_global_rest(sk.find_bone("mixamorig_Head"))
		var eye_y := h.origin.y + 0.09
		if p[3]:
			cam.fov = 18.0; cam.position = Vector3(0.0, eye_y, 1.25); cam.look_at(Vector3(0, eye_y - 0.03, 0))
		else:
			cam.fov = 30.0; cam.position = Vector3(0, 0.95, 3.9); cam.look_at(Vector3(0, 0.9, 0))
		CastFace.turn_eyes(sk, CastFace.eye_bones(sk), 18.0 if p[0] == "face-look-left" else 0.0, 0.0)
	else:
		var im := root.get_texture().get_image()
		im.save_png("%s-%s.png" % [out, p[0]])
	i += 1
	return false
