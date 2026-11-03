## Workstream M (design/godot-menu.md): the time-travel transition. A scene
## (scripts/timetravel.tscn) so it can be re-dressed: its look is the ColorRect's shader
## (scripts/timetravel.gdshader), driven by a few envelope values computed here (env()).
##
## MENU2 (Nov 3 2026, design/godot-menu.md "Time travel at the directory"): the trip from a mall
## directory (scripts/timetravel_trip.gd) runs it as a loop: start_loop() ramps up through the three
## flashes into the vortex and keeps looping for as long as the next year takes to load (across the
## page reload on the web, where web/shell.html carries on with the same formulas in WebGL), then
## outro() lets you out in the other year. Every value is a function of the wall-clock time since
## the trip began, so the Godot effect and the shell's overlay are in step at the hand-overs.
## play() is the old one-shot (ramp, flashes, fade to black), kept for any other caller.
##
## Sound: the "Hum" player is an empty slot (PLACEHOLDER: no sound yet); give it a stream and it
## plays with the effect.
extends CanvasLayer

signal finished

## The one-shot's length, in seconds (then the caller's fade and reload).
@export var duration := 1.5
## The outro's length, in seconds (the vortex unwinding into the other year).
@export var outro_time := 1.1

var from_year := 1995
var to_year := 2026
var start_unix := 0.0          # wall-clock second the trip began (shared with web/shell.html)
var mode := ""                 # "", "once", "loop", "outro"
var _t := 0.0
var _out_t := 0.0
var _rm := false
@onready var fx: ColorRect = $FX
@onready var hum: AudioStreamPlayer = $Hum

func _ready() -> void:
	layer = 60
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.visible = false
	_rm = _reduced_motion()

static func _pulse(t: float, at: float, w: float) -> float:
	var d := (t - at) / w
	return exp(-d * d)

## The envelope at t seconds into the trip (u = seconds into the outro, or < 0). The same formulas
## are in web/shell.html (ttEnv); change both together.
static func env(t: float, u: float, rm: bool) -> Dictionary:
	if rm:
		# reduced motion: no ripple, flashes or vortex, a dark veil that lifts
		var dk := 0.85 * smoothstep(0.0, 0.5, t)
		if u >= 0.0:
			dk *= 1.0 - smoothstep(0.0, 0.6, u)
		return {"amt": 0.0, "ph": 0.0, "flash": 0.0, "vort": 0.0, "dark": dk}
	var ph := t / 1.5
	var amt := smoothstep(0.0, 0.675, t)
	var vort := 0.85 * smoothstep(0.7, 1.7, t)
	# the three flashes of the original effect (at 14 %, 36 %, 62 % of 1.5 s), then a soft beat
	var flash := _pulse(t, 0.21, 0.0525) * 0.7 + _pulse(t, 0.54, 0.06) * 0.85 + _pulse(t, 0.93, 0.09)
	if t > 1.4:
		flash += 0.3 * pow(0.5 + 0.5 * sin((t - 1.4) * TAU / 1.6 - PI * 0.5), 8.0)
	if u >= 0.0:
		var k := 1.0 - smoothstep(0.0, 1.1, u)
		amt *= k
		vort *= 1.0 - smoothstep(0.0, 0.7, u)
		flash = maxf(flash * k, _pulse(u, 0.06, 0.14))
	return {"amt": amt, "ph": ph, "flash": flash, "vort": vort, "dark": 0.0}

## The old one-shot: from_y -> to_y, ending in black.
func play(from_y: int, to_y: int) -> void:
	_begin(from_y, to_y)
	mode = "once"
	_t = 0.0
	if hum.stream != null:
		hum.play()

## The trip: ramp up, then loop until outro(). began_unix: when the trip began (wall clock, s), so
## a trip resumed after a reload picks up where the shell's overlay is.
func start_loop(from_y: int, to_y: int, began_unix := 0.0) -> void:
	_begin(from_y, to_y)
	start_unix = began_unix if began_unix > 0.0 else Time.get_unix_time_from_system()
	mode = "loop"
	if hum.stream != null and not hum.playing:
		hum.play()
	_apply()

## The vortex unwinds into the room; finished fires when it is clear.
func outro() -> void:
	if mode != "loop":
		finished.emit()
		return
	mode = "outro"
	_out_t = 0.0

func elapsed() -> float:
	return Time.get_unix_time_from_system() - start_unix

func _begin(from_y: int, to_y: int) -> void:
	from_year = from_y
	to_year = to_y
	if not is_node_ready():
		await ready
	var m := fx.material as ShaderMaterial
	if m:
		m.set_shader_parameter("forward", 1.0 if to_y >= from_y else -1.0)
	fx.visible = true

func _process(dt: float) -> void:
	match mode:
		"once":
			_t += dt
			var p := clampf(_t / maxf(duration, 0.05), 0.0, 1.0)
			var e := env(p * 1.5, -1.0, _rm)
			e.vort = 0.0
			e.dark = smoothstep(0.78, 1.0, p)
			if _rm:
				e.dark = smoothstep(0.5, 1.0, p)
			_put_env(e)
			if p >= 1.0:
				mode = ""
				finished.emit()
		"loop":
			_apply()
		"outro":
			_out_t += dt
			_apply()
			if _out_t >= (0.6 if _rm else outro_time):
				mode = ""
				fx.visible = false
				finished.emit()

func _apply() -> void:
	_put_env(env(elapsed(), _out_t if mode == "outro" else -1.0, _rm))

func _put_env(e: Dictionary) -> void:
	var m := fx.material as ShaderMaterial
	if m == null:
		return
	for k in e:
		m.set_shader_parameter(k, e[k])

## Hold at a moment of the one-shot (p 0..1), for screenshots (tools/qa/menu_test.gd).
func hold(p: float) -> void:
	mode = ""
	fx.visible = true
	var e := env(p * 1.5, -1.0, false)
	e.vort = 0.0
	e.dark = smoothstep(0.78, 1.0, p)
	_put_env(e)

## Hold the trip at t seconds (the loop), for screenshots.
func hold_trip(t: float) -> void:
	mode = ""
	fx.visible = true
	_put_env(env(t, -1.0, false))

func _reduced_motion() -> bool:
	if not OS.has_feature("web"):
		return false
	return str(JavaScriptBridge.eval("(window.matchMedia&&window.matchMedia('(prefers-reduced-motion: reduce)').matches)?'1':'0'")) == "1"
