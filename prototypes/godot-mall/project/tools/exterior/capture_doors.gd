## Captures the lot as seen from each exit door, from the outside (wing 3), for the pictures the
## inside wings show past their doors (tools/exterior/door_view.gd; design/godot-exterior.md
## "Looking out"). Per door of inside wing --wing (exterior.json order), three off-axis cameras at
## eye height on the doorway, each framed exactly on one face of door_view.gd's box, go into one row
## of tex/standin/door_w<wing>_<mode>.png (2026: y26_door_w<wing>_day.png).
##
## Tone as the stand-in (capture_standin.gd): linear at half exposure, no glow; door_view.gd draws
## it unshaded at twice the brightness.
## With wing 3's lightmap in the project it captures the baked outside (time_of_day.gd); without
## one (cloud sessions), a plain sun and sky stand in for the bake and it says so.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/exterior/capture_doors.gd -- \
##     --wing=1 --mode=day [--year=2026]
## or tools/capture_standin.sh 3 [2026] (both inside wings, both modes).
extends SceneTree

const DV = preload("res://tools/exterior/door_view.gd")
const SS := 2              # supersampling
const SETTLE := 40
const PER_FACE := 4
var wing := 1
var year := 1995
var mode := "day"
var jobs: Array = []        # [row, face, camera transform, frustum size, offset, viewport size]
var k := -1
var frames := 0
var wait := 0
var vp: SubViewport
var cam: Camera3D
var atlas: Image
var scn: Node
var baked := false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wing="): wing = int(a.substr(7))
		elif a.begins_with("--mode="): mode = a.substr(7)
		elif a.begins_with("--year="): year = int(a.substr(7))
	var doors = DV.wing_doors(wing)
	print("capturing the lot from wing ", wing, "'s ", doors.size(), " doors (", year, ", ", mode, ")")
	scn = load("res://wing3_2026.tscn" if year == 2026 else "res://wing3.tscn").instantiate()
	var pl = scn.get_node_or_null("Player")
	if pl:
		scn.remove_child(pl); pl.free()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.get_node_or_null("LightmapGI")
	# int-53: cloud-built scenes don't embed light_data; apply() loads res://wing3[_2026]_<mode>.lmbake
	# by path when it exists (as capture_anchor.gd does), so apply first, then see whether it is baked
	if lm != null:
		load("res://scripts/time_of_day.gd").apply(scn, mode)
	baked = lm != null and lm.light_data != null
	var envn = scn.get_node("Env")
	if baked:
		pass
	else:
		print("  no lightmap for the outside: an unbaked sun and sky stand in (re-capture after the bake)")
		if lm:
			lm.get_parent().remove_child(lm); lm.free()
		var e0 := Environment.new()
		var sky := Sky.new(); sky.sky_material = ProceduralSkyMaterial.new()
		e0.background_mode = Environment.BG_SKY; e0.sky = sky
		e0.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e0.ambient_light_color = Color("#dfe8f2") if mode == "day" else Color("#2a3040")
		e0.ambient_light_energy = 0.45 if mode == "day" else 0.25
		if mode != "day":
			(sky.sky_material as ProceduralSkyMaterial).sky_energy_multiplier = 0.05
			(sky.sky_material as ProceduralSkyMaterial).ground_energy_multiplier = 0.05
		envn.environment = e0
		for l in scn.find_children("*", "Light3D", true, false):
			var night_light = str(l.get_meta("only", "")) == "night"
			l.visible = (mode == "night") == night_light and not (l is DirectionalLight3D)
			l.light_bake_mode = Light3D.BAKE_DYNAMIC
		if mode == "day":
			var sun := DirectionalLight3D.new(); sun.light_energy = 1.0; sun.shadow_enabled = true
			sun.directional_shadow_max_distance = 200.0
			sun.transform = Transform3D(Basis.looking_at(Vector3(0.35, -0.8, 0.45), Vector3.UP), Vector3.ZERO)
			scn.add_child(sun)
	var env: Environment = envn.environment.duplicate()
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 0.5
	env.glow_enabled = false
	env.adjustment_enabled = false
	envn.environment = env
	var A = DV.atlas_size(wing)
	atlas = Image.create(A.x, A.y, false, Image.FORMAT_RGB8)
	atlas.fill(Color(0.4, 0.42, 0.45))
	for row in doors.size():
		var d = doors[row]
		var n := Vector3(float(d.n[0]), 0, float(d.n[1]))
		var out := -n
		var mid := Vector3(float(d.mid[0]), 0, float(d.mid[1]))
		var W := Vector3(float(d.a[0]), 0, float(d.a[1])).distance_to(Vector3(float(d.b[0]), 0, float(d.b[1])))
		# outside, the doorway is `depth` further out than the hall edge the inside wing's glass is on
		var at := mid + out * (float(d.depth) + 0.3)
		var F = DV.faces(at, out, W)
		var eye := at + Vector3.UP * DV.EYE
		for f in 3:
			var look: Vector3 = F[f][1]
			var dist: float = F[f][2]
			var x0: float = F[f][3]; var x1: float = F[f][4]
			var y0 := -DV.EYE; var y1 := DV.TOP - DV.EYE
			var near := 0.05
			var s := near / dist
			var w := x1 - x0
			var vps := Vector2i(int(round(DV.SLOT * SS * w / DV.TOP)), DV.SLOT * SS)
			jobs.append([row, f, Transform3D(Basis.looking_at(look, Vector3.UP), eye), (y1 - y0) * s,
				Vector2((x0 + x1) * 0.5 * s, (y0 + y1) * 0.5 * s), vps])
	vp = SubViewport.new()
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(64, 64)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_FRUSTUM
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.far = 700.0
	vp.add_child(cam)
	root.add_child(vp)
	cam.current = true

func _setup(j: Array) -> void:
	vp.size = j[5]
	cam.global_transform = j[2]
	cam.set_frustum(j[3], j[4], 0.05, 700.0)

func _process(_dt: float) -> bool:
	frames += 1
	if frames < SETTLE:
		return false
	if k == -1:
		k = 0
		_setup(jobs[0]); wait = PER_FACE
		return false
	wait -= 1
	if wait > 0:
		return false
	var j: Array = jobs[k]
	var im := vp.get_texture().get_image()
	im.convert(Image.FORMAT_RGB8)
	im.resize(DV.SLOT, DV.SLOT, Image.INTERPOLATE_LANCZOS)
	atlas.blit_rect(im, Rect2i(0, 0, DV.SLOT, DV.SLOT), Vector2i(int(j[1]) * DV.SLOT, int(j[0]) * DV.SLOT))
	k += 1
	if k >= jobs.size():
		DirAccess.make_dir_recursive_absolute("res://tex/standin")
		var p := DV.atlas_path(wing, year, mode)
		atlas.save_png(ProjectSettings.globalize_path(p))
		print("wrote ", p, " (", "baked" if baked else "UNBAKED", ")")
		return true
	_setup(jobs[k])
	wait = PER_FACE
	return false
