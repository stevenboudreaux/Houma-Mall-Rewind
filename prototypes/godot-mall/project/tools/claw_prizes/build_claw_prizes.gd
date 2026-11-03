## The claw's prizes as bag items, step 2 of 2 (workstream ECON, Nov 3 2026; design/godot-economy.md "Claw prizes in
## the bag"). Reads .scratch/claw_prizes/<kind>.json (step 1, tools/claw_prizes/export_claw_prizes.py: the claw page's
## own prize meshes as data) and writes models/pc_claw_<kind>.scn: one Node3D, one MeshInstance3D, a surface per
## material, the page's textures (play/claw/*.webp) embedded at up to 256 px. Standing on its origin, the front +z.
##   godot --headless --path . --script res://tools/claw_prizes/build_claw_prizes.gd
## Prints CLAW PRIZES BUILT (n).
extends SceneTree

const KINDS := ["gator", "crawfish", "pelican", "nutria", "rougarou", "comet", "bruiser", "pogSkull", "pogGator", "pogEye", "slammer"]
const TEX_MAX := 256

var _tex := {}

func _texture(name: String) -> Texture2D:
	if _tex.has(name):
		return _tex[name]
	var path := ProjectSettings.globalize_path("res://").path_join("../play/claw/%s.webp" % name).simplify_path()
	var img := Image.load_from_file(path)
	if img == null:
		push_error("no texture " + path)
		return null
	if maxi(img.get_width(), img.get_height()) > TEX_MAX:
		var k := float(TEX_MAX) / maxi(img.get_width(), img.get_height())
		img.resize(maxi(1, int(img.get_width() * k)), maxi(1, int(img.get_height() * k)), Image.INTERPOLATE_LANCZOS)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	# saved once and shared by every prize that uses it (the fur is on all the plush)
	var out := "res://models/pc_claw_tex_%s.res" % name
	ResourceSaver.save(t, out, ResourceSaver.FLAG_COMPRESS)
	t = load(out)
	_tex[name] = t
	return t

func _material(s: Dictionary) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.html(str(s.color))
	m.roughness = float(s.rough)
	m.metallic = float(s.metal)
	if s.map != null:
		m.albedo_texture = _texture(str(s.map))
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if float(s.alpha_test) > 0.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = float(s.alpha_test)
	elif float(s.opacity) < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.albedo_color.a = float(s.opacity)
	if bool(s.double):
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m

func _initialize() -> void:
	var src := ProjectSettings.globalize_path("res://").path_join("../../../.scratch/claw_prizes").simplify_path()
	var n := 0
	for kind in KINDS:
		var j = JSON.parse_string(FileAccess.get_file_as_string(src.path_join(kind + ".json")))
		if not (j is Dictionary):
			push_error("missing " + kind)
			continue
		var mesh := ArrayMesh.new()
		for s in j.surfaces:
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var cnt: int = s.pos.size() / 3
			for t in range(0, cnt, 3):
				for k in [0, 2, 1]:      # three.js fronts are counter-clockwise, Godot's clockwise
					var i: int = t + k
					st.set_normal(Vector3(s.nrm[i * 3], s.nrm[i * 3 + 1], s.nrm[i * 3 + 2]))
					st.set_uv(Vector2(s.uv[i * 2], s.uv[i * 2 + 1]))
					st.add_vertex(Vector3(s.pos[i * 3], s.pos[i * 3 + 1], s.pos[i * 3 + 2]))
			st.index()           # shared corners once
			st.set_material(_material(s))
			st.commit(mesh)
		var root := Node3D.new()
		root.name = "pc_claw_" + kind
		var mi := MeshInstance3D.new()
		mi.name = "Mesh"
		mi.mesh = mesh
		root.add_child(mi)
		mi.owner = root
		var ps := PackedScene.new()
		ps.pack(root)
		var out := "res://models/pc_claw_%s.scn" % kind
		var err := ResourceSaver.save(ps, out, ResourceSaver.FLAG_COMPRESS)
		printerr("%s %s: %d surfaces, %s" % ["ok  " if err == OK else "FAIL", out, mesh.get_surface_count(), str(j.name)])
		if err == OK: n += 1
		root.free()
	printerr("CLAW PRIZES BUILT (%d)" % n)
	quit(0 if n == KINDS.size() else 1)
