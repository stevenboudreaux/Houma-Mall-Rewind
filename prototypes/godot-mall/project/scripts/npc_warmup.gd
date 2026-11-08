## NPC warm-up behind the loading screen (workstream H, Nov 1 2026; design/godot-performance.md).
##
## Without it, every shopper's first appearance stalls the frame twice: once when npcs.gd load()s
## its skin (.scn, meshes, VRAM textures) and npc/anims.res on the main thread, and again the first
## time a skinned mesh with that material is drawn, when the GL Compatibility renderer compiles
## the shader variant (skinning + lightmap probes, with and without the night self-light).
##
## This node runs before the crowd's first spawn, while web/shell.html still shows the loading
## card (the shell waits for window.__mallWarm == 1, see "warm-up" there):
##  1. loads npc/anims.res and every skin .scn this pack carries (threaded builds: ResourceLoader's
##     threaded loader; the no-threads web build: plain load()s, LOAD_BUDGET_MS of them per frame so
##     the card keeps updating), and holds the resources so later load()s are cache hits. The
##     render loop is paused meanwhile: nobody sees the canvas behind the card;
##  2. stands every skin as a real NpcBody a few metres in front of the camera, in batches, for
##     DRAW_FRAMES frames (twice: with and without the night self-light, when night is possible), so each material's
##     shader variants are compiled and its textures are on the GPU; the HTML card hides them;
##  3. frees the bodies and restores each skin's self-light to what npcs.gd will set. npcs.gd then
##     spawns the roles and the first crowd (still behind the card: every new body costs its
##     AnimationPlayer set-up, ~70 clips) and tells the shell the game is ready (ready_now()).
## Nothing it does is visible after the card lifts. ?warm=0 turns it off (for A/B measurements).
class_name NpcWarmup
extends Node

const DRAW_FRAMES := 2
const BATCH := 25       # all of them at once (19 skins ship today): 5 across, rows going back
const LOAD_BUDGET_MS := 400
## Held for the whole session so the skins stay in ResourceLoader's cache (npc_body.gd load()s by
## path). The skins are loaded anyway as the crowd fills in, so this costs no extra memory.
static var held := {}
## M (design/godot-menu.md): when set (scripts/npcs.gd, from npcs.json "years"), only these skin
## scenes are warmed (2026's few shoppers).
static var only: Array[String] = []

var paths: Array[String] = []
var self_light_on := 0.3      # npcs.json self_light_night (0 when lighting.json is day_only)
var self_light_now := 0.0     # what npcs.gd sets for the current lighting
var _stage := "load"
var _pending: Array[String] = []
var _bodies: Array = []
var _batch_from := 0
var _frames := 0
var _t0 := 0
var _threads := false
var _t_loaded := 0
var _t_bodies := 0
var done := false

signal finished

## The skins worth warming: every manifest skin whose scene this pack carries, and (CHAR-STRIP, Nov 8
## 2026) every cast file (scripts/cast.gd Cast.paths(): the player's body, the menu's portraits, cast
## attendants), so those are loaded and drawn once behind the card too: no body appears half-made.
static func skin_paths() -> Array[String]:
	var out: Array[String] = []
	for e in NpcBody.manifest().get("skins", []):
		var p := str(e.get("scn", ""))
		if p != "" and ResourceLoader.exists(p) and (only.is_empty() or p in only):   # M: only
			out.append(p)
	for p in Cast.paths():
		if not (p in out):
			if ResourceLoader.exists(p):
				out.append(p)
			else:
				push_error("npc_warmup: cast file %s is not in this pack" % p)
	return out

func _ready() -> void:
	_t0 = Time.get_ticks_msec()
	paths = skin_paths()
	_pending = paths.duplicate()
	_pending.append("res://npc/anims.res")
	_threads = OS.has_feature("threads")
	if _threads:
		for p in _pending:
			ResourceLoader.load_threaded_request(p, "", false)
	_js("window.__mallWarm=0")
	_say("Getting the shoppers ready…")
	# nothing on the canvas is seen behind the card: don't pay for frames while loading
	RenderingServer.render_loop_enabled = false

func _process(_dt: float) -> void:
	match _stage:
		"load": _poll_loads()
		"draw": _draw_step()

func _poll_loads() -> void:
	var left: Array[String] = []
	if not _threads:
		# the web build has no threads: the threaded loader would finish one file per frame. Load
		# directly instead, as many as fit in LOAD_BUDGET_MS per frame (the card stays responsive)
		var t := Time.get_ticks_msec()
		while not _pending.is_empty() and Time.get_ticks_msec() - t < LOAD_BUDGET_MS:
			var p: String = _pending.pop_front()
			var r = load(p)
			if r: held[p] = r
			else: push_warning("npc_warmup: could not load " + p)
		_say_progress()
		if _pending.is_empty(): _start_draw()
		return
	for p in _pending:
		var st := ResourceLoader.load_threaded_get_status(p)
		if st == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			left.append(p)
		elif st == ResourceLoader.THREAD_LOAD_LOADED:
			held[p] = ResourceLoader.load_threaded_get(p)
		else:
			push_warning("npc_warmup: could not load " + p)
	_pending = left
	_say_progress()
	if _pending.is_empty():
		_start_draw()

func _start_draw() -> void:
	_stage = "draw"
	_t_loaded = Time.get_ticks_msec()
	RenderingServer.render_loop_enabled = true

func _say_progress() -> void:
	_say("Getting the shoppers ready… %d/%d" % [paths.size() + 1 - _pending.size(), paths.size() + 1])

func _draw_step() -> void:
	var cam := get_viewport().get_camera_3d()
	if _bodies.is_empty():
		if _batch_from >= paths.size() or cam == null:
			_finish()
			return
		var n := mini(BATCH, paths.size() - _batch_from)
		var t := cam.global_transform
		for i in range(n):
			var b := NpcBody.new()
			b.set_skin({"id": "warm%d" % i, "scn": paths[_batch_from + i]})
			add_child(b)
			# rows of 5, 0.45 m apart, from 3.2 m out going back 0.8 m a row, centred in the view:
			# all inside the frustum, so every skin's draw call is issued
			var x := (float(i % 5) - 2.0) * 0.45
			var z := 3.2 + 0.8 * float(i / 5)
			b.global_position = t.origin - t.basis.z * z + t.basis.x * x - Vector3(0, 1.3, 0)
			b.face(t.origin - b.global_position)
			b.set_self_light(self_light_on)
			_bodies.append(b)
		_frames = 0
		_t_bodies = Time.get_ticks_msec()
		return
	_frames += 1
	# the night self-light is a second shader variant; only worth compiling if night can happen
	var both := not is_equal_approx(self_light_on, self_light_now)
	if both and _frames == DRAW_FRAMES:
		for b in _bodies: b.set_self_light(self_light_now)
	elif _frames >= DRAW_FRAMES * (2 if both else 1):
		for b in _bodies:
			b.set_self_light(self_light_now)           # shared materials: leave them as npcs.gd will
			b.queue_free()
		_batch_from += _bodies.size()
		_bodies.clear()

func _finish() -> void:
	if done: return
	done = true
	RenderingServer.render_loop_enabled = true
	set_process(false)
	var now := Time.get_ticks_msec()
	print("npc_warmup: %d skins + anims in %d ms (load %d, bodies %d, draw %d)" % [paths.size(), now - _t0,
		_t_loaded - _t0, _t_bodies - _t_loaded, now - _t_bodies])
	# npcs.gd lifts the card (ready_now) once it has also spawned the first crowd
	finished.emit()

## Tell web/shell.html the game needs no (more) warm-up: the card may lift.
static func ready_now() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__mallWarm=1", true)

func _say(t: String) -> void:
	_js("(function(){var e=document.getElementById('load-mb');if(e&&document.getElementById('status'))e.textContent=%s;})()" % JSON.stringify(t))

func _js(code: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval(code, true)
