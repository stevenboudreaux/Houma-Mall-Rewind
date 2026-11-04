## The animated lamps and neon of Pocket Change's light-ring ticket game
## (tools/stores/pocket_change/cyclone.gd, "WHIRLWIND"). Lightmaps are baked, so these
## parts are built here at run time and animated entirely on the GPU: every shader reads
## the built-in TIME and a per-lamp index, so the CPU does no work per frame. Works in the
## gl_compatibility renderer the web export uses (no Light3D nodes; the glow is emission).
##
## Built in _ready() from the "layout" meta that cyclone.gd sets (node-local, metres):
##   centre: the playfield centre (the dome's axis) at the field's height
##   field_y, dish_y: playfield and dish-floor heights
##   post: the foot of the BONUS readout's post (the pink coil winds round it)
##   lamps: [{pos, n, role}] the tower lamps ("tower_l", "tower_r") and the "bonus" lamp
## Node frame: x = the player's right, y = up, +z = toward the player (the machine's front).
##
## Light show (measured from Steven's 1995 video at 1/8 s steps):
## - Ring: one bright lamp with a short fading tail chases round fast (attract mode).
##   Every CYCLE_S the whole ring flashes together FLASH_COUNT times, then the chase runs
##   backwards for a while, then forward again.
## - Neon: the three centre coils take turns, green, pink, blue, NEON_STEP_S each. The
##   arches on the ring stay lit at ARCH_IDLE and brighten when their colour's coil is on;
##   they flash with the ring.
## - The two tower lamps blink alternately and slowly; the BONUS lamp pulses, and blinks
##   fast during the ring flash.
extends Node3D

# ---- timing, seconds (TIME wraps every 3600 s: keep these dividing 3600 evenly)
## One lap of the chasing lamp in attract mode.
const CHASE_LAP_S := 1.2
## The chase's tail: how many lamps it takes to fade to about a third.
const CHASE_TAIL := 1.3
## Forward chase, then the flash, then the reversed chase: one full cycle is their sum
## (10 s). The flash starts at 5.9 s so a whole-second preview frame (t = 6, which the
## movie writer renders a hair early) lands inside the first lit beat.
const CHASE_PHASE_S := 5.9
const FLASH_PHASE_S := 1.0
## Whole-ring flashes per second during the flash (FLASH_PHASE_S * FLASH_HZ flashes).
const FLASH_HZ := 4.0
const REVERSE_PHASE_S := 3.1
const REVERSE_LAP_S := 1.0
## Each neon coil's turn; three coils make one NEON_STEP_S * 3 = 1.6 s round.
const NEON_STEP_S := 1.6 / 3.0
## Arch brightness between their coil's turns (0 off .. 1 full).
const ARCH_IDLE := 0.55
## Tower lamps: one full on/off period; the two run half a period apart.
const TOWER_PERIOD_S := 1.5
## BONUS lamp: one slow pulse.
const BONUS_PULSE_S := 0.75

# ---- brightness (emission energy) and colours
const BULB_ENERGY := 5.0
const NEON_ENERGY := 3.4
const LAMP_ENERGY := 4.0
const BULB_ON := Color(1.0, 0.80, 0.34)
const BULB_OFF := Color(0.30, 0.20, 0.08)
const GREEN := Color(0.25, 1.0, 0.38)
const PINK := Color(1.0, 0.32, 0.68)
const CYAN := Color(0.30, 0.82, 1.0)
const WHITE := Color(0.95, 0.90, 1.0)
const LAMP_ORANGE := Color(1.0, 0.45, 0.10)

# ---- layout (must match paint_cyclone.py's ring radii)
const BULB_COUNT := 64
const BULB_R := 0.372
const BULB_DOME := 0.0118
const ARCH_TUBE := 0.0105
const COIL_TUBE := 0.009
## Neon groups: 0 green, 1 pink, 2 blue/cyan (the coils take turns); 3 white (arch only).
## Arches: [angle from the front in degrees (+ = player's left), inner foot r, outer foot r,
## height above the field, colour, group]. Feet stand in white collars on the ring.
const ARCHES := [
	[92.0, 0.33, 0.47, 0.13, GREEN, 0],
	[-92.0, 0.33, 0.47, 0.13, PINK, 1],
	[140.0, 0.33, 0.47, 0.12, GREEN, 0],
	[-140.0, 0.33, 0.47, 0.12, CYAN, 2],
	[8.0, 0.265, 0.335, 0.17, PINK, 1],
	[-8.0, 0.265, 0.335, 0.17, WHITE, 3],
]
## A straight neon post at the back: [angle, r, height, colour, group].
const POSTS := [[180.0, 0.31, 0.11, CYAN, 2]]
## Centre coils: [offset (x, z) from the dish centre or "post", radius, bottom y and top y
## above the field, turns, colour, group].
const COILS := [
	[Vector2(-0.115, 0.0), 0.085, -0.02, 0.13, 1.75, GREEN, 0],
	["post", 0.11, -0.01, 0.06, 1.25, PINK, 1],
	[Vector2(0.115, -0.01), 0.08, -0.01, 0.12, 1.5, CYAN, 2],
]

const COMMON := """
uniform float u_lap = 1.2;
uniform float u_tail = 1.3;
uniform float u_chase_t = 5.9;
uniform float u_flash_t = 1.0;
uniform float u_flash_hz = 4.0;
uniform float u_rev_t = 3.1;
uniform float u_rev_lap = 1.0;
uniform float u_count = 64.0;

// 0..1 brightness of ring lamp i at time t
float chase(float i, float head, float dir) {
	float d = mod((head - i) * dir, u_count);    // lamps behind the head
	return d < u_tail * 4.0 ? exp(-max(d - 0.5, 0.0) / u_tail) : 0.0;
}
float in_flash(float t) {
	float ph = mod(t, u_chase_t + u_flash_t + u_rev_t);
	return (ph >= u_chase_t && ph < u_chase_t + u_flash_t) ? 1.0 : 0.0;
}
float flash_beat(float t) {
	float ph = mod(t, u_chase_t + u_flash_t + u_rev_t) - u_chase_t;
	return fract(ph * u_flash_hz) < 0.5 ? 1.0 : 0.0;
}
float ring_level(float i, float t) {
	float ph = mod(t, u_chase_t + u_flash_t + u_rev_t);
	if (ph < u_chase_t) {
		return chase(i, fract(t / u_lap) * u_count, 1.0);
	} else if (ph < u_chase_t + u_flash_t) {
		return flash_beat(t);
	}
	return chase(i, (1.0 - fract(t / u_rev_lap)) * u_count, -1.0);
}
"""

## Ring bulbs (mode 0, index in INSTANCE_CUSTOM.r) and the single lamps (modes 2, 3).
const LAMP_SHADER := """
shader_type spatial;
render_mode cull_back;
%s
uniform int u_mode = 0;           // 0 ring bulb, 2 tower lamp, 3 BONUS lamp
uniform float u_phase = 0.0;      // tower lamps: offset in periods
uniform float u_period = 1.5;
uniform vec3 u_on : source_color = vec3(1.0, 0.8, 0.34);
uniform vec3 u_off : source_color = vec3(0.3, 0.2, 0.08);
uniform float u_energy = 5.0;
varying float v_level;

void vertex() {
	float t = TIME;
	float lvl = 0.0;
	if (u_mode == 0) {
		lvl = ring_level(INSTANCE_CUSTOM.r, t);
	} else if (u_mode == 2) {
		lvl = fract(t / u_period + u_phase) < 0.5 ? 1.0 : 0.0;
	} else {
		lvl = in_flash(t) > 0.5 ? flash_beat(t) : 0.55 + 0.45 * sin(t * 6.2831853 / u_period);
	}
	v_level = lvl;
}

void fragment() {
	float l = v_level;
	// glass over a filament: a hot middle, cooler rim
	float core = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	ALBEDO = mix(u_off, u_on * 0.7, l);
	ROUGHNESS = 0.12;
	SPECULAR = 0.75;
	EMISSION = u_on * (l * u_energy * (0.45 + 0.55 * core * core)) + u_off * 0.08;
}
"""

## Neon tubes: COLOR = the gas colour, UV.x = group (0-3), UV.y = 1 for arches/posts.
const NEON_SHADER := """
shader_type spatial;
render_mode cull_back;
%s
uniform float u_step = 0.5333;
uniform float u_idle = 0.55;
uniform float u_energy = 3.4;
varying float v_level;

void vertex() {
	float t = TIME;
	float group = UV.x;
	float seq = mod(floor(t / u_step), 3.0);
	float on = abs(seq - group) < 0.5 ? 1.0 : 0.0;
	float lvl = on;
	if (UV.y > 0.5) {
		if (group > 2.5) {
			// the white arch breathes with the whole three-step round
			on = 0.5 + 0.5 * sin(t * 6.2831853 / (u_step * 3.0));
		}
		lvl = u_idle + (1.0 - u_idle) * on;
		if (in_flash(t) > 0.5) {
			lvl = flash_beat(t) > 0.5 ? 1.0 : 0.15;
		}
	}
	v_level = lvl;
}

void fragment() {
	float l = v_level;
	vec3 col = COLOR.rgb;
	// unlit: milky glass faintly tinted; lit: the gas colour
	vec3 glass = vec3(0.62, 0.64, 0.68) * mix(vec3(1.0), col, 0.3);
	ALBEDO = mix(glass, col * 0.85, l);
	ROUGHNESS = 0.18;
	SPECULAR = 0.6;
	float core = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	EMISSION = col * (l * u_energy * (0.6 + 0.4 * core)) + col * 0.015;
}
"""

var _common_uniforms := {}

## Builds the bulbs, neon, collars and lamps from the "layout" meta (see the file header).
## PRIZES (Nov 3): games, inc.'s 2026 copy is a little dimmer (meta "dim", set by cyclone.gd's build).
func _dim() -> float:
	return float(get_meta("dim", 1.0))

func _ready() -> void:
	if not has_meta("layout"):
		push_warning("CycloneLights: no layout meta")
		return
	var lay: Dictionary = get_meta("layout")
	var centre: Vector3 = lay.get("centre", Vector3(0, 0.95, -0.70))
	var fy: float = float(lay.get("field_y", centre.y))
	var dish_y: float = float(lay.get("dish_y", fy - 0.05))
	var post: Vector3 = lay.get("post", centre)
	_common_uniforms = {"u_lap": CHASE_LAP_S, "u_tail": CHASE_TAIL, "u_chase_t": CHASE_PHASE_S,
		"u_flash_t": FLASH_PHASE_S, "u_flash_hz": FLASH_HZ, "u_rev_t": REVERSE_PHASE_S,
		"u_rev_lap": REVERSE_LAP_S, "u_count": float(BULB_COUNT)}
	_build_bulbs(centre, fy)
	_build_neon(centre, fy, dish_y, post)
	for l in lay.get("lamps", []):
		_build_lamp(l)

## Point on the playfield ring: angle th (degrees from the front, + = player's left), radius r.
static func ring_point(centre: Vector3, th: float, r: float, y: float) -> Vector3:
	var t := deg_to_rad(th)
	return Vector3(centre.x - sin(t) * r, y, centre.z + cos(t) * r)

func _shader(code: String) -> Shader:
	var sh := Shader.new()
	sh.code = code % COMMON
	return sh

func _material(sh: Shader, extra: Dictionary) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = sh
	for k in _common_uniforms:
		m.set_shader_parameter(k, _common_uniforms[k])
	for k in extra:
		m.set_shader_parameter(k, extra[k])
	return m

## The ring of 64 lamps: one MultiMesh of glass domes, lamp index in the custom data.
func _build_bulbs(centre: Vector3, fy: float) -> void:
	var dome := low_dome(BULB_DOME, BULB_DOME * 1.05, 8, 2)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = dome
	mm.instance_count = BULB_COUNT
	for i in BULB_COUNT:
		var p := ring_point(centre, 360.0 * i / BULB_COUNT, BULB_R, fy)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))
		mm.set_instance_custom_data(i, Color(float(i), 0, 0, 0))
	var mi := MultiMeshInstance3D.new()
	mi.name = "Bulbs"
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = _material(_shader(LAMP_SHADER), {"u_mode": 0, "u_on": BULB_ON, "u_off": BULB_OFF, "u_energy": _dim() * BULB_ENERGY})
	add_child(mi)

## Neon arches, the back post and the centre coils (one mesh, one material), and the
## white collars the arch feet stand in.
func _build_neon(centre: Vector3, fy: float, dish_y: float, post: Vector3) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var feet: Array[Vector3] = []
	for a in ARCHES:
		var th: float = a[0]
		var p_in := ring_point(centre, th, a[1], fy)
		var p_out := ring_point(centre, th, a[2], fy)
		var ra: float = (float(a[2]) - float(a[1])) * 0.5
		var leg: float = float(a[3]) - ra
		var mid := (p_in + p_out) * 0.5
		var out_dir := (p_out - p_in).normalized()
		var pts: Array[Vector3] = []
		for k in 4:
			pts.append(p_in + Vector3.UP * leg * k / 3.0)
		for k in range(1, 16):
			var ang := PI * k / 16.0
			pts.append(mid + Vector3.UP * leg - out_dir * cos(ang) * ra + Vector3.UP * sin(ang) * ra)
		for k in 4:
			pts.append(p_out + Vector3.UP * leg * (3 - k) / 3.0)
		_tube(st, pts, ARCH_TUBE, a[4], a[5], 1.0)
		feet.append(p_in); feet.append(p_out)
	for p in POSTS:
		var base := ring_point(centre, p[0], p[1], fy)
		var top := base + Vector3.UP * float(p[2])
		var pts: Array[Vector3] = [base, base.lerp(top, 0.5), top, top + Vector3.UP * ARCH_TUBE * 0.9]
		_tube(st, pts, ARCH_TUBE * 1.1, p[3], p[4], 1.0)
		feet.append(base)
	for c in COILS:
		var cc: Vector3
		if c[0] is String:
			cc = Vector3(post.x, 0, post.z)
		else:
			cc = Vector3(centre.x + c[0].x, 0, centre.z - c[0].y)
		var r: float = c[1]
		var y0: float = fy + float(c[2])
		var y1: float = fy + float(c[3])
		var turns: float = c[4]
		var n := int(turns * 28)
		var pts: Array[Vector3] = []
		var first := cc + Vector3(r, 0, 0)
		pts.append(Vector3(first.x, dish_y - 0.01, first.z))
		for k in n + 1:
			var t := float(k) / n
			var ang := TAU * turns * t
			pts.append(cc + Vector3(cos(ang) * r, lerp(y0, y1, t), sin(ang) * r))
		var last := pts[pts.size() - 1]
		pts.append(Vector3(last.x, lerp(last.y, dish_y, 0.5), last.z))
		pts.append(Vector3(last.x, dish_y - 0.01, last.z))
		_tube(st, pts, COIL_TUBE, c[5], c[6], 0.0)
	var mi := MeshInstance3D.new()
	mi.name = "Neon"
	mi.mesh = st.commit()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = _material(_shader(NEON_SHADER), {"u_step": NEON_STEP_S, "u_idle": ARCH_IDLE, "u_energy": _dim() * NEON_ENERGY})
	add_child(mi)
	# white moulded collars under the arch feet
	var cm := low_collar(0.019, 0.016, 0.016, 8)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#ece8de")
	mat.roughness = 0.35
	cm.surface_set_material(0, mat)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cm
	mm.instance_count = feet.size()
	for i in feet.size():
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, feet[i]))
	var ci := MultiMeshInstance3D.new()
	ci.name = "Collars"
	ci.multimesh = mm
	add_child(ci)

## Appends a smooth tube through pts to st: COLOR = gas colour, UV = (group, is_arch).
func _tube(st: SurfaceTool, pts: Array[Vector3], r: float, col: Color, group: int, arch: float) -> void:
	var seg := 6
	var rings: Array = []
	var normals: Array = []
	var prev_u := Vector3.ZERO
	for i in pts.size():
		var t := (pts[mini(i + 1, pts.size() - 1)] - pts[maxi(i - 1, 0)]).normalized()
		var u := prev_u
		if u == Vector3.ZERO or absf(u.dot(t)) > 0.95:
			u = t.cross(Vector3.UP if absf(t.y) < 0.9 else Vector3.RIGHT).normalized()
		u = (u - t * u.dot(t)).normalized()
		prev_u = u
		var v := t.cross(u).normalized()
		var ring: Array[Vector3] = []
		var rn: Array[Vector3] = []
		for k in seg + 1:
			var ang := TAU * k / seg
			var d := u * cos(ang) + v * sin(ang)
			ring.append(pts[i] + d * r)
			rn.append(d)
		rings.append(ring)
		normals.append(rn)
	var uv := Vector2(float(group), arch)
	for i in pts.size() - 1:
		for k in seg:
			var quad := [[i, k], [i, k + 1], [i + 1, k + 1], [i + 1, k]]
			for tri in [[0, 2, 1], [0, 3, 2]]:
				for j in tri:
					var a: Array = quad[j]
					st.set_color(col)
					st.set_uv(uv)
					st.set_normal(normals[a[0]][a[1]])
					st.add_vertex(rings[a[0]][a[1]])

## A low-poly glass dome (base on y = 0): `seg` sides, `bands` latitude bands, height h.
static func low_dome(r: float, h: float, seg: int, bands: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in bands:
		var a0 := PI * 0.5 * j / bands
		var a1 := PI * 0.5 * (j + 1) / bands
		for i in seg:
			var t0 := TAU * i / seg
			var t1 := TAU * (i + 1) / seg
			var p := func(t: float, a: float) -> Vector3: return Vector3(cos(t) * cos(a) * r, sin(a) * h, sin(t) * cos(a) * r)
			var nr := func(t: float, a: float) -> Vector3: return Vector3(cos(t) * cos(a) / r, sin(a) / h, sin(t) * cos(a) / r).normalized()
			var quad := [[t0, a0], [t1, a0], [t1, a1], [t0, a1]]
			var tris := [[0, 1, 2], [0, 2, 3]] if j < bands - 1 else [[0, 1, 3]]
			for tr in tris:
				for k in tr:
					var q: Array = quad[k]
					st.set_normal(nr.call(q[0], q[1]))
					st.add_vertex(p.call(q[0], q[1]))
	return st.commit()

## A low-poly moulded collar: a tapered ring with a flat top (base on y = 0).
static func low_collar(r0: float, r1: float, h: float, seg: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in seg:
		var t0 := TAU * i / seg
		var t1 := TAU * (i + 1) / seg
		var d0 := Vector3(cos(t0), 0, sin(t0))
		var d1 := Vector3(cos(t1), 0, sin(t1))
		var v := [d0 * r0, d1 * r0, d1 * r1 + Vector3.UP * h, d0 * r1 + Vector3.UP * h]
		var n := [d0, d1, d1, d0]
		for k in [0, 1, 2, 0, 2, 3]:
			st.set_normal(n[k]); st.add_vertex(v[k])
		for k in [[Vector3.UP * h, Vector3.UP], [v[2], Vector3.UP], [v[3], Vector3.UP]]:
			st.set_normal(k[1]); st.add_vertex(k[0])
	return st.commit()

## One single lamp dome: the towers' orange lamps and the BONUS lamp.
func _build_lamp(l: Dictionary) -> void:
	var role := str(l.get("role", ""))
	var n: Vector3 = Vector3(l.get("n", Vector3.UP)).normalized()
	var pos: Vector3 = l.get("pos", Vector3.ZERO)
	var dome := SphereMesh.new()
	dome.is_hemisphere = true
	dome.radial_segments = 14
	dome.rings = 4
	var extra := {"u_on": LAMP_ORANGE, "u_off": Color(0.32, 0.10, 0.03), "u_energy": _dim() * LAMP_ENERGY}
	if role == "bonus":
		dome.radius = 0.022
		dome.height = 0.044
		extra["u_mode"] = 3
		extra["u_period"] = BONUS_PULSE_S
		extra["u_on"] = Color(1.0, 0.55, 0.12)
	else:
		dome.radius = 0.030
		dome.height = 0.060
		extra["u_mode"] = 2
		extra["u_period"] = TOWER_PERIOD_S
		extra["u_phase"] = 0.0 if role == "tower_l" else 0.5
	var mi := MeshInstance3D.new()
	mi.name = "Lamp_" + role
	mi.mesh = dome
	# the dome's up axis along n, squashed into a lens
	var y := n
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y).normalized()
	mi.transform = Transform3D(Basis(x, y * 0.6, z), pos)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.material_override = _material(_shader(LAMP_SHADER), extra)
	add_child(mi)
