// Workstream V (design/godot-avatar.md): the avatar's skin, hair, top and bottom colours, painted
// over the body's own texture. For: the player's avatar only (one skinned body), Compatibility
// renderer (WebGL 2, phones), one texture read, no loops.
//
// scripts/avatar_body.gd copies the body's mesh with, per vertex, its UV island's class in COLOR.a
// (0 other, 1 skin, 2 hair, 3 top, 4 bottom; tools/avatar/analyze_bodies.gd sorts the islands) and
// the island's mean colour (linear) in COLOR.rgb. A texel of a changed class becomes the new colour
// at the texel's own brightness relative to its island's mean, so folds, seams and the shading
// painted into the texture stay; skin keeps its own per-channel variation (cheeks, knuckles).
shader_type spatial;
render_mode cull_back, diffuse_lambert, specular_disabled;

group_uniforms body;
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);    // NpcBody.tint, the mall's day colour on people
group_uniforms colours;
uniform vec3 new_skin = vec3(0.8, 0.6, 0.5);     // linear
uniform vec3 new_hair = vec3(0.1);
uniform vec3 new_top = vec3(0.5);
uniform vec3 new_bottom = vec3(0.3);
uniform vec4 on = vec4(0.0);                     // 1 where a class is changed: skin, hair, top, bottom
uniform float max_gain = 1.6;                    // a texel at most this much brighter than its new colour

varying vec4 island;   // rgb: the island's mean colour, a: its class

void vertex() {
	island = COLOR;
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// chroma distance of a texel from its island's mean: features painted into the skin (eyes, lips,
// brows) are far from it and keep their own colours
float chroma_dist(vec3 a, vec3 b) {
	vec3 sa = pow(a, vec3(1.0 / 2.2));
	vec3 sb = pow(b, vec3(1.0 / 2.2));
	vec3 d = sa - sb;
	return length(d - vec3(dot(d, vec3(0.333))));
}

// a new cloth colour carrying the texel's own light and shade: multiplied for dark colours, added
// (in sRGB) for light ones, so a white top keeps its folds instead of clipping flat
vec3 cloth(vec3 c, vec3 mean, vec3 col) {
	float g = clamp(luma(c) / luma(mean), 0.0, max_gain);
	vec3 dark = col * g;
	vec3 s = pow(col, vec3(1.0 / 2.2)) + vec3(pow(luma(c), 1.0 / 2.2) - pow(luma(mean), 1.0 / 2.2)) * 0.9;
	vec3 light = pow(clamp(s, vec3(0.0), vec3(1.0)), vec3(2.2));
	return mix(dark, light, smoothstep(0.15, 0.45, luma(col)));
}

void fragment() {
	vec3 c = texture(albedo_tex, UV).rgb;
	vec3 mean = max(island.rgb, vec3(0.004));
	// class one-hot from the stored value 0..4 (a/4), without branching
	float k = island.a * 4.0;
	vec4 is = vec4(1.0 - step(0.5, abs(k - 1.0)), 1.0 - step(0.5, abs(k - 2.0)),
		1.0 - step(0.5, abs(k - 3.0)), 1.0 - step(0.5, abs(k - 4.0))) * on;
	float skin_w = 1.0 - smoothstep(0.07, 0.16, chroma_dist(c, mean));
	vec3 skin = clamp(c / mean, vec3(0.0), vec3(max_gain)) * new_skin;
	vec3 o = c;
	o = mix(o, skin, is.x * skin_w);
	o = mix(o, cloth(c, mean, new_hair), is.y);
	o = mix(o, cloth(c, mean, new_top), is.z);
	o = mix(o, cloth(c, mean, new_bottom), is.w);
	ALBEDO = o * tint.rgb;
}
