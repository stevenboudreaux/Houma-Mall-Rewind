## Device pixels on phones and Retina screens (ws/directory, Nov 4 2026; Steven: yes to full iPhone
## sharpness, project-wide; design/godot-directory-legibility.md "The sharpness lever").
## project.godot allow_hidpi=true makes the web canvas as big as the screen's real pixels (an iPhone:
## 3x its 390 x 844 points). This autoload then
##   - scales every 2D layer by the same factor (root.content_scale_factor), so the HUD, the menu and
##     every screen keep the size they had, only sharper;
##   - draws the 3D world at 1 / factor (root.scaling_3d_scale), so the GPU does the work it did
##     before. The directory reader raises it to 1.0 while the camera is on the sign
##     (scripts/directory_ui.gd _sharp()).
## Native windows report scale 1 (Linux, Windows) and are unchanged. Tests may force a factor with
## Engine.set_meta("hidpi", 3.0) before the first frame.
extends Node

const MAX_SCALE := 3.0

func _ready() -> void:
	_apply()
	_root().size_changed.connect(_apply)

func _root() -> Window:
	return (Engine.get_main_loop() as SceneTree).root

func factor() -> float:
	if Engine.has_meta("hidpi"):
		return float(Engine.get_meta("hidpi"))
	return clampf(DisplayServer.screen_get_scale(), 1.0, MAX_SCALE)

func _apply() -> void:
	var s := factor()
	var w := _root()
	if not is_equal_approx(w.content_scale_factor, s):
		w.content_scale_factor = s
	var want := 1.0 / s
	# the directory reader may have it at 1.0 while reading; leave that alone
	if not (Engine.get_main_loop() as SceneTree).get_nodes_in_group("hidpi_full").is_empty():
		return
	if w.use_xr:
		want = 1.0      # a headset renders its own eye buffers: never lower them
	w.scaling_3d_scale = want

## WebXR turns use_xr on later (scripts/vr.gd): put the 3D scale back to 1 then, and down again after.
var _xr := false
func _process(_dt: float) -> void:
	var on := _root().use_xr
	if on != _xr:
		_xr = on
		_apply()
