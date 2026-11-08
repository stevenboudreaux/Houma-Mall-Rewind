## A counter attendant (workstream Q; design/godot-dialogue.md "Attendants"): one person behind a
## store's counter, from data/story/attendants.json. Made by scripts/dialogue/story.gd.
##
## This node is the interactable (groups "interactable" and "talker"), standing where the player
## stands to talk: on the shop side of the counter (`talk_at`), so the 1.6 m reach works across a
## counter. The body (an NpcBody, scripts/npc_body.gd) is a top-level child behind the counter:
##  - wanders a little: every WANDER_S seconds a new spot inside `area` (a small rect behind the
##    counter, world metres), walked at WALK_MPS; it never leaves the rect;
##  - turns to face the player when the player is within FACE_M (flat), otherwise faces `face`
##    (the counter) while standing;
##  - in a conversation: stops, turns to the player, plays its idle (talk_begin / talk_end).
## Steven writes who they are; until then the name and the file are PLACEHOLDERs.
extends Node3D

const WANDER_S := Vector2(4.0, 9.0)
const WALK_MPS := 0.55
const FACE_M := 3.0
const TURN_RATE := 5.0

var player: Node3D
var story: Node
var entry := {}
var body: NpcBody
var area := Rect2()
var face_dir := Vector3.FORWARD
var dialogue := ""
var display_name := ""
var talking := false
var _goal := Vector3.ZERO
var _wait := 1.0
var _rng := RandomNumberGenerator.new()

func setup(p: Node3D, st: Node, e: Dictionary) -> bool:
	player = p
	story = st
	entry = e
	name = "Attendant_" + str(e.get("id", "x"))
	dialogue = str(e.get("dialogue", ""))
	display_name = str(e.get("name", ""))
	var a: Array = e.get("area", [])
	area = Rect2(float(a[0]), float(a[1]), float(a[2]) - float(a[0]), float(a[3]) - float(a[1]))
	var f: Array = e.get("face", [0, -1])
	face_dir = Vector3(float(f[0]), 0, float(f[1])).normalized()
	var t: Array = e.get("talk_at", [area.get_center().x, area.get_center().y])
	position = Vector3(float(t[0]), 0, float(t[1]))
	add_to_group("interactable")
	add_to_group("talker")
	# CHAR-STRIP (Nov 8 2026, design/godot-avatar.md): the body comes from the one loader. "look":
	# "cast" + "cast": "<id>" = that cast member (data/cast.json); "look": "mixamo" = the Mixamo skin
	# the entry names (attendants with no cast member yet; written in the data, never a runtime test).
	# A missing file = no attendant (Cast logs the error), never a stand-in.
	body = Cast.attendant_body(e)
	if body == null:
		return false
	body.top_level = true
	add_child(body)
	body.play(str(e.get("idle", "idle")))
	var c := area.get_center()
	body.global_position = Vector3(c.x, 0, c.y)
	body.face(face_dir)
	_goal = body.global_position
	_rng.randomize()
	_wait = _rng.randf_range(WANDER_S.x, WANDER_S.y)
	return true

# ------------------------------------------------------------------ the interact contract
func interact_prompt() -> String:
	return "" if talking or body == null else "TALK"

func interact(p: Node) -> void:
	# --- R (the redemption screen, session R; design/godot-prize-counter.md): the Pocket Change
	# attendant opens it, else falls through to the PLACEHOLDER dialogue
	if bool(entry.get("redemption", false)) and p.mall and "redemption" in p.mall and p.mall.redemption \
			and p.mall.redemption.has_method("open"):
		p.mall.redemption.open()
		return
	# --- end R
	# --- SHOPS (design/godot-shops.md): a shop's attendant ("shop": id) opens its list
	if str(entry.get("shop", "")) != "" and p.mall and "shop" in p.mall and p.mall.shop \
			and p.mall.shop.open(str(entry.shop), self):
		return
	# --- end SHOPS
	if story and dialogue != "":
		story.talk(self, dialogue)

## The talk camera's target: the eyes.
func face_point() -> Vector3:
	return body.eye_pos() if body else global_position + Vector3(0, 1.6, 0)

func talk_begin(_p: Node) -> void:
	talking = true
	if body:
		body.set_speed(0.0)
		body.play(str(entry.get("idle", "idle")))
		_goal = body.global_position
		# turn to the player at once: the camera is framed on the line between them
		body.face(_to_player())

func talk_end() -> void:
	talking = false
	_wait = _rng.randf_range(WANDER_S.x, WANDER_S.y)

# ------------------------------------------------------------------ each frame
func _to_player() -> Vector3:
	if player == null:
		return face_dir
	var d := player.global_position - body.global_position
	d.y = 0.0
	return d if d.length() > 0.05 else face_dir

func _process(dt: float) -> void:
	if body == null:
		return
	var near := player != null and _to_player().length() < FACE_M
	if talking:
		body.face(_to_player(), TURN_RATE, dt)
		return
	var p := body.global_position
	var to_goal := Vector3(_goal.x - p.x, 0, _goal.z - p.z)
	if to_goal.length() > 0.05:
		var step := minf(WALK_MPS * dt, to_goal.length())
		var np := p + to_goal.normalized() * step
		np.x = clampf(np.x, area.position.x, area.end.x)
		np.z = clampf(np.z, area.position.y, area.end.y)
		body.global_position = np
		body.set_speed(WALK_MPS)
		body.face(to_goal, TURN_RATE, dt)
		return
	body.set_speed(0.0)
	body.face(_to_player() if near else face_dir, TURN_RATE * 0.6, dt)
	_wait -= dt
	if _wait <= 0.0 and not near:
		_wait = _rng.randf_range(WANDER_S.x, WANDER_S.y)
		_goal = Vector3(_rng.randf_range(area.position.x, area.end.x), 0, _rng.randf_range(area.position.y, area.end.y))
