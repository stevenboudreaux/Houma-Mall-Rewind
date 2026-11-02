## One interaction system for the Godot mall (workstream B+C, Steven Nov 1 2026;
## design/godot-interaction.md). Made by player.gd in every wing and year, as the player's child.
##
## THE CONTRACT (other workstreams write to it; keep it exactly):
##   any Node3D in group "interactable" with
##     func interact_prompt() -> String     # what the action button will do; "" = not now
##     func interact(player: Node) -> void  # do it
##   The action button (E, a gamepad's X, or the round touch button that shows only while something
##   is in reach) calls interact() on the nearest visible one within REACH m (flat distance from the
##   player, height within 2.2 m) that is roughly in front (within ~70 degrees of the view). A small
##   prompt (bottom middle) shows the key and interact_prompt(). Optional: func on_hit(player) is
##   called when a held item with a swing (Martin Folse's stick) hits it.
##   The older prompts (the wing seam / doors in player.gd, Pocket Change's closer look, an arcade
##   cabinet's Play) win while they show: this prompt hides and the button does nothing.
##
## Also here: pick-up items (data/items/*.json via scripts/items/item_db.gd, lying in the world as
## scripts/items/pickup.gd), the item in the hand (drawn in first person), the swing, the
## inventory panel (I, a gamepad's Select/Back, the "Bag" button) and the carried state
## player.mall (scripts/inventory.gd: mall.inventory, mall.tickets; localStorage per year).
extends Node

const ItemDB = preload("res://scripts/items/item_db.gd")
const Inventory = preload("res://scripts/inventory.gd")
const Pickup = preload("res://scripts/items/pickup.gd")

const REACH := 1.6           # metres, flat, from the player to the interactable's origin
const FRONT_DOT := 0.34      # cos ~70 degrees: "roughly in front"
const SWING_REACH := 1.9
const HAND_AT := Vector3(0.2, -0.19, -0.42)   # the hand, in camera space

var player: Node3D
var db
var mall                     # scripts/inventory.gd
var items_root: Node3D       # pickups in the mall (hidden with the mall, e.g. in the Stockrooms)
var target: Node = null      # the interactable the button would use
var input_kind := "kb"

# ui
var ui: CanvasLayer
var prompt: Button
var prompt_key: Label
var prompt_text: Label
var act_btn: Button          # the round touch button
var bag_btn: Button
var panel: PanelContainer
var panel_list: VBoxContainer
var panel_rows: Array = []   # [{id, hand: bool, btns: [[Button, Callable]...]}]
var panel_sel := 0
var _froze := false

# the hand
var hand_root: Node3D
var hand_item: Node3D
var hand_id := ""
var swinging := false
var _whoosh: AudioStreamPlayer
var _sway_t := 0.0

func _ready() -> void:
	db = ItemDB.new().load_dir()
	mall = Inventory.new()
	mall.year = int(player.year) if player and "year" in player else 1995
	mall.load_saved()
	# a saved hand item that isn't an item of this year (data changed) goes back to the inventory
	if mall.hand != "" and not ItemDB.in_year(db.get_item(mall.hand), mall.year):
		mall.put_away()
	if player and "mall" in player:
		player.mall = mall
	mall.changed.connect(_on_changed)
	_build_ui()
	hand_root = Node3D.new()
	hand_root.name = "Hand"
	hand_root.position = HAND_AT
	player.cam.add_child(hand_root)
	_show_hand()
	_whoosh = AudioStreamPlayer.new()
	_whoosh.stream = _make_whoosh()
	_whoosh.volume_db = -8.0
	add_child(_whoosh)
	_spawn_world.call_deferred()

# ------------------------------------------------------------------ the world's items
func _spawn_world() -> void:
	await get_tree().process_frame     # the Stockrooms and the Prizes are added deferred too
	var root := player.get_parent()
	items_root = Node3D.new()
	items_root.name = "Items"
	root.add_child(items_root)
	for id in db.ids_for_year(mall.year):
		var e: Dictionary = db.get_item(id)
		var pl = mall.where(id, e.get("place", null))
		if pl == null or mall.has(id):
			continue
		_spawn(e, pl, mall.moved.has(id))

func _spawn(e: Dictionary, pl: Dictionary, dropped: bool) -> Node3D:
	var w := int(pl.get("wing", 0))
	var y = pl.get("year", e.year)
	if str(y) != "both" and int(y) != mall.year:
		return null
	if player.wing != 0 and w != 0 and w != player.wing:
		return null
	var p: Array = pl.pos
	var pos := Vector3(float(p[0]), float(p[1]), float(p[2]))
	var parent: Node3D = items_root
	# in the Stockrooms (built far off at its ORIGIN): a child of that level, so it shows only there
	var sr = player.get_parent().get_node_or_null("Stockrooms")
	if pos.distance_to(Vector3(2000, 0, 2000)) < 1000.0:
		if sr == null:
			return null
		parent = sr
	var n := Pickup.new()
	n.set_meta("dropped", dropped)
	parent.add_child(n)
	n.global_position = pos
	n.rotation_degrees.y = float(pl.get("yaw", 0.0))
	n.setup(e, self)
	return n

## pickup.gd: the player took it.
func pick_up(n: Node) -> void:
	var e: Dictionary = n.entry
	var to_hand: bool = str(e["class"]) == "hand"
	mall.take(str(e.id), to_hand)
	mall.save()
	n.queue_free()
	target = null
	_say(("In hand: " if to_hand else "Into the bag: ") + str(e.name))

func drop(id: String) -> void:
	var e: Dictionary = db.get_item(id)
	if e.is_empty():
		return
	var fwd := -player.transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var at: Vector3 = player.position + fwd * 0.7
	if player.has_method("_free") and not player._free(at.x, at.z):
		at = player.position
	at.y = 0.0
	var yaw := rad_to_deg(player.yaw) + 90.0
	if not mall.drop(id, int(player.wing), at, yaw):
		return
	mall.save()
	_spawn(e, mall.moved[id], true)
	_say("Dropped " + str(e.name))

# ------------------------------------------------------------------ the hand
func _on_changed() -> void:
	_show_hand()
	if panel and panel.visible:
		_fill_panel()

func _show_hand() -> void:
	if hand_id == mall.hand:
		return
	if hand_item:
		hand_item.queue_free()
		hand_item = null
	hand_id = mall.hand
	if hand_id == "":
		return
	var e: Dictionary = db.get_item(hand_id)
	if e.is_empty() or not ResourceLoader.exists(str(e.scene)):
		return
	var inst: Node = load(str(e.scene)).instantiate()
	if not (inst is Node3D):
		inst.queue_free()
		return
	hand_item = inst
	var wo := inst.get_node_or_null("WorldOnly")
	if wo:
		inst.remove_child(wo)
		wo.queue_free()
	var grip := inst.get_node_or_null("Grip") as Node3D
	if grip:
		hand_item.transform = grip.transform.affine_inverse()
	_no_shadows(hand_item)
	hand_root.add_child(hand_item)
	hand_root.rotation = Vector3.ZERO

func _no_shadows(n: Node) -> void:
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for c in n.get_children():
		_no_shadows(c)

func _can_swing() -> bool:
	return hand_item != null and bool(hand_item.get_meta("swing", false))

## The held stick's swing: a wind-up, a sweep across, back. Halfway, whatever is in front within
## SWING_REACH is hit: an interactable with on_hit(player) gets the call; a shopper flinches and
## says something. No damage: there is no damage system.
func swing() -> void:
	if swinging or not _can_swing():
		return
	swinging = true
	_whoosh.play()
	var tw := create_tween()
	tw.tween_property(hand_root, "rotation", Vector3(0.35, -0.5, 0.25), 0.09)
	tw.tween_property(hand_root, "rotation", Vector3(-0.55, 0.9, -0.5), 0.13)
	tw.tween_callback(_hit)
	tw.tween_property(hand_root, "rotation", Vector3.ZERO, 0.26).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): swinging = false)

const HIT_LINES := ["Hey!", "Watch it!", "Do you mind?", "Ow! Kids these days.", "Easy with that thing."]

func _hit() -> void:
	var p: Vector3 = player.position
	var f := -player.transform.basis.z
	var f2 := Vector2(f.x, f.z).normalized()
	for n in get_tree().get_nodes_in_group("interactable"):
		if n is Node3D and n.is_visible_in_tree() and n.has_method("on_hit") and _in_front(n.global_position, p, f2, SWING_REACH):
			n.on_hit(player)
			return
	var sh = player.get_parent().get_node_or_null("Shoppers")
	if sh and "shoppers" in sh:
		for s in sh.shoppers:
			if s.body and _in_front(s.pos, p, f2, SWING_REACH):
				for g in ["flinch", "surprised", "shrug", "talk", "point"]:
					if s.body.has_method("has_clip") and s.body.has_clip(g):
						s.body.gesture(g)
						break
				_say(HIT_LINES[randi() % HIT_LINES.size()])
				return

func _in_front(q: Vector3, p: Vector3, f2: Vector2, reach: float) -> bool:
	var d := Vector2(q.x - p.x, q.z - p.z)
	if d.length() > reach or absf(q.y - p.y) > 2.2:
		return false
	return d.length() < 0.45 or d.normalized().dot(f2) > FRONT_DOT

# ------------------------------------------------------------------ each frame
func _blocked() -> bool:
	if player == null or player.vr_on or player.leaving:
		return true
	if player.frozen and not _froze:
		return true
	if player.jump_panel and player.jump_panel.visible:
		return true
	if player.prompt and player.prompt.visible:
		return true
	var root := player.get_parent()
	var pz = root.get_node_or_null("Prizes")
	if pz and pz.get("prompt") and pz.prompt.visible:
		return true
	var sg = root.get_node_or_null("Signs")
	if sg and sg.get("b_play") and sg.b_play.visible:
		return true
	return false

## The nearest usable interactable in reach and roughly in front, and its prompt.
func find_target() -> Array:
	var p: Vector3 = player.position
	var f := -player.transform.basis.z
	var f2 := Vector2(f.x, f.z).normalized()
	var best: Node = null
	var best_s := 1e9
	var best_t := ""
	for n in get_tree().get_nodes_in_group("interactable"):
		if not (n is Node3D) or not n.is_visible_in_tree() or not n.has_method("interact_prompt") or not n.has_method("interact"):
			continue
		var q: Vector3 = n.global_position
		var d := Vector2(q.x - p.x, q.z - p.z)
		var dl := d.length()
		if dl > REACH or absf(q.y - p.y) > 2.2:
			continue
		var dot := 1.0 if dl < 0.3 else d.normalized().dot(f2)
		if dot < FRONT_DOT and dl >= 0.45:
			continue
		var s := dl * (2.0 - dot)
		if s < best_s:
			var t: String = n.interact_prompt()
			if t == "":
				continue
			best = n; best_s = s; best_t = t
	return [best, best_t]

func _process(dt: float) -> void:
	if player == null:
		return
	var blocked := _blocked()
	var txt := ""
	target = null
	if not blocked and not (panel and panel.visible):
		var r := find_target()
		target = r[0]
		txt = r[1]
		if target == null and _can_swing():
			txt = "Swing " + _short_name(hand_id)
	var show := txt != ""
	prompt.visible = show and input_kind != "touch" or (show and input_kind == "touch" and target != null)
	if show:
		prompt_key.text = {"pad": "X", "touch": "Tap"}.get(input_kind, "E")
		prompt_key.custom_minimum_size.x = 50 if input_kind == "touch" else 38
		prompt_text.text = txt
	act_btn.visible = show and input_kind == "touch"
	if act_btn.visible:
		act_btn.text = "Use" if target != null else "Swing"
	# the panel and the bag button stay out of the way of the other full-screen moments
	bag_btn.visible = not (player.frozen and not _froze) and not player.vr_on
	_layout_bag()
	# a little sway while walking, so the held item feels carried
	if hand_item and not swinging:
		var moving: bool = player.move_vec.length() > 0.1 or Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D)
		_sway_t += dt * (7.0 if moving else 1.2)
		var a := 0.012 if moving else 0.004
		hand_root.position = HAND_AT + Vector3(sin(_sway_t) * a, absf(cos(_sway_t)) * a, 0)
	hand_root.visible = not player.vr_on

func _short_name(id: String) -> String:
	var e: Dictionary = db.get_item(id)
	return "the stick" if id == "folse_stick" else str(e.get("name", "it"))

## The Bag button sits under the last visible top-right button (Jump to, the year switch).
func _layout_bag() -> void:
	var top := 8.0
	for b in [player.jump_open_btn, player.year_btn]:
		if b and b.visible:
			top = maxf(top, b.offset_bottom + 8.0)
	bag_btn.offset_top = top
	bag_btn.offset_bottom = top + 32

# ------------------------------------------------------------------ input
func _input(e: InputEvent) -> void:
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and abs(e.axis_value) > 0.4):
		input_kind = "pad"
	elif e is InputEventKey or e is InputEventMouseButton:
		input_kind = "kb"
	elif e is InputEventScreenTouch:
		input_kind = "touch"
	if player == null or player.vr_on:
		return
	if panel.visible:
		if _panel_input(e):
			get_viewport().set_input_as_handled()
		return
	# touches skip mouse emulation: the bag and action buttons and the prompt are tapped here
	if e is InputEventScreenTouch and e.pressed:
		if bag_btn.visible and bag_btn.get_global_rect().has_point(e.position):
			get_viewport().set_input_as_handled()
			open_panel(true)
			return
		if (act_btn.visible and act_btn.get_global_rect().has_point(e.position)) or (prompt.visible and prompt.get_global_rect().has_point(e.position)):
			get_viewport().set_input_as_handled()
			action()
			return
	if _blocked():
		return
	if e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_E:
				if target != null or _can_swing():
					get_viewport().set_input_as_handled()
					action()
			KEY_I:
				get_viewport().set_input_as_handled()
				open_panel(true)
			KEY_R:
				if mall.hand != "":
					get_viewport().set_input_as_handled()
					_put_away()
			KEY_G:
				if mall.hand != "":
					get_viewport().set_input_as_handled()
					drop(mall.hand)
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_X:
				get_viewport().set_input_as_handled()
				action()
			JOY_BUTTON_BACK:
				get_viewport().set_input_as_handled()
				open_panel(true)

## The action button: use the target, or swing what's in the hand.
func action() -> void:
	if _blocked():
		return
	if target == null:
		target = find_target()[0]
	if target != null and is_instance_valid(target):
		var t := target
		target = null
		t.interact(player)
	elif _can_swing():
		swing()

func _put_away() -> void:
	var nm := str(db.get_item(mall.hand).get("name", ""))
	mall.put_away()
	mall.save()
	_say("Put away: " + nm)

# ------------------------------------------------------------------ the inventory panel
func open_panel(on: bool) -> void:
	if on and _blocked():
		return
	# M (design/godot-menu.md): the inventory lives in the menu's INVENTORY tab now (scripts/menu/menu.gd)
	if on and player.get("menu") != null and player.menu.has_method("open_tab"):
		player.menu.open_tab("inventory")
		return
	panel.visible = on
	if on:
		if not player.frozen:
			player.frozen = true
			_froze = true
		player.move_vec = Vector2.ZERO
		player.move_touch = -1
		player.look_touch = -1
		player.dragging = false
		if player.stick:
			player.stick.visible = false
		panel_sel = 0
		_fill_panel()
	elif _froze:
		player.frozen = false
		_froze = false

func _fill_panel() -> void:
	for c in panel_list.get_children():
		c.queue_free()
	panel_rows.clear()
	var tk := Label.new()
	tk.text = "Tickets: %d" % mall.tickets
	tk.add_theme_font_size_override("font_size", 15)
	tk.add_theme_color_override("font_color", Color(0.93, 0.85, 0.66))
	panel_list.add_child(tk)
	if mall.hand != "":
		_row(mall.hand, 1, true)
	for en in mall.inventory:
		_row(str(en.id), int(en.count), false)
	if panel_rows.is_empty():
		var l := Label.new()
		l.text = "Nothing yet. Things you can pick up show a prompt when you're close."
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size = Vector2(260, 0)
		l.add_theme_font_size_override("font_size", 14)
		l.add_theme_color_override("font_color", Color(1, 0.97, 0.9, 0.85))
		panel_list.add_child(l)
	panel_sel = clampi(panel_sel, 0, maxi(0, panel_rows.size() - 1))
	_sel_paint()

func _row(id: String, n: int, in_hand: bool) -> void:
	var e: Dictionary = db.get_item(id)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(0, 48)
	var ic := TextureRect.new()
	ic.custom_minimum_size = Vector2(44, 44)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon := str(e.get("icon", ""))
	if icon != "" and ResourceLoader.exists(icon):
		ic.texture = load(icon)
	row.add_child(ic)
	var l := Label.new()
	l.text = str(e.get("name", id)) + ("\nin hand" if in_hand else ("  ×%d" % n if n > 1 else ""))
	l.custom_minimum_size = Vector2(120, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override("font_size", 15)
	l.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	row.add_child(l)
	var btns: Array = []
	if in_hand:
		btns.append(_pbtn(row, "Put away", func(): _put_away()))
	elif str(e.get("class", "")) == "hand":
		btns.append(_pbtn(row, "Hold", func():
			mall.hold(id); mall.save()))
	btns.append(_pbtn(row, "Drop", func():
		drop(id)))
	panel_list.add_child(row)
	panel_rows.append({"id": id, "hand": in_hand, "btns": btns, "row": row})

func _pbtn(row: HBoxContainer, t: String, cb: Callable) -> Array:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(76, 40)
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(cb)
	row.add_child(b)
	return [b, cb]

func _sel_paint() -> void:
	for i in panel_rows.size():
		panel_rows[i].row.modulate = Color(1, 0.86, 0.5) if (i == panel_sel and input_kind != "touch") else Color(1, 1, 1)

## Keys, pad and taps while the panel is open. True when used.
func _panel_input(e: InputEvent) -> bool:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.physical_keycode:
			KEY_I, KEY_ESCAPE, KEY_TAB:
				open_panel(false)
			KEY_UP, KEY_W:
				panel_sel = maxi(0, panel_sel - 1); _sel_paint()
			KEY_DOWN, KEY_S:
				panel_sel = mini(panel_rows.size() - 1, panel_sel + 1); _sel_paint()
			KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE:
				_row_do(0)
			KEY_G:
				_row_do(-1)
			_:
				return false
		return true
	if e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_BACK, JOY_BUTTON_B:
				open_panel(false)
			JOY_BUTTON_DPAD_UP:
				panel_sel = maxi(0, panel_sel - 1); _sel_paint()
			JOY_BUTTON_DPAD_DOWN:
				panel_sel = mini(panel_rows.size() - 1, panel_sel + 1); _sel_paint()
			JOY_BUTTON_A:
				_row_do(0)
			JOY_BUTTON_X:
				_row_do(-1)
		return true
	if e is InputEventScreenTouch and e.pressed:
		for r in panel_rows:
			for bc in r.btns:
				if bc[0].is_visible_in_tree() and bc[0].get_global_rect().has_point(e.position):
					bc[1].call()
					return true
		if not panel.get_global_rect().has_point(e.position) and not bag_btn.get_global_rect().has_point(e.position):
			open_panel(false)
		elif bag_btn.get_global_rect().has_point(e.position):
			open_panel(false)
		return true
	if e is InputEventScreenDrag:
		return true
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if not panel.get_global_rect().has_point(e.position):
			open_panel(false)
			return not bag_btn.get_global_rect().has_point(e.position)
		return false      # a click inside: the panel's own buttons take it
	return false

## The selected row's first (0) or last (-1) button.
func _row_do(k: int) -> void:
	if panel_rows.is_empty():
		return
	var r: Dictionary = panel_rows[panel_sel]
	if r.btns.is_empty():
		return
	r.btns[k if k >= 0 else r.btns.size() - 1][1].call()

# ------------------------------------------------------------------ ui
func _box(bg: Color, border: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	return sb

func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 12
	add_child(ui)
	# the prompt: the same key-cap look as the wing seam's (player.gd), same place
	prompt = Button.new()
	prompt.focus_mode = Control.FOCUS_NONE
	prompt.visible = false
	var sb := _box(Color(0.08, 0.06, 0.05, 0.78), Color(0.93, 0.85, 0.66, 0.85), 10)
	sb.content_margin_left = 14; sb.content_margin_right = 18
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	for st in ["normal", "hover", "pressed", "focus"]:
		prompt.add_theme_stylebox_override(st, sb)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.custom_minimum_size = Vector2(300, 52)
	prompt.offset_left = -150; prompt.offset_right = 150
	prompt.offset_top = -132; prompt.offset_bottom = -80
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12; row.offset_right = -12
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.add_child(row)
	prompt_key = Label.new()
	prompt_key.custom_minimum_size = Vector2(38, 32)
	prompt_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_key.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_key.add_theme_font_size_override("font_size", 17)
	prompt_key.add_theme_color_override("font_color", Color(0.1, 0.08, 0.06))
	var kb := StyleBoxFlat.new()
	kb.bg_color = Color(0.95, 0.89, 0.74)
	kb.set_corner_radius_all(6)
	prompt_key.add_theme_stylebox_override("normal", kb)
	prompt_key.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(prompt_key)
	prompt_text = Label.new()
	prompt_text.add_theme_font_size_override("font_size", 16)
	prompt_text.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	prompt_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(prompt_text)
	prompt.pressed.connect(action)
	ui.add_child(prompt)
	# the round touch action button, by the right thumb (only while something is in reach)
	act_btn = Button.new()
	act_btn.focus_mode = Control.FOCUS_NONE
	act_btn.visible = false
	act_btn.text = "Use"
	var rb := _box(Color(0.95, 0.89, 0.74, 0.9), Color(0.08, 0.06, 0.05, 0.6), 44)
	for st in ["normal", "hover", "pressed", "focus"]:
		act_btn.add_theme_stylebox_override(st, rb)
	act_btn.add_theme_color_override("font_color", Color(0.1, 0.08, 0.06))
	act_btn.add_theme_color_override("font_pressed_color", Color(0.1, 0.08, 0.06))
	act_btn.add_theme_color_override("font_hover_color", Color(0.1, 0.08, 0.06))
	act_btn.add_theme_font_size_override("font_size", 17)
	act_btn.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	act_btn.offset_left = -124; act_btn.offset_right = -36
	act_btn.offset_top = -236; act_btn.offset_bottom = -148
	act_btn.pressed.connect(action)
	ui.add_child(act_btn)
	# the Bag button (top right, under Jump to and the year switch)
	bag_btn = Button.new()
	bag_btn.text = "Bag (I)"
	bag_btn.focus_mode = Control.FOCUS_NONE
	bag_btn.add_theme_font_size_override("font_size", 14)
	bag_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	bag_btn.offset_left = -200; bag_btn.offset_right = -10
	bag_btn.offset_top = 208; bag_btn.offset_bottom = 240
	bag_btn.pressed.connect(func(): open_panel(not panel.visible))
	ui.add_child(bag_btn)
	# the panel
	panel = PanelContainer.new()
	var pb := _box(Color(0.08, 0.06, 0.05, 0.9), Color(0.93, 0.85, 0.66, 0.85), 10)
	pb.set_content_margin_all(14)
	panel.add_theme_stylebox_override("panel", pb)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(380, 0)
	panel.offset_left = -190; panel.offset_right = 190
	panel.offset_top = -170; panel.offset_bottom = 170
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.visible = false
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var title := Label.new()
	title.text = "Bag"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	col.add_child(title)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(350, 220)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(sc)
	panel_list = VBoxContainer.new()
	panel_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel_list.add_theme_constant_override("separation", 6)
	sc.add_child(panel_list)
	var foot := Label.new()
	foot.text = "E hold · G drop · R put away · I / Esc closes\npad: A · X drop · Select / B closes"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.add_theme_font_size_override("font_size", 11)
	foot.add_theme_color_override("font_color", Color(0.93, 0.85, 0.66, 0.85))
	col.add_child(foot)
	ui.add_child(panel)

## A short line at the bottom of the screen (player.gd's).
func _say(t: String) -> void:
	if player and player.has_method("_say"):
		player._say(t)

## A short whoosh of filtered noise for the swing (generated, like the Stockrooms' sounds).
func _make_whoosh() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.28)
	var b := PackedByteArray()
	b.resize(n * 2)
	var r := RandomNumberGenerator.new()
	r.seed = 77
	var lp := 0.0
	for i in n:
		var t := float(i) / n
		var k := 0.04 + 0.25 * sin(PI * t)          # the filter opens and closes: a sweep
		lp += (r.randf_range(-1, 1) - lp) * k
		var v := lp * sin(PI * t) * 1.8
		b.encode_s16(i * 2, int(clampf(v, -1.0, 1.0) * 30000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = b
	return w
