## B2 (design/godot-character-editor.md): frame cost of a preset character vs a Mixamo NPC.
## For each case, N bodies play the idle in a bare scene (one light, camera framing them) for FRAMES
## frames after a warm-up; prints the mean and 95th-percentile frame time, triangles drawn and the
## CPU process time. Cases: mixamo (Ch22, an attendant's old skin), preset_live (blend shapes),
## preset_baked (CharPreset.bake), each with 1 and 10 bodies.
##   godot --headless --path . --script res://tools/qa/char_perf.gd                    (CPU only)
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --script res://tools/qa/char_perf.gd
extends SceneTree

const FRAMES := 240
const WARM := 40
var cases := [["mixamo", 1], ["preset_live", 1], ["preset_baked", 1], ["mixamo", 10], ["preset_live", 10], ["preset_baked", 10]]
var stage: Node3D
var rows := []

func _initialize() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	await process_frame
	for c in cases:
		await _run(str(c[0]), int(c[1]))
	print("\nB2 PERF (%s, %s)" % [RenderingServer.get_video_adapter_name(), "headless" if DisplayServer.get_name() == "headless" else DisplayServer.get_name()])
	print("case            n   mean ms   p95 ms    fps   tris drawn   build ms/body")
	for r in rows:
		print("%-14s %2d  %8.2f  %7.2f  %6.0f  %10d   %8.0f" % r)
	quit()

func _run(kind: String, n: int) -> void:
	stage = Node3D.new()
	root.add_child(stage)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.0, 6.5 if n > 1 else 3.2)
	cam.fov = 50
	stage.add_child(cam)
	cam.look_at(Vector3(0, 0.9, 0))
	cam.current = true
	var l := DirectionalLight3D.new()
	l.rotation_degrees = Vector3(-40, 30, 0)
	stage.add_child(l)
	var p := CharPreset.get_preset("pocket_change", false)
	var skin := {}
	for s in NpcBody.manifest().skins:
		if str(s.id) == "Ch22": skin = s
	var t0 := Time.get_ticks_usec()
	for i in n:
		var b: NpcBody
		if kind == "mixamo":
			b = NpcBody.new()
			b.set_skin(skin)
		else:
			b = CharPreset.body_for(p, kind == "preset_baked")
		stage.add_child(b)
		b.position = Vector3((i % 5 - 2) * 0.9, 0, -(i / 5) * 1.2)
		b.play("idle")
	var build := float(Time.get_ticks_usec() - t0) / 1000.0 / n
	for i in WARM: await process_frame
	var times := []
	var last := Time.get_ticks_usec()
	var tris := 0
	for i in FRAMES:
		await process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now - last) / 1000.0)
		last = now
		tris = maxi(tris, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)))
	times.sort()
	var mean := 0.0
	for x in times: mean += x
	mean /= times.size()
	var p95: float = times[int(times.size() * 0.95)]
	rows.append([kind, n, mean, p95, 1000.0 / mean, tris, build])
	stage.queue_free()
	await process_frame
	await process_frame
