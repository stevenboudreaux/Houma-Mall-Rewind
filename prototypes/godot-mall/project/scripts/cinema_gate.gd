## The Southland Cinema's gate (workstream S, Nov 2 2026; design/godot-wings.md "Wings 4-6"):
## a node in group "gate" (workstream Q's contract, design/godot-quests.md) holding the cinema doors
## shut while its flag (cinema_unlocked) is false. The doors are wing 6's threshold in wing 1
## (scripts/player.gd thresholds): pressing the action button there asks locks_threshold(6), and
## while locked try_open() runs instead of the crossing:
##   - holding the key item (Martin Folse's stick, folse_stick) sets the flag and rolls the gate up
##     (1995: the dynamic mesh dyn_cin_gate, tools/stores/cinema/front.gd; 2026: the vacant unit's
##     grille, its own static mesh cin_gate, build_mall.gd); the next press
##     goes in;
##   - otherwise it shows the PLACEHOLDER message from data/story/gates.json.
## The flag lives where Q keeps flags (mall.flags, scripts/flags.gd); until Q merges, a fallback
## reads and writes the same store (localStorage "mall-flags-1" on the web, Engine metadata
## "mall_flags" elsewhere, {"v": 1, "flags": {...}}), so it survives wing loads and reloads either way.
## "Holding" is mall.inventory.held_id() (workstream M); until M merges, B+C's mall.hand (as Q does).
## Made by make_all() from player.gd in every wing; only gates with a "threshold" are made here.
extends Node3D

const GATES := "res://data/story/gates.json"
const KEY := "mall-flags-1"

var player: Node3D
var flag := ""
var to_wing := 0
var key_item := ""
var message := ""
var _gate_mesh: Node3D = null
var _open := false

## Makes this wing's threshold gates (data/story/gates.json entries with "threshold" whose "wing"
## is the player's wing and whose "years" include the year on show) as children of the player.
static func make_all(p: Node3D) -> void:
	if not FileAccess.file_exists(GATES):
		return
	var j = JSON.parse_string(FileAccess.get_file_as_string(GATES))
	if not (j is Dictionary):
		return
	for e in j.get("gates", []):
		if not (e is Dictionary) or not e.has("threshold"):
			continue
		if int(e.get("wing", 0)) != int(p.wing) and int(p.wing) != 0:
			continue
		var yrs = e.get("years", "both")
		if not (str(yrs) == "both" or (yrs is Array and int(p.year) in yrs) or (not (yrs is Array) and int(yrs) == int(p.year))):
			continue
		var g = load("res://scripts/cinema_gate.gd").new()
		g.setup(p, e)
		p.add_child(g)

func setup(p: Node3D, e: Dictionary) -> void:
	player = p
	name = "Gate_" + str(e.get("id", "threshold"))
	flag = str(e.get("flag", ""))
	to_wing = int(e.get("threshold", 0))
	key_item = str(e.get("key_item", ""))
	message = str(e.get("message", "Locked."))
	add_to_group("gate")

func _ready() -> void:
	var root = player.get_parent() if player else null
	if root:
		# 1995: a dynamic mesh behind the door arches; 2026: the vacant unit's grille, a static
		# (lightmapped) mesh of its own
		_gate_mesh = root.get_node_or_null("Dynamic/dyn_cin_gate")
		if _gate_mesh == null:
			_gate_mesh = root.get_node_or_null("Static/cin_gate")
	var f = _flags()
	if f and f.has_signal("changed"):
		f.changed.connect(func(_n, _v): _sync(true))
	_sync(false)

# ------------------------------------------------------------------ Q's gate contract
func locked() -> bool:
	return not _flag_has(flag)

## player.gd: does this gate hold wing w's threshold shut?
func locks_threshold(w: int) -> bool:
	return w == to_wing and locked()

## Exterior doors: none (Q's contract asks; this gate only holds a threshold).
func locks_door(_store_key: String) -> bool:
	return false

## The press at the locked doors: open with the key item in hand, else the locked message.
func try_open(_p = null) -> void:
	if key_item != "" and _held() == key_item:
		_flag_set(flag, true)
		_sync(true)
	else:
		say_locked()

func say_locked(_door := false) -> void:
	var st = player.get_node_or_null("Story") if player else null
	if st and st.has_method("say"):
		st.say(message)
	else:
		_notice(message)

## Until Q's Story lands: the message just above the threshold prompt (player.gd's own _say sits
## under the prompt, where the prompt hides it), for 2.6 s.
var _note: Label = null
func _notice(t: String) -> void:
	if _note == null:
		var layer := CanvasLayer.new()
		layer.layer = 21
		add_child(layer)
		_note = Label.new()
		_note.add_theme_font_size_override("font_size", 22)
		_note.add_theme_color_override("font_color", Color(1, 0.95, 0.75))
		_note.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
		_note.add_theme_constant_override("outline_size", 6)
		_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_note.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
		_note.offset_left = -260; _note.offset_right = 260
		_note.offset_top = -200; _note.offset_bottom = -140
		_note.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(_note)
	_note.text = t
	_note.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(_note, "modulate:a", 0.0, 0.6)

# ------------------------------------------------------------------ the gate's look
## Rolled down while locked; rolled up (squashed into its top, then hidden) once open.
func _sync(animate: bool) -> void:
	var want_open := not locked()
	if want_open == _open:
		return
	_open = want_open
	if _gate_mesh == null:
		return
	var top := _gate_top()
	if not want_open:
		_gate_mesh.visible = true
		_gate_mesh.transform = Transform3D.IDENTITY
		return
	var up := Transform3D(Basis.from_scale(Vector3(1, 0.02, 1)), Vector3(0, top * 0.98, 0))
	if not animate:
		_gate_mesh.transform = up
		_gate_mesh.visible = false
		return
	var tw := create_tween()
	tw.tween_property(_gate_mesh, "transform", up, 1.1).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func(): _gate_mesh.visible = false)

func _gate_top() -> float:
	if _gate_mesh is MeshInstance3D and _gate_mesh.mesh:
		var bb: AABB = _gate_mesh.mesh.get_aabb()
		return bb.position.y + bb.size.y
	return 3.0

# ------------------------------------------------------------------ the hand and the flags
## The item in the hand: M's mall.inventory.held_id(); until M lands, B+C's mall.hand (as Q's
## dialogue_state.gd held()).
func _held() -> String:
	var mall = player.get("mall") if player else null
	if mall == null:
		return ""
	var inv = mall.get("inventory")
	if inv is Object and inv.has_method("held_id"):
		return str(inv.held_id())
	return str(mall.get("hand")) if mall.get("hand") != null else ""     # remove when M lands

func _flags():
	var mall = player.get("mall") if player else null
	if mall == null:
		return null
	var f = mall.get("flags")
	return f if f is Object else null

func _flag_has(n: String) -> bool:
	var f = _flags()
	if f:
		return f.has(n)
	var v = _store().get(n)
	# truthy as Q's has(): true, a non-zero number, a non-empty string
	if v is bool:
		return v
	if v is int or v is float:
		return v != 0
	return v != null and str(v) != ""

func _flag_set(n: String, v) -> void:
	var f = _flags()
	if f:
		f.set_flag(n, v)
		return
	var d := _store()
	d[n] = v
	var s := JSON.stringify({"v": 1, "flags": d})
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s)}catch(e){}})()" % [JSON.stringify(KEY), JSON.stringify(s)], true)
	else:
		Engine.set_meta("mall_flags", s)

## The fallback store (Q's format) until scripts/flags.gd lands.
func _store() -> Dictionary:
	var s := ""
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||''}catch(e){return ''}})()" % JSON.stringify(KEY), true)
		s = str(v) if v != null else ""
	else:
		s = str(Engine.get_meta("mall_flags", ""))
	var j = JSON.parse_string(s) if s != "" else null
	if j is Dictionary and int(j.get("v", 0)) == 1 and j.get("flags") is Dictionary:
		return j.flags
	return {}
