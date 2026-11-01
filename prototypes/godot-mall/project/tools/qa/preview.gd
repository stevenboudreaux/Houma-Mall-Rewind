## Renders one prop module, or one store with the hall in front of it, without
## building or baking the whole mall: realtime lights, raw PNG textures (no
## import step), one PNG per camera. For modelling and texture checks only:
## the game itself is lit by the baked lightmaps, so final looks are checked
## in a real build (tools/qa/movetest.py).
##
## Run through tools/qa/preview.sh, which wraps:
##   xvfb-run godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --write-movie <dir>/f.png --fixed-fps 1 --script res://tools/qa/preview.gd -- \
##     <target> <cams> [opts-json] [light]
## <target>: a prop module name under tools/stores/pocket_change/ (e.g. "skee"),
##           or "store:<STORE NAME>" (e.g. "store:POCKET CHANGE").
## <cams>:   "x,y,z,yaw,pitch;..." metres and degrees; yaw 0 looks along -z,
##           yaw 90 looks along -x. Props are built at the origin facing -z:
##           the player stands at +z and looks toward -z.
## [opts]:   JSON passed to the prop's build() as opts (default "{}").
## [light]:  "lit" (default: a showroom key + fill so the textures read),
##           "dark" (only the prop's own lights and emission: arcade at night).
extends "res://tools/build_mall.gd"

var cams = []
var frame_i = 0
var cam: Camera3D
const FRAMES_PER_CAM = 2

func _initialize():
	var args = OS.get_cmdline_user_args()
	var target = args[0] if args.size() > 0 else "skee"
	for c in (args[1] if args.size() > 1 else "0,1.6,3.5,0,-10").split(";"):
		var v = c.split(",")
		if v.size() >= 5:
			cams.append([Vector3(float(v[0]), float(v[1]), float(v[2])), float(v[3]), float(v[4])])
	var opts = JSON.parse_string(args[2]) if args.size() > 2 and args[2] != "" else {}
	var light = args[3] if args.size() > 3 else "lit"
	raw_tex = true
	seed(1995)
	mall = Node3D.new(); mall.name = "Preview"
	light_root = Node3D.new(); light_root.name = "Lights"
	mall.add_child(light_root)
	root.add_child(mall)
	if target.begins_with("store:"):
		build_store(target.substr(6))
	else:
		build_prop(target, opts if opts != null else {})
	commit_meshes()
	setup_env(light, target.begins_with("store:"))
	cam = Camera3D.new()
	cam.fov = 70.0
	mall.add_child(cam)
	place_cam(0)

func build_prop(module, opts):
	var m = load("res://tools/stores/pocket_change/%s.gd" % module)
	# a floor and a back wall, so shadows and glow have something to land on
	cur_color = Color("#2a2a30")
	quad("room", "vcolor_matte", [Vector3(-6, 0, -6), Vector3(6, 0, -6), Vector3(6, 0, 6), Vector3(-6, 0, 6)], Vector3.UP)
	cur_color = Color("#3a3a44")
	quad("room", "vcolor_matte", [Vector3(-6, 0, -6), Vector3(6, 0, -6), Vector3(6, 3.6, -6), Vector3(-6, 3.6, -6)], Vector3.BACK)
	cur_color = Color.WHITE
	m.build(self, "prop", Vector3.ZERO, Vector3.FORWARD, opts)

func build_store(store_name):
	# ws/g: MALL_YEAR=2026 previews a store of the 2026 map (layout_2026.json)
	if OS.get_environment("MALL_YEAR") == "2026":
		YEAR = 2026
	L = JSON.parse_string(FileAccess.get_file_as_string("res://layout_2026.json" if YEAR == 2026 else "res://layout_mall.json"))
	for z in L.zones:
		zones[z.id] = z
	var ids = L.stores.keys()
	ids.sort()
	var ci = 0
	for sid in ids:
		atlas_index[sid] = ci
		ci += 1
	var centre = null
	for e in L.edges:
		if e.has("store") and L.stores[e.store].name == store_name:
			centre = Vector3((e.a[0] + e.b[0]) * 0.5, 0, (e.a[1] + e.b[1]) * 0.5)
	if centre == null:
		push_error("no store " + store_name)
		return
	# the store, its neighbours, and the halls and courts around it
	for z in L.zones:
		var r = z.rect
		if Vector2(clamp(centre.x, r[0], r[2]), clamp(centre.z, r[1], r[3])).distance_to(Vector2(centre.x, centre.z)) < 30.0:
			floor_zone(z)
			if z.type == "hall":
				build_hall(z)
			else:
				build_court(z)
	for e in L.edges:
		var m = Vector3((e.a[0] + e.b[0]) * 0.5, 0, (e.a[1] + e.b[1]) * 0.5)
		if m.distance_to(centre) < 30.0:
			build_edge(e)

func commit_meshes():
	for A in [acc, dyn_acc]:
		for gname in A:
			var am = ArrayMesh.new()
			for mname in A[gname]:
				var s = A[gname][mname]
				s.index()
				s.commit(am)
				am.surface_set_material(am.get_surface_count() - 1, mat(mname))
			var mi = MeshInstance3D.new()
			mi.name = gname
			mi.mesh = am
			mall.add_child(mi)
	# the builder's baked lights become realtime ones here; their e_night energy is the one shown
	for l in light_root.get_children():
		if l is Light3D:
			if l.has_meta("only") and l.get_meta("only") == "day":
				l.visible = false
			elif l.has_meta("e_night"):
				l.light_energy = float(l.get_meta("e_night"))
			l.shadow_enabled = l is SpotLight3D
	for m in mats.values():
		if m.has_meta("e_night"):
			m.emission_energy_multiplier = float(m.get_meta("e_night"))
		if m.has_meta("floor"):
			m.albedo_color = Color("#d9cdb8")

func setup_env(light, is_store):
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#101014")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8a8a90") if light == "lit" else Color("#40404a")
	env.ambient_light_energy = 0.55 if light == "lit" else 0.15
	if is_store:
		env.ambient_light_energy = 0.35 if light == "lit" else 0.12
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.tonemap_white = 4.0
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_hdr_threshold = 1.0
	var we = WorldEnvironment.new()
	we.environment = env
	mall.add_child(we)
	if light == "lit":
		var key = DirectionalLight3D.new()
		key.light_energy = 0.9
		key.shadow_enabled = true
		key.transform = Transform3D(Basis.looking_at(Vector3(-0.45, -0.75, -0.5).normalized(), Vector3.UP), Vector3.ZERO)
		mall.add_child(key)
		var fill = DirectionalLight3D.new()
		fill.light_energy = 0.3
		fill.transform = Transform3D(Basis.looking_at(Vector3(0.6, -0.3, 0.4).normalized(), Vector3.UP), Vector3.ZERO)
		mall.add_child(fill)
		var under = DirectionalLight3D.new()   # a little light on ceilings and undersides
		under.light_energy = 0.25
		under.transform = Transform3D(Basis.looking_at(Vector3(-0.2, 0.8, 0.3).normalized(), Vector3.UP), Vector3.ZERO)
		mall.add_child(under)

func place_cam(i):
	if i >= cams.size():
		return
	var c = cams[i]
	cam.transform = Transform3D(Basis.from_euler(Vector3(deg_to_rad(c[2]), deg_to_rad(c[1]), 0.0), EULER_ORDER_YXZ), c[0])

func _process(_d):
	# call k comes before frame k is drawn: frames 2i and 2i+1 show camera i
	var ci = frame_i / FRAMES_PER_CAM
	frame_i += 1
	if ci >= cams.size():
		quit()
		return false
	place_cam(ci)
	return false
