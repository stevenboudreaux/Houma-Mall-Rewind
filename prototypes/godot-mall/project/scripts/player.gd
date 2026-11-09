## First-person walker for the Godot mall.
## Phone: drag on the left half to walk, drag on the right half to look.
## Desktop: WASD / arrow keys to walk, drag with the mouse to look, hold the right mouse button
## (or X / Shift) to run. J (a gamepad's Y, or the "Jump to" button) opens the quick-jump menu:
## Sears, the main entrance, Dillard's or JCPenney (Steven, Oct 8).
## URL ?cam=x,z,yaw,pitch places the camera (used for test screenshots).
## Wings (design/godot-wings.md): the mall ships as two game files; near the seam between them a
## prompt offers the other wing (E / Enter, a gamepad's A, a click or a tap), and the page reloads
## into that wing's file at the same spot, facing the same way, behind a fade to black.
extends Node3D

@export var obstacles: Array = []
var fx_obstacles: Array = []     # benches, planters, trash cans (only when shown)
var fixtures_on := false
var frozen := false        # the prize counter's closer look has the camera (scripts/prizes.gd)
var jump_locked := false   # inside the Stockrooms on a visitor's browser: no Jump menu (scripts/stockrooms.gd)
## B+C (design/godot-interaction.md): what the player carries (scripts/inventory.gd: mall.inventory,
## mall.tickets), set by scripts/interact.gd, the action button / pick-ups / inventory system.
var mall = null
var interact: Node = null
## V (design/godot-avatar.md): the avatar and the first / third person switch (scripts/avatar.gd);
## move_scale slows walking in third person to a walking pace (1.0 in first person, as before);
## WALK (Nov 3 2026) raised that pace to 3.0 m/s (run 6.6) and sub-steps every move (MOVE_SUB).
var avatar: Node = null
var move_scale := 1.0
## M (design/godot-menu.md): the full-screen menu (scripts/menu/menu.gd: AVATAR, CONTROLS, INVENTORY,
## YEAR), the opening screen and the remappable controls; the year change plays the time-travel
## transition (scripts/timetravel.tscn) first.
var menu: Node = null
## Walkable map tiles (rows of "0"/"1"), and how map tiles map to metres.
@export var walk_rows: PackedStringArray = []
@export var map_origin := Vector2(148, 100)
@export var map_scale := 2.0
const Years = preload("res://scripts/years.gd")   # ITEMS: the years as the player reads them
const EYE := 1.62
const SPEED := 4.0
const RUN := 2.2      # holding X (or Shift) runs: Steven, Oct 6, "add back the ability to run by hitting x"
const MOVE_SUB := 0.08   # WALK: the longest step tested against the walls and glass at once, m (see _process)
const RADIUS := 0.3
var yaw := PI * 0.5   # looking west (-x) from the entrance
var pitch := 0.06
var cam: Camera3D
var move_touch := -1
var look_touch := -1
var move_origin := Vector2.ZERO
var move_vec := Vector2.ZERO
var dragging := false
var rmb_run := false    # the right mouse button held: run (Steven, Oct 8)
# quick jump (Steven, Oct 8): name, wing, x, z, yaw (degrees), standing in front of each entrance
# with your back to it, looking out into the mall (Steven, Oct 9)
const JUMPS := [
	["Sears", 1, -4.0, -90.0, 180.0],
	["Mall entrance", 1, 31.0, 0.0, 90.0],
	["Dillard's", 2, -4.0, 75.5, 0.0],
	["JCPenney", 2, -148.0, 56.0, -90.0],
	["Outside", 3, 52.0, 0.0, 90.0]]
var jump_panel: PanelContainer
var jump_btns: Array = []
var jump_sel := 0
var jump_open_btn: Button
var last_pos := {}   # touch index -> last position
var hud: Label
var buttons: Array = []   # HUD buttons, tapped by hand since touch skips mouse emulation
var hint: Label
var stick: Control
var fps_t := 0.0
var debug := false
# wings
var wing := 0
## The year on show: 1995, or 2026 (the mall as Steven filmed it, Oct 23 2026: the same building,
## today's tenants; tools/make_layout_2026.py). Set from the scene's "year" meta.
var year := 1995
var year_btn: Button
var seam := []              # [x0, z, x1]: the seam line; the other wing lies on other_side
var other_side := 1.0
var prompt: Button
var prompt_key: Label
var prompt_text: Label
var fade: ColorRect
var leaving := false
var input_kind := "kb"      # "kb", "pad" or "touch": which glyph the prompt shows
## In a VR headset (scripts/vr.gd, design/godot-vr.md): the headset and its sticks move the player.
var vr: Node3D
var vr_on := false
const SEAM_NEAR := 2.6      # metres from the seam at which the prompt shows
const WING_NAMES := {1: "Wing 1 · Sears & the main entrance", 2: "Wing 2 · Dillard's & JCPenney", 3: "Outside · the parking lot",
	4: "Sears", 5: "Dillard's", 6: "Southland Cinema"}
## S (Nov 2 2026, design/godot-wings.md "Wings 4-6"): the room wings' thresholds, from wing.json: each
## {to, line [x0, z, x1], side}: a line like the seam (z = line[1], x line[0]..line[2]), the other wing
## on the `side` (+1: +z) of it. Crossed like the seam; a gate (group "gate", locks_threshold(to))
## may refuse it (the cinema, scripts/cinema_gate.gd).
var thresholds: Array = []
var thr_near = null         # the threshold whose prompt shows, or null
## The doors between inside and outside (design/godot-exterior.md, exterior.json via gen/w<n>/wing.json):
## in wings 1 and 2 the mall's exits and main entrance offer "Go outside" (wing 3, the lot); outside,
## each door offers the way back in. Each: store, kind, wing (the inside wing), out, inside (the
## spots either side), yaw_in / yaw_out (the facing, degrees).
var doors: Array = []
var door_near = null        # the door whose prompt shows, or null
const DOOR_NEAR := 2.8
const DOOR_NAMES := {"s39": "the main entrance", "s43": "the Sears hall entrance", "s41": "the cinema-side exit", "s55": "the south entrance"}
## Workstream E (Nov 1): the anchors' own outside doors (tools/make_exterior.py); "Sears" reads
## "Lynn's" in 2026 (_door_name).
const DOOR_NAMES_E := {"s1x": "the Sears side exit", "s1e": "the Sears customer entrance", "s2e": "Dillard's east entrance", "s2s": "Dillard's south entrance",
	"s1n": "the Sears north entrance"}   # EXT-LAYOUT (Nov 8 2026): the north-face customer entrance (design/godot-sears.md)

func _door_name(d) -> String:
	var k := str(d.get("store", ""))
	if DOOR_NAMES_E.has(k):
		return DOOR_NAMES_E[k].replace("Sears", "Lynn's") if year == 2026 else DOOR_NAMES_E[k]
	return DOOR_NAMES.get(k, "the doors")

func _ready() -> void:
	position = Vector3(33.0, 0, 0.0)
	var gen: String = get_parent().get_meta("gen", "res://gen/") if get_parent() else "res://gen/"
	wing = int(get_parent().get_meta("wing", 0)) if get_parent() else 0
	year = int(get_parent().get_meta("year", 1995)) if get_parent() else 1995
	var wj = null
	if FileAccess.file_exists(gen + "wing.json"):
		wj = JSON.parse_string(FileAccess.get_file_as_string(gen + "wing.json"))
	# the walkable grid comes from the layout file the mall was built from
	if walk_rows.is_empty() and FileAccess.file_exists("res://layout_mall.json"):
		var lay = JSON.parse_string(FileAccess.get_file_as_string("res://layout_mall.json"))
		if lay is Dictionary:
			walk_rows = PackedStringArray(lay.get("walk", []))
			map_origin = Vector2(lay.origin[0], lay.origin[1])
			map_scale = float(lay.scale)
	if wj is Dictionary:
		# this wing's walk grid: the other wing's tiles are closed, so the seam is a wall
		walk_rows = PackedStringArray(wj.get("walk", walk_rows))
		# EXT-B (Nov 4 2026): the outside's walk grid is grown past the mall map, with its own origin
		if wj.has("origin"):
			map_origin = Vector2(float(wj.origin[0]), float(wj.origin[1]))
		seam = wj.get("seam", [])
		other_side = float(wj.get("other_side", 1.0))
		thresholds = wj.get("thresholds", [])   # S
	# the doors between inside and outside (exterior.json, tools/make_exterior.py): in a mall wing,
	# the ones that open from this wing; outside, all of them
	if FileAccess.file_exists("res://exterior.json"):
		var ex = JSON.parse_string(FileAccess.get_file_as_string("res://exterior.json"))
		if ex is Dictionary:
			for d in ex.get("doors", []):
				if wing == 3 or int(d.get("wing", 0)) == wing:
					doors.append(d)
		var sp: Array = wj.get("spawn", [])
		if sp.size() >= 4:
			position = Vector3(float(sp[0]), 0, float(sp[1]))
			yaw = deg_to_rad(float(sp[2]))
			pitch = deg_to_rad(float(sp[3]))
	if FileAccess.file_exists(gen + "collide.json"):
		var col = JSON.parse_string(FileAccess.get_file_as_string(gen + "collide.json"))
		if col is Dictionary:
			obstacles = col.get("static", obstacles)
			fx_obstacles = col.get("fixtures", [])
	cam = Camera3D.new()
	cam.position = Vector3(0, EYE, 0)
	cam.fov = 70.0
	cam.near = 0.05
	cam.far = 600.0 if wing == 3 else 200.0   # outside, the water tower and the roads are far off
	add_child(cam)
	cam.current = true
	_build_hud()
	if OS.has_feature("web"):
		debug = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('debug') || ''")) == "1"
		if str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('refl') || ''")) == "0":
			buttons[0].button_pressed = false
		var tq := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('time') || ''"))
		if tq == "day" or _day_only():
			buttons[2].button_pressed = false
		elif tq == "night":
			buttons[2].button_pressed = true
		# ?hour=13.5&bright=1.1: an exact lighting (the owner's panel shows these numbers)
		var hq := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('hour') || ''"))
		var bq := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('bright') || ''"))
		if hq.is_valid_float() or bq.is_valid_float():
			_light_url = Vector2(float(hq) if hq.is_valid_float() else -1.0, float(bq) if bq.is_valid_float() else -1.0)
		_light_owner = str(JavaScriptBridge.eval("(function(){try{var q=new URLSearchParams(location.search).get('owner');if(q==='1')localStorage.setItem('southland-editor','1');return localStorage.getItem('southland-editor')==='1'?'1':'0'}catch(e){return '0'}})()")) == "1"
		if str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('fx') || ''")) == "1":
			buttons[1].button_pressed = true
		var q = JavaScriptBridge.eval("new URLSearchParams(location.search).get('cam') || ''")
		if q is String and q != "":
			var v: PackedStringArray = q.split(",")
			if v.size() >= 3:
				position = Vector3(float(v[0]), 0, float(v[1]))
				yaw = deg_to_rad(float(v[2]))
				if v.size() >= 4:
					pitch = deg_to_rad(float(v[3]))
				hint.visible = false
	elif Engine.has_meta("mall_xfer"):
		# arrived from the other wing in this same run (not on the web: the editor or a test)
		var x: Dictionary = Engine.get_meta("mall_xfer")
		Engine.remove_meta("mall_xfer")
		position = Vector3(x.x, 0, x.z)
		yaw = x.yaw
		pitch = x.pitch
		hint.visible = false
	_apply_rot()
	_light_start.call_deferred()
	_build_wing_ui()
	_build_jump_ui()
	_build_year_ui()
	# B+C: the shared action button, pick-up items and the bag (scripts/interact.gd), every wing and
	# year; then the owner-only HUD (design/godot-interaction.md)
	interact = load("res://scripts/interact.gd").new()
	interact.name = "Interact"; interact.player = self
	add_child(interact)
	# V: the player's body (CHAR-STRIP: its cast member, scripts/cast.gd) and the view switch (scripts/avatar.gd), after Interact (it moves the
	# held item into the avatar's hand in third person)
	avatar = load("res://scripts/avatar.gd").new()
	avatar.name = "Avatar"; avatar.player = self
	add_child(avatar)
	# Q: the story machinery (scripts/dialogue/story.gd: gates, counter attendants, the conversation
	# screen, the book reader; design/godot-dialogue.md), after Interact (it needs mall.flags) and
	# before the shoppers (a locked gate closes the walk grid they copy)
	var story = load("res://scripts/dialogue/story.gd").new()
	story.name = "Story"; story.player = self
	add_child(story)
	# M: the menu, after Avatar (its MAIN tab has the Character row, scripts/menu/menu.gd)
	menu = load("res://scripts/menu/menu.gd").new()
	menu.name = "Menu"; menu.player = self
	add_child(menu)
	# OWNER: the owner's own pictures on posters and ad panels (scripts/pictures.gd, design/godot-owner-mode.md)
	var pics = load("res://scripts/pictures.gd").new()
	pics.name = "Pictures"; pics.player = self
	get_parent().add_child.call_deferred(pics)
	# S: the threshold gates (the cinema doors, data/story/gates.json; scripts/cinema_gate.gd)
	load("res://scripts/cinema_gate.gd").make_all(self)
	_light_btn_ok = buttons[2].visible
	_owner_hud_load()   # OWNER
	owner_hud_sync()
	_spawn_1995_life()
	vr = Node3D.new()
	vr.name = "VR"
	vr.set_script(load("res://scripts/vr.gd"))
	add_child(vr)
	# MENU2: a time-travel trip from a mall directory lands here (scripts/timetravel_trip.gd)
	load("res://scripts/timetravel_trip.gd").arrive(self)

## The Runner, the shoppers, the shirt words, the Stockrooms and the prize counter: 1995 only (2026
## is the building as it is today).
func _spawn_1995_life() -> void:
	if wing == 6:
		return     # S: the cinema lobby placeholder is one empty room (design/godot-wings.md "Wings 4-6")
	if year != 1995:
		_spawn_2026_shoppers()   # M
		return
	# the Runner, a window mannequin come to life (scripts/runner_ai.gd; Steven, Oct 16 2026). He
	# replaced the Rougarou (scripts/rougarou_ai.gd, kept but no longer made).
	var rn = load("res://scripts/runner_ai.gd").new()
	rn.name = "RunnerAI"; rn.player = self
	if OS.has_feature("web"):
		rn.force = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('runner') || ''"))
	get_parent().add_child.call_deferred(rn)
	# the shoppers, the mall's crowd (scripts/npcs.gd; Steven, Oct 15 2026)
	var np = load("res://scripts/npcs.gd").new()
	np.name = "Shoppers"; np.player = self
	if OS.has_feature("web"):
		np.force = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('npcs') || ''"))
	get_parent().add_child.call_deferred(np)
	# the words on Ch02's sweatshirt, owner-editable (scripts/npc_shirt.gd; Steven, Oct 16 2026)
	var ns = load("res://scripts/npc_shirt.gd").new()
	ns.name = "ShirtWords"; ns.player = self
	get_parent().add_child.call_deferred(ns)
	# the Stockrooms, behind Woolworth's back corner (scripts/stockrooms.gd; Steven, Oct 15 2026)
	if wing == 1 or wing == 0:
		var sr = load("res://scripts/stockrooms.gd").new()
		sr.name = "Stockrooms"; sr.player = self
		if OS.has_feature("web"):
			sr.force = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('stockrooms') || ''"))
		get_parent().add_child.call_deferred(sr)
	# Pocket Change's ticket prizes and the closer look at them (scripts/prizes.gd; Steven, Oct 15 2026)
	if wing == 2 or wing == 0:
		var pz = load("res://scripts/prizes.gd").new()
		pz.name = "Prizes"; pz.player = self
		get_parent().add_child.call_deferred(pz)

## M (design/godot-menu.md): 2026 has a few shoppers too: npcs.json "years" sets how many and who
## (scripts/npcs.gd); no Runner, Stockrooms or prize counter. Not outside (wing 3).
func _spawn_2026_shoppers() -> void:
	if wing == 3:
		return
	# PRIZES (Nov 3): games, inc.'s prize counter (scripts/prizes_gi.gd; design/godot-prize-counter.md)
	if wing == 2 or wing == 0:
		var pg = load("res://scripts/prizes_gi.gd").new()
		pg.name = "Prizes"; pg.player = self
		get_parent().add_child.call_deferred(pg)
	var np = load("res://scripts/npcs.gd").new()
	np.name = "Shoppers"; np.player = self
	if OS.has_feature("web"):
		np.force = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('npcs') || ''"))
	get_parent().add_child.call_deferred(np)

func _build_hud() -> void:
	var cl := CanvasLayer.new()
	add_child(cl)
	hud = Label.new()
	hud.position = Vector2(12, 8)
	hud.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	hud.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	hud.add_theme_constant_override("shadow_offset_x", 1)
	hud.add_theme_constant_override("shadow_offset_y", 1)
	hud.add_theme_font_size_override("font_size", 14)
	cl.add_child(hud)
	_add_button("Reflections", true, 8, func(on: bool):
		var rt = get_tree().current_scene.get_node_or_null("Runtime")
		if rt:
			rt.set_reflections(on))
	_add_button("Benches & plants", false, 48, func(on: bool):
		fixtures_on = on
		var fxn = get_tree().current_scene.get_node_or_null("Dynamic/dyn_fixtures")
		if fxn:
			fxn.visible = on)
	var night0 := true
	if FileAccess.file_exists("res://scripts/lighting.json"):
		var lj = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/lighting.json"))
		if lj is Dictionary:
			night0 = str(lj.get("default", "night")) != "day" and not bool(lj.get("day_only", false))
	_add_button("Lighting", night0, 88, func(night: bool):
		var rt = get_tree().current_scene.get_node_or_null("Runtime")
		if rt:
			if rt.has_method("set_preset"):
				rt.set_preset(night)
				_light_panel_sync(rt)
			else:
				rt.set_time("night" if night else "day"), ["day", "night"])
	# the day lighting ships separately; hide the switch until it's baked
	var scn := get_tree().current_scene
	if scn == null:
		scn = get_parent()
	if scn and not ResourceLoader.exists(load("res://scripts/time_of_day.gd").lightmap_path(scn, "day")):
		buttons[2].visible = false
	if _day_only():
		buttons[2].visible = false     # day lighting only for now: no switch (scripts/lighting.json day_only)
	_cl = cl
	hint = Label.new()
	hint.text = "Drag left side to walk · drag right side to look"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -60
	hint.offset_left = -220
	hint.offset_right = 220
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.95))
	hint.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	hint.add_theme_constant_override("shadow_offset_x", 1)
	hint.add_theme_constant_override("shadow_offset_y", 1)
	cl.add_child(hint)
	stick = Control.new()
	stick.visible = false
	stick.draw.connect(func():
		stick.draw_circle(Vector2.ZERO, 46, Color(1, 1, 1, 0.12))
		stick.draw_arc(Vector2.ZERO, 46, 0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)
		stick.draw_circle(move_vec * 46, 18, Color(1, 1, 1, 0.55)))
	cl.add_child(stick)

var _cl: CanvasLayer

## scripts/lighting.json "day_only": the mall stays in its day lighting (Steven, Oct 16 2026).
func _day_only() -> bool:
	if not FileAccess.file_exists("res://scripts/lighting.json"): return false
	var lj = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/lighting.json"))
	return lj is Dictionary and bool(lj.get("day_only", false))

# ---- the owner's lighting panel (web/shell.html mallLight; scripts/lighting.json)
var _light_owner := false
var _light_url := Vector2(-1, -1)   # ?hour= / ?bright=, -1 when not given
var _light_t := 0.0

## After the Lighting button's first (deferred) call: apply ?hour=/?bright= and show the owner's panel.
func _light_start() -> void:
	await get_tree().process_frame
	var rt = get_tree().current_scene.get_node_or_null("Runtime")
	if rt == null or not rt.has_method("set_clock"):
		return
	if _light_url.x >= 0.0 or _light_url.y >= 0.0:
		var h: float = _light_url.x if _light_url.x >= 0.0 else rt.hour
		var b: float = _light_url.y if _light_url.y >= 0.0 else rt.bright
		rt.set_clock(clampf(h, 0.0, 24.0), clampf(b, 0.2, 3.0))
		_light_button_sync(rt)
	if _light_owner and OS.has_feature("web"):
		JavaScriptBridge.eval("window.mallLight && window.mallLight.show(%s, %s, %s)" % [rt.hour, rt.bright, JSON.stringify(JSON.stringify(rt.lighting()))], true)

## Show the Lighting button as day or night without firing it.
func _light_button_sync(rt) -> void:
	var night: bool = rt.mode == "night"
	if buttons.size() > 2:
		buttons[2].set_pressed_no_signal(night)
		buttons[2].text = "Lighting: %s" % ("night" if night else "day")

func _light_panel_sync(rt) -> void:
	if _light_owner and OS.has_feature("web"):
		JavaScriptBridge.eval("window.mallLight && window.mallLight.set(%s, %s)" % [rt.hour, rt.bright], true)

## The owner moved a slider: light the mall to match (polled 10 times a second).
func _light_poll(dt: float) -> void:
	if not _light_owner or not OS.has_feature("web"):
		return
	_light_t += dt
	if _light_t < 0.1:
		return
	_light_t = 0.0
	var c = JavaScriptBridge.eval("window.mallLight ? window.mallLight.poll() : ''", true)
	if not (c is String) or c == "":
		return
	var v = JSON.parse_string(c)
	var rt = get_tree().current_scene.get_node_or_null("Runtime")
	if v is Dictionary and rt and rt.has_method("set_clock"):
		rt.set_clock(float(v.get("hour", rt.hour)), float(v.get("bright", rt.bright)))
		_light_button_sync(rt)

## A toggle button in the top-right corner: "<name>: on/off".
func _add_button(name: String, on: bool, top: int, cb: Callable, words := ["off", "on"]) -> void:
	var btn := Button.new()
	btn.toggle_mode = true
	btn.button_pressed = on
	btn.text = "%s: %s" % [name, words[1] if on else words[0]]
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 14)
	btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -200
	btn.offset_right = -10
	btn.offset_top = top
	btn.offset_bottom = top + 32
	btn.toggled.connect(func(v: bool):
		btn.text = "%s: %s" % [name, words[1] if v else words[0]]
		cb.call(v))
	hud.get_parent().add_child(btn)
	buttons.append(btn)
	(func(): cb.call(btn.button_pressed)).call_deferred()   # current state, after any URL overrides

func _input(e: InputEvent) -> void:
	var half := get_viewport().get_visible_rect().size.x * 0.5
	if e is InputEventJoypadButton or (e is InputEventJoypadMotion and abs(e.axis_value) > 0.4):
		input_kind = "pad"
	elif e is InputEventKey or e is InputEventMouseButton:
		input_kind = "kb"
	elif e is InputEventScreenTouch:
		input_kind = "touch"
	_secret_input(e)
	if frozen:
		return
	# OWNER: Y (keyboard) and a tap on the year button switch the year, for the owner only
	if is_owner() and year_btn and year_btn.is_visible_in_tree() and not leaving:
		if (e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_Y) \
				or (e is InputEventScreenTouch and e.pressed and year_btn.get_global_rect().has_point(e.position)):
			get_viewport().set_input_as_handled()
			_switch_year()
			return
	if _jump_input(e):
		get_viewport().set_input_as_handled()
		return
	if prompt and prompt.visible and not leaving:
		var go := false
		if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER]:
			go = true
		elif e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A:
			go = true
		elif e is InputEventScreenTouch and e.pressed and prompt.get_global_rect().has_point(e.position):
			go = true
		if debug:
			print("DBG prompt input ", e)
		if go:
			get_viewport().set_input_as_handled()
			_cross()
			return
	if e is InputEventScreenTouch:
		# touches don't reach buttons (mouse emulation is off), so tap it here
		if e.pressed:
			for b in buttons:
				if b.is_visible_in_tree() and b.get_global_rect().has_point(e.position):   # B+C: hidden ones aren't tapped
					b.button_pressed = not b.button_pressed
					get_viewport().set_input_as_handled()
					return
		if e.pressed:
			last_pos[e.index] = e.position
			hint.visible = false
			if e.position.x < half and move_touch == -1:
				move_touch = e.index; move_origin = e.position; move_vec = Vector2.ZERO
				stick.position = e.position; stick.visible = true; stick.queue_redraw()
			elif look_touch == -1:
				look_touch = e.index
		else:
			last_pos.erase(e.index)
			if e.index == move_touch:
				move_touch = -1; move_vec = Vector2.ZERO; stick.visible = false
			if e.index == look_touch:
				look_touch = -1
	elif e is InputEventScreenDrag:
		var prev: Vector2 = last_pos.get(e.index, e.position)
		last_pos[e.index] = e.position
		if e.index == move_touch:
			move_vec = ((e.position - move_origin) / 46.0).limit_length(1.0)
			stick.queue_redraw()
		elif e.index == look_touch:
			var d: Vector2 = e.position - prev
			if d.length() < 120.0:   # ignore a jump if the browser swaps fingers
				_look(d * 0.0045)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		dragging = e.pressed
		hint.visible = false
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT:
		rmb_run = e.pressed
	elif e is InputEventMouseMotion and dragging and not DisplayServer.is_touchscreen_available():
		_look(e.relative * 0.004)

# ---- the owner's secret way in (Steven, Oct 16 2026)
## Stand at the dead end of the restroom hall (past MEN and WOMEN) and enter
## up up down down left right left right B A, on the keyboard (arrow keys, then the B and A
## keys) or a controller (d-pad, then B and A). It sets localStorage "southland-editor" (the
## same key the main game's code and ?owner=1 set) and reloads at the same spot, so every owner
## tool comes up: Edit signs / Publish signs, Shirt words, the prize words, the lighting panel.
## Any browser, any device with a keyboard or controller; the browser remembers from then on.
const SECRET := "UUDDLRLRBA"
## B+C: the same code on a touch screen, at the same spot, no hint shown: swipe up, up, down, down,
## left, right, left, right (anywhere on the screen), then tap twice.
const SECRET_TOUCH := "UUDDLRLRTT"
var _secret_touches := {}   # touch index -> where it started
const SECRET_CORNER := Rect2(-50.6, 85.0, 3.2, 11.6)   # x, z: H7's last 11 m (layout_mall.json)
var _secret_buf := ""

func _secret_tok(e: InputEvent) -> String:
	if e is InputEventKey and e.pressed and not e.echo:
		return {KEY_UP: "U", KEY_DOWN: "D", KEY_LEFT: "L", KEY_RIGHT: "R", KEY_B: "B", KEY_A: "A"}.get(e.physical_keycode, "")
	if e is InputEventJoypadButton and e.pressed:
		return {JOY_BUTTON_DPAD_UP: "U", JOY_BUTTON_DPAD_DOWN: "D", JOY_BUTTON_DPAD_LEFT: "L", JOY_BUTTON_DPAD_RIGHT: "R",
			JOY_BUTTON_B: "B", JOY_BUTTON_A: "A"}.get(e.button_index, "")
	return ""

func _secret_input(e: InputEvent) -> void:
	var tk := _secret_tok(e)
	if tk == "": tk = _secret_touch_tok(e)   # B+C: swipes and taps
	if tk == "": return
	if debug: print("DBG code token ", tk)
	_secret_buf = (_secret_buf + tk).right(SECRET.length())
	if _secret_buf != SECRET and _secret_buf != SECRET_TOUCH: return
	_secret_buf = ""
	if not SECRET_CORNER.has_point(Vector2(position.x, position.z)):
		return
	print("owner: secret code at ", position)
	if not OS.has_feature("web"):
		return
	if _light_owner:
		_say("Editor is already on in this browser")
		return
	var cam_s := "%.2f,%.2f,%.1f,%.1f" % [position.x, position.z, rad_to_deg(yaw), rad_to_deg(pitch)]
	_say("Editor unlocked")
	var js := "(function(){try{localStorage.setItem('southland-editor','1')}catch(e){}var u=new URL(location.href);var p=u.searchParams;"
	js += "p.set('cam','%s');%s" % [cam_s, ("p.set('wing','%d');" % wing) if wing != 0 else ""]
	js += "setTimeout(function(){if(window.mallGoWing){window.mallGoWing(u.toString())}else{location.replace(u.toString())}},900)})()"
	JavaScriptBridge.eval(js, true)

## B+C: a finished touch as a code token: a tap (moved < 20 px) "T", a swipe (> 45 px) "U"/"D"/"L"/"R".
func _secret_touch_tok(e: InputEvent) -> String:
	if not (e is InputEventScreenTouch):
		return ""
	if e.pressed:
		_secret_touches[e.index] = e.position
		return ""
	var st = _secret_touches.get(e.index)
	_secret_touches.erase(e.index)
	if st == null:
		return ""
	# no time limits: a slow phone (or a test browser) handles touches late, and the whole sequence
	# still has to match at the hidden spot, so looking around there can't trip it by chance
	var d: Vector2 = e.position - st
	if debug: print("DBG code touch ", e.index, " moved ", d)
	if d.length() < 20.0:
		return "T"
	if d.length() > 45.0:
		if absf(d.x) > absf(d.y):
			return "R" if d.x > 0 else "L"
		return "D" if d.y > 0 else "U"
	return ""

# ---- B+C: the owner-only HUD (design/godot-interaction.md has the full button list)
var _light_btn_ok := true   # the Lighting switch is wanted at all (a day lightmap, not day-only)

## OWNER (design/godot-owner-mode.md): the owner's fps line, on unless turned off in the menu's OWNER
## tab (kept in this browser: localStorage "mall-owner-hud" = "off"; tests: Engine meta).
var owner_hud_on := true
var _year_btn_owner := false

func set_owner_hud(on: bool) -> void:
	owner_hud_on = on
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{if(%s)localStorage.removeItem('mall-owner-hud');else localStorage.setItem('mall-owner-hud','off')}catch(e){}})()" % ("true" if on else "false"), true)
	else:
		Engine.set_meta("mall_owner_hud", on)
	owner_hud_sync()

func _owner_hud_load() -> void:
	if OS.has_feature("web"):
		owner_hud_on = str(JavaScriptBridge.eval("(function(){try{return localStorage.getItem('mall-owner-hud')||''}catch(e){return ''}})()")) != "off"
	else:
		owner_hud_on = bool(Engine.get_meta("mall_owner_hud", true))

## Owner mode: localStorage "southland-editor" = "1" (?owner=1 or the secret code); off the web,
## Engine meta "mall_owner" (tests).
func is_owner() -> bool:
	return _light_owner or bool(Engine.get_meta("mall_owner", false))

## Visitors see only Jump to, the year switch, the Bag and the action prompt: the fps readout and the
## Reflections / Benches & plants / Lighting toggles are the owner's. Jump to and the year switch move
## up into the freed corner. Called at start and whenever something re-shows the buttons.
func owner_hud_sync() -> void:
	var own := is_owner()
	hud.visible = own and owner_hud_on   # OWNER: the fps line can be turned off in the OWNER tab
	for b in buttons:
		b.visible = own
	if own and buttons.size() > 2 and not _light_btn_ok:
		buttons[2].visible = false
	# OWNER (design/godot-owner-mode.md): the owner's toggles and Shirt words are in the menu's OWNER
	# tab (scripts/menu/menu.gd tucks them away), so the corner column starts at the top for everyone;
	# the owner gets the year switch back (Steven, Nov 4: every old corner button, for him)
	var top := 40 if own and owner_hud_on else 8   # under the owner's fps line (it reaches across a phone)
	year_btn.visible = own and not vr_on
	_year_btn_owner = own
	jump_open_btn.offset_top = top; jump_open_btn.offset_bottom = top + 32
	year_btn.offset_top = top + 40; year_btn.offset_bottom = top + 72

## A short line at the bottom of the screen for a couple of seconds.
func _say(t: String) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 26)
	l.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	l.position = Vector2(get_viewport().get_visible_rect().size.x * 0.5 - 200, get_viewport().get_visible_rect().size.y - 90)
	l.size = Vector2(400, 40)
	hud.get_parent().add_child(l)
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(l, "modulate:a", 0.0, 0.5)
	tw.tween_callback(l.queue_free)

func _look(d: Vector2) -> void:
	yaw -= d.x
	pitch = clamp(pitch - d.y, -1.2, 1.2)
	_apply_rot()

func _apply_rot() -> void:
	rotation = Vector3(0, yaw, 0)
	cam.rotation = Vector3(pitch, 0, 0)

func _process(dt: float) -> void:
	# M: the walking keys are InputMap actions (remappable, scripts/menu/controls.gd); _mkey falls back
	# to W A S D when they aren't set up
	var iv := Vector2(
		Input.get_axis("ui_left", "ui_right") + _mkey("mall_right", KEY_D) - _mkey("mall_left", KEY_A),
		Input.get_axis("ui_up", "ui_down") + _mkey("mall_back", KEY_S) - _mkey("mall_forward", KEY_W))
	if move_touch != -1:
		iv = move_vec
	iv = iv.limit_length(1.0)
	if leaving or vr_on or frozen:
		iv = Vector2.ZERO
	if iv.length() > 0.05:
		hint.visible = false
		var fwd := -transform.basis.z
		var right := transform.basis.x
		var run := RUN if (rmb_run or _mkey("mall_run", KEY_X) > 0.0 or (not InputMap.has_action("mall_run") and Input.is_physical_key_pressed(KEY_SHIFT))) else 1.0   # M: _mkey
		var step := (right * iv.x - fwd * iv.y) * SPEED * run * dt * move_scale   # V: move_scale (third person)
		# WALK (Nov 3 2026): in sub-steps no longer than MOVE_SUB, so a long frame at speed (6.6 m/s in
		# third person is 0.33 m at 20 fps, 8.8 m/s in first person more) can't jump a 0.10 m glass rect
		# (the thinnest in wing 2) or a 0.2 m store front: the rect test has no margin. Same speed, same
		# x-then-z sliding, per sub-step.
		var n := maxi(1, int(ceil(Vector2(step.x, step.z).length() / MOVE_SUB)))
		for i in n:
			_try_move(Vector3(step.x / n, 0, 0))
			_try_move(Vector3(0, 0, step.z / n))
	_update_prompt()
	_light_poll(dt)
	if year_btn and _year_btn_owner:   # OWNER: the year switch steps aside for the menu and full-screen moments
		year_btn.visible = not vr_on and not frozen and not leaving
	fps_t += dt
	if fps_t > 0.5:
		fps_t = 0.0
		if hud.visible:   # B+C: the fps readout is the owner's (owner_hud_sync)
			hud.text = "Houma Mall Rewind · Godot mall (%s)   %d fps" % [Years.label(year), Engine.get_frames_per_second()]
		if debug:
			print("DBG pos=", position, " touch=", move_touch, " vec=", move_vec, " iv=", iv, " free_here=", _free(position.x, position.z), " rows=", walk_rows.size())

## M: how far a walking / running action is held (its InputMap action; key k when there is none).
func _mkey(act: String, k: Key) -> float:
	if InputMap.has_action(act):
		return Input.get_action_strength(act)
	return float(Input.is_physical_key_pressed(k))

func _try_move(d: Vector3) -> void:
	var p := position + d
	if _free(p.x, p.z):
		position = p

func _walk(x: float, z: float) -> bool:
	var tx := int(floor(x / map_scale + map_origin.x))
	var ty := int(floor(z / map_scale + map_origin.y))
	if ty < 0 or ty >= walk_rows.size() or tx < 0 or tx >= walk_rows[ty].length():
		return false
	return walk_rows[ty][tx] == "1"

func _free(x: float, z: float) -> bool:
	var r := RADIUS
	if not (_walk(x - r, z - r) and _walk(x + r, z - r) and _walk(x - r, z + r) and _walk(x + r, z + r)):
		return false
	if _hits(obstacles, x, z):
		return false
	if fixtures_on and _hits(fx_obstacles, x, z):
		return false
	return true

func _hits(list: Array, x: float, z: float) -> bool:
	for o in list:
		if o.size() == 3 and not (o[0] is String):
			if Vector2(x - o[0], z - o[1]).length() < o[2] + RADIUS * 0.5:
				return true
		elif o[0] == "rect":
			if x > o[1] and x < o[3] and z > o[2] and z < o[4]:
				return true
	return false

# ------------------------------------------------------------------ wings
## The prompt (bottom middle, as in Fallout: a key cap and where it leads) and the fade.
func _build_wing_ui() -> void:
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 1)
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var arriving := Engine.has_meta("mall_arrived")
	if OS.has_feature("web"):
		arriving = str(JavaScriptBridge.eval("(function(){try{var v=sessionStorage.getItem('mall-xfer')||'';sessionStorage.removeItem('mall-xfer');return v}catch(e){return ''}})()")) != ""
	if Engine.has_meta("mall_arrived"):
		Engine.remove_meta("mall_arrived")
	fade.modulate.a = 1.0 if arriving else 0.0
	var top := CanvasLayer.new()
	top.layer = 20
	add_child(top)
	if wing == 0 or (seam.size() < 3 and doors.is_empty() and thresholds.is_empty()):
		if arriving:
			top.add_child(fade)
			create_tween().tween_property(fade, "modulate:a", 0.0, 0.6).set_delay(0.25)
		return
	prompt = Button.new()
	prompt.focus_mode = Control.FOCUS_NONE
	prompt.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.05, 0.78)
	sb.border_color = Color(0.93, 0.85, 0.66, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 14; sb.content_margin_right = 18
	sb.content_margin_top = 8; sb.content_margin_bottom = 8
	for st_name in ["normal", "hover", "pressed", "focus"]:
		prompt.add_theme_stylebox_override(st_name, sb)
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.custom_minimum_size = Vector2(340, 58)
	prompt.offset_left = -170; prompt.offset_right = 170
	prompt.offset_top = -132; prompt.offset_bottom = -74
	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14; row.offset_right = -14
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt.add_child(row)
	prompt_key = Label.new()
	prompt_key.custom_minimum_size = Vector2(38, 34)
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
	prompt.pressed.connect(_cross)
	top.add_child(prompt)
	top.add_child(fade)
	if arriving:
		create_tween().tween_property(fade, "modulate:a", 0.0, 0.6).set_delay(0.25)

## Distance from the player to the seam line, or a large number when not beside it.
func _seam_dist() -> float:
	if seam.size() < 3:
		return 1e9
	var x0 := float(seam[0]); var z := float(seam[1]); var x1 := float(seam[2])
	if position.x < x0 - 0.6 or position.x > x1 + 0.6:
		return 1e9
	# only from this wing's side
	var d := (z - position.z) * other_side
	return d if d >= -0.2 else 1e9

## S: the room-wing threshold beside the player (within SEAM_NEAR, on this wing's side), or null.
func _thr_here():
	for th in thresholds:
		var ln: Array = th.line
		if position.x < float(ln[0]) - 0.6 or position.x > float(ln[2]) + 0.6:
			continue
		var d := (float(ln[1]) - position.z) * float(th.side)
		if d >= -0.2 and d < SEAM_NEAR:
			return th
	return null

## S: a wing's name on the prompt ("Lynn's" for wing 4 in 2026).
func _wing_name(w: int) -> String:
	if w == 4 and year == 2026:
		return "Lynn's"
	return WING_NAMES.get(w, "Wing %d" % w)

## The door beside the player: in the mall, by its inside spot; outside, by its outside spot.
func _door_here():
	for d in doors:
		var sp: Array = d.get("out" if wing == 3 else "inside", [])
		if sp.size() < 2:
			continue
		if Vector2(position.x, position.z).distance_to(Vector2(float(sp[0]), float(sp[1]))) < DOOR_NEAR:
			return d
	return null

func _update_prompt() -> void:
	if prompt == null:
		return
	door_near = _door_here() if not leaving else null
	thr_near = _thr_here() if not leaving and door_near == null else null
	var near := (door_near != null or thr_near != null or _seam_dist() < SEAM_NEAR) and not leaving
	if near != prompt.visible:
		prompt.visible = near
	if near:
		prompt_key.text = {"pad": "A", "touch": "Tap", "kb": "E"}[input_kind]
		prompt_key.custom_minimum_size.x = 50 if input_kind == "touch" else 38
		if door_near != null:
			if wing == 3:
				prompt_text.text = "Enter the mall · " + _door_name(door_near)
			else:
				prompt_text.text = "Go outside · " + _door_name(door_near)
		elif thr_near != null:
			prompt_text.text = "Enter " + _wing_name(int(thr_near.to))
		else:
			prompt_text.text = "Enter " + WING_NAMES[3 - wing]

## Walk across the seam: fade to black, then load the other wing at the same spot (1.3 m past the
## seam), facing the same way, with the same lighting and toggles.
## The scene of wing w in the year on show.
func _wing_scene(w: int) -> String:
	return ("res://wing%d_2026.tscn" if year == 2026 else "res://wing%d.tscn") % w

## The 1995 / 2026 switch (was top right, under Jump to; key Y; hidden since MENU2): the same spot in the other year. The
## building is the same, the stores change. On the web it reloads the page with ?year= (each year's
## wing is its own pair of game files, web/shell.html), keeping the place you stand and the view.
func _build_year_ui() -> void:
	year_btn = Button.new()
	year_btn.text = ("Visit %s (Y)" if year == 1995 else "Back to the %s (Y)") % Years.label(Years.other(year))   # ITEMS: the years' names
	year_btn.focus_mode = Control.FOCUS_NONE
	year_btn.add_theme_font_size_override("font_size", 14)
	year_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	year_btn.offset_left = -200; year_btn.offset_right = -10
	year_btn.offset_top = 168; year_btn.offset_bottom = 200
	# MENU2 (Nov 3 2026, design/godot-menu.md): the year changes only at a mall directory's toggle
	# (scripts/timetravel_trip.gd). The button is kept, never shown, as other HUD code lays out
	# round it.
	year_btn.visible = false
	# OWNER (design/godot-owner-mode.md): the owner keeps this button (owner_hud_sync shows it)
	year_btn.pressed.connect(func(): if is_owner(): _switch_year())
	_cl.add_child(year_btn)


## M: the time-travel transition (scripts/timetravel.tscn) before a year change; returns when it
## has finished (at once in VR, where a flat overlay isn't seen).
func _time_travel(to_year: int) -> void:
	if vr_on or not ResourceLoader.exists("res://scripts/timetravel.tscn"):
		return
	var tt = load("res://scripts/timetravel.tscn").instantiate()
	add_child(tt)
	tt.play(year, to_year)
	await tt.finished

## MENU2: no player control reaches this any more (the directory's toggle travels instead); kept for
## tools and tests.
func _switch_year() -> void:
	if leaving:
		return
	var other := 2026 if year == 1995 else 1995
	var w := wing if wing != 0 else 1
	if not OS.has_feature("web") and not ResourceLoader.exists(("res://wing%d_2026.tscn" if other == 2026 else "res://wing%d.tscn") % w):
		return
	leaving = true
	if prompt:
		prompt.visible = false
	await _time_travel(other)   # M: the transition, then the fade and the reload as before
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.35)
	tw.tween_callback(func():
		var day: bool = not buttons[2].button_pressed
		if OS.has_feature("web"):
			var cam_s := "%.2f,%.2f,%.1f,%.1f" % [position.x, position.z, rad_to_deg(yaw), rad_to_deg(pitch)]
			var js := "(function(){try{sessionStorage.setItem('mall-xfer','%d')}catch(e){}var u=new URL(location.href);var p=u.searchParams;p.set('wing','%d');p.set('cam','%s');" % [w, w, cam_s]
			js += ("p.set('year','2026');" if other == 2026 else "p.delete('year');")
			js += "p.set('time','%s');" % ("day" if day else "night")
			js += "if(%s)p.set('refl','0');else p.delete('refl');" % ("true" if not _refl_wanted() else "false")
			js += "if(%s)p.set('fx','1');else p.delete('fx');" % ("true" if buttons[1].button_pressed else "false")
			js += "console.log('switching year '+u.toString());if(window.mallGoWing){window.mallGoWing(u.toString())}else{location.replace(u.toString())}})()"
			JavaScriptBridge.eval(js, true)
		else:
			Engine.set_meta("mall_xfer", {"x": position.x, "z": position.z, "yaw": yaw, "pitch": pitch})
			Engine.set_meta("mall_arrived", true)
			get_tree().change_scene_to_file(("res://wing%d_2026.tscn" if other == 2026 else "res://wing%d.tscn") % w))

func _cross() -> void:
	if leaving or wing == 0:
		return
	if door_near != null:
		# through a door: into the lot, or back into the wing the door belongs to
		var d = door_near
		# Q: a door a gate keeps locked (data/story/gates.json, design/godot-quests.md)
		var st = get_node_or_null("Story")
		var g = st.door_gate(str(d.get("store", ""))) if st else null
		if g:
			g.say_locked(true)
			return
		if wing == 3:
			var sp: Array = d.inside
			_go_to_wing(int(d.wing), float(sp[0]), float(sp[1]), deg_to_rad(float(d.yaw_in)), deg_to_rad(2.0))
		else:
			var sp: Array = d.out
			_go_to_wing(3, float(sp[0]), float(sp[1]), deg_to_rad(float(d.yaw_out)), deg_to_rad(2.0))
		return
	if thr_near != null:
		# S: a room wing's threshold (the mall opening of Sears / Dillard's, the cinema doors): the
		# other side, 1.3 m past the line, same x and facing, unless a gate holds it shut
		var th = thr_near
		for gt in get_tree().get_nodes_in_group("gate"):
			if gt.has_method("locks_threshold") and gt.locks_threshold(int(th.to)):
				gt.try_open(self)
				return
		var ln: Array = th.line
		_go_to_wing(int(th.to), clampf(position.x, float(ln[0]) + 0.5, float(ln[2]) - 0.5), float(ln[1]) + float(th.side) * 1.3, yaw, pitch)
		return
	if seam.size() < 3:
		return
	var other := 3 - wing
	var tz := float(seam[1]) + other_side * 1.3
	var tx := clampf(position.x, float(seam[0]) + 0.5, float(seam[2]) - 0.5)
	_go_to_wing(other, tx, tz, yaw, pitch)

## Fade to black, then load wing w at (x, z) facing yaw: on the web by reloading the page into
## that wing's file (web/shell.html) with the lighting and the toggles kept; in the editor or a
## test by changing the scene.
## year_to (the mall directory's jump, jump_to below): load that year's file instead of this one's.
func _go_to_wing(w: int, x: float, z: float, yaw_to: float, pitch_to: float, year_to := 0) -> void:
	leaving = true
	print("crossing to wing ", w)
	if prompt:
		prompt.visible = false
	if year_to != 0 and year_to != year:
		await _time_travel(year_to)   # M: a jump into the other year travels in time too
	var tw := create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 0.35)
	tw.tween_callback(func():
		var day: bool = not buttons[2].button_pressed
		if OS.has_feature("web"):
			var cam_s := "%.2f,%.2f,%.1f,%.1f" % [x, z, rad_to_deg(yaw_to), rad_to_deg(pitch_to)]
			var js := "(function(){try{sessionStorage.setItem('mall-xfer','%d')}catch(e){}var u=new URL(location.href);var p=u.searchParams;p.set('wing','%d');p.set('cam','%s');" % [w, w, cam_s]
			if year_to != 0:
				js += ("p.set('year','2026');" if year_to == 2026 else "p.delete('year');")
			js += "p.set('time','%s');" % ("day" if day else "night")
			js += "if(%s)p.set('refl','0');else p.delete('refl');" % ("true" if not _refl_wanted() else "false")
			js += "if(%s)p.set('fx','1');else p.delete('fx');" % ("true" if buttons[1].button_pressed else "false")
			js += "console.log('crossing to '+u.toString());if(window.mallGoWing){window.mallGoWing(u.toString())}else{location.replace(u.toString())}})()"
			JavaScriptBridge.eval(js, true)
		else:
			Engine.set_meta("mall_xfer", {"x": x, "z": z, "yaw": yaw_to, "pitch": pitch_to})
			Engine.set_meta("mall_arrived", true)
			var path := _wing_scene(w)
			if year_to != 0:
				path = ("res://wing%d_2026.tscn" if year_to == 2026 else "res://wing%d.tscn") % w
			if ResourceLoader.exists(path):
				get_tree().change_scene_to_file(path)
			else:
				leaving = false
				fade.modulate.a = 0.0)

## Whether the floor reflection is wanted in the flat game (VR turns it off while it runs).
func _refl_wanted() -> bool:
	return vr._refl_was if vr_on else buttons[0].button_pressed

# ------------------------------------------------------------------ quick jump
## A small menu (J, a gamepad's Y, or the "Jump to" button) that drops the player in front of
## Sears, the main entrance, Dillard's or JCPenney. In the other wing, it loads that wing's file
## the same way the seam does.
func _build_jump_ui() -> void:
	jump_open_btn = Button.new()
	jump_open_btn.text = "Jump to (J)"
	jump_open_btn.focus_mode = Control.FOCUS_NONE
	jump_open_btn.add_theme_font_size_override("font_size", 14)
	jump_open_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	jump_open_btn.offset_left = -200; jump_open_btn.offset_right = -10
	jump_open_btn.offset_top = 128; jump_open_btn.offset_bottom = 160
	jump_open_btn.pressed.connect(func(): _jump_show(not jump_panel.visible))
	_cl.add_child(jump_open_btn)
	jump_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.06, 0.05, 0.86)
	sb.border_color = Color(0.93, 0.85, 0.66, 0.85)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(14)
	jump_panel.add_theme_stylebox_override("panel", sb)
	jump_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	jump_panel.custom_minimum_size = Vector2(280, 0)
	jump_panel.offset_left = -140; jump_panel.offset_right = 140
	jump_panel.offset_top = -130; jump_panel.offset_bottom = 130
	jump_panel.visible = false
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	jump_panel.add_child(col)
	var title := Label.new()
	title.text = "Jump to"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 0.97, 0.9))
	col.add_child(title)
	for i in JUMPS.size():
		var b := Button.new()
		b.text = "%d   %s" % [i + 1, JUMPS[i][0]]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(0, 40)
		b.add_theme_font_size_override("font_size", 16)
		var k := i
		b.pressed.connect(func(): _jump_go(k))
		b.mouse_entered.connect(func(): _jump_select(k))
		col.add_child(b)
		jump_btns.append(b)
	var foot := Label.new()
	foot.text = "1–4 or arrows + Enter · gamepad: D-pad + A · Esc / B closes"
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	foot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	foot.add_theme_font_size_override("font_size", 12)
	foot.add_theme_color_override("font_color", Color(0.93, 0.85, 0.66, 0.9))
	col.add_child(foot)
	_cl.add_child(jump_panel)
	_jump_select(0)

func _jump_show(on: bool) -> void:
	if leaving or jump_locked:
		on = false
	jump_panel.visible = on
	if on:
		move_vec = Vector2.ZERO
		dragging = false
		_jump_select(0)

func _jump_select(i: int) -> void:
	jump_sel = posmod(i, JUMPS.size())
	for k in jump_btns.size():
		jump_btns[k].modulate = Color(1, 0.86, 0.5) if k == jump_sel else Color(1, 1, 1)

## Handles the menu's keys, pad buttons and taps. True when the event was used.
func _jump_input(e: InputEvent) -> bool:
	if jump_panel == null or leaving:
		return false
	var open := jump_panel.visible
	if e is InputEventKey and e.pressed and not e.echo:
		var k: int = e.physical_keycode
		if k == KEY_J:
			_jump_show(not open)
			return true
		if not open:
			return false
		if k == KEY_ESCAPE:
			_jump_show(false)
		elif k in [KEY_UP, KEY_W]:
			_jump_select(jump_sel - 1)
		elif k in [KEY_DOWN, KEY_S]:
			_jump_select(jump_sel + 1)
		elif k in [KEY_ENTER, KEY_KP_ENTER, KEY_E, KEY_SPACE]:
			_jump_go(jump_sel)
		elif k >= KEY_1 and k < KEY_1 + JUMPS.size():
			_jump_go(k - KEY_1)
		return true
	if e is InputEventJoypadButton and e.pressed:
		if e.button_index == JOY_BUTTON_Y:
			_jump_show(not open)
			return true
		if not open:
			return false
		match e.button_index:
			JOY_BUTTON_B, JOY_BUTTON_BACK:
				_jump_show(false)
			JOY_BUTTON_DPAD_UP:
				_jump_select(jump_sel - 1)
			JOY_BUTTON_DPAD_DOWN:
				_jump_select(jump_sel + 1)
			JOY_BUTTON_A:
				_jump_go(jump_sel)
		return true
	if e is InputEventJoypadMotion and open and e.axis == JOY_AXIS_LEFT_Y and abs(e.axis_value) > 0.6:
		if not Engine.has_meta("_jump_axis_held"):
			Engine.set_meta("_jump_axis_held", true)
			_jump_select(jump_sel + (1 if e.axis_value > 0 else -1))
		return true
	if e is InputEventJoypadMotion and e.axis == JOY_AXIS_LEFT_Y and abs(e.axis_value) < 0.3 and Engine.has_meta("_jump_axis_held"):
		Engine.remove_meta("_jump_axis_held")
	if e is InputEventScreenTouch and e.pressed:
		# touches skip mouse emulation, so the menu and its button are tapped here
		if jump_open_btn.is_visible_in_tree() and jump_open_btn.get_global_rect().has_point(e.position):   # UI-OFFSCREEN: tucked away
			_jump_show(not open)
			return true
		if open:
			for i in jump_btns.size():
				if jump_btns[i].get_global_rect().has_point(e.position):
					_jump_go(i)
					return true
			if not jump_panel.get_global_rect().has_point(e.position):
				_jump_show(false)
			return true
	if open and (e is InputEventScreenDrag or (e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and e.pressed and not jump_panel.get_global_rect().has_point(e.position))):
		if e is InputEventMouseButton:
			_jump_show(false)
		return true
	return false

## Go to JUMPS[i]: in this wing, at once; in the other wing, by loading its file there.
func _jump_go(i: int) -> void:
	var j: Array = JUMPS[i]
	_jump_show(false)
	hint.visible = false
	var tw_wing := int(j[1])
	if wing == 0 or tw_wing == wing:
		position = Vector3(float(j[2]), 0, float(j[3]))
		yaw = deg_to_rad(float(j[4]))
		pitch = deg_to_rad(3.0)
		_apply_rot()
		if vr_on:
			vr.recentre()
		return
	_go_to_wing(tw_wing, float(j[2]), float(j[3]), deg_to_rad(float(j[4])), deg_to_rad(3.0))

# ------------------------------------------------------------------ mall directory jump
## The mall directory's "Jump to this store?" (scripts/directory_ui.gd, design/godot-directory.md):
## stand at (x, z) in wing w of year yr, facing yaw_deg (0 looks along -z, 90 along -x). In this
## wing and year it happens at once; otherwise that wing's / year's file loads there, the way the
## seam crossing and the year switch do (the same fade, lighting and toggles).
func jump_to(w: int, yr: int, x: float, z: float, yaw_deg: float) -> void:
	if leaving:
		return
	hint.visible = false
	if yr == year and (wing == 0 or w == wing):
		position = Vector3(x, 0, z)
		yaw = deg_to_rad(yaw_deg)
		pitch = deg_to_rad(3.0)
		_apply_rot()
		if vr_on:
			vr.recentre()
		return
	_go_to_wing(w if wing != 0 else 1, x, z, deg_to_rad(yaw_deg), deg_to_rad(3.0), yr if yr != year else 0)
