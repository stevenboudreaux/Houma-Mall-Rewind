// Workstream M (design/godot-menu.md): the time-travel transition's look. Since MENU2 (Nov 3) it is
// driven by envelope values the script computes from the time since the trip began
// (scripts/timetravel.gd env()): amt (the ripple, twist, split and washes), ph (the phase, always
// running), flash (the light flashes), vort (the vortex tunnel that covers the reload) and dark (a
// fade to black). web/shell.html runs a word-for-word copy of this file in WebGL over the page
// reload (TT_FRAG there), on a picture of the screen, so keep the two the same when re-dressing it.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;   // kept for old callers; unused
uniform float amt = 0.0;
uniform float ph = 0.0;
uniform float flash = 0.0;
uniform float vort = 0.0;
uniform float dark = 0.0;
uniform float forward = 1.0;        // 1 travelling forward in time (1995 -> 2026), -1 back
uniform vec3 tint_a : source_color = vec3(1.0, 0.72, 0.30);   // warm
uniform vec3 tint_b : source_color = vec3(0.35, 0.80, 1.00);  // cold
uniform vec3 tint_c : source_color = vec3(0.95, 0.40, 0.95);  // magenta

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 c = uv - vec2(0.5);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 cc = vec2(c.x / aspect, c.y);
	float r = length(cc);
	// a ripple running out from the middle, and a slow twist
	float wave = sin(r * 38.0 - ph * 40.0 * forward) * 0.012 * amt;
	float ang = amt * 0.35 * (1.0 - r) * forward + vort * 1.2 * (1.0 - smoothstep(0.0, 0.6, r)) * forward;
	mat2 rot = mat2(vec2(cos(ang), -sin(ang)), vec2(sin(ang), cos(ang)));
	vec2 q = rot * c * (1.0 - 0.06 * amt - 0.25 * vort) + normalize(c + 1e-5) * wave + 0.5;
	// chromatic split, widening with the distortion
	float split = 0.012 * amt;
	vec3 col;
	col.r = texture(screen_tex, q + normalize(c + 1e-5) * split).r;
	col.g = texture(screen_tex, q).g;
	col.b = texture(screen_tex, q - normalize(c + 1e-5) * split).b;
	// colour washes that cycle through the three tints
	float cyc = fract(ph * 3.0 + r * 0.6 * forward);
	vec3 wash = mix(mix(tint_a, tint_b, smoothstep(0.0, 0.5, cyc)), tint_c, smoothstep(0.5, 1.0, cyc));
	col = mix(col, col * 0.4 + wash * 0.8, amt * 0.55);
	// scan bands sweeping down
	float band = smoothstep(0.92, 1.0, sin((uv.y + ph * 3.0) * 60.0)) * amt * 0.35;
	col += wash * band;
	// the vortex: a tunnel of spiralling bands in the three tints, falling inward, the world still
	// glimpsed through its eye
	float a = atan(cc.y, cc.x);
	float depth = 0.3 / (r + 0.06);
	float tw = a / 6.2832 + depth * 0.2 * forward + ph * 0.3 * forward;
	float s1 = 0.5 + 0.5 * sin(tw * 6.2832 * 6.0);
	float s2 = 0.5 + 0.5 * sin((depth - ph * 2.4) * 6.2832);
	float cyc2 = fract(depth * 0.35 - ph * 0.8);
	vec3 wash2 = mix(mix(tint_a, tint_b, smoothstep(0.0, 0.5, cyc2)), tint_c, smoothstep(0.5, 1.0, cyc2));
	vec3 vc = mix(tint_b * 0.12, wash2, s1 * 0.85) * (0.45 + 0.55 * s2) + wash2 * pow(s1 * s2, 6.0) * 0.8;
	vc += vec3(1.0, 0.97, 0.9) * (1.0 - smoothstep(0.0, 0.12, r)) * 0.7;
	col = mix(col, vc, clamp(vort * (0.3 + 0.7 * smoothstep(0.04, 0.32, r)), 0.0, 1.0));
	// flashes of light
	col = mix(col, vec3(1.0, 0.97, 0.9), clamp(flash, 0.0, 1.0));
	// the edges darken, then (dark) everything goes to black
	col *= 1.0 - smoothstep(0.35, 0.95, r) * max(amt, vort) * 0.8;
	col *= 1.0 - dark;
	COLOR = vec4(col, 1.0);
}
