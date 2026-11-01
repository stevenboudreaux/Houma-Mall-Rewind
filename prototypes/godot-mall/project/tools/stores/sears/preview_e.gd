## Workstream E preview: tools/qa/preview.gd's "store:<NAME>" mode with the year taken from the
## MALL_YEAR environment variable (2026 reads layout_2026.json), and only the store's own edge plus
## the zones round its mouth. Run: MALL_YEAR=2026 tools/stores/sears/preview_e.sh "store:NAME" out "cams"
extends "res://tools/qa/preview.gd"

func build_store(store_name):
	var y26 = OS.get_environment("MALL_YEAR") == "2026"
	YEAR = 2026 if y26 else 1995
	L = JSON.parse_string(FileAccess.get_file_as_string("res://layout_2026.json" if y26 else "res://layout_mall.json"))
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
	for z in L.zones:
		var r = z.rect
		if Vector2(clamp(centre.x, r[0], r[2]), clamp(centre.z, r[1], r[3])).distance_to(Vector2(centre.x, centre.z)) < 20.0:
			floor_zone(z)
			if z.type == "hall":
				build_hall(z)
			else:
				build_court(z)
	for e in L.edges:
		var m = Vector3((e.a[0] + e.b[0]) * 0.5, 0, (e.a[1] + e.b[1]) * 0.5)
		if m.distance_to(centre) < 20.0:
			build_edge(e)

## "amb": the store's own lights plus an even ambient fill, standing in for the bake's bounce light
## (no directional key: the preview has no roof over a big store, so a key light streaks through).
func setup_env(light, is_store):
	if light != "amb":
		super.setup_env(light, is_store)
		return
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#101014")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#f2efe8")
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 4.0
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_hdr_threshold = 1.0
	var we = WorldEnvironment.new()
	we.environment = env
	mall.add_child(we)
	for l in light_root.get_children():
		if l is Light3D:
			l.shadow_enabled = false
		elif l is ReflectionProbe:
			l.queue_free()
