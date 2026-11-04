## B2 (design/godot-character-editor.md): the player's avatar as a B1 body dressed from the player's
## preset (localStorage "mall-avatar-preset-1", made in the menu's AVATAR tab by
## scripts/chars/char_editor.gd). Stands in for V's AvatarBody in scripts/avatar.gd: the same
## `info.sex`, `mats`, `hand` (the right-hand holder for a held item in third person) and show_body().
## Before a preset exists, V's saved look (body sex, skin, hair, the year's top / bottom colours)
## is turned into one, so a returning player keeps their colours.
class_name AvatarChar
extends CharBody

const Look = preload("res://scripts/avatar_look.gd")

var info := {}
var mats: Array = []
var hand: Node3D

## True when this pack ships the B1 bodies (else avatar.gd keeps V's body), and the animations they
## play (CHARS, Nov 3: without npc/anims.res a body would stand in its bind pose).
static func available() -> bool:
	var b: Dictionary = CharBody.cman().get("bodies", {})
	return not b.is_empty() and ResourceLoader.exists(str(b.female.glb)) and ResourceLoader.exists(str(b.male.glb)) \
		and ResourceLoader.exists("res://npc/anims.res")

## V's look -> a preset (used until the player saves one in the editor).
static func from_look(L: Dictionary, year: int) -> Dictionary:
	var info_v := Look.body(str(L.get("body", Look.DEFAULT_BODY)))
	var sex := "female" if str(info_v.get("sex", "m")) == "f" else "male"
	var cl: Dictionary = L.get(Look.year_key(year), {})
	var p := CharPreset.blank(sex)
	p.id = "player"
	if str(L.get("skin", "")) != "": p.skin = str(L.skin)
	p.hair = {"id": "hair_shoulder" if sex == "female" else "hair_crew", "color": str(L.get("hair", "")) if str(L.get("hair", "")) != "" else "#3b2619"}
	p.outfit.top = "top_tee"
	p.outfit.bottom = "bot_jeans"
	p.outfit.shoes = "shoe_sneakers"
	p.outfit.colors = {}
	if str(cl.get("top", "")) != "": p.outfit.colors["top_tee"] = {"main": str(cl.top)}
	if str(cl.get("bottom", "")) != "": p.outfit.colors["bot_jeans"] = {"main": str(cl.bottom)}
	return CharPreset.normalize(p)

## The player's preset, or one made from V's look.
static func preset_for(L: Dictionary, year: int) -> Dictionary:
	var p := CharPreset.player_preset()
	return p if not p.is_empty() else from_look(L, year)

## Dress as the player's preset (rebuilt from scratch, then baked: one body, changed only on Done).
func wear_look(L: Dictionary, year: int) -> void:
	var p := preset_for(L, year)
	# CHAR-EDITOR: a new skin brings a new AnimationPlayer: forget the old one's clip, or play("idle")
	# (which skips the clip already playing) leaves the new body standing in its T-pose
	clip = ""
	base = "idle"
	make(str(p.body))
	CharPreset.dress(self, p)
	CharPreset.bake(self)
	info = {"sex": "f" if str(p.body) == "female" else "m", "id": "b2_player",
		"height_m": float(CharBody.cman().bodies[str(p.body)].height_m) * (1.0 + float(p.keys.get("height", 0.0)) * 0.14)}
	_attach_hand()
	clip = ""
	play("idle", 0.0, false)

func _attach_hand() -> void:
	hand = null
	var rh := sk.find_bone("mixamorig_RightHand")
	if rh < 0: return
	var hb := BoneAttachment3D.new()
	hb.bone_idx = rh
	sk.add_child(hb)
	hand = Node3D.new()
	hand.name = "Hand"
	hb.add_child(hand)
	# undo the skeleton's own scale so an item keeps its size in the hand
	var t := Transform3D()
	var c: Node = sk
	while c and c != self:
		if c is Node3D: t = (c as Node3D).transform * t
		c = c.get_parent()
	var s := t.basis.get_scale().x * sk.get_bone_global_rest(rh).basis.get_scale().x
	hand.scale = Vector3.ONE / maxf(s, 0.001)

func show_body(on: bool) -> void:
	visible = on
