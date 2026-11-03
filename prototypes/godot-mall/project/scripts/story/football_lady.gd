## The football lady (workstream CUCOS, Nov 3 2026; design/godot-cucos.md): the crowd shopper who
## wears skin Ch02 (the purple sweatshirt with gold letters). She walks the mall like any shopper
## (scripts/npcs.gd); this node rides along with her and is the interactable, so wherever she is
## the player can walk up and talk. The conversation is data/story/cucos/football_lady.dialogue.
##
## While talking: her shopper is held (state "talk", which scripts/npcs.gd's _step leaves alone),
## stands, turns to the player and plays her idle; the talk camera frames her face
## (scripts/dialogue/dialogue_ui.gd via face_point()). After: she resumes her day.
## Not talkable while she sits in a salon chair or is mid-gesture between rooms (state other than
## "walk" / "dwell").
extends Node3D

const TURN_RATE := 5.0

var player: Node3D
var story: Node
var skin := "Ch02"
var dialogue := ""
var crowd: Node             # scripts/npcs.gd ("Shoppers")
var s = null                # her Shopper record (npcs.gd class Shopper), null while she's not in the crowd
var talking := false
var _rng := RandomNumberGenerator.new()

func setup(p: Node3D, st: Node, e: Dictionary) -> void:
	player = p
	story = st
	skin = str(e.get("skin", "Ch02"))
	dialogue = str(e.get("dialogue", ""))
	name = "FootballLady"
	top_level = true
	add_to_group("interactable")
	add_to_group("talker")
	_rng.randomize()

## Her shopper, if she is in the crowd now.
func find() -> Variant:
	if crowd == null or not is_instance_valid(crowd):
		crowd = player.get_parent().get_node_or_null("Shoppers") if player else null
	if crowd == null or not ("shoppers" in crowd):
		return null
	if s != null and s in crowd.shoppers and is_instance_valid(s.body):
		return s
	for x in crowd.shoppers:
		if x.body and is_instance_valid(x.body) and str(x.body.get("id")) == skin:
			return x
	return null

func _process(dt: float) -> void:
	s = find()
	if s == null:
		visible = false
		return
	visible = s.body.visible
	global_position = Vector3(s.pos.x, s.body.global_position.y, s.pos.z)
	if talking:
		s.body.face(_to_player(), TURN_RATE, dt)

func _to_player() -> Vector3:
	if player == null or s == null:
		return Vector3.FORWARD
	var d := player.global_position - s.body.global_position
	d.y = 0.0
	return d if d.length() > 0.05 else Vector3.FORWARD

# ------------------------------------------------------------------ the interact contract
func interact_prompt() -> String:
	if talking or s == null or dialogue == "":
		return ""
	return "TALK" if str(s.state) in ["walk", "dwell"] else ""

func interact(_p: Node) -> void:
	if story and dialogue != "":
		story.talk(self, dialogue)

## The talk camera's target: her eyes.
func face_point() -> Vector3:
	return s.body.eye_pos() if s else global_position + Vector3(0, 1.6, 0)

func talk_begin(_p: Node) -> void:
	talking = true
	if s == null:
		return
	s.state = "talk"
	s.path = PackedVector3Array()
	s.body.set_speed(0.0)
	s.body.play("idle")
	s.body.face(_to_player())

func talk_end() -> void:
	talking = false
	if s == null:
		return
	# back to her day: a short pause where she stands, then her next goal (npcs.gd _dwell_done)
	s.state = "dwell"
	s.timer = _rng.randf_range(2.0, 4.0)
	s.goal = {"type": "start"}

## A one-shot gesture from the dialogue (`$> act("thinking")`).
func act(clip: String) -> void:
	if s and s.body.has_method("gesture") and NpcBody.has_clip(clip):
		s.body.gesture(clip)
