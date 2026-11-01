## An item lying in the world, waiting to be picked up (workstream B+C; design/godot-interaction.md).
## One of the "interactable" nodes of scripts/interact.gd: the prompt reads "Pick up <name>"
## (or "Take <name>" for a pocket item), and interact() moves it into the player's hands or
## pockets through player.mall (scripts/inventory.gd), then frees itself.
## Made by interact.gd from data/items/*.json ("place") and from drops ("moved").
extends Node3D

var entry: Dictionary = {}
var system: Node          # scripts/interact.gd

func setup(e: Dictionary, sys: Node) -> void:
	entry = e
	system = sys
	name = "it_" + str(e.id)
	add_to_group("interactable")
	var ps = load(str(e.scene)) if ResourceLoader.exists(str(e.scene)) else null
	if ps is PackedScene:
		var inst: Node = ps.instantiate()
		add_child(inst)
		_pose(inst)

## A dropped hand item lies down if its scene says so (root meta "drop_pose" = "lie").
func _pose(inst: Node) -> void:
	if inst is Node3D and str(inst.get_meta("drop_pose", "")) == "lie" and bool(get_meta("dropped", false)):
		(inst as Node3D).rotation = Vector3(0, 0, PI * 0.5)
		(inst as Node3D).position.y = float(inst.get_meta("lie_y", 0.02))
	elif inst is Node3D and inst.has_meta("place_rot") and not bool(get_meta("dropped", false)):
		# the scene's resting pose at its data "place" (e.g. the stick leaning in its corner)
		(inst as Node3D).rotation_degrees = inst.get_meta("place_rot")

func interact_prompt() -> String:
	if entry.is_empty():
		return ""
	return ("Pick up " if str(entry["class"]) == "hand" else "Take ") + str(entry.name)

func interact(player: Node) -> void:
	if system and system.has_method("pick_up"):
		system.pick_up(self)
