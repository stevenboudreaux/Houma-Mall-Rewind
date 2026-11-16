## TEST-DEBT (Nov 16 2026): the Rougarou for the QA suites.
## Since Oct 16 2026 the game no longer makes the Rougarou: the Runner (scripts/runner_ai.gd)
## replaced it, and scripts/player.gd keeps scripts/rougarou_ai.gd "kept but no longer made". So
## rougarou_test, rougarou_stalk_test and rougarou_woolworth_test make it themselves, the way
## player.gd used to (a node "RougarouAI" beside the Player, player = the Player, force = the
## ?rougarou= value). A pass means the kept code still works on today's wing; it says nothing
## about the shipped game, where no player ever meets it.
extends RefCounted

## Adds the RougarouAI to the wing scene once the Player is ready (its walk grid is read in
## _ready). force: "sightings", "stalk", "s3", ... as ?rougarou= took. Returns the node.
static func spawn(scn: Node, player: Node3D, force: String) -> Node:
	var rg = load("res://scripts/rougarou_ai.gd").new()
	rg.name = "RougarouAI"
	rg.player = player
	rg.force = force
	scn.add_child(rg)
	return rg

## True while the game itself made one (it should not: see above). The suites print it.
static func game_made_one(scn: Node) -> bool:
	return scn.get_node_or_null("RougarouAI") != null
