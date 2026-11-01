## Workstream V (design/godot-avatar.md): the player's avatar in the mall, and the first / third
## person switch. Made by scripts/player.gd as its child "Avatar" (every wing, both years), after
## "Interact".
##
## - The look (scripts/avatar_look.gd) is read from localStorage "mall-avatar-1" at start. A visitor
##   who has never made one gets the creator (scripts/avatar_creator.tscn) when the game starts;
##   Skip gives the default body and first person. The "Avatar (C)" button, C, or a gamepad's Start
##   opens it again later. Not opened by itself when the address has ?cam= (tests and shared spots);
##   ?avatar=1 opens it whatever the saved state.
## - View: V, a gamepad's right-stick click, or the "View" button switches first / third person; the
##   choice is saved with the look. ?view=third / ?view=first sets it for one load (tests).
##   First person is the game exactly as before (player.gd's camera, speed, hand item).
##   Third person: the avatar (scripts/avatar_body.gd) stands where the player stands, turns to
##   the way it walks, walks / jogs / runs with the shoppers' clips played at the ground speed
##   (playback = speed / the clip's own m/s from npc/anims.json, so the feet don't slide), idles
##   when still. The camera rides a boom behind and over the right shoulder; the boom is tested
##   against the same walk grid and obstacle list the player walks on (walls, store glass, the
##   arcade's machines), pulled in at once when something is in the way, let out slowly; very close
##   in, the avatar is hidden so the view is never from inside its head. Walking in third person is
##   at a walking pace (TP_WALK m/s; running x2.2 as in first person) so the walk clip fits.
## - In VR (design/godot-vr.md) the view is always first person and the avatar is hidden.
## - A held item (B+C, scripts/interact.gd) is moved into the avatar's right hand in third person and
##   back to the first-person hand after; a swing turns it there too.
extends Node

const Look = preload("res://scripts/avatar_look.gd")
const AvatarBody = preload("res://scripts/avatar_body.gd")
const CREATOR := "res://scripts/avatar_creator.tscn"

const TP_WALK := 2.0          # m/s at full stick in third person (first person stays 4.0); a guess
const PIVOT_H := 1.5          # the boom's pivot, m above the floor (shoulder height)
const SHOULDER := 0.35        # the pivot's offset to the right, m
const BOOM := 2.4             # the boom's length when nothing is in the way, m
const CAM_R := 0.14           # the camera's clearance from walls and glass, m
const CAM_TOP := 2.7          # highest camera, m (store ceilings are ~3.2 m: build_mall OPEN_H)
const CAM_LOW := 0.35         # lowest camera, m
const HIDE_UNDER := 0.75      # boom shorter than this: the avatar is hidden
const PITCH_MIN := -1.05      # third person looks at most this far down / up (rad)
const PITCH_MAX := 0.5
## gaits: clip, the speed (m/s) from which it is used
const GAITS := [["walk", 0.0], ["jog", 2.4], ["run", 3.6], ["sprint", 5.4]]

var player: Node3D
var look := {}
var body: AvatarBody
var tp_cam: Camera3D
var third := false            # the saved choice
var creator: Node = null
var _froze := false           # the creator froze the player
var _boom := BOOM
var _last := Vector3.INF
var _speed := 0.0
var _gait := "walk"
var _hand_xf := {}            # the hand item's first-person local transform, by instance id
var _tp_active := false
var _tint := Color(1, 1, 1)
# ui
var view_btn: Button
var make_btn: Button

func _ready() -> void:
	player.add_to_group("mall_player")
	look = Look.load_look()
	third = look.view == "third"
	var force_open := false
	var cam_q := false
	if OS.has_feature("web"):
		var vq := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('view') || ''"))
		if vq == "third" or vq == "first": third = vq == "third"
		force_open = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('avatar') || ''")) == "1"
		cam_q = str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('cam') || ''")) != ""
	else:
		if Engine.has_meta("avatar_view"): third = str(Engine.get_meta("avatar_view")) == "third"
		force_open = bool(Engine.get_meta("avatar_open", false))
		cam_q = true
	body = AvatarBody.new()
	body.name = "Avatar"
	player.get_parent().add_child.call_deferred(body)
	body.ready.connect(func():
		body.wear(look, player.year)
		body.visible = false, CONNECT_ONE_SHOT)
	tp_cam = Camera3D.new()
	tp_cam.name = "ThirdPersonCam"
	tp_cam.fov = player.cam.fov
	tp_cam.near = 0.05
	tp_cam.far = player.cam.far
	player.get_parent().add_child.call_deferred(tp_cam)
	_build_ui()
	if force_open or (not look.done and not cam_q):
		open_creator.call_deferred()

# ------------------------------------------------------------------ the view
func toggle_view() -> void:
	if player.vr_on or creator != null:
		return
	third = not third
	look.view = "third" if third else "first"
	Look.save_look(look)
	_say("Third person" if third else "First person")

func _process(dt: float) -> void:
	if body == null or not body.is_inside_tree() or tp_cam == null or not tp_cam.is_inside_tree():
		return
	var tp: bool = third and not player.vr_on and creator == null
	var hide: bool = player.frozen or player.leaving
	# walking speed: third person walks at a walking pace (the first person's 4 m/s is untouched)
	if "move_scale" in player:
		player.move_scale = (TP_WALK / player.SPEED) if tp else 1.0
	if tp != _tp_active:
		_tp_active = tp
		if not tp and not player.vr_on and not player.frozen:
			player.cam.current = true
		_last = Vector3.INF
	_ui_sync()
	_hand_sync(tp)
	if not tp:
		body.visible = false
		return
	_move_body(dt)
	_place_cam(dt)
	if body.mats.size() > 0 and _tint != NpcBody.tint:
		_tint = NpcBody.tint     # the shoppers' day colour (scripts/npcs.gd sets it after we dress)
		for m in body.mats: m.set_shader_parameter("tint", _tint)
	body.visible = not hide and _boom > HIDE_UNDER and not has_meta("qa_hide")   # qa_hide: tools/qa/avatar_test.gd fps
	if not player.frozen and not tp_cam.current:
		tp_cam.current = true

func _move_body(dt: float) -> void:
	var p: Vector3 = player.position
	if _last == Vector3.INF or dt <= 0.0:
		_last = p
		body.position = p
		body.face(-player.transform.basis.z)
		return
	var v := (p - _last) / dt
	v.y = 0.0
	_last = p
	if v.length() > 15.0:          # a jump, a seam, the Stockrooms' copies: not walking
		v = Vector3.ZERO
	_speed = lerpf(_speed, v.length(), clampf(dt * 10.0, 0.0, 1.0))
	body.position = p
	if _speed > 0.15:
		body.face(v, 10.0, dt)
		var g := _pick_gait(_speed)
		var clip := g
		if g == "walk":
			clip = "walk_f" if str(body.info.get("sex", "m")) == "f" else "walk_m"
		body.walk_clip = clip
		body.set_speed(_speed)
		if body.ap and body.clip == clip:
			var own := float(NpcBody.meta().clips.get(clip, {}).get("mps", 1.6))
			body.ap.speed_scale = clampf(_speed / own, 0.3, 2.0)
	else:
		_speed = 0.0 if _speed < 0.05 else _speed
		body.set_speed(0.0)

## The gait for a ground speed, with a little hysteresis so it doesn't flicker at a boundary.
func _pick_gait(s: float) -> String:
	var cur := 0
	for i in GAITS.size():
		if GAITS[i][0] == _gait: cur = i
	var best := 0
	for i in GAITS.size():
		if s >= float(GAITS[i][1]): best = i
	if best < cur and s > float(GAITS[cur][1]) - 0.25:
		best = cur
	if not NpcBody.has_clip(str(GAITS[best][0])) and best > 0:
		best = 0
	_gait = str(GAITS[best][0])
	return _gait

## The camera on its boom, behind and over the right shoulder, kept out of walls and glass. Where
## the boom is cut short (an arcade aisle, a small store), the camera rises and looks down over the
## machines and counters instead (the "high" boom: box-shaped obstacles are lower than CAM_TOP;
## walls, columns and glass still stop it), blended in and out.
func _place_cam(dt: float) -> void:
	var yaw: float = player.yaw
	var by := Basis(Vector3.UP, yaw)
	var base: Vector3 = player.position + Vector3(0, PIVOT_H, 0)
	var side := by * Vector3(SHOULDER, 0, 0)
	var pivot := base + side * _clear(base, base + side, false)
	var pitch := clampf(player.pitch, PITCH_MIN, PITCH_MAX)
	var low := _boom_len(pivot, by * Basis(Vector3.RIGHT, pitch), false)
	var hp := minf(pitch, HIGH_PITCH)
	var high := _boom_len(pivot, by * Basis(Vector3.RIGHT, hp), true)
	var want_high := 1.0 if (low < HIGH_UNDER and high > low + 0.3) else 0.0
	_high = move_toward(_high, want_high, dt * 2.5)
	var p := lerpf(pitch, hp, _high)
	var b := by * Basis(Vector3.RIGHT, p)
	var want := _boom_len(pivot, b, _high > 0.5)
	_boom = want if want < _boom else lerpf(_boom, want, clampf(dt * 3.0, 0.0, 1.0))
	tp_cam.global_transform = Transform3D(b, pivot + b * Vector3(0, 0, 1) * _boom)

const HIGH_UNDER := 1.5       # a normal boom shorter than this: try the high one
const HIGH_PITCH := -0.8      # the high boom looks down at least this much (rad)
var _high := 0.0

## How long the boom can be along basis b's +Z from the pivot: walls, glass, ceiling and floor.
func _boom_len(pivot: Vector3, b: Basis, high: bool) -> float:
	var back := b * Vector3(0, 0, 1)
	var want := BOOM * _clear(pivot, pivot + back * BOOM, high)
	if back.y > 0.01: want = minf(want, (CAM_TOP - pivot.y) / back.y)
	if back.y < -0.01: want = minf(want, (CAM_LOW - pivot.y) / back.y)
	return maxf(want, 0.0)

## How far (0..1) along from -> to the camera can go before it meets a wall, glass or a machine
## (high: machines and counters, the box-shaped obstacles, don't count).
func _clear(from: Vector3, to: Vector3, high: bool) -> float:
	var n := int(ceil(from.distance_to(to) / 0.06))
	if n <= 0:
		return 1.0
	if not _free(from.x, from.z, high):
		return 0.0
	for i in range(1, n + 1):
		var t := float(i) / n
		var q := from.lerp(to, t)
		if not _free(q.x, q.z, high):
			return maxf(0.0, float(i - 1) / n - 0.02)
	return 1.0

func _free(x: float, z: float, high := false) -> bool:
	var r := CAM_R
	if not (player._walk(x - r, z - r) and player._walk(x + r, z - r) and player._walk(x - r, z + r) and player._walk(x + r, z + r)):
		return false
	if _hits(player.obstacles, x, z, high):
		return false
	if player.fixtures_on and _hits(player.fx_obstacles, x, z, high):
		return false
	return true

const BOX_MIN := 0.55         # a rect at least this deep both ways is a box (a machine, a counter)

func _hits(list: Array, x: float, z: float, high := false) -> bool:
	for o in list:
		if o.size() == 3 and not (o[0] is String):
			if Vector2(x - o[0], z - o[1]).length() < float(o[2]) + CAM_R:
				return true
		elif o.size() >= 5 and o[0] == "rect":
			if high and minf(o[3] - o[1], o[4] - o[2]) >= BOX_MIN:
				continue
			if x > o[1] - CAM_R and x < o[3] + CAM_R and z > o[2] - CAM_R and z < o[4] + CAM_R:
				return true
	return false

# ------------------------------------------------------------------ the held item
## Third person: the held item (scripts/interact.gd hand_item) goes into the avatar's right hand;
## first person: back under the camera's hand, as it was.
func _hand_sync(tp: bool) -> void:
	var it = player.interact
	if it == null or not ("hand_item" in it):
		return
	var item: Node3D = it.hand_item
	if item == null or not is_instance_valid(item):
		return
	var grip: Node3D = _grip()
	var want: Node3D = grip if (tp and grip != null) else it.hand_root
	if want == null:
		return
	if item.get_parent() != want:
		var key := item.get_instance_id()
		if not _hand_xf.has(key):
			_hand_xf[key] = item.transform
		item.reparent(want, false)
		item.transform = _hand_xf[key]
	if tp and grip != null:
		# the swing's turn (interact.gd tweens hand_root) turns the item in the avatar's hand too
		grip.rotation = GRIP_ROT + it.hand_root.rotation

## The item's frame in the right hand: the first-person hand's axes (-Z ahead, +Y up) turned onto
## the Mixamo hand bone (+Y along the fingers), so a stick points ahead out of the fist.
const GRIP_ROT := Vector3(deg_to_rad(-90), 0, deg_to_rad(180))
const GRIP_AT := Vector3(0.0, 0.08, 0.03)

func _grip() -> Node3D:
	if body == null or body.hand == null:
		return null
	var g := body.hand.get_node_or_null("Grip") as Node3D
	if g == null:
		g = Node3D.new()
		g.name = "Grip"
		g.position = GRIP_AT
		g.rotation = GRIP_ROT
		body.hand.add_child(g)
	return g

# ------------------------------------------------------------------ the creator
func open_creator() -> void:
	if creator != null or player.vr_on or player.leaving:
		return
	if player.frozen:
		return
	var ps: PackedScene = load(CREATOR)
	creator = ps.instantiate()
	creator.year = player.year
	creator.look = look.duplicate(true)
	creator.first_time = not look.done
	creator.closed.connect(_creator_closed)
	add_child(creator)
	player.frozen = true
	_froze = true
	player.move_vec = Vector2.ZERO
	player.move_touch = -1
	player.stick.visible = false

func _creator_closed(L: Dictionary, how: String) -> void:
	if how == "done" or how == "skip":
		look = L
		look.done = true
		if how == "done" and creator.first_time:
			third = true            # you just made it: see it
		look.view = "third" if third else "first"
		Look.save_look(look)
		body.wear(look, player.year)
	creator.queue_free()
	creator = null
	if _froze:
		player.frozen = false
		_froze = false

# ------------------------------------------------------------------ ui
func _build_ui() -> void:
	view_btn = _btn("View: 1st person (V)", toggle_view)
	make_btn = _btn("Avatar (C)", open_creator)

func _btn(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 14)
	b.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	b.offset_left = -200; b.offset_right = -10
	b.pressed.connect(cb)
	player._cl.add_child(b)
	return b

## Under the Bag button (interact.gd), or under the last visible top-right button.
func _ui_sync() -> void:
	var top := 8.0
	var it = player.interact
	var cands := [player.jump_open_btn, player.year_btn]
	if it and "bag_btn" in it: cands.append(it.bag_btn)
	for b in cands:
		if b and b.visible:
			top = maxf(top, b.offset_bottom + 8.0)
	var show: bool = not player.vr_on and creator == null and not (player.frozen and not _froze)
	view_btn.visible = show
	make_btn.visible = show
	view_btn.offset_top = top; view_btn.offset_bottom = top + 32
	make_btn.offset_top = top + 40; make_btn.offset_bottom = top + 72
	view_btn.text = "View: %s (V)" % ("3rd person" if third else "1st person")

func _input(e: InputEvent) -> void:
	if creator != null:
		return
	if player.frozen or player.leaving:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		if e.physical_keycode == KEY_V:
			toggle_view(); get_viewport().set_input_as_handled()
		elif e.physical_keycode == KEY_C:
			open_creator(); get_viewport().set_input_as_handled()
	elif e is InputEventJoypadButton and e.pressed:
		if e.button_index == JOY_BUTTON_RIGHT_STICK:
			toggle_view(); get_viewport().set_input_as_handled()
		elif e.button_index == JOY_BUTTON_START:
			open_creator(); get_viewport().set_input_as_handled()
	elif e is InputEventScreenTouch and e.pressed:
		# touches skip mouse emulation (project setting), so the buttons are tapped here
		for pair in [[view_btn, toggle_view], [make_btn, open_creator]]:
			var b: Button = pair[0]
			if b.is_visible_in_tree() and b.get_global_rect().has_point(e.position):
				get_viewport().set_input_as_handled()
				(pair[1] as Callable).call()
				return

func _say(t: String) -> void:
	if player.has_method("_say"):
		player._say(t)
