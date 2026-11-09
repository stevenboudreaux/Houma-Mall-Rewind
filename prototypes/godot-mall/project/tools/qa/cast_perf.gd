## CHAR-BUILD (design/godot-cast.md "Cost"): frame cost of cast members vs a Mixamo shopper. For each case,
## N bodies play the idle in a bare scene (one light, a camera framing them; all within LOD0 range, or all
## beyond it with --far) for FRAMES frames after a warm-up; prints mean / p95 frame time, triangles and draw
## calls drawn, and build time per body. Same renderer path as the web build (Compatibility / opengl3).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/qa/cast_perf.gd [-- --far]
extends SceneTree

const FRAMES := 240
const WARM := 40
var far := false
var rows := []

func _initialize() -> void:
	far = "--far" in OS.get_cmdline_user_args()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await process_frame
	var cases := [["none", 0]]
	for k in ["mixamo:Ch22"] + Array(CastGlb.ids()):
		cases.append([k, 1]); cases.append([k, 10])
	for c in cases:
		await _run(str(c[0]), int(c[1]))
	print("\nCAST PERF (%s, %s, %s)" % [RenderingServer.get_video_adapter_name(), DisplayServer.get_name(), "LOD1 distance" if far else "LOD0 distance"])
	print("case                    n   mean ms   p95 ms    fps   tris drawn   draw calls   build ms/body")
	for r in rows:
		print("%-22s %2d  %8.2f  %7.2f  %6.0f  %10d   %9d   %8.0f" % r)
	quit()

func _run(kind: String, n: int) -> void:
	var stage := Node3D.new()
	root.add_child(stage)
	var cam := Camera3D.new()
	var dist := (14.0 if far else (6.5 if n > 1 else 3.2))
	cam.position = Vector3(0, 1.0, dist)
	cam.fov = 50 if not far else 22
	stage.add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0))
	cam.current = true
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-40, 30, 0)
	stage.add_child(l)
	var t0 := Time.get_ticks_usec()
	for i in n:
		var b: NpcBody
		if kind.begins_with("mixamo:"):
			var skin := {}
			for s in NpcBody.manifest().skins:
				if str(s.id) == kind.substr(7): skin = s
			b = NpcBody.new()
			b.set_skin(skin)
		else:
			b = CastGlb.body(kind)
		stage.add_child(b)
		b.position = Vector3((i % 5 - 2) * 0.9, 0, -(i / 5) * 1.2)
		b.play("idle")
	var build := float(Time.get_ticks_usec() - t0) / 1000.0 / maxi(n, 1)
	for i in WARM: await process_frame
	var times := []
	var last := Time.get_ticks_usec()
	var tris := 0; var calls := 0
	for i in FRAMES:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now - last) / 1000.0)
		last = now
		tris = maxi(tris, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
		calls = maxi(calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	times.sort()
	var mean := 0.0
	for x in times: mean += x
	mean /= times.size()
	var p95: float = times[int(times.size() * 0.95)]
	rows.append([kind, n, mean, p95, 1000.0 / mean, tris, calls, build])
	stage.queue_free()
	await process_frame
	await process_frame
