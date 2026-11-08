## The talk camera (workstream TALK, Nov 8 2026; design/godot-dialogue.md "The talk camera"): the shot,
## the lights and the NPC's look when the player talks to someone. One per wing, under the wing root
## ("TalkCamera"), shared by the conversation screen (scripts/dialogue/dialogue_ui.gd) and the shop list
## (scripts/shop.gd). Everything it does is undone by end(); nothing here is baked or saved.
##
##   var tc := TalkCamera.for_player(player)
##   tc.begin(npc, {"yaw_bias": -17.0})   # move in (ease_s), light the NPC, start its look
##   await tc.end()                       # move back, lights off, the NPC back to idle
##
## The shot (data/story/talk_camera.json "shot"): a medium close-up at the NPC's eye height, the eyes
## from the head bone (scripts/npc_look.gd eye_point), so it is the same for every body height; the
## camera stands `distance` m from the eyes toward the player and `side` m to the NPC's left, turned
## back onto the face with the eyes `eye_line` from the top. The FOV is set so `frame_h` m of the
## person fills the frame height at that distance; when a wall, a fixture or the player stands closer,
## the camera comes in (to min_distance) and the FOV opens, so the framing does not change.
## The lights ("lights"): two omni lights carried by the camera, a key from the camera side up and to
## screen-left and a fill to screen-right, lighting render layer 20 only; while talking, the NPC's
## meshes are put on that layer too, so nothing else in the mall (and nothing baked) is touched.
## Per-NPC overrides: "npc": {"<id>": {...}} in the JSON, or an entry's own "talk_cam" dictionary.
class_name TalkCamera
extends Node

const CONFIG := "res://data/story/talk_camera.json"

static var _cfg := {}

signal out_done

var player: Node3D
var cam: Camera3D
var key: OmniLight3D
var fill: OmniLight3D
var look: NpcLook = null
var npc: Node3D = null
var active := false
var cfg := {}                  # the merged config of the NPC on screen
var _gen := 0
var _from_cam: Camera3D
var _from_xf := Transform3D()
var _from_fov := 70.0
var _tw: Tween
var _lit: Array = []           # GeometryInstance3Ds we put on the light layer
var _energy := Vector2.ZERO    # key, fill at full

## The wing's talk camera (made on first use, beside the player).
static func for_player(p: Node3D) -> TalkCamera:
	var root := p.get_parent()
	var n = root.get_node_or_null("TalkCamera")
	if n == null:
		n = (load("res://scripts/story/talk_camera.gd") as GDScript).new()
		n.name = "TalkCamera"
		n.player = p
		root.add_child(n)
	return n

## data/story/talk_camera.json, loaded once.
static func config() -> Dictionary:
	if _cfg.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(CONFIG)) if FileAccess.file_exists(CONFIG) else null
		_cfg = j if j is Dictionary else {}
	return _cfg

## The config for one NPC: the standard, with "npc"[id] and the entry's own "talk_cam" laid over it
## one section deep ("shot", "lights", "look").
static func config_for(who: Node) -> Dictionary:
	var c: Dictionary = config().duplicate(true)
	var e = who.get("entry") if who else null
	var over := {}
	if e is Dictionary:
		over = c.get("npc", {}).get(str(e.get("id", "")), {}).duplicate(true)
		var own = e.get("talk_cam", {})
		if own is Dictionary:
			for s in own:
				if own[s] is Dictionary and over.get(s) is Dictionary:
					(over[s] as Dictionary).merge(own[s], true)
				else:
					over[s] = own[s]
	for s in over:
		if over[s] is Dictionary and c.get(s) is Dictionary:
			(c[s] as Dictionary).merge(over[s], true)
		else:
			c[s] = over[s]
	return c

## Where the eyes of `who` are now: the head bone for an NPC with a body, else its face_point(), else
## 1.6 m up.
static func eye_of(who: Node3D) -> Vector3:
	var b = who.get("body") if who else null
	if b is NpcBody and is_instance_valid(b):
		return NpcLook.eye_point(b)
	if who and who.has_method("face_point"):
		return who.face_point()
	return who.global_position + Vector3(0, 1.6, 0) if who else Vector3.ZERO

## The shot for eyes at `eye`, the player at `toward`: {"xf": Transform3D, "fov": degrees, "dist": m}.
## space: a PhysicsDirectSpaceState3D to keep the camera out of walls and fixtures (null: no check).
static func shot(eye: Vector3, toward: Vector3, sc: Dictionary, aspect := 16.0 / 9.0, space = null) -> Dictionary:
	var f := Vector3(toward.x - eye.x, 0, toward.z - eye.z)
	var dp := f.length()
	f = f / dp if dp > 0.01 else Vector3.BACK
	var left := Vector3.UP.cross(f)                 # the NPC's left, the player's right
	var d := float(sc.get("distance", 1.3))
	var lo := float(sc.get("min_distance", 0.75))
	if dp > 0.01:
		d = minf(d, dp - float(sc.get("player_clear", 0.35)))
	var side := float(sc.get("side", 0.12))
	var want := f * d + left * side
	if space:
		var from := eye + want.normalized() * 0.12
		var q := PhysicsRayQueryParameters3D.create(from, eye + want)
		var hit: Dictionary = space.intersect_ray(q)
		if not hit.is_empty():
			d = minf(d, ((hit.position as Vector3) - eye).length() * (d / want.length()) - 0.12)
	d = maxf(d, lo)
	var at := eye + f * d + left * side * (d / maxf(float(sc.get("distance", 1.3)), 0.01))
	var dist := at.distance_to(eye)
	var fh := float(sc.get("portrait_frame_h", 1.0) if aspect < 1.0 else sc.get("frame_h", 0.74))
	var fov := rad_to_deg(2.0 * atan(fh * 0.5 / dist))
	# eyes eye_line of the way down: aim below them by the matching angle
	var t := float(sc.get("eye_line", 0.36))
	var drop := atan((1.0 - 2.0 * t) * tan(deg_to_rad(fov) * 0.5))
	var b := Basis.looking_at(eye - at, Vector3.UP)
	b = b * Basis(Vector3.RIGHT, -drop)
	return {"xf": Transform3D(b, at), "fov": fov, "dist": dist}

# ------------------------------------------------------------------ in and out
## Move in on `who` (any Node3D; an attendant's body gets the lights and the look).
## opts: "yaw_bias" / "pitch_bias" (degrees, turn the finished shot: the shop puts the face beside its
## list), "ease_s" (override).
func begin(who: Node3D, opts := {}) -> void:
	_gen += 1
	_make()
	if look and is_instance_valid(look):
		look.stop()
		look = null
	if npc and npc != who:
		_unlight()
	npc = who
	cfg = config_for(who)
	var sc: Dictionary = cfg.get("shot", {})
	var cur := get_viewport().get_camera_3d()
	if not active:
		_from_cam = cur if cur and cur != cam else player.cam
		_from_xf = _from_cam.global_transform
		_from_fov = _from_cam.fov
		cam.global_transform = _from_xf
		cam.fov = _from_fov
	active = true
	cam.current = true
	var vp := get_viewport().get_visible_rect().size
	var space = player.get_world_3d().direct_space_state if player and player.is_inside_tree() else null
	var s := shot(eye_of(who), player.global_position, sc, vp.x / maxf(vp.y, 1.0), space)
	var to: Transform3D = s.xf
	if opts.has("yaw_bias"):
		to.basis = to.basis.rotated(Vector3.UP, deg_to_rad(float(opts.yaw_bias)))
	if opts.has("pitch_bias"):
		to.basis = to.basis * Basis(Vector3.RIGHT, deg_to_rad(float(opts.pitch_bias)))
	var ease_s := float(opts.get("ease_s", sc.get("ease_s", 0.5)))
	_light(who)
	var b = who.get("body")
	if b is NpcBody and is_instance_valid(b) and b.rig:
		look = NpcLook.new()
		look.name = "NpcLook"
		add_child(look)
		look.start(b, cam, cfg)
	var from := cam.global_transform
	if _tw: _tw.kill()
	_tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tw.tween_method(func(t: float): cam.global_transform = from.interpolate_with(to, t), 0.0, 1.0, ease_s)
	_tw.tween_property(cam, "fov", float(s.fov), ease_s)
	_tw.tween_property(key, "light_energy", _energy.x, ease_s)
	_tw.tween_property(fill, "light_energy", _energy.y, ease_s)

## Move back to the view we came from; the lights fade, the NPC eases back to idle. Await it.
func end() -> void:
	if not active:
		return
	active = false
	var g := _gen
	if look and is_instance_valid(look):
		look.stop()
	look = null
	var ease_s := float(cfg.get("shot", {}).get("ease_s", 0.5))
	var from := cam.global_transform
	var back := _from_cam.global_transform if is_instance_valid(_from_cam) else _from_xf
	var ffov := _from_fov
	if _tw: _tw.kill()
	_tw = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	_tw.tween_method(func(t: float): cam.global_transform = from.interpolate_with(back, t), 0.0, 1.0, ease_s)
	_tw.tween_property(cam, "fov", ffov, ease_s)
	_tw.tween_property(key, "light_energy", 0.0, ease_s)
	_tw.tween_property(fill, "light_energy", 0.0, ease_s)
	await _tw.finished
	if g != _gen or active:
		return          # begun again meanwhile: that conversation owns the camera now
	key.visible = false
	fill.visible = false
	_unlight()
	npc = null
	if is_instance_valid(_from_cam):
		_from_cam.current = true
	out_done.emit()

## Cut everything at once (a wing unloading, a test): no tween.
func reset() -> void:
	_gen += 1
	active = false
	if _tw: _tw.kill()
	if look and is_instance_valid(look):
		look.stop()
	look = null
	if key:
		key.visible = false; fill.visible = false
		key.light_energy = 0.0; fill.light_energy = 0.0
	_unlight()
	npc = null
	if is_instance_valid(_from_cam):
		_from_cam.current = true

func _exit_tree() -> void:
	_unlight()

# ------------------------------------------------------------------ the camera and the lights
func _make() -> void:
	if cam:
		return
	cam = Camera3D.new()
	cam.name = "TalkCam"
	cam.near = 0.03
	cam.far = 200.0
	add_child(cam)
	key = _omni("TalkKey")
	fill = _omni("TalkFill")

func _omni(n: String) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = n
	l.shadow_enabled = false
	l.light_bake_mode = Light3D.BAKE_DISABLED
	l.light_energy = 0.0
	l.visible = false
	cam.add_child(l)
	return l

func _layer_bit() -> int:
	return 1 << (int(cfg.get("lights", {}).get("layer", 20)) - 1)

## Set the two lights from the config and put the NPC's meshes on their layer.
func _light(who: Node3D) -> void:
	var lc: Dictionary = cfg.get("lights", {})
	var yk := 1.0
	var years: Dictionary = lc.get("years", {})
	if player and "year" in player:
		yk = float(years.get(str(player.year), 1.0))
	var bit := _layer_bit()
	var energies := []
	for pair in [[key, lc.get("key", {})], [fill, lc.get("fill", {})]]:
		var l: OmniLight3D = pair[0]
		var e: Dictionary = pair[1]
		var o: Array = e.get("offset", [0, 0, 0])
		l.position = Vector3(float(o[0]), float(o[1]), float(o[2]))
		l.omni_range = float(e.get("range", 3.0))
		l.omni_attenuation = float(e.get("attenuation", 1.0))
		var c: Array = e.get("color", [1, 1, 1])
		l.light_color = Color(float(c[0]), float(c[1]), float(c[2]))
		l.light_cull_mask = bit
		l.visible = true
		energies.append(float(e.get("energy", 0.0)) * yk)
	_energy = Vector2(energies[0], energies[1])
	var b = who.get("body")
	var root: Node = b if b is Node3D and is_instance_valid(b) else who
	for gi in root.find_children("*", "GeometryInstance3D", true, false):
		if gi.layers & bit == 0:
			gi.layers |= bit
			_lit.append(gi)

func _unlight() -> void:
	var bit := _layer_bit()
	for gi in _lit:
		if is_instance_valid(gi):
			gi.layers &= ~bit
	_lit.clear()
