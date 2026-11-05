## One NPC's body: a baked skin from npc/skins/<id>.scn playing the shared Mixamo clip library
## npc/anims.res (tools/npc/bake_clips.gd, ~70 clips from Steven's Oct 16 2026 download).
## Behaviour lives in scripts/npcs.gd; this node shows a person, faces a direction, plays a base
## loop (walk, idle, browse, sit, play…) and one-shot gestures on top that return to the loop.
##
## Retargeting (NpcRig, a SkeletonModifier3D): the clips were authored on Ch01's skeleton; every
## skin's bones point a few degrees differently (Remy ~20°), so each frame every animated local
## rotation is carried over as the same global motion from each skeleton's own T-pose, and the
## hips' position is scaled by hips height. Then optional arm IK (hands on an arcade panel,
## following the clip's own small hand motions) and a head aim (eyes on the arcade screen).
## Models face +Z, so `face(dir)` turns +Z toward dir. Walk clips have their travel removed at
## bake time: `set_speed(mps)` runs the walk at mps / that clip's own m/s so the feet keep up.
class_name NpcBody
extends Node3D

static var _lib: AnimationLibrary
static var _meta := {}
static var _manifest := {}
## The day light's colour on a white surface in the bake (Sears' white interior reads 214/206/193
## where an untinted white NPC shirt read 220/221/221): skins are multiplied by it so people take
## the mall's warm day colour on top of the lightmap probes (scripts/npcs.json day_tint).
static var tint := Color(1, 1, 1)

signal gesture_done(name: String)

var id := ""
var entry := {}
var skin: Node3D
var ap: AnimationPlayer
var rig: NpcRig
var clip := ""             # what is playing now
var base := "idle"         # the loop to return to after a gesture
var walk_clip := "walk_m"
var yaw := 0.0
var speed := 0.0

## npc/skins.json, loaded once.
static func manifest() -> Dictionary:
	if _manifest.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://npc/skins.json"))
		_manifest = j if j is Dictionary else {"skins": []}
	return _manifest

## npc/anims.json: the clips' lengths, loops, walk speeds and the source skeleton's rest.
static func meta() -> Dictionary:
	if _meta.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://npc/anims.json"))
		_meta = j if j is Dictionary else {"clips": {}, "rest": {}, "hips": 1.0}
	return _meta

static func has_clip(n: String) -> bool:
	return meta().clips.has(n)

static func clip_len(n: String) -> float:
	return float(meta().clips.get(n, {}).get("len", 1.0))

## Build the body for one manifest entry.
func set_skin(e: Dictionary) -> void:
	entry = e
	id = str(e.id)
	if skin:
		skin.queue_free(); skin = null
	var ps: PackedScene = load(str(e.scn))
	if ps == null:
		push_warning("npc_body: no skin " + str(e.scn)); return
	skin = ps.instantiate()
	add_child(skin)
	if tint != Color(1, 1, 1):
		for mi in skin.find_children("*", "MeshInstance3D", true, false):
			for i in range(mi.mesh.get_surface_count()):
				var mat = mi.mesh.surface_get_material(i)
				if mat is StandardMaterial3D: mat.albedo_color = tint
	if _lib == null:
		_lib = load("res://npc/anims.res")
	ap = AnimationPlayer.new()
	ap.name = "Anim"
	skin.add_child(ap)
	ap.root_node = ap.get_path_to(skin)
	# CHARS-UBC: the clips address "Skeleton3D:<bone>"; a Blender glTF puts the skeleton one node down
	# (Armature/Skeleton3D), so the clips are rooted at the skeleton's parent
	var sk0: Skeleton3D = skin.find_child("Skeleton3D", true, false)
	if sk0 and sk0.get_parent() != skin:
		ap.root_node = ap.get_path_to(sk0.get_parent())
	ap.add_animation_library("npc", _lib)
	ap.playback_default_blend_time = 0.3
	ap.animation_finished.connect(_on_finished)
	var sk: Skeleton3D = skin.find_child("Skeleton3D", true, false)
	rig = NpcRig.new()
	rig.setup(sk, float(e.get("hips", 1.0)) / float(meta().get("hips", 1.0)))
	sk.add_child(rig)
	play("idle")

## A little light of their own (albedo as emission × k). Off by day since Oct 16 2026: the flat
## glow ignored the mall's shading and warm light; kept for a future night mode.
func set_self_light(k: float) -> void:
	if skin == null: return
	for mi in skin.find_children("*", "MeshInstance3D", true, false):
		for i in range(mi.mesh.get_surface_count()):
			var m = mi.mesh.surface_get_material(i)
			if m is StandardMaterial3D:
				m.emission_enabled = k > 0.0
				m.emission_texture = m.albedo_texture
				m.emission = Color(k, k, k)

## Play a loop as the body's base (or a one-shot, which then returns to the base).
func play(name: String, blend := 0.3, random_start := true) -> void:
	if ap == null or not has_clip(name): return
	if clip == name: return
	var info: Dictionary = meta().clips[name]
	if bool(info.get("loop", true)): base = name
	clip = name
	ap.play("npc/" + name, blend)
	if random_start and bool(info.get("loop", true)):
		ap.seek(randf() * ap.current_animation_length, false)
	if not name.begins_with("walk"):
		ap.speed_scale = 1.0

## A one-shot over the base loop (a nod, a cheer, a point); back to the base when it ends.
func gesture(name: String, blend := 0.25) -> void:
	if ap == null or not has_clip(name): return
	clip = name
	ap.speed_scale = 1.0
	ap.play("npc/" + name, blend)

## True while a one-shot (gesture or transition) is playing.
func busy() -> bool:
	return ap != null and clip != "" and not bool(meta().clips.get(clip, {}).get("loop", true))

func _on_finished(n: StringName) -> void:
	var nm := str(n).trim_prefix("npc/")
	if nm != clip: return
	if bool(meta().clips.get(nm, {}).get("loop", true)): return
	clip = ""
	gesture_done.emit(nm)
	if clip == "":          # nobody chose something else on the signal
		play(base, 0.35, false)

## Freeze on one frame of a clip (the QA sheet).
func freeze(name: String, at: float) -> void:
	if ap == null: return
	clip = name
	ap.active = true
	ap.play("npc/" + name, 0.0)
	ap.seek(at, true)
	ap.speed_scale = 0.0

## Walking speed in m/s (0 stands). Scales the walk clip so the stride matches the ground.
func set_speed(mps: float) -> void:
	speed = mps
	if mps > 0.05:
		if clip != walk_clip:
			play(walk_clip, 0.25, true)
		var own := float(meta().clips.get(walk_clip, {}).get("mps", 1.4))
		ap.speed_scale = clampf(mps / maxf(own, 0.3), 0.6, 1.5)
	elif clip.begins_with("walk"):
		ap.speed_scale = 1.0
		clip = ""
		play(base if not base.begins_with("walk") else "idle")

## Stand the body so the hips of `clip` (its first frame) land over a world point: a seat on a
## bench, whatever the clip's own hip offset.
func place_at(point: Vector3, clip_name: String) -> void:
	var h: Array = meta().clips.get(clip_name, {}).get("hips0", [0, 0])
	var r: float = rig.ratio if rig else 1.0
	position = point - global_basis.orthonormalized() * Vector3(float(h[0]) * r, 0, float(h[1]) * r) if is_inside_tree() else point

## Turn +Z (the model's front) toward a world direction, smoothly if `rate` is given.
func face(dir: Vector3, rate := 0.0, dt := 0.0) -> void:
	if dir.length_squared() < 1e-6:
		return
	var target := atan2(dir.x, dir.z)
	if rate <= 0.0 or dt <= 0.0:
		yaw = target
	else:
		yaw = lerp_angle(yaw, target, clampf(rate * dt, 0.0, 1.0))
	rotation.y = yaw

## Hands to two world points (an arcade panel), following the clip's own hand motion around them.
func hands_to(left: Vector3, right: Vector3) -> void:
	if rig: rig.hands = {"Left": left, "Right": right}

func hands_off() -> void:
	if rig: rig.hands = {}

## Eyes on a world point (the arcade screen); Vector3.INF clears it.
func look_at_point(p: Vector3) -> void:
	if rig: rig.look = p

## Pause the animation and the rig far away (LOD).
func set_animated(on: bool) -> void:
	if ap: ap.active = on
	if rig: rig.active = on

## Head height for a look-at or a close-up.
func eye_pos() -> Vector3:
	return global_position + Vector3(0, float(entry.get("height_m", 1.7)) - 0.1, 0)
