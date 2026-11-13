## Runtime looks that don't need a re-bake:
## - Floors: a procedural terrazzo shader (hall checker bands, plank-laid store
##   lanes, court fields with borders) driven by per-zone parameters stored on
##   each floor material, plus a mirrored-camera reflection for the polish.
## - Store side walls: shelving with merchandise.
## The baked lightmap still lights everything; these only change surface colour.
extends Node

@export var scale := 0.5          # reflection resolution vs. the screen
@export var strength := 0.6
## bake-look (design/godot-bake-quality.md): the floor's specular share, i.e. how much it reflects the
## hall ReflectionProbes and the sky. 0 since FLOOR-FIX (Nov 11 2026,
## design/godot-floor-lighting-diagnosis.md "Fix shipped"): at 0.25 (Demos 51-53) those reflections showed
## as patches that slid across the floor as the player walked. The polish now comes from the mirror alone.
## On the web ?floorspec=0.25 brings the old look back for comparison.
@export var floor_spec := 0.0
var vp: SubViewport
var mcam: Camera3D
var floor_mats := []

const FLOOR := """
shader_type spatial;
render_mode specular_schlick_ggx;
uniform sampler2D refl_tex : source_color, filter_linear, repeat_disable;
uniform int pattern = 0;       // 0 plank field, 1 hall, 2 court
uniform int axis = 0;          // hall: 0 runs along x, 1 along z
uniform float center = 0.0;    // hall centre line (across coordinate)
uniform float half_w = 6.0;    // hall half width
uniform int medallions = 0;
uniform vec4 court = vec4(0.0, 0.0, 8.0, 8.0);  // cx, cz, hx, hz
uniform int palette = 0;       // court: 0 taupe, 1 blue-grey (Dillard's), 2 terracotta (Sears), 3 sage (Shoe Dept.), 4 terracotta straight (JCPenney)
uniform float strength = 0.5;
uniform float refl_clamp = 1.5;
uniform vec2 px = vec2(0.002, 0.003);
// bake-look (design/godot-bake-quality.md): how much the floor takes from the hall ReflectionProbes.
// The probes' box-projected picture of the shop grilles shows as pale streaks and hard-edged patches
// on the floor, and where no probe reaches the floor shows the sky as a glow ahead of the camera; both
// move with the view. 0 (since FLOOR-FIX, Nov 11 2026) leaves the polish to the mirror below.
// 0.25 = Demos 51-53 (?floorspec=0.25 for the old look).
uniform float floor_spec = 0.0;
varying vec3 wpos;

void vertex() { wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }

// anti-aliased line mask: 1 on a line of half-width w at integer values of t
float lines(float t, float w) {
	float d = abs(t - round(t));
	float fw = fwidth(t);
	return 1.0 - smoothstep(w, w + fw * 1.2, d);
}
// ---- bake-look (Nov 4 2026, design/godot-bake-quality.md): anti-aliased edges. 1 where x < e,
// 0 where x > e, blended over one pixel's footprint, so the band, border, inlay and medallion edges
// no longer step in pixels ("the floors pixelate"). aa_on = 0 gives the old hard edges.
uniform int aa_on = 1;
float inside(float x, float e) {
	if (aa_on == 0) return x < e ? 1.0 : 0.0;
	float fw = max(fwidth(x), 1e-4) * 0.75;
	return 1.0 - smoothstep(e - fw, e + fw, x);
}
// 1 on |x - c| < w, anti-aliased
float near(float x, float c, float w) { return inside(abs(x - c), w); }
// ---- end bake-look
// filtered checkerboard (0/1) on a diagonal grid
float diag_checker(vec2 p, float period) {
	vec2 q = vec2(p.x + p.y, p.x - p.y) / period;
	vec2 w = fwidth(q) + 1e-4;
	vec2 i = 2.0 * (abs(fract((q - 0.5 * w) * 0.5) - 0.5) - abs(fract((q + 0.5 * w) * 0.5) - 0.5)) / w;
	return 0.5 - 0.5 * i.x * i.y;
}
vec3 planks(float across, float along) {
	float col = floor(across / 0.30);
	float shift = mod(col, 2.0) * 0.30;
	float row = floor((along + shift) / 0.60);
	float tone = hash(vec2(col, row));
	vec3 c = vec3(0.851, 0.780, 0.659) * (0.94 + 0.08 * tone);
	float g = max(lines(across / 0.30, 0.012), lines((along + shift) / 0.60, 0.007));
	return mix(c, vec3(0.66, 0.59, 0.49), g * 0.85);
}

void fragment() {
	vec3 a;
	if (pattern == 1) {
		float across = (axis == 0 ? wpos.z : wpos.x) - center;
		float along = axis == 0 ? wpos.x : wpos.z;
		float band = half_w * 0.5;
		float d = abs(across);
		vec2 p = axis == 0 ? vec2(along, across) : vec2(across, along);
		// bake-look: the three bands blended across their edges (was: if / else if / else)
		float k = diag_checker(p, 0.75);
		vec3 a1 = mix(vec3(0.561, 0.486, 0.400), vec3(0.937, 0.902, 0.824), k);
		vec2 q = vec2(p.x + p.y, p.x - p.y) / 0.75;
		a1 = mix(a1, vec3(0.725, 0.671, 0.580), max(lines(q.x, 0.008), lines(q.y, 0.008)) * 0.7);
		a = planks(across + 50.0, along);
		a = mix(a, vec3(0.227, 0.216, 0.204), inside(d, band + 0.18));
		a = mix(a, a1, inside(d, band));
		if (medallions == 1) {
			float lane = band + 0.18 + (half_w - band - 0.18) * 0.5;
			float m = abs(d - lane) + abs(mod(along, 9.0) - 4.5);
			vec3 mc = mix(vec3(0.227, 0.216, 0.204), vec3(0.788, 0.541, 0.451), inside(m, 0.45));
			mc = mix(mc, vec3(0.227, 0.216, 0.204), inside(m, 0.18));
			a = mix(a, mc, inside(m, 0.47));
		}
	} else if (pattern == 2) {
		vec2 c = wpos.xz - court.xy;
		vec2 h = court.zw;
		float m0 = 1.6;
		float bw = 0.9;
		float d = min(h.x - abs(c.x), h.y - abs(c.y)) - m0;
		vec3 c1 = vec3(0.914, 0.890, 0.827);
		vec3 c2 = palette == 1 ? vec3(0.490, 0.557, 0.639) : palette == 2 ? vec3(0.722, 0.420, 0.322) : palette == 3 ? vec3(0.478, 0.588, 0.529) : palette == 4 ? vec3(0.690, 0.380, 0.290) : vec3(0.561, 0.486, 0.400);
		// bake-look: field, border and plank lane blended across their edges (was: if / else if / else)
		vec3 af;
		if (palette == 4) {
			// JCPenney court: a straight (not diagonal) checker
			vec2 q4 = c / 0.8;
			vec2 w4 = fwidth(q4) + 1e-4;
			vec2 i4 = 2.0 * (abs(fract((q4 - 0.5 * w4) * 0.5) - 0.5) - abs(fract((q4 + 0.5 * w4) * 0.5) - 0.5)) / w4;
			af = mix(c2, c1, 0.5 - 0.5 * i4.x * i4.y);
			af = mix(af, vec3(0.714, 0.698, 0.651), max(lines(q4.x, 0.01), lines(q4.y, 0.01)) * 0.6);
		} else {
			float k = diag_checker(c, 0.8);
			af = mix(c2, c1, k);
			vec2 q = vec2(c.x + c.y, c.x - c.y) / 0.8;
			af = mix(af, vec3(0.714, 0.698, 0.651), max(lines(q.x, 0.01), lines(q.y, 0.01)) * 0.6);
		}
		vec3 ab = vec3(0.231, 0.227, 0.239);
		float along = (h.x - abs(c.x) < h.y - abs(c.y)) ? c.y : c.x;
		float t = mod(along, 1.5) - 0.75;
		float across2 = d - bw * 0.5;
		ab = mix(ab, vec3(0.925, 0.894, 0.816), inside(abs(t) + abs(across2), 0.26));
		ab = mix(ab, vec3(0.847, 0.816, 0.741), max(near(d, 0.05, 0.02), near(d, bw - 0.05, 0.02)));
		a = planks(c.x + 50.0, c.y);
		a = mix(a, ab, 1.0 - inside(d, 0.0));
		a = mix(a, af, 1.0 - inside(d, bw));
	} else {
		a = planks(wpos.x + 50.0, wpos.z);
	}

	// Polished-floor reflection (mirrored camera). Kept subtle on purpose:
	// a 9-tap blur hides aliasing in the half-res mirror image, bright sources
	// are clamped so windows and sky can't wash the floor out, and it fades
	// with distance so far floor doesn't turn milky.
	vec2 ruv = vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y);
	vec3 r = vec3(0.0);
	float wsum = 0.0;
	for (int i = -1; i <= 1; i++) {
		for (int j = -1; j <= 1; j++) {
			float w = (i == 0 ? 2.0 : 1.0) * (j == 0 ? 2.0 : 1.0);
			r += min(texture(refl_tex, ruv + vec2(float(i) * px.x, float(j) * px.y * 1.6)).rgb, vec3(refl_clamp)) * w;
			wsum += w;
		}
	}
	r /= wsum;
	float ndv = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fres = 0.04 + 0.96 * pow(1.0 - ndv, 5.0);
	float k = mix(0.12, 0.55, fres) * strength;
	float dist = length(VERTEX);
	k *= clamp(1.0 - (dist - 14.0) / 30.0, 0.25, 1.0);
	float lum = dot(a, vec3(0.3, 0.59, 0.11));
	k *= mix(1.25, 0.55, lum);   // dark tiles mirror more, as real terrazzo does
	ALBEDO = a * (1.0 - k * 0.35);
	ROUGHNESS = 0.35;
	SPECULAR = floor_spec;   // FLOOR-FIX: 0, no probe or sky reflection (was 0.25)
	EMISSION = r * k;
}
"""

const INTERIOR := """
shader_type spatial;
uniform sampler2D shelf_tex : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 wpos;
varying vec3 wnrm;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}
void fragment() {
	vec3 base = vec3(0.925, 0.902, 0.855);
	if (abs(wnrm.y) < 0.5) {
		float u = abs(wnrm.x) > 0.5 ? wpos.z : wpos.x;
		vec3 t = texture(shelf_tex, vec2(u / 3.4, 1.0 - wpos.y / 3.2)).rgb;
		base = mix(t, vec3(dot(t, vec3(0.3, 0.59, 0.11))), 0.3) * 0.9;
	}
	ALBEDO = base;
	ROUGHNESS = 0.9;
}
"""

## The web page ships two builds of the game: textures in computer GPU formats (S3TC and
## BPTC) or in phone and headset ones (ETC2 and ASTC), and web/shell.html picks one before
## the engine starts. If it guessed wrong for this GPU, switch to the other build once and
## remember the choice in this browser.
## bake-look: the floor's specular share, from ?floorspec= on the web, else floor_spec.
func _floor_spec() -> float:
	if OS.has_feature("web"):
		var q := str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('floorspec') || ''"))
		if q.is_valid_float():
			return clampf(float(q), 0.0, 1.0)
	return floor_spec

func _check_pack() -> void:
	if not OS.has_feature("web"):
		return
	var kind := str(JavaScriptBridge.eval("window.__mallPack || ''", true))
	if kind == "":
		return
	var desk := OS.has_feature("s3tc") and OS.has_feature("bptc")
	var mob := OS.has_feature("etc2") and OS.has_feature("astc")
	var ok := desk if kind == "desktop" else mob
	var other := "mobile" if kind == "desktop" else "desktop"
	var other_ok := mob if kind == "desktop" else desk
	if not ok and other_ok:
		JavaScriptBridge.eval("try{if(!sessionStorage.getItem('southland-pack-flip')){sessionStorage.setItem('southland-pack-flip','1');localStorage.setItem('southland-pack','%s');location.reload();}}catch(e){}" % other, true)

func _ready() -> void:
	_check_pack()
	# ---- workstream H (Nov 1 2026, design/godot-performance.md): web/shell.html keeps the loading
	# card up until window.__mallWarm == 1. scripts/npc_warmup.gd sets 0 while it warms the shoppers
	# (added by player.gd with call_deferred); a wing without shoppers says ready right after: a
	# call deferred from a deferred call runs after every call deferred before it, in the same flush.
	if OS.has_feature("web"):
		var say_ready := func(): JavaScriptBridge.eval("if (window.__mallWarm === undefined) window.__mallWarm = 1;", true)
		(func(): say_ready.call_deferred()).call_deferred()
	# ---- end workstream H
	vp = SubViewport.new()
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.positional_shadow_atlas_size = 0
	add_child(vp)
	mcam = Camera3D.new()
	vp.add_child(mcam)
	mcam.current = true
	var fsh := Shader.new()
	fsh.code = FLOOR
	var ish := Shader.new()
	ish.code = INTERIOR
	var imat := ShaderMaterial.new()
	imat.shader = ish
	imat.set_shader_parameter("shelf_tex", load("res://tex/int_side.png"))
	# ---- SEAMLESS (Nov 13 2026, scripts/wing_stream.gd): the floor and side-wall materials are kept, so a
	# wing streamed in beside this one gets the same ones (adopt)
	_fsh = fsh; _imat = imat
	adopt(get_tree().current_scene, false)
	_resize()
	get_viewport().size_changed.connect(_resize)

var _fsh: Shader
var _imat: ShaderMaterial
var _fcache := {}

## Give the meshes under `root` this runtime's floor shader and store side walls: the scene itself at
## start, and each wing scripts/wing_stream.gd brings in.
func adopt(root: Node, late := true) -> void:
	var fsh := _fsh
	var imat := _imat
	var cache := _fcache
	for mi in _meshes(root):
		var m: Mesh = mi.mesh
		for i in m.get_surface_count():
			var sm := m.surface_get_material(i)
			if sm == null:
				continue
			if sm.resource_name.begins_with("floorz_") and sm.has_meta("floor"):
				if not cache.has(sm.resource_name):
					var f: Dictionary = sm.get_meta("floor")
					var s := ShaderMaterial.new()
					s.shader = fsh
					s.set_shader_parameter("refl_tex", vp.get_texture())
					s.set_shader_parameter("strength", strength)
					s.set_shader_parameter("pattern", int(f.get("pattern", 0)))
					s.set_shader_parameter("axis", int(f.get("axis", 0)))
					s.set_shader_parameter("center", float(f.get("center", 0.0)))
					s.set_shader_parameter("half_w", float(f.get("half", 6.0)))
					s.set_shader_parameter("medallions", int(f.get("medallions", 0)))
					s.set_shader_parameter("court", Vector4(f.get("cx", 0.0), f.get("cz", 0.0), f.get("hx", 8.0), f.get("hz", 8.0)))
					s.set_shader_parameter("palette", int(f.get("palette", 0)))
					s.set_shader_parameter("floor_spec", _floor_spec())
					cache[sm.resource_name] = s
					floor_mats.append(s)
				mi.set_surface_override_material(i, cache[sm.resource_name])
			elif sm.resource_name == "int_wall":
				mi.set_surface_override_material(i, imat)
	if late:
		set_reflections(refl_on)
		_resize()
# ---- end SEAMLESS

func _meshes(n: Node) -> Array:
	var out := []
	if n is MeshInstance3D and n.mesh:
		out.append(n)
	for c in n.get_children():
		out += _meshes(c)
	return out

var refl_on := true
var mode := "night"

## Night (default) or day: swaps the baked lightmap, sky and light set.
func set_time(m: String) -> void:
	mode = m
	load("res://scripts/time_of_day.gd").apply(get_tree().current_scene, m)
	_env_base = null
	# the ribbed vaults glow softly at night instead of reading as a lit ceiling
	set_reflections(refl_on)

# ---- lighting through the day (Steven, Oct 15 2026: "a sliding scale to control lighting
# throughout the day"). There are only two bakes, day and night, so the hour picks the bake
# and then shapes the look on top of it without a rebake: exposure and sky follow the sun's
# height (brightest at noon, warmer and dimmer toward morning and evening), and the night bake
# gets a dusk sky either side of dark. Brightness scales the exposure. At the presets in
# scripts/lighting.json (noon and 10 pm at 100 %) the look is exactly the bake as it shipped.
var hour := 22.0
var bright := 1.0
var _env_base = null     # the unmodified Environment of the current bake
var LIGHT := {}

## scripts/lighting.json: everyone's defaults and the curve's knobs.
func lighting() -> Dictionary:
	if LIGHT.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/lighting.json"))
		LIGHT = j if j is Dictionary else {}
	return LIGHT

## The day or night preset from scripts/lighting.json.
func set_preset(night: bool) -> void:
	var L := lighting()
	if night:
		set_clock(float(L.get("night_hour", 22.0)), float(L.get("night_brightness", 1.0)))
	else:
		set_clock(float(L.get("day_hour", 12.0)), float(L.get("day_brightness", 1.0)))

## Which bake an hour uses.
func mode_at(h: float) -> String:
	var L := lighting()
	if bool(L.get("day_only", false)): return "day"
	return "day" if h >= float(L.get("day_from", 6.5)) and h < float(L.get("day_to", 18.75)) else "night"

## Light the mall for hour h (5-24, 12 = noon) at brightness b (1 = as baked).
func set_clock(h: float, b: float) -> void:
	var L := lighting()
	if bool(L.get("day_only", false)):
		# day lighting only for now (Steven, Oct 16 2026): the clock stays inside the day bake's hours
		h = clampf(h, float(L.get("day_from", 6.5)), float(L.get("day_to", 18.75)) - 0.01)
	hour = h; bright = b
	var m := mode_at(h)
	if m != mode or _env_base == null:
		set_time(m)
	var env_node = get_tree().current_scene.get_node_or_null("Env")
	if env_node == null:
		return
	if _env_base == null:
		_env_base = env_node.environment
		var e: Environment = _env_base.duplicate()
		if _env_base.sky:
			e.sky = _env_base.sky.duplicate()
			e.sky.sky_material = _env_base.sky.sky_material.duplicate()
		env_node.environment = e
	var base: Environment = _env_base
	var env: Environment = env_node.environment
	var exp_k := 1.0
	var sky_k := 1.0
	var top_to = null; var hor_to = null; var w := 0.0
	if m == "day":
		# the sun's height: 0 at 6 am and 6 pm, 1 at noon
		var sun := clampf(sin(PI * (h - 6.0) / 12.0), 0.0, 1.0)
		exp_k = lerpf(float(L.get("low_sun_exposure", 0.8)), 1.0, sun)
		sky_k = lerpf(float(L.get("low_sun_sky", 0.55)), 1.0, sun)
		w = pow(1.0 - sun, 2.0) * 0.85
		top_to = L.get("warm_top", [0.52, 0.56, 0.78]); hor_to = L.get("warm_horizon", [1.0, 0.64, 0.42])
	else:
		# dusk and dawn: how close to the day bake, 1 at the switch, 0 when fully dark
		var dh := float(L.get("dusk_hours", 1.75))
		var from := float(L.get("day_from", 6.5)); var to := float(L.get("day_to", 18.75))
		var k := 0.0
		if h >= to:
			k = 1.0 - (h - to) / dh
		elif h < from:
			k = 1.0 - (from - h) / dh
		k = clampf(k, 0.0, 1.0)
		exp_k = 1.0 + 0.12 * k
		sky_k = 1.0 + 0.8 * k
		w = k
		top_to = L.get("dusk_top", [0.17, 0.19, 0.40]); hor_to = L.get("dusk_horizon", [0.62, 0.38, 0.40])
	env.tonemap_exposure = base.tonemap_exposure * exp_k * b
	var bm = base.sky.sky_material if base.sky else null
	var em = env.sky.sky_material if env.sky else null
	if bm is ProceduralSkyMaterial and em is ProceduralSkyMaterial:
		em.sky_energy_multiplier = bm.sky_energy_multiplier * sky_k
		em.sky_top_color = bm.sky_top_color.lerp(Color(top_to[0], top_to[1], top_to[2]), w)
		em.sky_horizon_color = bm.sky_horizon_color.lerp(Color(hor_to[0], hor_to[1], hor_to[2]), w)
		em.ground_horizon_color = bm.ground_horizon_color.lerp(Color(hor_to[0], hor_to[1], hor_to[2]), w * 0.5)

func _set_emission(mat_name: String, e: float) -> void:
	for mi in _meshes(get_tree().current_scene):
		for i in mi.mesh.get_surface_count():
			var sm = mi.mesh.surface_get_material(i)
			if sm is StandardMaterial3D and sm.resource_name == mat_name:
				sm.emission_energy_multiplier = e

## Turn the floor reflection on or off (it costs a second render of the scene).
func set_reflections(on: bool) -> void:
	refl_on = on
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if on else SubViewport.UPDATE_DISABLED
	var st := strength * 1.2 if mode == "night" else strength * 0.7
	for m in floor_mats:
		m.set_shader_parameter("strength", st if on else 0.0)

func _resize() -> void:
	var s := get_viewport().get_visible_rect().size
	vp.size = Vector2i(max(64, int(s.x * scale)), max(64, int(s.y * scale)))
	for m in floor_mats:
		m.set_shader_parameter("px", Vector2(1.5 / vp.size.x, 2.0 / vp.size.y))

func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or cam == mcam:
		return
	var t := cam.global_transform
	var S := Basis(Vector3(1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, 1))
	var b := S * t.basis
	b.y = -b.y
	mcam.global_transform = Transform3D(b, Vector3(t.origin.x, -t.origin.y, t.origin.z))
	mcam.fov = cam.fov
	mcam.near = cam.near
	mcam.far = cam.far
