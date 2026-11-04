## The "You received" pop-up (workstream R, Steven Nov 2 2026; design/godot-prize-counter.md "The pop-up
## contract"). Made by scripts/interact.gd in every wing and year.
##
## THE CONTRACT: scripts/inventory.gd emits mall.received(id) for every item that enters the player's
## things from outside, all through mall.receive() (ITEMS, Nov 4 2026; design/godot-items.md): bought (a
## shop, a dialogue's buy), won (the redemption counter, a game page), given (a dialogue's give), picked
## up (mall.take). Moving a thing between the hand and the bag (hold, put away) doesn't. Each one shows a
## card here: the item's icon (data/items "icon"; the Blender items' are 256 px renders), its name, "You
## received <name>" and where it went: "In your hand" (a holdable thing; how to put it in the bag) or
## "In your bag". After a short minimum (MIN_TIME) any key, button, click or tap dismisses it. Several in
## a row queue up and show one after another.
## While a card shows, the player is held (player.frozen) and mall meta "popup_open" is true, so the
## screen under it (the redemption screen) leaves the input alone.
extends Node

const MIN_TIME := 0.6        # seconds before a press can dismiss the card

var player: Node3D
var mall                     # scripts/inventory.gd
var db                       # scripts/items/item_db.gd
var queue: Array = []        # [item id, "hand" | "bag"] waiting
var current := ""
var shown_for := 0.0
var _froze := false

var ui: CanvasLayer
var card: PanelContainer
var icon_r: TextureRect
var name_l: Label
var line_l: Label
var hint_l: Label
var input_kind := "kb"

## Wire it to the carried state (listens to mall.received). Returns self.
func setup(p: Node3D, m, item_db):
	player = p
	mall = m
	db = item_db
	mall.received.connect(show_item)
	return self

## Where id went, read when it is received (mall.receive emits after placing it): "hand" or "bag".
func _where(id: String) -> String:
	return "hand" if mall != null and "hand" in mall and str(mall.hand) == id else "bag"

func is_showing() -> bool:
	return current != ""

## Show (or queue) the card for item id.
func show_item(id: String) -> void:
	var where := _where(id)
	if current != "":
		queue.append([id, where])
		return
	_show(id, where)

var where_l: Label
var current_where := ""
func _show(id: String, where := "bag") -> void:
	if ui == null:
		_build_ui()
	current = id
	shown_for = 0.0
	var e: Dictionary = db.get_item(id) if db else {}
	var nm := str(e.get("name", id))
	name_l.text = nm
	line_l.text = "You received %s" % nm
	current_where = where
	where_l.text = "In your hand" if where == "hand" else "In your bag"
	var ic := str(e.get("icon", ""))
	icon_r.texture = load(ic) if ic != "" and ResourceLoader.exists(ic) else null
	hint_l.text = ""
	ui.visible = true
	mall.set_meta("popup_open", true)
	if player and not player.frozen:
		player.frozen = true
		_froze = true
	if player and "move_vec" in player:
		player.move_vec = Vector2.ZERO
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(0.85, 0.85)
	card.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate:a", 1.0, 0.14)

func dismiss() -> void:
	if current == "":
		return
	current = ""
	if not queue.is_empty():
		var q: Array = queue.pop_front()
		_show(str(q[0]), str(q[1]))
		return
	ui.visible = false
	mall.set_meta("popup_open", false)
	if _froze and player:
		player.frozen = false
	_froze = false

func _process(dt: float) -> void:
	if current == "":
		return
	shown_for += dt
	if shown_for >= MIN_TIME and hint_l.text == "":
		hint_l.text = {"pad": "Press any button", "touch": "Tap to continue"}.get(input_kind, "Press any key")
		if current_where == "hand":   # ITEMS: how to put it away (actions.json put_away: R; the menu's INVENTORY)
			where_l.text = "In your hand" + ("  ·  R puts it in the bag" if input_kind == "kb" else "  ·  put it away from the Bag")

func _input(e: InputEvent) -> void:
	if e is InputEventJoypadButton:
		input_kind = "pad"
	elif e is InputEventKey or e is InputEventMouseButton:
		input_kind = "kb"
	elif e is InputEventScreenTouch:
		input_kind = "touch"
	if current == "":
		return
	var press: bool = (e is InputEventKey and e.pressed and not e.echo) \
		or (e is InputEventJoypadButton and e.pressed) \
		or (e is InputEventMouseButton and e.pressed) \
		or (e is InputEventScreenTouch and e.pressed)
	# every press and drag stops here while the card shows; a press after MIN_TIME dismisses it
	if not (e is InputEventMouseMotion):
		get_viewport().set_input_as_handled()
	if press and shown_for >= MIN_TIME:
		dismiss()

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 20              # over everything else on screen (redemption 16, prizes 15, HUD 12)
	ui.visible = false
	add_child(ui)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(center)
	card = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.99, 0.97, 0.9, 0.97)
	sb.border_color = Color(0.75, 0.05, 0.08)       # the prize cards' red
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 10
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(280, 0)
	center.add_child(card)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	card.add_child(v)
	var top := Label.new()
	top.text = "YOU RECEIVED"
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top.add_theme_font_size_override("font_size", 13)
	top.add_theme_color_override("font_color", Color(0.75, 0.05, 0.08))
	v.add_child(top)
	icon_r = TextureRect.new()
	icon_r.custom_minimum_size = Vector2(160, 160)
	icon_r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	v.add_child(icon_r)
	name_l = Label.new()
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.add_theme_font_size_override("font_size", 22)
	name_l.add_theme_color_override("font_color", Color(0.12, 0.08, 0.06))
	v.add_child(name_l)
	line_l = Label.new()
	line_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line_l.add_theme_font_size_override("font_size", 15)
	line_l.add_theme_color_override("font_color", Color(0.3, 0.24, 0.2))
	v.add_child(line_l)
	where_l = Label.new()       # ITEMS: where it went
	where_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	where_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	where_l.add_theme_font_size_override("font_size", 14)
	where_l.add_theme_color_override("font_color", Color(0.75, 0.05, 0.08))
	v.add_child(where_l)
	hint_l = Label.new()
	hint_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_l.custom_minimum_size = Vector2(0, 18)
	hint_l.add_theme_font_size_override("font_size", 12)
	hint_l.add_theme_color_override("font_color", Color(0.45, 0.4, 0.36))
	v.add_child(hint_l)
