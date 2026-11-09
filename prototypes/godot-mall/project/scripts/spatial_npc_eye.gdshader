// spatial_npc_eye (Claude for Steven Boudreaux): the UBC bodies' eyes while an NPC is being talked to (workstream TALK, Nov 8 2026;
// design/godot-dialogue.md "The look"). Swapped onto the eye surface by scripts/npc_look.gd for the
// length of a conversation and swapped back after. The UBC eyes have no bones and no lids: one mesh
// skinned to the head, the iris painted in a fisheye map (data/story/talk_camera.json "eyes_ubc").
//  - gaze: the iris texture slides by the eye's turn (degrees: x toward the body's +x, y up); the two
//    eyes are mirrored in u, told apart by which side of the head the vertex sits at rest (unpose
//    takes the skinned vertex back to the rest pose through the head bone);
//  - blink: the lid colour wipes down over the eye from lid_top (0 open, 1 shut).
// Same look as spatial_char_region otherwise (albedo x tint, roughness). Targets Forward+ and
// Compatibility (web); one variant, one texture read, no branching in the fragment.
shader_type spatial;
render_mode depth_draw_opaque, cull_back;

group_uniforms look;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool has_albedo = false;
uniform float roughness = 0.35;
uniform float metallic = 0.0;
group_uniforms gaze;
// skinned vertex -> rest pose through the head bone (mesh space), set every frame
uniform mat4 unpose = mat4(1.0);
// the eye's turn in degrees: x toward the body's +x, y up
uniform vec2 gaze = vec2(0.0);
// the iris map: front at center, 90 degrees toward +x at +dx, toward +y at +dy (uv units)
uniform vec2 center = vec2(0.496, 0.501);
uniform vec2 dx = vec2(0.309, 0.212);
uniform vec2 dy = vec2(0.217, -0.311);
group_uniforms blink;
// the lid's resting edge above the iris centre (uv units along dy); blink 0 open .. 1 shut
uniform float lid_top = 0.16;
uniform float blink = 0.0;
uniform vec4 lid_color : source_color = vec4(0.6, 0.45, 0.38, 1.0);

varying float side;

void vertex() {
	vec3 rest = (unpose * vec4(VERTEX, 1.0)).xyz;
	side = rest.x >= 0.0 ? 1.0 : -1.0;
}

void fragment() {
	// the texture moves with the eye, so sample against the turn
	vec2 off = gaze.x / 90.0 * side * dx + gaze.y / 90.0 * dy;
	vec4 a = has_albedo ? texture(albedo_tex, UV - off) : vec4(1.0);
	vec3 c = a.rgb * albedo_color.rgb;
	float up = dot(UV - center, normalize(dy));
	float edge = lid_top - blink * 2.0 * lid_top;
	// a soft 0.02-uv lid edge; at blink 0 the edge sits above every visible texel
	float lid = smoothstep(edge - 0.01, edge + 0.01, up) * step(0.001, blink);
	ALBEDO = mix(c, lid_color.rgb, lid);
	ROUGHNESS = mix(roughness, 0.6, lid);
	METALLIC = metallic;
}
