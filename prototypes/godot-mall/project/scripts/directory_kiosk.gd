## A mall directory kiosk (design/godot-directory.md; built by tools/stores/directory/kiosk.gd).
## It is an "interactable" (the shared interaction contract with workstream B+C): the player's
## action button calls interact() on the nearest one in reach, and interact_prompt() names it.
## Interacting brings the camera to the sign to read it (scripts/directory_ui.gd).
##
## The year switch (Steven, Nov 4 2026: the time-travel switch goes on the kiosk itself, not on the
## screen): a small dark plate on the frame's bottom rail, under the lit art, with two keys, "1990s"
## and "2026"; the year you are in is lit (the sign's own colour), the other is dark. It is made here
## at run time (dynamic, so no rebuild or rebake). It is pressed from the reader's whole-sign view
## (directory_ui.gd), or with Y while reading.
extends Node3D

const REACH := 2.4          # metres from the kiosk's centre, on its lit side
# the switch, in the kiosk's own frame (x to the viewer's right, z toward the viewer); kiosk.gd:
# the frame's bottom rail runs from PLINTH_H 0.46 to 0.58 m, its face at CAB_D / 2 + 0.016
const SWITCH_Y := 0.52
const SWITCH_Z := 0.166
const PLATE := Vector3(0.40, 0.088, 0.008)
const KEY := Vector3(0.182, 0.066, 0.006)
const KEY_X := 0.096
const LIT := {"1995": Color("#2a8a96"), "2026": Color("#3fa9d8")}   # the 1990s sign's teal, the 2026 sign's cyan
const LABEL := {"1995": "1990s", "2026": "2026"}

var switch_node: Node3D

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("directory_kiosk")
	_ui()
	_build_switch()

## What the prompt says beside the action button.
func interact_prompt() -> String:
	return "Mall Directory"

## Read the sign: the camera goes to it (scripts/directory_ui.gd).
func interact(player: Node) -> void:
	_ui().open(player, self)

## Whether p (a world position) is close enough, on the lit side or beside it (the back is plain).
func in_reach(p: Vector3) -> bool:
	var d := Vector2(p.x - position.x, p.z - position.z)
	if d.length() > REACH:
		return false
	var f: Vector2 = get_meta("face", Vector2(0, 1))
	return d.dot(f) > -0.2

## The one reader for the whole scene: made by the first kiosk, kept at the end of the scene so its
## input comes before the player's.
func _ui() -> Node:
	var scn := get_parent()
	if scn.has_meta("directory_ui"):
		return scn.get_meta("directory_ui")
	var ui := Node.new()
	ui.name = "DirectoryUI"
	ui.set_script(load("res://scripts/directory_ui.gd"))
	scn.set_meta("directory_ui", ui)
	scn.add_child.call_deferred(ui)
	return ui

## The year this kiosk stands in: "1995" (shown as 1990s) or "2026".
func year() -> String:
	if has_meta("year"):
		return str(get_meta("year"))
	var scn := get_tree().current_scene if is_inside_tree() else null
	if scn and scn.scene_file_path.contains("_2026"):
		return "2026"
	return "1995"

func _basis() -> Basis:
	var f: Vector2 = get_meta("face", Vector2(0, 1))
	var fw := Vector3(f.x, 0, f.y).normalized()
	return Basis((-fw).cross(Vector3.UP).normalized(), Vector3.UP, fw)

func _build_switch() -> void:
	switch_node = Node3D.new()
	switch_node.name = "YearSwitch"
	switch_node.basis = _basis()
	add_child(switch_node)
	var here := year()
	_box(Vector3(0, SWITCH_Y, SWITCH_Z + PLATE.z * 0.5), PLATE, Color("#1c1d20"), 0.0)
	for y in ["1995", "2026"]:
		var x := -KEY_X if y == "1995" else KEY_X
		var on: bool = y == here
		var z := SWITCH_Z + PLATE.z + KEY.z * 0.5
		_box(Vector3(x, SWITCH_Y, z), KEY, LIT[y] if on else Color("#2e3136"), 0.35 if on else 0.0)
		var l := Label3D.new()
		l.text = LABEL[y]
		l.font = load("res://fonts/sans.otf")
		l.font_size = 64
		l.pixel_size = 0.0005
		l.outline_size = 0
		l.shaded = false
		l.double_sided = false
		l.modulate = Color.WHITE if on else Color("#8d939a")
		l.position = Vector3(x, SWITCH_Y, z + KEY.z * 0.5 + 0.0008)
		l.name = "Key" + LABEL[y]
		switch_node.add_child(l)

func _box(c: Vector3, sz: Vector3, col: Color, glow: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = sz
	mi.mesh = bm
	var m := StandardMaterial3D.new()
	m.albedo_color = col
	m.roughness = 0.45
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = glow
	mi.material_override = m
	mi.position = c
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	switch_node.add_child(mi)

## Which key of the year switch a ray (world) hits: "1995", "2026" or "".
func switch_key_at(o: Vector3, d: Vector3) -> String:
	var b := _basis()
	var n: Vector3 = b.z
	var face := global_position + b * Vector3(0, SWITCH_Y, SWITCH_Z + PLATE.z + KEY.z)
	var den := d.dot(n)
	if absf(den) < 1e-5:
		return ""
	var w := o + d * ((face - o).dot(n) / den) - global_position
	var lx := w.dot(b.x)
	var ly := w.y - SWITCH_Y
	for y in ["1995", "2026"]:
		var x := -KEY_X if y == "1995" else KEY_X
		# a little slack round each key, so a finger finds it
		if absf(lx - x) <= KEY.x * 0.5 + 0.004 and absf(ly) <= KEY.y * 0.5 + 0.02:
			return y
	return ""

## Where a key of the switch is in the world (tests, shots).
func switch_key_pos(y: String) -> Vector3:
	var x := -KEY_X if y == "1995" else KEY_X
	return global_position + _basis() * Vector3(x, SWITCH_Y, SWITCH_Z + PLATE.z + KEY.z)
