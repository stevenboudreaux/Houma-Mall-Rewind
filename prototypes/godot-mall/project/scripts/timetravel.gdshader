// Workstream M (design/godot-menu.md): the time-travel transition's look, driven by "progress"
// (0 -> 1 over the scene's duration, scripts/timetravel.gd). Light and colour flashes, a ripple
// and a chromatic split over the frame, then a fade to black for the reload. Re-dress freely: the
// script only sets progress, from_year and to_year.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_linear;
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float forward = 1.0;        // 1 travelling forward in time (1995 -> 2026), -1 back
uniform vec3 tint_a : source_color = vec3(1.0, 0.72, 0.30);   // warm
uniform vec3 tint_b : source_color = vec3(0.35, 0.80, 1.00);  // cold
uniform vec3 tint_c : source_color = vec3(0.95, 0.40, 0.95);  // magenta

float pulse(float t, float at, float w) {
	float d = (t - at) / w;
	return exp(-d * d);
}

void fragment() {
	float p = progress;
	vec2 uv = SCREEN_UV;
	vec2 c = uv - vec2(0.5);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	vec2 cc = vec2(c.x / aspect, c.y);
	float r = length(cc);
	// how strong the distortion is: up from 0, strongest around 0.55, gone by the black
	float amt = smoothstep(0.0, 0.45, p) * (1.0 - smoothstep(0.7, 0.95, p));
	// a ripple running out from the middle, and a slow twist
	float wave = sin(r * 38.0 - p * 40.0 * forward) * 0.012 * amt;
	float ang = amt * 0.35 * (1.0 - r) * forward;
	mat2 rot = mat2(vec2(cos(ang), -sin(ang)), vec2(sin(ang), cos(ang)));
	vec2 q = rot * c * (1.0 - 0.06 * amt) + normalize(c + 1e-5) * wave + 0.5;
	// chromatic split, widening with the distortion
	float split = 0.012 * amt;
	vec3 col;
	col.r = texture(screen_tex, q + normalize(c + 1e-5) * split).r;
	col.g = texture(screen_tex, q).g;
	col.b = texture(screen_tex, q - normalize(c + 1e-5) * split).b;
	// colour washes that cycle through the three tints
	float cyc = fract(p * 3.0 + r * 0.6 * forward);
	vec3 wash = mix(mix(tint_a, tint_b, smoothstep(0.0, 0.5, cyc)), tint_c, smoothstep(0.5, 1.0, cyc));
	col = mix(col, col * 0.4 + wash * 0.8, amt * 0.55);
	// scan bands sweeping down
	float band = smoothstep(0.92, 1.0, sin((uv.y + p * 3.0) * 60.0)) * amt * 0.35;
	col += wash * band;
	// three flashes of light, the last the brightest
	float flash = pulse(p, 0.14, 0.035) * 0.7 + pulse(p, 0.36, 0.04) * 0.85 + pulse(p, 0.62, 0.06) * 1.0;
	col = mix(col, vec3(1.0, 0.97, 0.9), clamp(flash, 0.0, 1.0));
	// the edges darken, then everything goes to black for the reload
	col *= 1.0 - smoothstep(0.35, 0.95, r) * amt * 0.8;
	col *= 1.0 - smoothstep(0.78, 1.0, p);
	COLOR = vec4(col, 1.0);
}
