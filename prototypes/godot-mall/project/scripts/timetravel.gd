## Workstream M (design/godot-menu.md): the time-travel transition played when the year changes
## (player.gd _time_travel, before the existing fade and wing reload). A scene
## (scripts/timetravel.tscn) so it can be re-dressed: its look is the ColorRect's shader
## (scripts/timetravel.gdshader), driven by one value, progress 0 -> 1 over `duration`.
## Sound: the "Hum" player is an empty slot (PLACEHOLDER: no sound yet); give it a stream and it
## plays with the effect.
extends CanvasLayer

signal finished

## The one config value: how long the effect runs, in seconds (then the fade and the reload).
@export var duration := 1.5

var from_year := 1995
var to_year := 2026
var _t := 0.0
var _playing := false
@onready var fx: ColorRect = $FX
@onready var hum: AudioStreamPlayer = $Hum

func _ready() -> void:
	layer = 60
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.visible = false

## Start it: from_y -> to_y (forward in time when to_y > from_y).
func play(from_y: int, to_y: int) -> void:
	from_year = from_y
	to_year = to_y
	if not is_node_ready():
		await ready
	var m := fx.material as ShaderMaterial
	if m:
		m.set_shader_parameter("forward", 1.0 if to_y >= from_y else -1.0)
		m.set_shader_parameter("progress", 0.0)
	fx.visible = true
	if hum.stream != null:
		hum.play()
	_t = 0.0
	_playing = true
	# reduced motion (the 2D game's rule): no flashes, just the fade
	if _reduced_motion():
		if m:
			m.set_shader_parameter("progress", 0.8)
		var tw := create_tween()
		tw.tween_method(func(v: float): m.set_shader_parameter("progress", v), 0.8, 1.0, 0.4)
		tw.tween_callback(_end)
		_playing = false

func _process(dt: float) -> void:
	if not _playing:
		return
	_t += dt
	var p := clampf(_t / maxf(duration, 0.05), 0.0, 1.0)
	var m := fx.material as ShaderMaterial
	if m:
		m.set_shader_parameter("progress", p)
	if p >= 1.0:
		_playing = false
		_end()

## Hold at a moment of the effect, for screenshots (tools/qa/menu_test.gd).
func hold(p: float) -> void:
	_playing = false
	fx.visible = true
	var m := fx.material as ShaderMaterial
	if m:
		m.set_shader_parameter("progress", p)

func _end() -> void:
	finished.emit()

func _reduced_motion() -> bool:
	if not OS.has_feature("web"):
		return false
	return str(JavaScriptBridge.eval("(window.matchMedia&&window.matchMedia('(prefers-reduced-motion: reduce)').matches)?'1':'0'")) == "1"
