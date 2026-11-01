## Headless check of COIN COMET's play positions (scripts/pusher_play.gd, workstream P):
##   godot --headless --path . --script res://tools/qa/pusher_play_test.gd
## Builds the hook under a stand-in Signs node carrying the wing-2 sign record, and checks the six
## interactables: group, contract methods, prompt text, and where they stand (on each side's
## front face, 0.527 m apart, in the cabinet's order). Prints PUSHER PLAY TEST OK or the failures.
extends SceneTree

var oks := 0
var errors: Array = []

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok:
		oks += 1
	else:
		errors.append(what)

class FakeSigns:
	extends Node
	var recs := {}
	func text_of(_id: String) -> String:
		return "COIN COMET"

func _initialize() -> void:
	var J = JSON.parse_string(FileAccess.get_file_as_string("res://gen/w2/signs.json"))
	var signs := FakeSigns.new()
	signs.name = "Signs"
	for r in J.get("signs", []):
		signs.recs[r.id] = r
	var wing := Node.new()      # stands in for the wing root, which names its gen folder
	wing.set_meta("gen", "res://gen/w2/")
	root.add_child(wing)
	wing.add_child(signs)
	_check(signs.recs.has("pc.pusher.1"), "wing 2 has the cabinet's sign record")
	var hook = load("res://scripts/pusher_play.gd").new()
	signs.add_child(hook)
	await process_frame      # the hook builds its nodes in _ready
	var nodes := get_nodes_in_group("interactable")
	_check(nodes.size() == 6, "six positions (%d)" % nodes.size())
	var pos := {}
	for n in nodes:
		_check(n is Node3D and n.has_method("interact_prompt") and n.has_method("interact"), "%s follows the contract" % n.name)
		_check(n.interact_prompt() == "Play COIN COMET", "%s prompt: %s" % [n.name, n.interact_prompt()])
		pos[n.pos] = n.position
	# side A (marquee facing +x): x = cabinet front -105.68, z = 65.5 - PX; side B: x = -107.32, z = 65.5 + PX
	_check(pos.has(1) and absf(pos[1].x - -105.68) < 0.02 and absf(pos[1].z - 66.027) < 0.02, "position 1 at the +x front, z 66.03 (%s)" % str(pos.get(1)))
	_check(pos.has(3) and absf(pos[3].z - 64.973) < 0.02, "position 3 at z 64.97 (%s)" % str(pos.get(3)))
	_check(pos.has(4) and absf(pos[4].x - -107.32) < 0.02 and absf(pos[4].z - 64.973) < 0.02, "position 4 at the -x front, z 64.97 (%s)" % str(pos.get(4)))
	_check(pos.has(6) and absf(pos[6].z - 66.027) < 0.02, "position 6 at z 66.03 (%s)" % str(pos.get(6)))
	_check(pos.has(2) and absf(pos[2].z - 65.5) < 0.02 and pos.has(5) and absf(pos[5].z - 65.5) < 0.02, "positions 2 and 5 at the middle")
	# off the web, play() only prints
	if nodes.size() > 0:
		nodes[0].interact(null)
	# a wing without the record makes nothing
	var signs2 := FakeSigns.new()
	wing.add_child(signs2)
	var hook2 = load("res://scripts/pusher_play.gd").new()
	signs2.add_child(hook2)
	await process_frame
	_check(hook2.get_child_count() == 0, "no positions without the sign record")
	printerr("PUSHER PLAY TEST OK (%d checks)" % oks if errors.is_empty() else "PUSHER PLAY TEST FAILED: " + str(errors))
	quit(0 if errors.is_empty() else 1)
