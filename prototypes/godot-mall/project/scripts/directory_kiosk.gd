## A mall directory kiosk (design/godot-directory.md; built by tools/stores/directory/kiosk.gd).
## It is an "interactable" (the shared interaction contract with workstream B+C): the player's
## action button calls interact() on the nearest one in reach, and interact_prompt() names it.
## Interacting opens the map of every stall (scripts/directory_ui.gd).
extends Node3D

const REACH := 2.4          # metres from the kiosk's centre, on its lit side

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("directory_kiosk")
	_ui()

## What the prompt says beside the action button.
func interact_prompt() -> String:
	return "Mall Directory"

## Open the map, the "You are here" dot on this kiosk.
func interact(player: Node) -> void:
	# PROTOTYPE ws/directory (design/godot-directory-legibility.md): ?dirlook=a|b|c tries a camera on the sign
	var look_mode: String = load("res://scripts/directory_look.gd").flag()
	if look_mode != "":
		_look().open(player, self, look_mode)
		return
	_ui().open(player, self)

## PROTOTYPE ws/directory: the camera-on-the-sign reader, one per scene (scripts/directory_look.gd).
func _look() -> Node:
	var scn := get_parent()
	if scn.has_meta("directory_look"):
		return scn.get_meta("directory_look")
	var lk := Node.new()
	lk.name = "DirectoryLook"
	lk.set_script(load("res://scripts/directory_look.gd"))
	scn.set_meta("directory_look", lk)
	scn.add_child(lk)
	return lk

## Whether p (a world position) is close enough, on the lit side or beside it (the back is plain).
func in_reach(p: Vector3) -> bool:
	var d := Vector2(p.x - position.x, p.z - position.z)
	if d.length() > REACH:
		return false
	var f: Vector2 = get_meta("face", Vector2(0, 1))
	return d.dot(f) > -0.2

## The one map for the whole scene: made by the first kiosk, kept at the end of the scene so its
## input comes before the player's.
func _ui() -> Node:
	var scn := get_parent()
	if scn.has_meta("directory_ui"):
		return scn.get_meta("directory_ui")
	var ui := CanvasLayer.new()
	ui.name = "DirectoryUI"
	ui.set_script(load("res://scripts/directory_ui.gd"))
	scn.set_meta("directory_ui", ui)
	scn.add_child.call_deferred(ui)
	return ui
