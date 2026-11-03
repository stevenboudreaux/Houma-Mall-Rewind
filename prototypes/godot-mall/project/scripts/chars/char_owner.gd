## B2 (design/godot-character-editor.md): the owner's way into the character editor. Made by
## scripts/player.gd as its child "CharOwner". With owner mode on (player.is_owner()), standing within
## REACH_M of an NPC that wears a preset (a counter attendant with "look": "preset", or a shopper
## swapped by npcs.json "presets"), the owner presses:
##   K (keyboard) · the left-stick click (gamepad) · the "Edit character (K)" button (touch, owner only)
## and scripts/chars/char_editor.gd opens on that NPC. Visitors never see the button and K does nothing.
extends Node

const EDITOR := preload("res://scripts/chars/char_editor.gd")
const REACH_M := 3.0

var player: Node3D
var editor: Node = null
var btn: Button
var _near: Dictionary = {}       # {"node", "body", "preset"} of the nearest NPC with a preset

## A crowd shopper's body (no attendant node): the editor talks to this instead.
class BodyTarget extends RefCounted:
	var body: CharBody
	func wear_preset(p: Dictionary, live := false) -> void:
		var at := body.global_position
		body.make(str(p.body))
		CharPreset.dress(body, p)
		if not live: CharPreset.bake(body)
		body.global_position = at
	func get_tree(): return body.get_tree()
	func get_viewport(): return body.get_viewport()
	func get_parent(): return body.get_parent()

func _ready() -> void:
	btn = Button.new()
	btn.text = "Edit character (K)"
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 14)
	btn.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	btn.offset_left = -90; btn.offset_right = 90
	btn.offset_top = -196; btn.offset_bottom = -162     # above the TALK prompt
	btn.visible = false
	btn.pressed.connect(open)
	player._cl.add_child(btn)

func _process(_dt: float) -> void:
	_near = {}
	var own: bool = player.is_owner() and not player.vr_on
	if own and editor == null and not player.frozen:
		_near = nearest()
	btn.visible = not _near.is_empty()

## The nearest NPC wearing a preset within REACH_M (flat), or {}.
func nearest() -> Dictionary:
	var best := {}
	var bd := REACH_M
	var pp: Vector3 = player.global_position
	for n in get_tree().get_nodes_in_group("talker"):
		if not n.has_method("preset_id") or n.preset_id() == "" or n.body == null: continue
		# CHARS (Nov 3): not while it still wears its Mixamo fallback (the character pack is on its way)
		if not (n.body is CharBody): continue
		var d := Vector2(n.body.global_position.x - pp.x, n.body.global_position.z - pp.z).length()
		if d < bd:
			bd = d
			best = {"node": n, "body": n.body, "preset": n.preset_id()}
	for b in get_tree().get_nodes_in_group("char_preset_npc"):
		if not (b is CharBody) or str(b.get_meta("preset", "")) == "": continue
		var d := Vector2(b.global_position.x - pp.x, b.global_position.z - pp.z).length()
		if d < bd:
			bd = d
			var t := BodyTarget.new()
			t.body = b
			best = {"node": t, "body": b, "preset": str(b.get_meta("preset"))}
	return best

## Open the editor on the nearest NPC with a preset (owner mode only).
func open() -> void:
	if editor != null or not player.is_owner() or player.vr_on or player.frozen:
		return
	var n := nearest()
	if n.is_empty():
		return
	var p := CharPreset.get_preset(str(n.preset))
	if p.is_empty():
		player._say("No preset file for " + str(n.preset))
		return
	editor = EDITOR.new()
	editor.setup("owner", p, n.node)
	editor.closed.connect(_closed)
	player.frozen = true
	player.move_vec = Vector2.ZERO
	player.move_touch = -1
	if player.stick: player.stick.visible = false
	add_child(editor)

func _closed(_look: Dictionary, _how: String) -> void:
	editor = null
	player.frozen = false

func _input(e: InputEvent) -> void:
	if editor != null or not player.is_owner() or player.frozen or player.vr_on:
		return
	var go := false
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_K:
		go = true
	elif e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_LEFT_STICK:
		go = true
	elif e is InputEventScreenTouch and e.pressed and btn.is_visible_in_tree() and btn.get_global_rect().has_point(e.position):
		go = true
	if go and not nearest().is_empty():
		get_viewport().set_input_as_handled()
		open()
