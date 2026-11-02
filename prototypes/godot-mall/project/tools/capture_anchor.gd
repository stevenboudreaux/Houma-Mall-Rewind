## Captures an anchor's own wing (4 = Sears / Lynn's, 5 = Dillard's level 1) as seen from the mall
## through its opening, for the picture the mall wing shows there (workstream S, Nov 2 2026;
## tools/build_mall.gd anchor_standin, design/godot-wings.md "Wings 4-6").
##
## The opening comes from gen/w<wing>[y26]/wing.json "views": the plane just inside the mall wall
## (a..b, floor to the soffit h) and n, pointing out into the mall. A camera stands `out` metres out in
## the mall at eye height, looking in, with an off-axis frustum framed exactly on that rectangle and its
## near plane on it, so everything on the mall side (the mall wing's coarse copy in this scene) is
## clipped and the picture lines up from that spot. Same tone deal as the stand-in
## (tools/capture_standin.gd: linear, half exposure, no glow), shown unshaded at twice the brightness.
## Writes tex/standin/from_w<wing>_<mode>.png (2026: y26_from_w<wing>_<mode>.png), PX_M pixels a metre.
##
## Run (needs a display: xvfb-run), from the project folder:
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --script res://tools/capture_anchor.gd -- --wing=4 --mode=day [--year=2026]
## or tools/capture_standin.sh 4 [2026]. Before the wing's first bake it captures it unbaked.
extends SceneTree

const PX_M := 128.0        # picture pixels per metre of the opening
const SS := 2              # supersampling
const SETTLE := 40
const EYE := 1.62
var wing := 4
var year := 1995
var mode := "day"
var vp: SubViewport
var cam: Camera3D
var scn: Node
var V: Dictionary
var frames := 0
var W := 0
var H := 0
var flip := false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wing="):
			wing = int(a.substr(7))
		elif a.begins_with("--mode="):
			mode = a.substr(7)
		elif a.begins_with("--year="):
			year = int(a.substr(7))
	var y26 := year == 2026
	var wj = JSON.parse_string(FileAccess.get_file_as_string(("res://gen/w%dy26/wing.json" if y26 else "res://gen/w%d/wing.json") % wing))
	if not (wj is Dictionary) or wj.get("views", []).is_empty():
		push_error("no opening in gen/w%d wing.json (views): build the wing first" % wing)
		quit(1)
		return
	V = wj.views[0]
	scn = load(("res://wing%d_2026.tscn" if y26 else "res://wing%d.tscn") % wing).instantiate()
	var pl0 = scn.get_node_or_null("Player")
	if pl0:
		scn.remove_child(pl0)
		pl0.free()
	root.add_child(scn)
	current_scene = scn
	load("res://scripts/time_of_day.gd").apply(scn, mode)
	var lm = scn.get_node_or_null("LightmapGI")
	if lm == null or lm.light_data == null:
		print("unbaked: no lightmap for wing %d %s yet; capturing it as it is" % [wing, mode])
	var envn = scn.get_node("Env")
	var env: Environment = envn.environment.duplicate()
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 0.5
	env.glow_enabled = false
	env.adjustment_enabled = false
	envn.environment = env
	var a := Vector3(float(V.a[0]), 0, float(V.a[1]))
	var b := Vector3(float(V.b[0]), 0, float(V.b[1]))
	var n := Vector3(float(V.n[0]), 0, float(V.n[1]))
	var h := float(V.h)
	var wd := a.distance_to(b)
	W = int(round(wd * PX_M)); H = int(round(h * PX_M))
	var mid := (a + b) * 0.5
	var out := float(V.out)
	vp = SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(W * SS, H * SS)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.near = out
	cam.far = 200.0
	cam.size = h                                          # the near plane's height: the opening's
	cam.frustum_offset = Vector2(0.0, h * 0.5 - EYE)       # centred on the opening, not the eye
	vp.add_child(cam)
	root.add_child(vp)
	cam.current = true
	cam.global_transform = Transform3D(Basis.looking_at(-n, Vector3.UP), mid + n * out + Vector3.UP * EYE)
	# the picture's left edge is a (build_mall.gd anchor_view's UVs): flip when the camera's right
	# runs from b to a
	flip = (b - a).dot(cam.global_transform.basis.x) < 0.0
	print("capturing wing ", wing, " (", year, " ", mode, "): opening ", snappedf(wd, 0.01), " x ", h, " m from ", out, " m out -> ", W, " x ", H)

func _process(_dt: float) -> bool:
	frames += 1
	if frames == 10:
		var envn = scn.get_node("Env")
		var keep: Environment = envn.environment
		load("res://scripts/time_of_day.gd").apply(scn, mode)
		envn.environment = keep
	if frames < SETTLE:
		return false
	var im := vp.get_texture().get_image()
	im.convert(Image.FORMAT_RGB8)
	im.resize(W, H, Image.INTERPOLATE_LANCZOS)
	if flip:
		im.flip_x()
	DirAccess.make_dir_recursive_absolute("res://tex/standin")
	var o := ("res://tex/standin/y26_from_w%d_%s.png" if year == 2026 else "res://tex/standin/from_w%d_%s.png") % [wing, mode]
	im.save_png(ProjectSettings.globalize_path(o))
	print("wrote ", o)
	return true
