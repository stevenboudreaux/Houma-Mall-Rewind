## MENU2 (Nov 3 2026, design/godot-menu.md "Time travel at the directory"): the only way to change
## year. The year toggle on a mall directory (scripts/directory_ui.gd) starts a trip:
##   1. the directory closes; you stand at the kiosk in your own view (first or third person);
##   2. the time-travel effect (scripts/timetravel.tscn) ramps up into its vortex and keeps looping;
##   3. the other year's file loads: on the web the page reloads (each wing / year is its own pack,
##      web/shell.html), and the shell carries the same vortex over the reload in WebGL on a picture
##      of your last frame, with no load screen; in the editor / native tests the scene changes and
##      this node, on the root, simply carries on;
##   4. the new year's player picks the vortex up at the same moment (arrive()), the shell's overlay
##      fades into it, and it unwinds: you stand at the same directory in the other year, facing the
##      same way.
## The directory's twin in the other year: data/directory_twins.json. Where you stand relative to the
## kiosk is kept (turned with the kiosk if its twin faces another way).
extends Node

const TT := "res://scripts/timetravel.tscn"
const TWINS := "res://data/directory_twins.json"
## How long the effect runs here before the other year starts loading (s): through the three flashes
## and into the vortex.
const GO_AFTER := 1.75
## The longest a trip may be resumed after (s): an old trip left in the session is not replayed.
const STALE := 120.0
## web/shell.html's overlay fade, waited for before the vortex unwinds (s).
const SHELL_FADE := 0.35

var tt: CanvasLayer = null
var player: Node = null
var from_year := 1995
var to_year := 2026

## The twin of the kiosk at (x, z) in year y: {"wing", "x", "z", "face": Vector2, "here_face", "known"}.
## known = false: no kiosk at this spot in the other year (then the same spot, a guess).
static func twin(y: int, x: float, z: float) -> Dictionary:
	var other := 2026 if y == 1995 else 1995
	var out := {"known": false, "wing": 0, "x": x, "z": z, "face": Vector2(0, 1), "here_face": Vector2(0, 1), "found": false}
	if not FileAccess.file_exists(TWINS):
		return out
	var d = JSON.parse_string(FileAccess.get_file_as_string(TWINS))
	if not (d is Dictionary):
		return out
	var best := 1.5
	for k in d.get("kiosks", []):
		var h = k.get(str(y))
		if not (h is Dictionary):
			continue
		var dd := Vector2(float(h.x) - x, float(h.z) - z).length()
		if dd > best:
			continue
		best = dd
		out.found = true
		out.wing = int(k.get("wing", 0))
		out.here_face = Vector2(float(h.face[0]), float(h.face[1])).normalized()
		var t = k.get(str(other))
		if t is Dictionary:
			out.known = true
			out.x = float(t.x); out.z = float(t.z)
			out.face = Vector2(float(t.face[0]), float(t.face[1])).normalized()
		else:
			out.known = false
			out.x = float(h.x); out.z = float(h.z)
			out.face = out.here_face
	return out

## Where the player lands: their place relative to the kiosk, carried to the twin. Returns
## {"x", "z", "yaw"} (yaw in radians, the player's convention).
static func landing(tw: Dictionary, kx: float, kz: float, px: float, pz: float, yaw: float) -> Dictionary:
	var a: float = (tw.face as Vector2).angle() - (tw.here_face as Vector2).angle()
	var rel := Vector2(px - kx, pz - kz).rotated(a)
	# yaw 0 looks along -z, 90° along -x: a turn of the floor by a turns the view by -a
	return {"x": float(tw.x) + rel.x, "z": float(tw.z) + rel.y, "yaw": yaw - a}

## Start a trip from kiosk k (a node with a position). Called by the directory's year toggle.
static func begin(p: Node, k: Node3D) -> void:
	if p == null or p.get("leaving") or p.get("vr_on"):
		return
	var trip = load("res://scripts/timetravel_trip.gd").new()
	trip.name = "TimeTravelTrip"
	p.get_tree().root.add_child(trip)
	trip._go(p, k)

func _go(p: Node, k: Node3D) -> void:
	player = p
	from_year = int(p.year)
	to_year = 2026 if from_year == 1995 else 1995
	var tw := twin(from_year, k.position.x, k.position.z)
	var w: int = tw.wing if tw.found and int(tw.wing) != 0 else (int(p.wing) if int(p.wing) != 0 else 1)
	var ld := landing(tw, k.position.x, k.position.z, p.position.x, p.position.z, p.yaw)
	print("time travel: %d -> %d from kiosk (%.1f, %.1f) to wing %d (%.2f, %.2f)%s" % [from_year, to_year,
		k.position.x, k.position.z, w, ld.x, ld.z, "" if tw.known else " (no twin: same spot, a guess)"])
	p.leaving = true
	p.frozen = true
	if p.prompt:
		p.prompt.visible = false
	p.move_vec = Vector2.ZERO
	# the walking view first: two frames after the directory closed, then a picture of it for the
	# shell's overlay (the web only)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var snap := ""
	if OS.has_feature("web"):
		snap = _snapshot()
	tt = load(TT).instantiate()
	add_child(tt)
	tt.start_loop(from_year, to_year)
	var began: float = tt.start_unix
	await get_tree().create_timer(GO_AFTER).timeout
	var day: bool = not p.buttons[2].button_pressed if p.buttons.size() > 2 else true
	if OS.has_feature("web"):
		var info := {"start": began, "from": from_year, "to": to_year, "snap": snap}
		var cam_s := "%.2f,%.2f,%.1f,%.1f" % [ld.x, ld.z, rad_to_deg(ld.yaw), rad_to_deg(p.pitch)]
		var js := "(function(){try{sessionStorage.setItem('mall-tt',%s)}catch(e){console.warn('time travel: no session storage',e)}" % JSON.stringify(JSON.stringify(info))
		js += "var u=new URL(location.href);var q=u.searchParams;q.set('wing','%d');q.set('cam','%s');" % [w, cam_s]
		js += ("q.set('year','2026');" if to_year == 2026 else "q.delete('year');")
		js += "q.set('time','%s');" % ("day" if day else "night")
		js += "if(%s)q.set('refl','0');else q.delete('refl');" % ("true" if not p._refl_wanted() else "false")
		js += "if(%s)q.set('fx','1');else q.delete('fx');" % ("true" if p.buttons.size() > 1 and p.buttons[1].button_pressed else "false")
		js += "console.log('time travel to '+u.toString());if(window.mallGoWing){window.mallGoWing(u.toString())}else{location.replace(u.toString())}})()"
		JavaScriptBridge.eval(js, true)
		return
	# native: change the scene; this node stays on the root and keeps the vortex going
	var path := ("res://wing%d_2026.tscn" if to_year == 2026 else "res://wing%d.tscn") % w
	if not ResourceLoader.exists(path):
		push_warning("time travel: no scene " + path)
		tt.outro()
		await tt.finished
		p.leaving = false
		p.frozen = false
		queue_free()
		return
	Engine.set_meta("mall_xfer", {"x": ld.x, "z": ld.z, "yaw": ld.yaw, "pitch": p.pitch})
	Engine.set_meta("mall_arrived", true)
	Engine.set_meta("mall_tt", true)
	player = null
	get_tree().change_scene_to_file(path)

## A small JPEG of the screen (base64), for the shell's overlay over the reload.
func _snapshot() -> String:
	var img := get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		return ""
	var w := 480
	if img.get_width() > w:
		img.resize(w, maxi(1, int(round(float(img.get_height()) * w / img.get_width()))), Image.INTERPOLATE_BILINEAR)
	var buf := img.save_jpg_to_buffer(0.7)
	return Marshalls.raw_to_base64(buf)

## Called by every player at start (scripts/player.gd _ready): a trip in progress lands here.
static func arrive(p: Node) -> void:
	var root := p.get_tree().root
	var trip = root.get_node_or_null("TimeTravelTrip")
	if trip != null and Engine.has_meta("mall_tt"):
		Engine.remove_meta("mall_tt")
		trip._land(p, false)
		return
	if not OS.has_feature("web"):
		return
	var s = JavaScriptBridge.eval("window.__mallTT||''", true)
	if not (s is String) or s == "":
		return
	var info = JSON.parse_string(s)
	if not (info is Dictionary):
		return
	var began := float(info.get("start", 0.0))
	if began <= 0.0 or Time.get_unix_time_from_system() - began > STALE:
		return
	trip = load("res://scripts/timetravel_trip.gd").new()
	trip.name = "TimeTravelTrip"
	root.add_child(trip)
	trip.from_year = int(info.get("from", 1995))
	trip.to_year = int(info.get("to", 2026))
	trip.tt = load(TT).instantiate()
	trip.add_child(trip.tt)
	trip.tt.start_loop(trip.from_year, trip.to_year, began)
	trip._land(p, true)

func _land(p: Node, web: bool) -> void:
	player = p
	p.frozen = true
	if web:
		# the shell's overlay lifts when the new year is ready (its load-screen rule); then it fades
		# into this vortex, and the vortex unwinds
		JavaScriptBridge.eval("window.__mallTTGodot=1", true)
		while str(JavaScriptBridge.eval("window.__mallTTLifted?'1':''", true)) != "1":
			await get_tree().process_frame
		await get_tree().create_timer(SHELL_FADE).timeout
	else:
		await get_tree().create_timer(0.3).timeout
	if tt:
		tt.outro()
		await tt.finished
	if is_instance_valid(p):
		p.frozen = false
		p.set_meta("tt_landed", Time.get_ticks_msec())
	if is_instance_valid(p):
		print("time travel: arrived in %d at %.2f,%.2f yaw %.1f" % [to_year, p.position.x, p.position.z, rad_to_deg(p.yaw)])
	if web:
		JavaScriptBridge.eval("window.__mallTTDone=1", true)
	queue_free()
