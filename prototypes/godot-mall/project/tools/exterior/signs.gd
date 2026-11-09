## The outside's department-store signs as real 3D signs (Workstream EXT-SIGNS, Nov 9 2026;
## design/exterior/signage-research.md, design/godot-exterior.md "EXT-SIGNS"). They replace the flat Label3D
## words and the flat K&B oval that tools/exterior/exterior.gd drew (Steven, Nov 9: "Sears" was flat blue text
## painted on the wall, Dillard's a flat decal that shimmered as the camera moved, K&B a flat purple oval).
##
## Each sign is a Blender model (tools/blender/assets_src/bl_exs_*.py, built with tools/blender/run.sh; shared
## construction in _exsign.py, after the Cucos neon in tools/stores/signs/cucos_sign.gd): channel letters with
## returns, a trim cap, a face material of their own, studs or a raceway standing them off the wall, and a soft
## contact shadow on the wall. The model's atlas carries everything painted; the faces (and K&B's red line,
## letters) come out of the .glb as flat materials, and this script swaps each for its game material
## "ex_sign_<sign>_<part>" with the emission the time of day sets (scripts/time_of_day.gd: e_day / e_night).
##
## Signs are dynamic meshes (no lightmap, like the Cucos sign), casting real shadows in an unbaked view.

const UP = Vector3.UP
const DIR = "res://models/exterior/signs/"

## Per face material: albedo, emission colour, energy by day, by night (null = unlit). Guesses noted in the
## research note: a lit acrylic face reads a little brighter than its paint by day, and glows at night.
const LOOK = {
	"sears_face": ["#1f4fa8", "#2f66e0", 0.15, 1.5],
	"sears_hw_face": ["#1f4fa8", "#2f66e0", 0.15, 1.5],
	"dillards_face": ["#141312", null, 0.0, 0.0],
	"dillards_portal_face": ["#1a1918", null, 0.0, 0.0],
	"kb_face": ["#5b2a86", "#7a3cc0", 0.1, 1.2],
	"kb_line": ["#c8202e", "#ff3040", 0.1, 1.2],
	"kb_letters": ["#f6f3ff", "#fff8f0", 0.2, 1.8],
	# the options sheet's B models (models/exterior/signs/options/; not shipped)
	"sears_optb_face": ["#f4f6fa", "#ffffff", 0.2, 1.6],
	"sears_optb_cabinet": ["#1f4fa8", "#2f66e0", 0.1, 1.0],
	"dillards_optb_face": ["#141312", null, 0.0, 0.0],
	"kb_optb_letters": ["#f6f3ff", "#fff8f0", 0.2, 1.8],
	"kb_optb_line": ["#c8202e", null, 0.0, 0.0],
	"sears_hw_optb_face": ["#1f4fa8", "#2f66e0", 0.1, 0.8],
	"sears_hw_optb_face2": ["#c8202e", "#ff3040", 0.1, 0.8],
	"sears_hw_optb_cabinet": ["#f4f4f0", "#ffffff", 0.1, 1.2],
	"unitech_optb_face": ["#f4f6fa", "#ffffff", 0.15, 1.4],
}

## The options sheet: EXS_OPTIONS=B in the environment builds every sign's option B model instead (where one
## exists, models/exterior/signs/options/). Unset in every real build.
const OPT_B = ["bl_exs_sears", "bl_exs_dillards", "bl_exs_kb", "bl_exs_sears_hw"]
static func opt(id):
	if OS.get_environment("EXS_OPTIONS") == "B" and id in OPT_B:
		return "options/" + id + "_optb"
	return id

static var _mats = {}
static var _meshes = {}

## The game material for one of a sign's flat parts (`key` = "<sign>_<part>", from the .glb's material name
## "bl_exs_<sign>_<part>"). Faces get their LOOK; "_shadow" parts are a soft dark film on the wall.
static func sign_mat(key, src):
	if _mats.has(key):
		return _mats[key]
	var m = StandardMaterial3D.new()
	m.resource_name = "ex_sign_" + key
	if key.ends_with("_halo"):
		# a reverse-channel letter's light on the wall behind it: added light, night only
		m.albedo_color = Color.BLACK
		m.roughness = 1.0
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.emission_enabled = true
		m.emission = Color("#ffd9a0")
		m.emission_energy_multiplier = 1.2
		m.set_meta("e_day", 0.0)
		m.set_meta("e_night", 1.2)
	elif key.ends_with("_shadow"):
		m.albedo_color = Color(0.0, 0.0, 0.0, 0.16)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.render_priority = -1
	else:
		var lk = LOOK.get(key, null)
		m.albedo_color = Color(lk[0]) if lk != null else (src.albedo_color if src is BaseMaterial3D else Color.WHITE)
		m.roughness = 0.35
		if lk != null and lk[1] != null:
			m.emission_enabled = true
			m.emission = Color(lk[1])
			m.emission_energy_multiplier = lk[3]
			m.set_meta("e_day", lk[2])
			m.set_meta("e_night", lk[3])
			m.disable_receive_shadows = true   # a lit face: no shadow acne striping it (unbaked views)
	_mats[key] = m
	return m

## The sign's mesh with its flat parts swapped for the game materials (cached per model).
static func sign_mesh(id):
	if _meshes.has(id):
		return _meshes[id]
	var path = DIR + id + "/" + id.get_file() + ".glb"   # "options/<id>" for the options sheet
	var out = null
	if ResourceLoader.exists(path):
		var root = load(path).instantiate()
		var mis = root.find_children("*", "MeshInstance3D", true, false)
		if not mis.is_empty():
			out = mis[0].mesh.duplicate()
			for i in out.get_surface_count():
				var m = out.surface_get_material(i)
				var nm = String(m.resource_name) if m != null else ""
				if nm.begins_with("bl_exs_") and not nm.ends_with("_baked"):
					out.surface_set_material(i, sign_mat(nm.substr(7), m))
		root.free()
	_meshes[id] = out
	return out

## Places sign `id` (bl_exs_<name>) with its origin at `at` (a point on the wall's face, the sign's centre),
## facing `n` (the wall's outward normal). Returns the node, or null when the model is missing (the caller
## keeps its old flat sign then).
## EXS_OFF=1 in the environment builds the old flat signs (the "before" evidence shots).
static func place(b, id, at: Vector3, n: Vector3, label := ""):
	if OS.get_environment("EXS_OFF") == "1":
		return null
	var mesh = sign_mesh(id)
	if mesh == null or b.mall == null:
		return null
	var z = n.normalized()
	var x = UP.cross(z).normalized()
	var mi = MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = Transform3D(Basis(x, UP, z), at)
	mi.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	var h = b.mall.get_node_or_null("ExSigns")
	if h == null:
		h = Node3D.new()
		h.name = "ExSigns"
		b.mall.add_child(h)
		h.owner = b.mall
	mi.name = label if label != "" else "%s_%d" % [id, h.get_child_count()]
	h.add_child(mi)
	mi.owner = b.mall
	return mi
