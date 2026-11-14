## SEAMLESS stage 3 (Nov 13 2026, scripts/wing_stream.gd): pictures of the borders, natively (opengl3 under xvfb).
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/qa/stream_shots.gd -- \
##       --wing=1 [--year=2026] [--stream=0] [--need=4,2] --out=/tmp/prefix --cams="name:x,z,yaw,pitch;name2:..."
## Starts in --wing with streaming on (--stream=0: off, the stand-ins as they were), the cinema's gate open,
## waits until the wings in --need are in and peopled (default: every interior wing), then for each camera
## places the player there, lets 40 frames pass and saves <out>-<name>.jpg (the game's own first-person view).
extends SceneTree
var wing := 1
var year := 1995
var stream := true
var need := [1, 2, 4, 5, 6]
var out := "/tmp/stream"
var cams := []
var ws
var t := 0.0
var ci := -1
var frames := 0
func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wing="): wing = int(a.substr(7))
		elif a.begins_with("--year="): year = int(a.substr(7))
		elif a.begins_with("--stream="): stream = a.substr(9) != "0"
		elif a.begins_with("--need="): need = Array(a.substr(7).split(",")).map(func(v): return int(v))
		elif a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--cams="):
			for c in a.substr(7).split(";"):
				var nm := c.get_slice(":", 0); var v := c.get_slice(":", 1).split(",")
				cams.append([nm, float(v[0]), float(v[1]), float(v[2]), float(v[3])])
	Engine.set_meta("mall_state_%d" % year, "")
	Engine.set_meta("mall_stream", stream)
	Engine.set_meta("mall_stream_kind", "desktop")
	Engine.set_meta("mall_flags", {"v": 1, "flags": {"cinema_unlocked": true}})
	var scn: Node = load(("res://wing%d_2026.tscn" if year == 2026 else "res://wing%d.tscn") % wing).instantiate()
	root.add_child(scn); current_scene = scn
func _process(dt: float) -> bool:
	t += dt
	ws = root.get_node_or_null("WingStream")
	var p = current_scene.get_node_or_null("Player") if current_scene else null
	if ws == null or p == null: return false
	if ci == -1:
		ws.cfg["start_delay_s"] = 0.0
		var ok := t > 3.0
		if stream:
			for w in need:
				if not (w == ws.home_wing or ws.is_in(w)): ok = false
			if ws._span_changed(): ok = false
		if ok or t > 240.0:
			if not ok: print("NOT ALL IN: ", ws.span())
			ci = 0; frames = 0
		return false
	if ci >= cams.size():
		return true
	var c: Array = cams[ci]
	if frames == 0:
		p.position = Vector3(c[1], 0, c[2]); p.yaw = deg_to_rad(c[3]); p.pitch = deg_to_rad(c[4]); p._apply_rot()
		p.hint.visible = false
	frames += 1
	if frames >= 40:
		var img := root.get_texture().get_image()
		img.save_jpg("%s-%s.jpg" % [out, c[0]], 0.9)
		print("wrote %s-%s.jpg (home %d, in %s)" % [out, c[0], ws.home_wing, str(ws.span())])
		ci += 1; frames = 0
	return false
