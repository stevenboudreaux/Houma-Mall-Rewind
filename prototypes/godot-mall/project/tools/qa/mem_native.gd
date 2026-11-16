## PHONE-MEMORY (Nov 16 2026; production/qa/evidence/wsPHONE-MEMORY-findings.md): the engine's own memory counters
## with one wing, then two, natively, through the phone path of the streamer (scripts/wing_stream.gd, kind mobile).
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##       --script res://tools/qa/mem_native.gd -- --home=1 --next=2 [--year=2026] [--x=33 --z=0]
## Must run with a real GL renderer (not --headless: the dummy renderer counts no textures). On a Linux GL the
## engine uploads the desktop (S3TC/BPTC) copies of VRAM textures: the same size as ETC2/ASTC LDR. The mobile
## lightmap (ASTC 4x4 HDR) is decompressed to RGBAH on the web: 8x its size here. The report adds that difference.
## Prints MEM lines and MEM NATIVE OK.
extends SceneTree

var home := 1
var nxt := 2
var year := 1995
var pos := Vector2(33, 0)
var scn: Node
var ws
var t := 0.0
var step := 0
var frames := 0
var rows := []

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--home="): home = int(a.substr(7))
		if a.begins_with("--next="): nxt = int(a.substr(7))
		if a.begins_with("--year="): year = int(a.substr(7))
		if a.begins_with("--x="): pos.x = float(a.substr(4))
		if a.begins_with("--z="): pos.y = float(a.substr(4))
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_stream", true)
	Engine.set_meta("mall_stream_kind", "mobile")
	Engine.set_meta("mall_upfront", false)
	Engine.set_meta("mall_mem", true)
	var path := "res://wing%d%s.tscn" % [home, "_2026" if year == 2026 else ""]
	scn = load(path).instantiate()
	root.add_child(scn)
	current_scene = scn

func _mon() -> Dictionary:
	return {
		"tex": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / 1048576.0,
		"buf": Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / 1048576.0,
		"video": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0,
		"static": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0,
		"static_max": Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1048576.0,
		"objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"resources": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"nodes": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"wings": ws.span() if ws else [],
	}

func _rec(label: String) -> void:
	var m := _mon()
	m["label"] = label
	rows.append(m)
	_dump(label)
	print("MEM %s wings=%s tex=%.1f buf=%.1f video=%.1f static=%.1f static_max=%.1f objects=%d resources=%d nodes=%d" % [
		label, str(m.wings), m.tex, m.buf, m.video, m.static, m.static_max, m.objects, m.resources, m.nodes])

## Every texture reachable from the tree (materials, shader parameters, lightmaps, sprites, decals), by
## resource path, into .scratch/mem/<tag>-tex.json; tools/qa/packmemory.py's inventory prices them
## (production/qa/evidence/wsPHONE-MEMORY-findings.md section b). Textures a script holds outside the tree are
## not in it: compare the sum with the engine's counter.
func _dump(label: String) -> void:
	var seen := {}
	var tex := {}
	for n in _all(root):
		for pr in n.get_property_list():
			if pr.type == TYPE_OBJECT:
				var v = n.get(pr.name)
				if v is Resource:
					_walk(v, seen, tex, 0)
		if n is MeshInstance3D and n.mesh:
			for i in n.mesh.get_surface_count():
				var m = n.mesh.surface_get_material(i)
				if m: _walk(m, seen, tex, 0)
			for i in n.get_surface_override_material_count():
				var m = n.get_surface_override_material(i)
				if m: _walk(m, seen, tex, 0)
	var tag := "h%d_n%d_y%d_%s" % [home, nxt, year, label]
	var f := FileAccess.open(ProjectSettings.globalize_path("res://").path_join("../../../.scratch/mem/%s-tex.json" % tag).simplify_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(tex.keys()))
	print("MEMTEX %s %d textures in the tree" % [label, tex.size()])

func _all(n: Node) -> Array:
	var out := [n]
	for c in n.get_children():
		out.append_array(_all(c))
	return out

func _walk(r: Resource, seen: Dictionary, tex: Dictionary, depth: int) -> void:
	if r == null or depth > 5 or seen.has(r.get_instance_id()):
		return
	seen[r.get_instance_id()] = true
	if r is Texture:
		if r.resource_path != "":
			tex[r.resource_path.get_slice("::", 0)] = true
		if not (r is AtlasTexture):
			return
	if r is Mesh and not (r is PrimitiveMesh):
		for i in r.get_surface_count():
			var m = r.surface_get_material(i)
			if m: _walk(m, seen, tex, depth + 1)
		return
	if r is ShaderMaterial and r.shader:
		for u in r.shader.get_shader_uniform_list():
			var v = r.get_shader_parameter(u.name)
			if v is Resource: _walk(v, seen, tex, depth + 1)
	for pr in r.get_property_list():
		if pr.type == TYPE_OBJECT:
			var v = r.get(pr.name)
			if v is Resource: _walk(v, seen, tex, depth + 1)
		elif pr.type == TYPE_ARRAY and (pr.usage & PROPERTY_USAGE_STORAGE):
			var a = r.get(pr.name)
			if a is Array:
				for v in a:
					if v is Resource: _walk(v, seen, tex, depth + 1)

func _process(dt: float) -> bool:
	t += dt
	frames += 1
	ws = root.get_node_or_null("WingStream")
	var p: Node3D = current_scene.get_node_or_null("Player") if current_scene else null
	match step:
		0:
			if ws:
				ws.cfg["start_delay_s"] = 100000.0      # hold the neighbour back until one wing is measured (the first frame the streamer exists, before its own _process)
			if ws and p and frames > 5:
				p.position = Vector3(pos.x, 0, pos.y)
				ws.cfg["borders"] = (ws.cfg["borders"] as Array).filter(func(b): return (int(b.a) == home and int(b.b) == nxt) or (int(b.a) == nxt and int(b.b) == home))
				ws.cfg["near_m"] = {"desktop": 100000, "mobile": 100000}
				ws.cfg["far_m"] = {"desktop": 100000, "mobile": 100000}
				step = 1; frames = 0
		1:
			if ws.span().size() > 1:
				print("MEM NATIVE FAILED: wing %d came in before one wing was measured" % nxt)
				quit(1)
			if frames > 300:   # one wing, its probes and crowd settled
				_rec("one-wing")
				ws.cfg["start_delay_s"] = 0.0
				step = 2; frames = 0; t = 0.0
		2:
			if ws.is_in(nxt):
				step = 3; frames = 0
			elif t > 900.0:
				print("MEM NATIVE FAILED: wing %d never came in" % nxt)
				quit(1)
		3:
			if frames > 300:
				_rec("two-wings")
				var a: Dictionary = rows[0]
				var b: Dictionary = rows[1]
				print("MEM delta tex=%.1f buf=%.1f video=%.1f static=%.1f objects=%d resources=%d" % [
					b.tex - a.tex, b.buf - a.buf, b.video - a.video, b.static - a.static, b.objects - a.objects, b.resources - a.resources])
				print("MEM NATIVE OK")
				quit(0)
	return false
