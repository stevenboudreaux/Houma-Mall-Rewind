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
	print("MEM %s wings=%s tex=%.1f buf=%.1f video=%.1f static=%.1f static_max=%.1f objects=%d resources=%d nodes=%d" % [
		label, str(m.wings), m.tex, m.buf, m.video, m.static, m.static_max, m.objects, m.resources, m.nodes])

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
			if frames > 600:   # one wing, its probes and crowd settled
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
			if frames > 600:
				_rec("two-wings")
				var a: Dictionary = rows[0]
				var b: Dictionary = rows[1]
				print("MEM delta tex=%.1f buf=%.1f video=%.1f static=%.1f objects=%d resources=%d" % [
					b.tex - a.tex, b.buf - a.buf, b.video - a.video, b.static - a.static, b.objects - a.objects, b.resources - a.resources])
				print("MEM NATIVE OK")
				quit(0)
	return false
