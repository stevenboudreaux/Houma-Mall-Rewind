// spatial_char_region: B1 (Claude for Steven Boudreaux, Nov 2 2026). Targets Forward+ and
// Compatibility (web); one variant, 3-4 texture reads. B1 character bodies and pieces (design/godot-characters.md): the standard material's look
// (albedo x tint, tangent normal map, ORM) plus REGION HIDING: every vertex carries its body
// region in UV2.x (models/characters/characters.json "regions"); `hide_mask` bit r set = region r
// is under a piece that covers it, so this surface discards it (no poke-through, less overdraw).
// The skin also blends its age wrinkle map by `wrinkle` (the age slider).
shader_type spatial;
render_mode depth_draw_opaque, cull_back;

group_uniforms look;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool has_albedo = false;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool has_normal = false;
uniform float normal_strength = 1.0;
uniform sampler2D orm_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform bool has_orm = false;
uniform float roughness = 0.7;
uniform float metallic = 0.0;
group_uniforms age;
uniform sampler2D wrinkle_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float wrinkle = 0.0;
group_uniforms layering;
// bit r set = body region r (UV2.x) is covered by an outer piece: discard it
uniform int hide_mask = 0;
uniform bool use_vertex_color = false;
group_uniforms base_layer;
// B-FIX (Nov 2): the clothed rule's permanent base layer. On skin surfaces, bit r set = body region r
// is drawn as plain opaque fabric (base_color, not tinted by the skin tone). The albedo map is also
// painted there, so even a plain material shows no bare chest or groin.
uniform int base_mask = 0;
uniform vec4 base_color : source_color = vec4(0.74, 0.73, 0.69, 1.0);

varying flat int region;

void vertex() {
	region = int(UV2.x + 0.5);
}

void fragment() {
	if (hide_mask != 0 && ((hide_mask >> region) & 1) == 1) {
		discard;
	}
	vec4 a = has_albedo ? texture(albedo_tex, UV) : vec4(1.0);
	vec3 c = a.rgb * albedo_color.rgb;
	if (use_vertex_color) {
		c *= COLOR.rgb;
	}
	bool based = base_mask != 0 && ((base_mask >> region) & 1) == 1;
	if (based) {
		c = base_color.rgb;
	}
	ALBEDO = c;
	float r = based ? 0.85 : roughness;
	if (has_orm) {
		vec3 o = texture(orm_tex, UV).rgb;
		AO = o.r;
		r *= o.g;
	}
	ROUGHNESS = r;
	METALLIC = metallic;
	if (has_normal) {
		vec3 n = texture(normal_tex, UV).rgb;
		if (wrinkle > 0.0) {
			vec3 w = texture(wrinkle_tex, UV).rgb;
			n = normalize(mix(n * 2.0 - 1.0, w * 2.0 - 1.0, clamp(wrinkle, 0.0, 1.0))) * 0.5 + 0.5;
		}
		NORMAL_MAP = n;
		NORMAL_MAP_DEPTH = normal_strength;
	}
}
