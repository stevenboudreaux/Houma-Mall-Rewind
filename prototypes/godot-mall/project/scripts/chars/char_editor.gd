## B2 (design/godot-character-editor.md): the character editor. One editor, two modes:
##  - "owner": the owner's NPC editor (scripts/chars/char_owner.gd opens it on an NPC that wears a
##    preset): tabs BODY · SKIN · BASE · HAIR · OUTFIT · NAME, Save (this browser) + Download (the
##    file Steven commits to data/characters/), Reset, Copy from another preset, view in place.
##  - "player": the player's avatar creator inside the menu's AVATAR tab (scripts/menu/menu.gd hosts
##    it as it hosted V's creator: frame, embedded, feed(), sel, closed): BODY · SKIN · HAIR · OUTFIT
##    by default; "Advanced" adds BASE and every slider. The NAME is the menu's own field above.
##
## The preview is a turntable: the character alone in its own world (SubViewport), neutral light,
## white or dark backdrop, idle or A-pose; drag or the arrows on the view row rotate, the wheel /
## pinch / − + zoom, Front / Side / Back. Pieces change while it spins. The body is live (blend
## shapes); NPCs in the mall are baked (CharPreset.bake).
##
## Input: all by hand (the menu and the project turn GUI mouse emulation off for touches), so every
## event goes through handle(): keys / pad (rows ↑↓, values ←→, Enter / A), mouse (click, drag,
## wheel), touch (tap, drag, pinch, a drag on a slider sets it).
extends CanvasLayer

signal closed(look: Dictionary, how: String)     # how: "done", "skip", "cancel", "saved"

const P := preload("res://scripts/chars/char_preset.gd")
const INK := Color(1, 0.97, 0.9)
const GOLD := Color(0.93, 0.85, 0.66)
const AMBER := Color(0.85, 0.62, 0.22)
const PANEL := Color(0.09, 0.07, 0.055, 1.0)
const ROW := Color(0.16, 0.13, 0.1)
const ROW_SEL := Color(0.32, 0.24, 0.13)
const GROUPS := [["overall", ["body"]], ["torso", ["torso"]], ["limbs", ["legs", "arms"]], ["head", ["head"]], ["face", ["face"]]]
const SIMPLE_KEYS := ["height", "weight", "muscle", "age"]
## Clothes palette (1995 mall clothes and neutrals; V's palettes and B1's defaults are added per piece).
const CLOTH := ["#f4f4f2", "#1c1c1f", "#8d8e90", "#e8eef5", "#1f6f6a", "#5b2a5e", "#2f4a2e", "#7a1f2b", "#c79a2c",
	"#24346b", "#b8352f", "#4a6a96", "#8fb0d3", "#c2ab84", "#3e4b5a", "#d9b8c4", "#f4c6d0", "#6b4f3a"]
const UNDER := ["#f2f2f0", "#e9d9d0", "#d9b8c4", "#efe6dc", "#c9a58c", "#8a6450", "#3a3a40", "#1d1d24", "#2b5f8a", "#c8492e", "#2a2c33", "#8fa6c7"]

# ---- what menu.gd (and V's contract) reads
var year := 1995
var look := {}               # the player's V look (player mode), passed back on close
var first_time := false
var embedded := false
var frame := Rect2()
var root: Control
var hits: Array = []         # kept empty: the menu then feeds every click to feed()
var sel := 0                 # the selected row (0 = the tab row; the menu goes to NAME above it)
var _built_for := Vector2.ZERO

# ---- the edit
var mode := "owner"          # "owner" | "player"
var preset := {}             # the working copy
var loaded := {}             # as opened (Reset)
var target: Node = null      # owner mode: the attendant (wear_preset) the editor opened on
var dirty := false
var advanced := false
var tab := "body"
var tabs: Array = []
var in_place := false
var dark := false
var a_pose := false
var copy_from := 0
var msg := ""
var _msg_t := 0.0
var _confirm_close := false
var _need := ""              # "", "paint", "keys", "dress"
var _expanded := ""          # the colour row whose fine sliders are open

# ---- the preview
var vp: SubViewport
var vpc: SubViewportContainer
var pv: CharBody
var pv_cam: Camera3D
var place_cam: Camera3D
var env_bg: Environment
var yaw := 0.5
var zoom := 1.0              # 1 = the whole body; up to 3.2 = the face
var spin := true
var _spin_wait := 0.0

# ---- ui
var _list: Control
var _rows: Array = []        # row dicts
var _row_ctl: Array = []     # the row's panel
var _zones: Array = []       # [Control, Callable(pos: Vector2), kind] kind: "tap" | "slide"
var _scroll := 0.0
var _scroll_max := 0.0
var sub := 0                 # the item within a row of buttons
var _drag := {}              # index -> {"at", "start", "kind": "pv"|"list"|"slide", "zone", "scroll", "moved"}
var _pinch := 0.0
var _msg_lbl: Label
var _fs := 14
var _rh := 40.0
var _catcher: Node = null

class Catcher extends Node:
	var ed: Node
	func _input(e: InputEvent) -> void:
		if ed and is_instance_valid(ed) and ed.visible and not ed.embedded:
			get_viewport().set_input_as_handled()
			ed.handle(e)

## Open on a preset. m: "owner" | "player"; p: the preset; t: the NPC (owner mode).
func setup(m: String, p: Dictionary, t: Node = null) -> void:
	mode = m
	preset = P.normalize(p)
	loaded = preset.duplicate(true)
	target = t

func _ready() -> void:
	layer = 47
	if preset.is_empty():
		preset = P.normalize(P.player_preset() if mode == "player" else P.blank())
		loaded = preset.duplicate(true)
	_tabs()
	_make_preview()
	if not embedded:
		_catcher = Catcher.new()
		_catcher.name = "CharEditorInput"
		_catcher.ed = self
		get_tree().root.add_child.call_deferred(_catcher)
	get_viewport().size_changed.connect(func(): _built_for = Vector2.ZERO)
	_layout()

func _exit_tree() -> void:
	if _catcher and is_instance_valid(_catcher):
		_catcher.queue_free()
	_drop_place_cam()

func _tabs() -> void:
	if mode == "owner":
		tabs = ["body", "skin", "base", "hair", "outfit", "name"]
	else:
		tabs = ["body", "skin", "hair", "outfit"] + (["base"] if advanced else [])
	if not (tab in tabs): tab = tabs[0]

# ------------------------------------------------------------------ the turntable
func _make_preview() -> void:
	vpc = SubViewportContainer.new()
	vpc.stretch = true
	vpc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vp = SubViewport.new()
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_2X
	vp.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	vpc.add_child(vp)
	var we := WorldEnvironment.new()
	env_bg = Environment.new()
	env_bg.background_mode = Environment.BG_COLOR
	env_bg.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_bg.ambient_light_color = Color(0.62, 0.62, 0.64)
	env_bg.ambient_light_energy = 0.55
	env_bg.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	we.environment = env_bg
	vp.add_child(we)
	# neutral light: a soft key, a fill and a rim, white
	for l in [[Vector3(-35, 30, 0), 1.25], [Vector3(-15, -60, 0), 0.45], [Vector3(-20, 160, 0), 0.6]]:
		var d := DirectionalLight3D.new()
		d.rotation_degrees = l[0]
		d.light_energy = l[1]
		d.light_color = Color(1, 0.99, 0.97)
		vp.add_child(d)
	var floor_m := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.55; disc.bottom_radius = 0.55; disc.height = 0.02
	floor_m.mesh = disc
	floor_m.position.y = -0.011
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.8, 0.8, 0.8)
	fm.roughness = 0.9
	floor_m.material_override = fm
	floor_m.name = "Stage"
	vp.add_child(floor_m)
	pv_cam = Camera3D.new()
	pv_cam.fov = 30
	pv_cam.near = 0.05
	vp.add_child(pv_cam)
	pv = CharBody.new()
	pv.name = "Preview"
	vp.add_child(pv)
	P.dress(pv, preset)
	_pose()
	_backdrop()

func _backdrop() -> void:
	env_bg.background_color = Color(0.13, 0.13, 0.14) if dark else Color(0.96, 0.96, 0.95)
	var st := vp.get_node_or_null("Stage") as MeshInstance3D
	if st: (st.material_override as StandardMaterial3D).albedo_color = Color(0.22, 0.22, 0.23) if dark else Color(0.82, 0.82, 0.82)

## Idle (the shoppers' clip) or the A-pose (the bind pose B1 modelled the mesh in).
func _pose() -> void:
	for body in _bodies():
		if body == null or body.ap == null: continue
		if a_pose:
			body.ap.stop()
			var bones: Dictionary = CharBody.cman().bodies[body.sex].bones
			for i in range(body.sk.get_bone_count()):
				var n = body.sk.get_bone_name(i)
				if not bones.has(n): continue
				var q: Array = bones[n].bind_rot
				body.sk.set_bone_pose_rotation(i, Quaternion(q[0], q[1], q[2], q[3]))
				body.sk.set_bone_pose_position(i, body.sk.get_bone_rest(i).origin)
		else:
			body.clip = ""
			body.play("idle", 0.0)

## The bodies an edit goes to: the turntable's, and the NPC's own when viewing in place.
func _bodies() -> Array:
	var out: Array = [pv]
	if in_place and target and is_instance_valid(target) and "body" in target and target.body is CharBody:
		out.append(target.body)
	return out

func _frame_cam(dt := 0.0) -> void:
	var h := float(CharBody.cman().bodies[str(preset.body)].height_m) * (1.0 + float(preset.keys.get("height", 0.0)) * 0.14)
	var look_y := lerpf(h * 0.52, h * 0.93, clampf((zoom - 1.0) / 2.2, 0.0, 1.0))
	var dist := lerpf(h * 2.15, 0.55, clampf((zoom - 1.0) / 2.2, 0.0, 1.0))
	if in_place and place_cam and target and is_instance_valid(target) and target.body:
		# in place: from the side the player stands on (the shop floor, not behind the counter),
		# closer than on the turntable, the NPC left of the panel (h_offset)
		var b: Node3D = target.body
		var c := b.global_position + Vector3(0, look_y, 0)
		var base_dir := _place_dir
		var dir := base_dir.rotated(Vector3.UP, yaw - _place_yaw0)
		var dd := minf(dist, 2.4)
		place_cam.global_position = c + dir * dd + Vector3(0, 0.1, 0)
		place_cam.look_at(c, Vector3.UP)
		place_cam.h_offset = dd * 0.28 if not _phone_place else 0.0
		place_cam.v_offset = -dd * 0.22 if _phone_place else 0.0
		return
	var c := Vector3(0, look_y, 0)
	pv_cam.position = c + Vector3(sin(yaw), 0, cos(yaw)) * dist + Vector3(0, 0.05, 0)
	pv_cam.look_at(c, Vector3.UP)

func _process(dt: float) -> void:
	if root == null:
		return
	var vs := get_viewport().get_visible_rect().size
	if _built_for != vs and not embedded:
		_layout()
	if _need != "":
		_push()
	if spin and _drag.is_empty():
		_spin_wait -= dt
		if _spin_wait <= 0.0:
			yaw = wrapf(yaw + dt * 0.45, -PI, PI)
	# a gamepad's right stick: rotate and zoom
	var rx := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var ry := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if absf(rx) > 0.25:
		yaw = wrapf(yaw + rx * dt * 2.5, -PI, PI); _hold_spin()
	if absf(ry) > 0.25:
		zoom = clampf(zoom - ry * dt * 1.5, 1.0, 3.2)
	_frame_cam(dt)
	if _msg_t > 0.0:
		_msg_t -= dt
		if _msg_t <= 0.0 and _msg_lbl: _msg_lbl.text = _status()

func _hold_spin() -> void:
	spin = false
	_spin_wait = 4.0

## Push the working preset onto the bodies (once a frame, however many changes came in).
func _push() -> void:
	var what := _need
	_need = ""
	for b in _bodies():
		if what == "dress":
			P.dress(b, _shown(b))
		elif what == "keys":
			b.apply(preset.keys)
		else:
			P.paint(b, _shown(b))
	if what != "paint" and a_pose:
		_pose()
	elif what == "dress" and not a_pose:
		for b in _bodies(): b.clip = ""; b.play("idle", 0.0)

## What a body shows: the preset, but on the BASE tab the turntable shows the base layer alone
## (the clothes come back on the other tabs; the preset itself keeps them).
func _shown(b) -> Dictionary:
	return P.stripped(preset) if (tab == "base" and b == pv) else preset

func _changed(what: String) -> void:
	dirty = true
	_confirm_close = false
	if what == "dress" or _need == "dress": _need = "dress"
	elif what == "keys" or _need == "keys": _need = "keys"
	else: _need = "paint"

# ------------------------------------------------------------------ layout
func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	_built_for = vs
	var fr := frame if (embedded and frame.size.x > 10) else Rect2(Vector2.ZERO, vs)
	if root:
		if vpc.get_parent(): vpc.get_parent().remove_child(vpc)
		root.queue_free()
	_zones = []
	root = Control.new()
	root.position = fr.position
	root.size = fr.size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var narrow := fr.size.x < 640.0
	_fs = 13 if narrow else 15
	_rh = 40.0 if narrow else 38.0
	var bg := ColorRect.new()
	bg.color = PANEL
	bg.size = fr.size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	# the preview: left half on a wide screen, the top on a phone held upright
	var pv_r: Rect2
	var pan_r: Rect2
	if narrow and fr.size.y > fr.size.x:
		var ph := floorf(fr.size.y * 0.38)
		pv_r = Rect2(0, 0, fr.size.x, ph)
		pan_r = Rect2(0, ph, fr.size.x, fr.size.y - ph)
	else:
		var pw := floorf(fr.size.x * (0.44 if not narrow else 0.4))
		pv_r = Rect2(0, 0, pw, fr.size.y)
		pan_r = Rect2(pw, 0, fr.size.x - pw, fr.size.y)
	if in_place:
		# the NPC in its own spot through the main camera: the panel keeps to the right / bottom
		pv_r = Rect2(pv_r.position, Vector2(0, 0))
		if narrow and fr.size.y > fr.size.x:
			pan_r = Rect2(0, fr.size.y * 0.5, fr.size.x, fr.size.y * 0.5)
		else:
			pan_r = Rect2(fr.size.x * 0.58, 0, fr.size.x * 0.42, fr.size.y)
		bg.position = pan_r.position
		bg.size = pan_r.size
		_phone_place = narrow and fr.size.y > fr.size.x
		_in_place_cam(true)
	else:
		_in_place_cam(false)
	vpc.position = pv_r.position
	vpc.size = pv_r.size
	vpc.visible = not in_place
	root.add_child(vpc)
	if not in_place:
		var pvz := Control.new()
		pvz.position = pv_r.position; pvz.size = pv_r.size
		pvz.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(pvz)
		_zones.append([pvz, Callable(), "pv"])
	# the panel: the rows (scrolling), the message line and the bottom buttons
	var foot_h := _rh + 10.0
	var msg_h := 20.0
	_list = Control.new()
	_list.position = pan_r.position + Vector2(6, 6)
	_list.size = pan_r.size - Vector2(12, 12 + foot_h + msg_h)
	_list.clip_contents = true
	_list.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_list)
	_zones.append([_list, Callable(), "list"])
	_msg_lbl = Label.new()
	_msg_lbl.position = Vector2(pan_r.position.x + 8, pan_r.end.y - foot_h - msg_h - 4)
	_msg_lbl.size = Vector2(pan_r.size.x - 16, msg_h)
	_msg_lbl.add_theme_font_size_override("font_size", _fs - 2)
	_msg_lbl.add_theme_color_override("font_color", GOLD)
	_msg_lbl.clip_text = true
	_msg_lbl.text = msg if _msg_t > 0.0 else _status()
	root.add_child(_msg_lbl)
	var foot := HBoxContainer.new()
	foot.position = Vector2(pan_r.position.x + 6, pan_r.end.y - foot_h)
	foot.size = Vector2(pan_r.size.x - 12, _rh)
	foot.add_theme_constant_override("separation", 6)
	root.add_child(foot)
	for it in _foot_items():
		var b := _btn(foot, it[0], it[1])
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_rows()

func _status() -> String:
	var who := "player avatar" if mode == "player" else "preset %s" % str(preset.id)
	var s := "%s · %s" % [who, "unsaved changes" if dirty else "saved"]
	if mode == "owner" and P.has_local(str(preset.id)):
		s += " · this browser's edit"
	return s

func _foot_items() -> Array:
	if mode == "owner":
		return [["Save", _save], ["Download", _download], ["Reset", _reset], ["Close", _close]]
	return [["Advanced: " + ("on" if advanced else "off"), _toggle_adv], ["Reset", _reset], ["Done", _done]]

func _btn(parent: Control, t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_theme_font_size_override("font_size", _fs)
	b.clip_text = true
	b.custom_minimum_size = Vector2(0, _rh)
	parent.add_child(b)
	_zones.append([b, func(_p): cb.call(), "tap"])
	return b

# ------------------------------------------------------------------ the rows
func _build_rows() -> void:
	for c in _list.get_children(): c.queue_free()
	# zones inside the list are rebuilt: drop the old ones (keep pv / list / foot)
	var keep := []
	for z in _zones:
		if not (is_instance_valid(z[0]) and _list.is_ancestor_of(z[0])): keep.append(z)
	_zones = keep
	_rows = _rows_for_tab()
	_row_ctl = []
	var y := 0.0
	var w := _list.size.x
	for i in _rows.size():
		var r: Dictionary = _rows[i]
		var h := _row_h(r, w)
		var pnl := Panel.new()
		pnl.position = Vector2(0, y - _scroll)
		pnl.size = Vector2(w, h)
		pnl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0) if r.kind in ["header", "note"] else ROW
		sb.set_corner_radius_all(4)
		pnl.add_theme_stylebox_override("panel", sb)
		_list.add_child(pnl)
		_row_ctl.append(pnl)
		_fill_row(pnl, r, i)
		y += h + 4.0
	_scroll_max = maxf(0.0, y - _list.size.y)
	_scroll = clampf(_scroll, 0.0, _scroll_max)
	sel = clampi(sel, 0, _rows.size() - 1)
	_paint_sel()

func _row_h(r: Dictionary, w: float) -> float:
	match r.kind:
		"header": return _rh * 0.7
		"note":
			var per_line := maxf(10.0, (w - 12.0) / (_fs * 0.55))
			return maxf(_rh * 0.8, ceilf(str(r.label).length() / per_line) * (_fs + 5.0) + 8.0)
		"chips":
			var per := maxi(1, int(w / 118.0))
			return 22.0 + ceilf(float(r.opts.size()) / per) * (_rh * 0.85 + 4.0)
		"color":
			var per := maxi(1, int((w - 8.0) / 30.0))
			return 22.0 + ceilf(float(r.pal.size()) / per) * 30.0 + 4.0
		"view", "buttons", "tabs":
			var n: int = r.items.size()
			var per := maxi(1, int(w / _min_w(r)))
			return ceilf(float(n) / per) * (_bh(r) + 4.0)
	return _rh

func _fill_row(pnl: Panel, r: Dictionary, i: int) -> void:
	var w := pnl.size.x
	match r.kind:
		"header", "note":
			var l := _lbl(pnl, r.label, _fs - (0 if r.kind == "header" else 2), GOLD if r.kind == "header" else Color(INK, 0.75))
			l.position = Vector2(6, 0); l.size = pnl.size - Vector2(12, 0)
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		"slider":
			var lw := clampf(w * 0.34, 80.0, 150.0)
			var l := _lbl(pnl, r.label, _fs)
			l.position = Vector2(8, 0); l.size = Vector2(lw, _rh)
			var bar := Panel.new()
			bar.position = Vector2(lw + 12, _rh * 0.3); bar.size = Vector2(w - lw - 70, _rh * 0.4)
			bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var bs := StyleBoxFlat.new(); bs.bg_color = Color(0.06, 0.05, 0.04); bs.set_corner_radius_all(3)
			bar.add_theme_stylebox_override("panel", bs)
			pnl.add_child(bar)
			var fill := ColorRect.new()
			fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
			fill.color = AMBER
			bar.add_child(fill)
			var knob := ColorRect.new()
			knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
			knob.color = INK
			bar.add_child(knob)
			var vl := _lbl(pnl, "", _fs - 1)
			vl.position = Vector2(w - 54, 0); vl.size = Vector2(50, _rh)
			vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			r.ui = [bar, fill, knob, vl]
			_slider_paint(r)
			# the bar and a little around it is the drag zone
			var z := Control.new()
			z.mouse_filter = Control.MOUSE_FILTER_IGNORE
			z.position = Vector2(lw + 4, 0); z.size = Vector2(w - lw - 58, _rh)
			pnl.add_child(z)
			_zones.append([z, func(p: Vector2): _slide_to(i, p), "slide"])
		"choice":
			var lw := clampf(w * 0.34, 80.0, 150.0)
			var l := _lbl(pnl, r.label, _fs)
			l.position = Vector2(8, 0); l.size = Vector2(lw, _rh)
			var hb := HBoxContainer.new()
			hb.position = Vector2(lw + 8, 3); hb.size = Vector2(w - lw - 12, _rh - 6)
			pnl.add_child(hb)
			var a := _btn(hb, "◀", func(): _cycle(i, -1)); a.custom_minimum_size = Vector2(36, _rh - 6)
			var v := _lbl(hb, _choice_text(r), _fs)
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.clip_text = true
			var b := _btn(hb, "▶", func(): _cycle(i, 1)); b.custom_minimum_size = Vector2(36, _rh - 6)
		"chips":
			var l := _lbl(pnl, r.label, _fs - 1, GOLD)
			l.position = Vector2(8, 0); l.size = Vector2(w - 16, 20)
			var per := maxi(1, int(w / 118.0))
			var cw := (w - 8.0 - 4.0 * (per - 1)) / per
			var cur = r.get.call()
			for k in r.opts.size():
				var o: Array = r.opts[k]
				var b := _btn(pnl, o[0], func(): r.set.call(o[1]); _after(i))
				b.position = Vector2(4 + (k % per) * (cw + 4), 22 + (k / per) * (_rh * 0.85 + 4))
				b.size = Vector2(cw, _rh * 0.85)
				b.custom_minimum_size = b.size
				if str(cur) == str(o[1]): b.modulate = Color(1.3, 1.1, 0.7)
		"color":
			var l := _lbl(pnl, r.label, _fs - 1, GOLD)
			l.position = Vector2(8, 0); l.size = Vector2(w - 16, 20)
			var cur := str(r.get.call())
			var per := maxi(1, int((w - 8.0) / 30.0))
			for k in r.pal.size():
				var hexs: String = r.pal[k]
				var sw := Button.new()
				sw.focus_mode = Control.FOCUS_NONE
				sw.mouse_filter = Control.MOUSE_FILTER_IGNORE
				sw.position = Vector2(4 + (k % per) * 30, 22 + (k / per) * 30)
				sw.size = Vector2(26, 26)
				var st := StyleBoxFlat.new()
				st.bg_color = Color.from_string(hexs, Color.GRAY) if hexs != "+" else Color(0.25, 0.2, 0.15)
				st.set_corner_radius_all(3)
				if hexs != "+" and Color.from_string(hexs, Color.GRAY).to_html(false) == Color.from_string(cur, Color.GRAY).to_html(false):
					st.set_border_width_all(3); st.border_color = INK
				for s in ["normal", "hover", "pressed"]: sw.add_theme_stylebox_override(s, st)
				if hexs == "+":
					sw.text = "…" if _expanded != r.id else "×"
					sw.add_theme_font_size_override("font_size", 14)
				pnl.add_child(sw)
				_zones.append([sw, func(_p): _pick_color(i, hexs), "tap"])
		"button":
			var b := _btn(pnl, r.label, func(): r.call.call(); _after(i))
			b.position = Vector2(2, 2); b.size = Vector2(w - 4, _rh - 4)
		"buttons", "view", "tabs":
			var n: int = r.items.size()
			var per := maxi(1, int(w / _min_w(r)))
			var cols := mini(per, n)
			var bw := (w - 4.0 * (cols - 1)) / cols
			var bh := _bh(r)
			for k in n:
				var it: Array = r.items[k]
				var b := _btn(pnl, it[0], func(): sub = k; it[1].call())
				b.position = Vector2((k % per) * (bw + 4), (k / per) * (bh + 4))
				b.size = Vector2(bw, bh)
				b.custom_minimum_size = b.size
				if _list.size.x < 420.0: b.add_theme_font_size_override("font_size", _fs - 2)
				if r.kind == "tabs" and it.size() > 2 and it[2] == tab:
					b.modulate = Color(1.35, 1.1, 0.6)
				r.ui = r.get("ui", []) + [b]

## A row of buttons: narrower buttons (and shorter rows) on a phone, so the tab and view rows
## don't take the panel.
func _min_w(r: Dictionary) -> float:
	var phone := _list.size.x < 420.0
	match str(r.kind):
		"tabs": return 58.0 if phone else 82.0
		"view": return 44.0 if phone else 82.0
	return 82.0

func _bh(r: Dictionary) -> float:
	return _rh * (0.8 if (_list.size.x < 420.0 and str(r.kind) in ["tabs", "view"]) else 1.0)

func _lbl(parent: Control, t: String, fs: int, col := INK) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _paint_sel() -> void:
	for i in _row_ctl.size():
		var pnl: Panel = _row_ctl[i]
		if not is_instance_valid(pnl): continue
		var r: Dictionary = _rows[i]
		if r.kind in ["header", "note"]: continue
		var sb: StyleBoxFlat = pnl.get_theme_stylebox("panel")
		sb.bg_color = ROW_SEL if i == sel else ROW
		if r.has("ui") and r.kind in ["buttons", "view", "tabs"]:
			for k in r.ui.size():
				var b: Button = r.ui[k]
				if r.kind == "tabs" and r.items[k].size() > 2 and r.items[k][2] == tab:
					b.modulate = Color(1.35, 1.1, 0.6)
				else:
					b.modulate = Color(1.3, 1.2, 0.95) if (i == sel and k == sub) else Color(1, 1, 1)

func _see_sel() -> void:
	if sel >= _row_ctl.size(): return
	var pnl: Panel = _row_ctl[sel]
	var top := pnl.position.y + _scroll
	if top < _scroll: _scroll = top
	elif top + pnl.size.y > _scroll + _list.size.y: _scroll = top + pnl.size.y - _list.size.y
	_scroll = clampf(_scroll, 0.0, _scroll_max)
	_place_rows()

func _place_rows() -> void:
	var y := 0.0
	for pnl in _row_ctl:
		if not is_instance_valid(pnl): continue
		pnl.position.y = y - _scroll
		y += pnl.size.y + 4.0

## Rebuild after a change, keeping the selection and scroll.
func _after(_i := -1) -> void:
	_build_rows()
	if _msg_lbl and _msg_t <= 0.0: _msg_lbl.text = _status()

func _say(t: String) -> void:
	msg = t
	_msg_t = 4.0
	if _msg_lbl: _msg_lbl.text = t

# ------------------------------------------------------------------ what each tab holds
func _rows_for_tab() -> Array:
	var rows: Array = []
	var ti := []
	for t in tabs: ti.append([t.to_upper(), func(): _go_tab(t), t])
	rows.append({"kind": "tabs", "items": ti})
	var view := [["⟲", func(): _turn(-1)], ["⟳", func(): _turn(1)], ["Front", func(): _face(0.0)],
		["Side", func(): _face(PI * 0.5)], ["Back", func(): _face(PI)], ["−", func(): _zoom(-0.4)],
		["+", func(): _zoom(0.4)], ["Spin" if not spin else "Stop", func(): spin = not spin; _after()],
		["Dark" if not dark else "White", func(): dark = not dark; _backdrop(); _after()],
		["A-pose" if not a_pose else "Idle", func(): a_pose = not a_pose; _pose(); _after()]]
	if mode == "owner" and target != null:
		view.append(["In place" if not in_place else "Turntable", _toggle_place])
	rows.append({"kind": "view", "items": view})
	var sex: String = preset.body
	match tab:
		"body":
			if mode == "owner" or advanced:
				rows.append({"kind": "choice", "label": "Body", "opts": [["Female", "female"], ["Male", "male"]],
					"get": func(): return preset.body, "set": _set_sex})
			var pres: Dictionary = CharBody.cman().presets.get(sex, {})
			var po := []
			for k in pres: po.append([k, k])
			rows.append({"kind": "chips", "label": "Shape presets", "opts": po,
				"get": func(): return preset.get("shape_from", ""), "set": _apply_shape})
			for g in GROUPS:
				var any := false
				for sl in CharBody.cman().sliders:
					if not ((g[1] as Array).has(str(sl.group))): continue
					if sl.has("sex") and str(sl.sex) != sex: continue
					if mode == "player" and not advanced and not SIMPLE_KEYS.has(str(sl.name)): continue
					if not any:
						rows.append({"kind": "header", "label": str(g[0]).to_upper()}); any = true
					rows.append(_key_row(sl))
			if mode == "player" and not advanced:
				rows.append({"kind": "note", "label": "Advanced: on (the button below) shows every slider, the body choice and the base layer."})
		"skin":
			var tones := []
			for t in CharBody.cman().skin_tones: tones.append(str(t[1]))
			tones.append("+")
			rows.append(_color_row("skin", "Skin tone", tones, func(): return preset.skin, func(v): preset.skin = v))
			rows.append(_sub_sliders("skin", func(): return preset.skin, func(v): preset.skin = v))
			var iris := []
			for t in CharBody.cman().iris_colors: iris.append(str(t[1]))
			iris.append("+")
			rows.append(_color_row("iris", "Eyes", iris, func(): return preset.iris, func(v): preset.iris = v))
			rows.append(_sub_sliders("iris", func(): return preset.iris, func(v): preset.iris = v))
			for sl in CharBody.cman().sliders:
				if str(sl.name) == "age":
					rows.append({"kind": "note", "label": "Age also deepens the skin's wrinkles (the age slider, BODY)."})
					rows.append(_key_row(sl))
		"base":
			rows.append({"kind": "note", "label": "The base layer is always worn and can't be removed, only swapped." +
				(" A female body always has a base top and a base bottom." if sex == "female" else " A male body always has a base bottom; the base top is optional.")})
			for bs in P.BASE_SLOTS:
				rows.append_array(_piece_rows(str(bs.slot), str(bs.label)))
		"hair":
			rows.append_array(_piece_rows("hair", "Hair style"))
			var hc := []
			for t in CharBody.cman().hair_colors: hc.append(str(t[1]))
			hc.append("+")
			rows.append(_color_row("hairc", "Hair colour", hc, func(): return preset.hair.color, func(v): preset.hair.color = v))
			rows.append(_sub_sliders("hairc", func(): return preset.hair.color, func(v): preset.hair.color = v))
		"outfit":
			rows.append({"kind": "buttons", "items": [["Strip to base", _strip], ["Dress as opened", func(): _restore_outfit()]]})
			for s in P.SLOTS:
				rows.append_array(_piece_rows(str(s.slot), str(s.label)))
		"name":
			rows.append({"kind": "note", "label": "File: data/characters/%s.json  (Save keeps it in this browser; Download gives the file to commit)" % str(preset.id)})
			rows.append({"kind": "button", "label": "Name: " + (str(preset.name) if str(preset.name) != "" else "(none)") + "   ✎", "call": _type_name})
			var ids := P.list_ids()
			ids.erase(str(preset.id))
			if not ids.is_empty():
				copy_from = clampi(copy_from, 0, ids.size() - 1)
				var co := []
				for k in ids.size(): co.append([ids[k], k])
				rows.append({"kind": "choice", "label": "Copy from", "opts": co, "get": func(): return copy_from, "set": func(v): copy_from = int(v)})
				rows.append({"kind": "button", "label": "Copy that preset's look here (keeps this name and file)", "call": func(): _copy(ids[copy_from])})
			rows.append({"kind": "button", "label": "Forget this browser's edit (back to the repo file)", "call": _forget})
	return rows.filter(func(r): return not r.get("skip", false))

func _key_row(sl: Dictionary) -> Dictionary:
	var n := str(sl.name)
	return {"kind": "slider", "label": n.replace("_", " "), "min": float(sl.range[0]), "max": float(sl.range[1]),
		"step": 0.05, "get": _get_key.bind(n), "set": _set_key.bind(n)}

func _get_key(n: String) -> float:
	return float(preset.keys.get(n, 0.0))

func _set_key(v: float, n: String) -> void:
	if absf(v) < 0.001: preset.keys.erase(n)
	else: preset.keys[n] = snappedf(v, 0.01)
	preset.erase("shape_from")
	_changed("keys")

## A piece slot: the choice of pieces (none where allowed), then each colour region of the worn one.
func _piece_rows(slot: String, label: String) -> Array:
	var rows := []
	var sex: String = preset.body
	var opts := []
	var required := slot in CharBody.base_required(sex)
	if not required: opts.append(["none", ""])
	for e in P.options(sex, slot): opts.append([str(e.label), str(e.base_id)])
	if opts.is_empty(): return rows
	rows.append({"kind": "choice", "label": label, "opts": opts, "get": func(): return _slot_get(slot), "set": func(v): _slot_set(slot, str(v))})
	var cur := _slot_get(slot)
	if cur == "" or slot == "hair": return rows
	var e := P._entry(sex, cur)
	var mats: Dictionary = e.get("materials", {})
	for reg in mats:
		var dflt := str(mats[reg].get("default", ""))
		var pal: Array = (UNDER if slot.begins_with("base_") else CLOTH).duplicate()
		if dflt != "" and not pal.has(dflt): pal.insert(0, dflt)
		pal.append("+")
		var key := cur + ":" + str(reg)
		var lbl := "  %s · %s" % [str(e.label), str(mats[reg].get("label", reg))]
		var g := func(): return str(preset.outfit.colors.get(cur, {}).get(reg, dflt))
		var s := func(v):
			if not preset.outfit.colors.has(cur): preset.outfit.colors[cur] = {}
			preset.outfit.colors[cur][reg] = v
		rows.append(_color_row(key, lbl, pal, g, s))
		rows.append(_sub_sliders(key, g, s))
	if e.get("patterns", false):
		var po := []
		for pn in P.pattern_names(): po.append([pn, pn])
		rows.append({"kind": "choice", "label": "  pattern", "opts": po,
			"get": func(): return str(preset.outfit.patterns.get(cur, "solid")),
			"set": func(v): preset.outfit.patterns[cur] = str(v); _changed("paint")})
	return rows

func _color_row(id: String, label: String, pal: Array, g: Callable, s: Callable) -> Dictionary:
	return {"kind": "color", "id": id, "label": label, "pal": pal, "get": g, "set": func(v): s.call(v); _changed("paint")}

## Fine colour sliders (hue, saturation, value) under a colour row, shown when its "…" is open.
func _sub_sliders(id: String, g: Callable, s: Callable) -> Dictionary:
	if _expanded != id:
		return {"kind": "header", "label": "", "skip": true, "h": 0}
	return {"kind": "buttons", "items": [
		["hue −", func(): _hsv(g, s, -0.03, 0, 0)], ["hue +", func(): _hsv(g, s, 0.03, 0, 0)],
		["sat −", func(): _hsv(g, s, 0, -0.06, 0)], ["sat +", func(): _hsv(g, s, 0, 0.06, 0)],
		["dark", func(): _hsv(g, s, 0, 0, -0.05)], ["light", func(): _hsv(g, s, 0, 0, 0.05)]]}

func _hsv(g: Callable, s: Callable, dh: float, ds: float, dv: float) -> void:
	var c := Color.from_string(str(g.call()), Color.GRAY)
	c = Color.from_hsv(wrapf(c.h + dh, 0.0, 1.0), clampf(c.s + ds, 0.0, 1.0), clampf(c.v + dv, 0.02, 1.0))
	s.call("#" + c.to_html(false))
	_changed("paint")
	_after()

func _slot_get(slot: String) -> String:
	if slot == "hair": return str(preset.hair.id)
	if slot in ["hat", "glasses", "watch"]:
		for id in preset.outfit.extras:
			var e := P._entry(str(preset.body), str(id))
			if not e.is_empty() and str(e.slot) == slot: return str(id)
		return ""
	return str(preset.outfit.get(slot, ""))

func _slot_set(slot: String, id: String) -> void:
	if slot == "hair":
		preset.hair.id = id
	elif slot in ["hat", "glasses", "watch"]:
		var ex: Array = []
		for x in preset.outfit.extras:
			var e := P._entry(str(preset.body), str(x))
			if e.is_empty() or str(e.slot) != slot: ex.append(x)
		if id != "": ex.append(id)
		preset.outfit.extras = ex
	else:
		var full_base := id != "" and str(P._entry(str(preset.body), id).get("slot", "")) == "base_full"
		if slot.begins_with("base_") and not full_base:
			# leaving the one-piece: the other base slot falls back to its default (the base rule)
			for o in ["base_top", "base_bottom"]:
				if o != slot and P._is_full_base(str(preset.body), str(preset.outfit[o])): preset.outfit[o] = ""
		if slot == "full" and id != "":
			preset.outfit.top = ""; preset.outfit.bottom = ""; preset.outfit.under = ""
		elif slot in ["top", "bottom", "under"] and id != "":
			preset.outfit.full = ""
		for o in ["under", "top", "outer"]:
			if o != slot and id != "" and str(preset.outfit.get(o, "")) == id: preset.outfit[o] = ""
		preset.outfit[slot] = id
	preset = P.normalize(preset)    # the base rule, every time
	_changed("dress")

func _choice_text(r: Dictionary) -> String:
	var cur = r.get.call()
	for o in r.opts:
		if str(o[1]) == str(cur): return str(o[0])
	return str(cur)

# ------------------------------------------------------------------ edits
func _go_tab(t: String) -> void:
	if (t == "base") != (tab == "base"):
		_need = "dress"
	tab = t
	_scroll = 0.0
	sel = 0
	_expanded = ""
	sub = tabs.find(t)
	_build_rows()

func _turn(d: int) -> void:
	yaw = wrapf(yaw + d * PI / 8.0, -PI, PI)
	_hold_spin()

func _face(a: float) -> void:
	yaw = a
	spin = false
	_after()

func _zoom(d: float) -> void:
	zoom = clampf(zoom + d, 1.0, 3.2)

func _set_sex(v) -> void:
	if str(v) == str(preset.body): return
	var q := P.blank(str(v))
	q.id = preset.id; q.name = preset.name
	q.skin = preset.skin; q.iris = preset.iris
	q.hair.color = preset.hair.color
	if P.slot_offers(str(v), "hair", str(preset.hair.id)): q.hair.id = preset.hair.id
	for k in preset.keys:
		q.keys[k] = preset.keys[k]
	preset = P.normalize(q)
	_changed("dress")

func _apply_shape(name_: String) -> void:
	var pres: Dictionary = CharBody.cman().presets.get(str(preset.body), {}).get(name_, {})
	# a shape preset sets the body (overall / torso / limbs); head and face keys stay
	var keep := {}
	for sl in CharBody.cman().sliders:
		if str(sl.group) in ["head", "face"] and preset.keys.has(sl.name): keep[sl.name] = preset.keys[sl.name]
		if str(sl.name) in ["age", "youth", "youth_small", "posture"] and preset.keys.has(sl.name): keep[sl.name] = preset.keys[sl.name]
	var k := keep.duplicate()
	for n in pres: k[n] = pres[n]
	preset.keys = k
	preset = P.normalize(preset)
	preset.shape_from = name_
	_changed("keys")
	_say("Shape: " + name_)

func _strip() -> void:
	preset = P.stripped(preset)
	_changed("dress")
	_say("Stripped to the base layer")

func _restore_outfit() -> void:
	preset.outfit = loaded.outfit.duplicate(true)
	preset.hair = loaded.hair.duplicate(true)
	preset = P.normalize(preset)
	_changed("dress")

func _pick_color(i: int, hexs: String) -> void:
	var r: Dictionary = _rows[i]
	sel = i
	if hexs == "+":
		_expanded = "" if _expanded == str(r.id) else str(r.id)
	else:
		r.set.call(hexs)
	_after()

func _cycle(i: int, d: int) -> void:
	var r: Dictionary = _rows[i]
	sel = i
	var cur = r.get.call()
	var k := 0
	for j in r.opts.size():
		if str(r.opts[j][1]) == str(cur): k = j
	k = posmod(k + d, r.opts.size())
	r.set.call(r.opts[k][1])
	_after()

func _slide_to(i: int, p: Vector2) -> void:
	var r: Dictionary = _rows[i]
	if not r.has("ui"): return
	var bar: Control = r.ui[0]
	var t := clampf((p.x - bar.get_global_rect().position.x) / maxf(bar.size.x, 1.0), 0.0, 1.0)
	var v := lerpf(float(r.min), float(r.max), t)
	if absf(v) < (float(r.max) - float(r.min)) * 0.02: v = 0.0     # a little snap at neutral
	r.set.call(v)
	sel = i
	_slider_paint(r)
	_paint_sel()

func _nudge(i: int, d: int) -> void:
	var r: Dictionary = _rows[i]
	var v := clampf(float(r.get.call()) + d * float(r.step), float(r.min), float(r.max))
	r.set.call(v)
	_slider_paint(r)

func _slider_paint(r: Dictionary) -> void:
	if not r.has("ui"): return
	var bar: Control = r.ui[0]
	var fill: ColorRect = r.ui[1]
	var knob: ColorRect = r.ui[2]
	var vl: Label = r.ui[3]
	var v := float(r.get.call())
	var t := inverse_lerp(float(r.min), float(r.max), v)
	var z := inverse_lerp(float(r.min), float(r.max), 0.0) if float(r.min) < 0.0 else 0.0
	var a := minf(t, z); var b := maxf(t, z)
	fill.position = Vector2(a * bar.size.x, 0); fill.size = Vector2((b - a) * bar.size.x, bar.size.y)
	knob.position = Vector2(t * bar.size.x - 3, -4); knob.size = Vector2(6, bar.size.y + 8)
	vl.text = "%+.2f" % v if float(r.min) < 0.0 else "%.2f" % v

func _toggle_adv() -> void:
	advanced = not advanced
	_tabs()
	_layout()

func _toggle_place() -> void:
	in_place = not in_place
	if in_place and target and target.has_method("wear_preset"):
		target.wear_preset(preset, true)      # the NPC itself, live (unbaked) while editing
	elif not in_place and target and target.has_method("wear_preset"):
		target.wear_preset(loaded if not dirty else preset, true)
	_layout()

func _in_place_cam(on: bool) -> void:
	if on:
		if place_cam == null:
			_game_cam = target.get_viewport().get_camera_3d()
			# the side the player is on (the shop floor), flat
			var pl := target.get_tree().get_first_node_in_group("mall_player") as Node3D
			var b: Node3D = target.body
			var d := (pl.global_position - b.global_position) if pl else Vector3.BACK
			d.y = 0.0
			_place_dir = d.normalized() if d.length() > 0.05 else Vector3.BACK
			_place_yaw0 = yaw
			place_cam = Camera3D.new()
			place_cam.fov = 40
			place_cam.near = 0.05
			target.get_parent().add_child(place_cam)
		place_cam.current = true
		_frame_cam()
	elif place_cam:
		_drop_place_cam()

var _game_cam: Camera3D = null
var _place_dir := Vector3.BACK
var _place_yaw0 := 0.0
var _phone_place := false

func _drop_place_cam() -> void:
	if place_cam and is_instance_valid(place_cam):
		place_cam.queue_free()
	place_cam = null
	if _game_cam and is_instance_valid(_game_cam):
		_game_cam.current = true

func _type_name() -> void:
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(function(){var v=prompt('Name (PLACEHOLDER until Steven names them)', %s);return v===null?'\\u0000':v})()" % JSON.stringify(str(preset.name)))
		if v != null and str(v) != "\u0000":
			preset.name = str(v).strip_edges().left(40)
			dirty = true
			_after()
		return
	_say("Type the name, Enter to end")
	set_meta("typing", true)

func _copy(id: String) -> void:
	var src := P.get_preset(id)
	if src.is_empty(): return
	var keep_id: String = preset.id
	var keep_name: String = preset.name
	preset = src.duplicate(true)
	preset.id = keep_id
	preset.name = keep_name
	preset = P.normalize(preset)
	_changed("dress")
	_say("Copied the look of " + id)

func _forget() -> void:
	P.forget_local(str(preset.id))
	preset = P.load_repo(str(preset.id))
	loaded = preset.duplicate(true)
	dirty = false
	_changed("dress")
	dirty = false
	if target and target.has_method("wear_preset"): target.wear_preset(preset, in_place)
	_say("Back to data/characters/%s.json" % str(preset.id))
	_after()

func _reset() -> void:
	preset = loaded.duplicate(true)
	_changed("dress")
	dirty = false
	_say("Reset to how it was opened")
	_after()

# ------------------------------------------------------------------ save / close
func _save() -> void:
	if mode == "player":
		P.save_player(preset)
	else:
		P.save_local(str(preset.id), preset)
		if target and target.has_method("wear_preset"):
			target.wear_preset(preset, in_place)
	loaded = preset.duplicate(true)
	dirty = false
	_say("Saved in this browser. Download gives the file to commit.")

func _download() -> void:
	var where := P.download(str(preset.id), preset)
	_say("Downloaded " + where + "  → commit it as data/characters/%s.json" % str(preset.id))

func _close() -> void:
	if dirty and not _confirm_close:
		_confirm_close = true
		_say("Unsaved changes: Close again to drop them, or Save.")
		return
	if mode == "owner" and target and target.has_method("wear_preset"):
		target.wear_preset(P.get_preset(str(preset.id)), false)    # back to the saved look, baked
	_finish("cancel")

## The player's Done (and the menu closing): save the preset as the player's, hand the look back.
func _done() -> void:
	if mode == "owner":
		_save(); _close(); return
	P.save_player(preset)
	look["preset"] = true
	look["done"] = true
	_finish("done")

func _skip() -> void:
	_finish("skip" if mode == "player" else "cancel")

func _finish(how: String) -> void:
	_drop_place_cam()
	closed.emit(look, how)
	if not embedded:
		queue_free()

# ------------------------------------------------------------------ input
## The menu hands events here (embedded); standalone, our own catcher does.
func feed(e: InputEvent) -> void:
	handle(e)

func handle(e: InputEvent) -> void:
	if root == null: return
	if has_meta("typing") and e is InputEventKey:
		if e.pressed: _type_key(e)
		return
	if e is InputEventKey and e.pressed:
		_key(e.keycode, e.echo)
	elif e is InputEventJoypadButton and e.pressed:
		_pad(e.button_index)
	elif e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP or e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if e.pressed: _wheel(e.position, -1 if e.button_index == MOUSE_BUTTON_WHEEL_UP else 1)
		elif e.button_index == MOUSE_BUTTON_LEFT:
			if e.pressed: _press(-1, e.position)
			else: _release(-1, e.position)
	elif e is InputEventMouseMotion:
		if _drag.has(-1): _move(-1, e.position)
	elif e is InputEventScreenTouch:
		if e.pressed: _press(e.index, e.position)
		else: _release(e.index, e.position)
	elif e is InputEventScreenDrag:
		_move(e.index, e.position)
	elif e is InputEventMagnifyGesture:
		_zoom((e.factor - 1.0) * 2.0)

func _key(k: int, echo: bool) -> void:
	match k:
		KEY_ESCAPE:
			if embedded: return
			_close()
		KEY_UP, KEY_W: _sel_move(-1)
		KEY_DOWN, KEY_S: _sel_move(1)
		KEY_LEFT, KEY_A: _side(-1)
		KEY_RIGHT, KEY_D: _side(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: if not echo: _enter()
		KEY_BRACKETLEFT, KEY_PAGEUP: if not echo: _tab_step(-1)
		KEY_BRACKETRIGHT, KEY_PAGEDOWN: if not echo: _tab_step(1)
		KEY_Q: if not echo and not embedded: _tab_step(-1)
		KEY_E: if not echo and not embedded: _tab_step(1)
		KEY_COMMA: _turn(-1)
		KEY_PERIOD: _turn(1)
		KEY_MINUS, KEY_KP_SUBTRACT: _zoom(-0.3)
		KEY_EQUAL, KEY_KP_ADD: _zoom(0.3)

func _pad(b: int) -> void:
	match b:
		JOY_BUTTON_B: if not embedded: _close()
		JOY_BUTTON_DPAD_UP: _sel_move(-1)
		JOY_BUTTON_DPAD_DOWN: _sel_move(1)
		JOY_BUTTON_DPAD_LEFT: _side(-1)
		JOY_BUTTON_DPAD_RIGHT: _side(1)
		JOY_BUTTON_A: _enter()
		JOY_BUTTON_LEFT_SHOULDER: if not embedded: _tab_step(-1)
		JOY_BUTTON_RIGHT_SHOULDER: if not embedded: _tab_step(1)
		JOY_BUTTON_X: _tab_step(-1)
		JOY_BUTTON_Y: _tab_step(1)

func _tab_step(d: int) -> void:
	_go_tab(tabs[posmod(tabs.find(tab) + d, tabs.size())])

func _sel_move(d: int) -> void:
	var n := _rows.size()
	var i := sel
	for _k in n:
		i = clampi(i + d, 0, n - 1)
		if not (_rows[i].kind in ["header", "note"]): break
	if _rows[i].kind in ["header", "note"]: return
	if i != sel:
		sel = i
		sub = tabs.find(tab) if _rows[i].kind == "tabs" else 0
	_paint_sel()
	_see_sel()

func _side(d: int) -> void:
	if sel >= _rows.size(): return
	var r: Dictionary = _rows[sel]
	match r.kind:
		"tabs": _tab_step(d)
		"view":
			if sub <= 1: _turn(d)
			else:
				sub = clampi(sub + d, 0, r.items.size() - 1); _paint_sel()
		"buttons":
			sub = clampi(sub + d, 0, r.items.size() - 1); _paint_sel()
		"slider": _nudge(sel, d)
		"choice": _cycle(sel, d)
		"chips":
			var cur = r.get.call()
			var k := -1
			for j in r.opts.size():
				if str(r.opts[j][1]) == str(cur): k = j
			k = posmod(k + d, r.opts.size())
			r.set.call(r.opts[k][1]); _after()
		"color":
			var cur := Color.from_string(str(r.get.call()), Color.GRAY).to_html(false)
			var k := -1
			var pal: Array = r.pal.filter(func(x): return x != "+")
			for j in pal.size():
				if Color.from_string(pal[j], Color.GRAY).to_html(false) == cur: k = j
			k = posmod(k + d, pal.size())
			r.set.call(pal[k]); _after()

func _enter() -> void:
	if sel >= _rows.size(): return
	var r: Dictionary = _rows[sel]
	match r.kind:
		"tabs": pass
		"view", "buttons":
			var it: Array = r.items[clampi(sub, 0, r.items.size() - 1)]
			it[1].call()
		"button": r.call.call(); _after()
		"choice": _cycle(sel, 1)
		"color":
			_expanded = "" if _expanded == str(r.id) else str(r.id); _after()
		"slider":
			r.set.call(0.0); _slider_paint(r)

func _zone_at(p: Vector2) -> Array:
	for i in range(_zones.size() - 1, -1, -1):
		var z: Array = _zones[i]
		var c: Control = z[0]
		if not is_instance_valid(c) or not c.is_visible_in_tree(): continue
		if _list.is_ancestor_of(c) and not _list.get_global_rect().has_point(p): continue
		if c.get_global_rect().has_point(p): return z
	return []

func _press(idx: int, p: Vector2) -> void:
	var z := _zone_at(p)
	var kind: String = z[2] if not z.is_empty() else ""
	_drag[idx] = {"at": p, "start": p, "kind": kind, "zone": z, "scroll": _scroll, "moved": false, "yaw": yaw}
	if kind == "slide":
		(z[1] as Callable).call(p)
	if _drag.size() == 2:
		var ks := _drag.keys()
		_pinch = (_drag[ks[0]].at as Vector2).distance_to(_drag[ks[1]].at)

func _move(idx: int, p: Vector2) -> void:
	if not _drag.has(idx): return
	var d: Dictionary = _drag[idx]
	var prev: Vector2 = d.at
	d.at = p
	if (p - d.start).length() > 10.0: d.moved = true
	if _drag.size() == 2:
		var ks := _drag.keys()
		var nd := (_drag[ks[0]].at as Vector2).distance_to(_drag[ks[1]].at)
		if _pinch > 0.0: _zoom((nd - _pinch) / 120.0)
		_pinch = nd
		return
	match d.kind:
		"slide": (d.zone[1] as Callable).call(p)
		"pv":
			yaw = wrapf(yaw - (p.x - prev.x) * 0.012, -PI, PI); _hold_spin()
		"list", "tap":
			if d.moved and _list.get_global_rect().has_point(d.start):
				_scroll = clampf(float(d.scroll) - (p.y - d.start.y), 0.0, _scroll_max)
				_place_rows()
				d.kind = "list"

func _release(idx: int, p: Vector2) -> void:
	if not _drag.has(idx): return
	var d: Dictionary = _drag[idx]
	_drag.erase(idx)
	if d.kind == "tap" and not d.moved:
		var z := _zone_at(p)
		if not z.is_empty() and z[0] == d.zone[0]:
			# the row under a tap becomes the selection
			for i in _row_ctl.size():
				if is_instance_valid(_row_ctl[i]) and (_row_ctl[i] as Control).is_ancestor_of(z[0]): sel = i
			(z[1] as Callable).call(p)

func _wheel(p: Vector2, d: int) -> void:
	if _list.get_global_rect().has_point(p):
		_scroll = clampf(_scroll + d * 48.0, 0.0, _scroll_max)
		_place_rows()
	else:
		_zoom(-d * 0.2)

func _type_key(e: InputEventKey) -> void:
	if e.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE, KEY_TAB]:
		remove_meta("typing"); _after(); return
	if e.keycode == KEY_BACKSPACE:
		preset.name = str(preset.name).left(-1)
	elif e.unicode >= 32:
		preset.name = (str(preset.name) + char(e.unicode)).left(40)
	dirty = true
	_after()
