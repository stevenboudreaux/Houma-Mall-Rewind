## The Stockrooms (Steven, Oct 15 2026): an Easter-egg level behind Woolworth's back corner. The
## Rougarou walks into that corner on its last Woolworth encounter; from then on (in that browser)
## walking into the same patch of wall brings you here: yellow wallpaper, damp carpet, buzzing
## ceiling panels, nobody home. The only way out is the same patch of wall in the start room.
## Spec: design/godot-stockrooms.md. Layout: scripts/stockrooms_map.json, made by
## tools/stockrooms/make_stockrooms.py (one cell = 1 m; '.' floor, '#' solid, 'X' the door home).
##
## Everything is built at runtime from primitives and generated textures, far from the mall
## (ORIGIN), so neither wing's bake, stand-ins or game files change. While inside: the mall is
## hidden, the environment swapped for this one, the player's walk grid swapped for the maze's,
## the floor mirror off, the lighting/benches buttons hidden, and the Jump menu hidden unless this
## is the owner's browser. Seams: a wrong turn ends in a copy of the station you left; crossing
## the line in the copy's entry moves you by the seam's offset into the real entry.
##
## Made by player.gd in Wing 1. URL: ?stockrooms=in starts inside.
## Since Oct 16 2026 (Steven: "on anyone's initial startup, as long as they know that spot, they
## can go into the stock rooms ... not tied to following the Rougarou") the door is open for
## everyone from the start; the Rougarou is gone (the Runner, scripts/runner_ai.gd, replaced it).
extends Node3D

const MAP = "res://scripts/stockrooms_map.json"
const ORIGIN = Vector3(2000, 0, 2000)        # grid (0, 0) in the world
const CEIL = 2.75
const WOOL_DOOR = Rect2(-45.75, 21.0, 0.75, 0.9)   # the patch of Woolworth wall (x, z), walked into
const WOOL_BACK_OUT = Vector3(-43.9, 0, 20.9)       # where you come back out, facing into the store
const STICK_SAY_M = 2.0
var stick_is_item := false   # B+C: the interact prompt names it instead of the caption

var player: Node3D
var built := false
var inside := false
var unlocked := false
var J := {}
var rows: PackedStringArray
var seams := []
var door := []
var prev := Vector3.ZERO
var fade: ColorRect
var caption: Label
var stick_pos := Vector3.ZERO
var env: Environment
var saved := {}
var flicker := []          # [material, phase]
var hum: AudioStreamPlayer
var hum_pb: AudioStreamGeneratorPlayback
var hum_t := 0.0
var busy := false
var t := 0.0
var force := ""

func _ready() -> void:
	unlocked = true
	var cl = CanvasLayer.new(); cl.layer = 30; add_child(cl)
	fade = ColorRect.new(); fade.color = Color(0, 0, 0, 0); fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_preset(Control.PRESET_FULL_RECT); cl.add_child(fade)
	caption = Label.new(); caption.visible = false
	caption.text = "Martin Folse's stick"
	caption.add_theme_font_size_override("font_size", 26)
	caption.add_theme_color_override("font_color", Color(1.0, 0.95, 0.75))
	caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	caption.add_theme_constant_override("outline_size", 6)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	caption.offset_top = -140; caption.offset_bottom = -100; caption.offset_left = -300; caption.offset_right = 300
	cl.add_child(caption)
	if force == "in":
		enter.call_deferred(true)

# ------------------------------------------------------------------ unlock
func _load_unlock() -> bool:
	if OS.has_feature("web"):
		return str(JavaScriptBridge.eval("(function(){try{return localStorage.getItem('mall-stockrooms')||''}catch(e){return ''}})()", true)) == "1"
	return bool(Engine.get_meta("mall_stockrooms", false))

func _save_unlock() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try{localStorage.setItem('mall-stockrooms','1')}catch(e){}", true)
	else:
		Engine.set_meta("mall_stockrooms", true)

## The Rougarou went through the wall: the door opens for this browser from now on.
func unlock() -> void:
	unlocked = true
	_save_unlock()
	print("stockrooms: unlocked")

# ------------------------------------------------------------------ the loop
func _process(dt: float) -> void:
	t += dt
	if player == null or busy:
		return
	var p = player.position
	if not inside:
		if unlocked and WOOL_DOOR.has_point(Vector2(p.x, p.z)):
			enter(false)
		return
	# left by some other way (the owner's Jump): put everything back
	if p.distance_to(ORIGIN) > 2000.0:
		_restore(); return
	var g = p - ORIGIN
	var pg = prev - ORIGIN
	# seams: a copy's entry, crossed heading north, is the real entry
	for s in seams:
		var r = s.rect
		var line = float(r[1]) + 0.5
		if pg.z >= line and g.z < line and g.x >= float(r[0]) and g.x <= float(r[2]) + 1.0:
			player.position += Vector3(float(s.dx), 0, float(s.dy))
			p = player.position
			print("stockrooms: seam ", s.name)
			break
	prev = player.position
	# the door home: walk into the wall
	g = player.position - ORIGIN
	if g.z > float(door[1]) + 0.12 and g.x >= float(door[0]) and g.x <= float(door[2]) + 1.0:
		leave(); return
	caption.visible = not stick_is_item and Vector2(p.x - stick_pos.x, p.z - stick_pos.z).length() < STICK_SAY_M
	for f in flicker:
		var m: StandardMaterial3D = f[0]
		var on = sin(t * 13.0 + f[1]) + sin(t * 31.0 + f[1] * 2.0) > -0.9 or fmod(t + f[1], 7.0) > 0.3
		m.emission_energy_multiplier = 2.6 if on else 0.15
	_hum(dt)
	_sfx(dt)

# ------------------------------------------------------------------ in and out
func enter(instant: bool) -> void:
	if inside or busy: return
	busy = true
	if not instant: await _fade_to(1.0, 0.35)
	if not built: _build()
	var root = get_parent()
	saved = {"walk": player.walk_rows, "scale": player.map_scale, "origin": player.map_origin,
		"obs": player.obstacles, "fx": player.fx_obstacles, "vis": {}, "env": null, "refl": true}
	for c in root.get_children():
		if c is Node3D and c != self and c != player and c.name != "RougarouAI" and c.visible:
			saved.vis[c] = true; c.visible = false
		if c is WorldEnvironment:
			saved.env = c.environment; c.environment = env
	var rt = root.get_node_or_null("Runtime")
	if rt:
		saved.refl = rt.refl_on; rt.set_reflections(false)
	var ai = root.get_node_or_null("RougarouAI")
	if ai:
		ai.set_process(false)
		if ai.fig: ai.fig.visible = false
	player.walk_rows = rows
	player.map_scale = 1.0
	player.map_origin = Vector2(-ORIGIN.x, -ORIGIN.z)
	player.obstacles = J.obstacles
	player.fx_obstacles = []
	_hud(false)
	var sp = J.notes.spawn
	player.position = ORIGIN + Vector3(float(sp[0]), 0, float(sp[1]))
	player.yaw = 0.0; player.pitch = 0.0; player._apply_rot()
	prev = player.position
	visible = true
	inside = true
	_hum_start()
	print("stockrooms: in")
	if not instant: await _fade_to(0.0, 0.6)
	busy = false

func leave() -> void:
	if not inside or busy: return
	busy = true
	await _fade_to(1.0, 0.35)
	_restore()
	player.position = WOOL_BACK_OUT
	player.yaw = -PI * 0.5; player.pitch = 0.0; player._apply_rot()
	await _fade_to(0.0, 0.6)
	busy = false

func _restore() -> void:
	var root = get_parent()
	for c in saved.get("vis", {}):
		if is_instance_valid(c): c.visible = true
	for c in root.get_children():
		if c is WorldEnvironment and saved.get("env") != null:
			c.environment = saved.env
	var rt = root.get_node_or_null("Runtime")
	if rt:
		rt.set_time(rt.mode)
		rt.set_reflections(saved.get("refl", true))
	player.walk_rows = saved.walk; player.map_scale = saved.scale; player.map_origin = saved.origin
	player.obstacles = saved.obs; player.fx_obstacles = saved.fx
	for an in ["RougarouAI", "RunnerAI"]:
		var ai = root.get_node_or_null(an)
		if ai: ai.set_process(true)
	_hud(true)
	visible = false
	inside = false
	caption.visible = false
	if hum: hum.stop()
	print("stockrooms: out")

## The HUD while inside: no lighting or benches buttons (they would put the mall back), no floor
## mirror button, and no Jump menu unless this is the owner's browser.
func _hud(on: bool) -> void:
	for b in player.buttons:
		b.visible = on
	if on and player.has_method("owner_hud_sync"):
		player.owner_hud_sync()   # B+C: the toggles stay the owner's (design/godot-interaction.md)
	var own = false
	var sg = get_parent().get_node_or_null("Signs")
	if sg: own = sg.is_owner
	player.jump_locked = (not on) and not own
	if player.jump_open_btn: player.jump_open_btn.visible = on or own
	if not on and not own: player._jump_show(false)

func _fade_to(a: float, s: float) -> void:
	var tw = create_tween()
	tw.tween_property(fade, "color:a", a, s)
	await tw.finished

# ------------------------------------------------------------------ the hum
# ------------------------------------------------------------------ the sounds you never see the
# source of (Steven, Oct 15 10:26: "faint footsteps sometimes, or papers shuffling"): every
# 15-45 s, a short walk of muffled steps or a rustle of paper, from somewhere 9-22 m off.
var snd_step: AudioStreamWAV
var snd_paper: AudioStreamWAV
var sfx_next := 12.0
var sfx_rng := RandomNumberGenerator.new()

func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var w = AudioStreamWAV.new(); w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = 22050
	var b = PackedByteArray(); b.resize(samples.size() * 2)
	for i in samples.size():
		b.encode_s16(i * 2, int(clamp(samples[i], -1.0, 1.0) * 32000.0))
	w.data = b
	return w

func _make_sounds() -> void:
	sfx_rng.seed = 1031
	var r = RandomNumberGenerator.new(); r.seed = 7
	# a footstep on carpet: a dull low thump with a little muffled scuff
	var n = int(22050 * 0.22); var a = PackedFloat32Array(); a.resize(n)
	var lp = 0.0
	for i in n:
		var tt = float(i) / 22050.0
		lp += (r.randf_range(-1, 1) - lp) * 0.08
		a[i] = (sin(TAU * 68.0 * tt) * 0.9 * exp(-tt * 28.0) + lp * 1.6 * exp(-tt * 18.0)) * min(1.0, tt * 400.0)
	snd_step = _wav(a)
	# paper: hiss with crackle bursts, shaped like a sheet being turned over
	n = int(22050 * 1.1); var p = PackedFloat32Array(); p.resize(n)
	var lp2 = 0.0; var burst = 0.0
	for i in n:
		var tt = float(i) / 22050.0
		var x = r.randf_range(-1, 1)
		lp2 += (x - lp2) * 0.35
		if r.randf() < 0.0025: burst = r.randf_range(0.5, 1.0)
		burst *= 0.9993
		var env = sin(PI * clamp(tt / 1.1, 0.0, 1.0))
		p[i] = (x - lp2) * (0.25 + burst) * env * 0.7
	snd_paper = _wav(p)

func _sfx(dt: float) -> void:
	sfx_next -= dt
	if sfx_next > 0.0: return
	sfx_next = sfx_rng.randf_range(15.0, 45.0)
	# somewhere on the floor 9-22 m away
	var pp = player.position - ORIGIN
	var spot = null
	for k in 40:
		var a = sfx_rng.randf() * TAU; var d = sfx_rng.randf_range(9.0, 22.0)
		var c = Vector2(pp.x + cos(a) * d, pp.z + sin(a) * d)
		var ix = int(c.x); var iy = int(c.y)
		if iy >= 0 and iy < rows.size() and ix >= 0 and ix < rows[0].length() and rows[iy][ix] == "1":
			spot = ORIGIN + Vector3(c.x, 0.1, c.y); break
	if spot == null: return
	var src = AudioStreamPlayer3D.new(); src.position = spot; add_child(src)
	src.unit_size = 4.0; src.max_db = -6.0; src.volume_db = -10.0
	if sfx_rng.randf() < 0.6:
		src.stream = snd_step
		var dir = Vector3(sfx_rng.randf_range(-1, 1), 0, sfx_rng.randf_range(-1, 1)).normalized()
		var steps = sfx_rng.randi_range(4, 9)
		for k in steps:
			if not inside: break
			src.position += dir * 0.7
			src.pitch_scale = sfx_rng.randf_range(0.9, 1.08)
			src.play()
			await get_tree().create_timer(sfx_rng.randf_range(0.5, 0.62)).timeout
	else:
		src.stream = snd_paper; src.pitch_scale = sfx_rng.randf_range(0.85, 1.15)
		src.play()
		await get_tree().create_timer(1.3).timeout
	if is_instance_valid(src): src.queue_free()

func _hum_start() -> void:
	if hum == null:
		hum = AudioStreamPlayer.new()
		var gen = AudioStreamGenerator.new(); gen.mix_rate = 22050; gen.buffer_length = 0.25
		hum.stream = gen; hum.volume_db = -20.0
		add_child(hum)
	hum.play()
	hum_pb = hum.get_stream_playback()

## Fluorescent hum: 120 Hz with odd harmonics and a slow beat.
func _hum(_dt: float) -> void:
	if hum_pb == null: return
	var n = hum_pb.get_frames_available()
	var inc = 1.0 / 22050.0
	for i in n:
		hum_t += inc
		var w = TAU * 120.0 * hum_t
		var v = 0.30 * sin(w) + 0.12 * sin(3.0 * w) + 0.05 * sin(5.0 * w + 0.4) + 0.03 * sin(TAU * 1830.0 * hum_t)
		v *= 0.85 + 0.15 * sin(TAU * 0.7 * hum_t)
		hum_pb.push_frame(Vector2(v, v) * 0.5)

# ------------------------------------------------------------------ building
func _build() -> void:
	J = JSON.parse_string(FileAccess.get_file_as_string(MAP))
	var src: Array = J.rows
	seams = J.seams
	door = J.notes.door
	# the walk grid: floor and the door cells walk; the door is drawn as wall (you walk into it)
	var walk = PackedStringArray()
	for r in src:
		walk.append(r.replace(".", "1").replace("X", "1").replace("#", "0"))
	rows = walk
	env = _env()
	var m_wall = _mat_tex(_tex_wall(), Color(1, 1, 1), 0.95)
	m_wall.vertex_color_use_as_albedo = true
	var m_floor = _mat_tex(_tex_carpet(), Color(1, 1, 1), 1.0)
	var m_ceil = _mat_tex(_tex_ceiling(), Color(1, 1, 1), 0.9)
	var s_wall = SurfaceTool.new(); s_wall.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s_floor = SurfaceTool.new(); s_floor.begin(Mesh.PRIMITIVE_TRIANGLES)
	var s_ceil = SurfaceTool.new(); s_ceil.begin(Mesh.PRIMITIVE_TRIANGLES)
	var H = src.size(); var W = src[0].length()
	var isfloor = func(x, y): return x >= 0 and y >= 0 and y < H and x < W and src[y][x] == "."
	var panels_on = []; var panels_dead = []; var panels_flick = []
	var rng = RandomNumberGenerator.new(); rng.seed = 1969
	for y in H:
		var row: String = src[y]
		for x in W:
			var c = row[x]
			if c != "." and c != "X": continue
			var o = Vector3(x, 0, y)
			if c == ".":
				_quad(s_floor, o, o + Vector3(1, 0, 0), o + Vector3(1, 0, 1), o + Vector3(0, 0, 1), Vector3.UP, 0.5)
				_quad(s_ceil, o + Vector3(0, CEIL, 1), o + Vector3(1, CEIL, 1), o + Vector3(1, CEIL, 0), o + Vector3(0, CEIL, 0), Vector3.DOWN, 0.5)
				# walls on each side that meets solid (or the door)
				for d in [[1, 0], [-1, 0], [0, 1], [0, -1]]:
					var nx = x + d[0]; var ny = y + d[1]
					var nc = src[ny][nx] if ny >= 0 and ny < H and nx >= 0 and nx < W else "#"
					if nc == "#" or nc == "X":
						_wall(s_wall, x, y, d)
				# ceiling panels on a 4 x 3 m lattice where the cell has room around it
				if x % 4 == 1 and y % 3 == 1 and isfloor.call(x + 1, y) and isfloor.call(x - 1, y):
					var k = rng.randf()
					(panels_dead if k < 0.12 else (panels_flick if k < 0.17 else panels_on)).append(Vector3(x + 1.0, CEIL - 0.01, y + 0.5))
	var root = Node3D.new(); root.position = ORIGIN; add_child(root)
	_add(root, s_wall, m_wall); _add(root, s_floor, m_floor); _add(root, s_ceil, m_ceil)
	# panels: lit, dead, flickering (each flickering one its own material)
	var m_on = _mat_glow(2.2)
	var m_dead = _mat_glow(0.08)
	_panels(root, panels_on, m_on)
	_panels(root, panels_dead, m_dead)
	for p in panels_flick:
		var m = _mat_glow(2.6); flicker.append([m, rng.randf() * 10.0]); _panels(root, [p], m)
	# a dim light from one side so walls facing different ways read different
	var sun = DirectionalLight3D.new(); sun.rotation_degrees = Vector3(-35, 30, 0); sun.light_energy = 0.38
	sun.light_color = Color(1.0, 0.93, 0.7); root.add_child(sun)
	# props
	J.obstacles = []
	for p in J.props:
		_prop(root, p)
	_make_sounds()
	visible = false
	built = true
	print("stockrooms: built, ", panels_on.size() + panels_dead.size() + panels_flick.size(), " panels, ", J.props.size(), " props")

func _add(root: Node3D, s: SurfaceTool, m: Material) -> void:
	s.index(); s.generate_tangents()
	var mi = MeshInstance3D.new(); mi.mesh = s.commit(); mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)

func _quad(s: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, uvs: float, col := Color.WHITE, col_top := Color.WHITE) -> void:
	var pts = [a, b, c, d]
	var uv = []
	for p in pts:
		uv.append(Vector2(p.x, p.z) * uvs if abs(n.y) > 0.5 else (Vector2(p.x + p.z, -p.y) * uvs))
	for i in [0, 1, 2, 0, 2, 3]:
		s.set_normal(n); s.set_uv(uv[i])
		s.set_color(col_top if pts[i].y > 0.1 else col)
		s.add_vertex(pts[i])

## The wall face of floor cell (x, y) on side d (pointing at the solid cell), facing back in.
func _wall(s: SurfaceTool, x: int, y: int, d: Array) -> void:
	var n = Vector3(-d[0], 0, -d[1])
	var a: Vector3; var b: Vector3
	if d[0] == 1: a = Vector3(x + 1, 0, y + 1); b = Vector3(x + 1, 0, y)
	elif d[0] == -1: a = Vector3(x, 0, y); b = Vector3(x, 0, y + 1)
	elif d[1] == 1: a = Vector3(x, 0, y + 1); b = Vector3(x + 1, 0, y + 1)
	else: a = Vector3(x + 1, 0, y); b = Vector3(x, 0, y)
	# darker at the foot, the way the video's walls fall off into the carpet
	_quad(s, a, b, b + Vector3(0, CEIL, 0), a + Vector3(0, CEIL, 0), n, 0.5, Color(0.55, 0.52, 0.42), Color(0.95, 0.93, 0.86))

func _panels(root: Node3D, list: Array, m: Material) -> void:
	if list.is_empty(): return
	var s = SurfaceTool.new(); s.begin(Mesh.PRIMITIVE_TRIANGLES)
	for p in list:
		var hx = 0.6; var hz = 0.3
		_quad(s, p + Vector3(-hx, 0, hz), p + Vector3(hx, 0, hz), p + Vector3(hx, 0, -hz), p + Vector3(-hx, 0, -hz), Vector3.DOWN, 1.0)
	_add(root, s, m)

# ------------------------------------------------------------------ props
func _box(root: Node3D, c: Vector3, size: Vector3, col: Color, rot := 0.0, emit := 0.0) -> MeshInstance3D:
	var mi = MeshInstance3D.new(); var bm = BoxMesh.new(); bm.size = size
	var m = StandardMaterial3D.new(); m.albedo_color = col; m.roughness = 0.85
	if emit > 0.0: m.emission_enabled = true; m.emission = col; m.emission_energy_multiplier = emit
	bm.material = m; mi.mesh = bm
	mi.position = c; mi.rotation.y = rot
	root.add_child(mi)
	return mi

func _prop(root: Node3D, p: Dictionary) -> void:
	var kind = str(p.kind)
	var node = Node3D.new(); node.position = Vector3(float(p.x), 0, float(p.y)); node.rotation_degrees.y = float(p.get("rot", 0))
	root.add_child(node)
	var wpos = ORIGIN + node.position
	match kind:
		"table", "table_pc":
			_box(node, Vector3(0, 0.73, 0), Vector3(1.4, 0.04, 0.75), Color("#c8c0a6"))
			for sx in [-0.64, 0.64]:
				for sz in [-0.32, 0.32]:
					_box(node, Vector3(sx, 0.36, sz), Vector3(0.04, 0.72, 0.04), Color("#5a5650"))
			if kind == "table_pc":
				_box(node, Vector3(-0.1, 0.96, 0.05), Vector3(0.42, 0.38, 0.4), Color("#d8d0b8"))       # a beige monitor
				_box(node, Vector3(-0.1, 0.97, -0.16), Vector3(0.34, 0.26, 0.02), Color("#2a3328"), 0.0, 0.3)
				_box(node, Vector3(-0.1, 0.76, -0.25), Vector3(0.44, 0.03, 0.15), Color("#cfc7ae"))     # keyboard
			J.obstacles.append([wpos.x, wpos.z, 0.75])
		"camera":
			for k in 3:
				var a = TAU * k / 3.0
				var leg = _box(node, Vector3(cos(a) * 0.18, 0.62, sin(a) * 0.18), Vector3(0.025, 1.3, 0.025), Color("#1c1c1c"))
				leg.rotation = Vector3(sin(a) * 0.25, 0, -cos(a) * 0.25)
			_box(node, Vector3(0, 1.32, 0), Vector3(0.12, 0.13, 0.28), Color("#222222"))
			_box(node, Vector3(0.05, 1.37, 0.12), Vector3(0.015, 0.015, 0.015), Color("#ff2020"), 0.0, 3.0)   # recording
			J.obstacles.append([wpos.x, wpos.z, 0.35])
		"boxes":
			var r2 = RandomNumberGenerator.new(); r2.seed = int(p.x * 100 + p.y)
			var h = 0.0
			for k in 3 + r2.randi() % 3:
				var sz = Vector3(r2.randf_range(0.4, 0.6), r2.randf_range(0.3, 0.45), r2.randf_range(0.4, 0.6))
				_box(node, Vector3(r2.randf_range(-0.05, 0.05), h + sz.y * 0.5, r2.randf_range(-0.05, 0.05)), sz, Color("#a88a5a"), r2.randf_range(-0.3, 0.3))
				h += sz.y
			J.obstacles.append([wpos.x, wpos.z, 0.5])
		"chairs", "chair":
			var n = 4 if kind == "chairs" else 1
			for k in n:
				var y0 = k * 0.08
				_box(node, Vector3(0, 0.45 + y0, 0), Vector3(0.42, 0.03, 0.42), Color("#3c3a36"))
				_box(node, Vector3(0, 0.75 + y0, 0.2), Vector3(0.42, 0.42, 0.03), Color("#3c3a36"))
				for sx in [-0.19, 0.19]:
					_box(node, Vector3(sx, 0.22 + y0, 0), Vector3(0.025, 0.45, 0.4), Color("#77736a"))
			J.obstacles.append([wpos.x, wpos.z, 0.4])
		"crate":
			# the start room's one thing: a small wooden crate by the wall you came in through
			_box(node, Vector3(0, 0.22, 0), Vector3(0.45, 0.44, 0.45), Color("#8a6a3e"))
			_box(node, Vector3(0, 0.445, 0), Vector3(0.47, 0.01, 0.06), Color("#6a4e2a"))
			J.obstacles.append([wpos.x, wpos.z, 0.4])
		"ladder":
			# a ladder leaning on the wall (local +z) up to a dark square in the ceiling (a landmark).
			# Built upright in a pivot at its foot, then the whole thing tilted, so the rungs stay
			# between the rails (Steven, Oct 15 10:26: they stuck out to one side)
			var piv = Node3D.new(); piv.position = Vector3(0, 0, -0.12); node.add_child(piv)
			var L = 2.85
			for sx in [-0.21, 0.21]:
				_box(piv, Vector3(sx, L * 0.5, 0), Vector3(0.045, L, 0.06), Color("#9a9a92"))
			for k in 9:
				_box(piv, Vector3(0, 0.28 + k * 0.29, 0), Vector3(0.42, 0.032, 0.032), Color("#9a9a92"))
			piv.rotation.x = atan2(0.55, CEIL)          # the top leans 0.55 m toward the wall
			_box(node, Vector3(0, CEIL - 0.006, 0.14), Vector3(0.72, 0.01, 0.62), Color("#050403"))
		"stick":
			# B+C (design/godot-interaction.md): the stick is a pick-up item now (data/items/stockrooms.json,
			# placed by scripts/interact.gd at this spot, glow and all); the old prop and its caption only
			# when that item file is missing
			if FileAccess.file_exists("res://data/items/stockrooms.json"):
				stick_is_item = true
			else:
				_stick(node)
			stick_pos = wpos

## Martin Folse's stick: the plain white pointer he lays on the radar map to call landfall (HTV,
## Houma). About four feet, white, a little worn at the tip, leaning in the corner of the far room
## with a faint glow of its own. No pickup yet (Steven: a later mechanic); a caption within 2 m.
func _stick(node: Node3D) -> void:
	var lean = Node3D.new(); lean.rotation = Vector3(0.16, 0, -0.16); node.add_child(lean)
	var cy = MeshInstance3D.new(); var cm = CylinderMesh.new()
	cm.top_radius = 0.011; cm.bottom_radius = 0.014; cm.height = 1.22; cm.radial_segments = 10
	var m = StandardMaterial3D.new(); m.albedo_color = Color("#f4f2ec"); m.roughness = 0.45
	m.emission_enabled = true; m.emission = Color("#fff6dc"); m.emission_energy_multiplier = 0.9
	cm.material = m; cy.mesh = cm; cy.position = Vector3(0, 0.61, 0); lean.add_child(cy)
	var tip = MeshInstance3D.new(); var tm = CylinderMesh.new()
	tm.top_radius = 0.0115; tm.bottom_radius = 0.0115; tm.height = 0.05; tm.radial_segments = 10
	var tmm = StandardMaterial3D.new(); tmm.albedo_color = Color("#9a958a"); tm.material = tmm
	tip.mesh = tm; tip.position = Vector3(0, 1.2, 0); lean.add_child(tip)
	# the aura: a soft additive halo that always faces you, and a little warm light
	var halo = MeshInstance3D.new(); var q = QuadMesh.new(); q.size = Vector2(0.9, 1.7)
	var hm = StandardMaterial3D.new(); hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	hm.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y; hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD; hm.albedo_texture = _tex_halo(); hm.albedo_color = Color(1.0, 0.92, 0.65, 0.55)
	q.material = hm; halo.mesh = q; halo.position = Vector3(0, 0.75, 0); node.add_child(halo)
	var l = OmniLight3D.new(); l.position = Vector3(0, 0.9, 0); l.light_color = Color(1.0, 0.9, 0.65)
	l.light_energy = 0.9; l.omni_range = 2.6; node.add_child(l)

# ------------------------------------------------------------------ look
func _env() -> Environment:
	var e = Environment.new()
	e.background_mode = Environment.BG_COLOR; e.background_color = Color("#1a170a")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color("#e6d79a"); e.ambient_light_energy = 0.78
	e.fog_enabled = true; e.fog_light_color = Color("#2b2610"); e.fog_density = 0.065
	e.glow_enabled = true; e.glow_intensity = 0.55; e.glow_bloom = 0.08; e.glow_hdr_threshold = 1.1
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC; e.tonemap_exposure = 0.95
	e.adjustment_enabled = true; e.adjustment_saturation = 0.85; e.adjustment_contrast = 1.1
	return e

func _mat_tex(tex: Texture2D, col: Color, rough: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_texture = tex; m.albedo_color = col; m.roughness = rough
	m.metallic_specular = 0.15
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m

func _mat_glow(e: float) -> StandardMaterial3D:
	var m = StandardMaterial3D.new(); m.albedo_color = Color("#fffbe8")
	m.emission_enabled = true; m.emission = Color("#fff6d8"); m.emission_energy_multiplier = e
	return m

func _noise(seed: int, freq: float, size: int) -> Image:
	var n = FastNoiseLite.new(); n.seed = seed; n.frequency = freq; n.fractal_octaves = 4
	return n.get_seamless_image(size, size)

## Yellow-ochre wallpaper: faint vertical stripes of a slightly lighter yellow, and a damp mottle.
func _tex_wall() -> ImageTexture:
	var S = 256
	var mot = _noise(11, 0.022, S)
	var im = Image.create(S, S, false, Image.FORMAT_RGB8)
	for y in S:
		for x in S:
			var stripe = 0.035 if (x % 24) < 9 else 0.0
			var v = mot.get_pixel(x, y).r
			var k = 0.88 + stripe + (v - 0.5) * 0.10
			im.set_pixel(x, y, Color(0.76 * k, 0.70 * k, 0.41 * k))
	im.generate_mipmaps()
	return ImageTexture.create_from_image(im)

## Damp beige-green carpet: fine fibre noise over a blotchy stain layer.
func _tex_carpet() -> ImageTexture:
	var S = 256
	var fine = _noise(23, 0.35, S)
	var stain = _noise(29, 0.008, S)
	var im = Image.create(S, S, false, Image.FORMAT_RGB8)
	for y in S:
		for x in S:
			var f = fine.get_pixel(x, y).r
			var st = stain.get_pixel(x, y).r
			var k = 0.82 + (f - 0.5) * 0.18 - max(0.0, st - 0.55) * 0.25
			im.set_pixel(x, y, Color(0.56 * k, 0.52 * k, 0.34 * k))
	im.generate_mipmaps()
	return ImageTexture.create_from_image(im)

## Drop-ceiling tiles: 2 x 2 tiles per texture (each 0.5 m... one tile per metre at uv 0.5), a pale
## grid between, a speckle in each tile.
func _tex_ceiling() -> ImageTexture:
	var S = 256
	var sp = _noise(41, 0.5, S)
	var im = Image.create(S, S, false, Image.FORMAT_RGB8)
	for y in S:
		for x in S:
			var grid = (x % 128) < 2 or (y % 128) < 2
			var k = 0.74 if grid else 0.86 + (sp.get_pixel(x, y).r - 0.5) * 0.1
			im.set_pixel(x, y, Color(0.86 * k, 0.82 * k, 0.6 * k))
	im.generate_mipmaps()
	return ImageTexture.create_from_image(im)

func _tex_halo() -> ImageTexture:
	var S = 64
	var im = Image.create(S, S, false, Image.FORMAT_RGBA8)
	for y in S:
		for x in S:
			var dx = (x - S * 0.5) / (S * 0.5); var dy = (y - S * 0.5) / (S * 0.5)
			var a = clamp(1.0 - sqrt(dx * dx * 1.6 + dy * dy), 0.0, 1.0)
			im.set_pixel(x, y, Color(1, 1, 1, a * a))
	return ImageTexture.create_from_image(im)
