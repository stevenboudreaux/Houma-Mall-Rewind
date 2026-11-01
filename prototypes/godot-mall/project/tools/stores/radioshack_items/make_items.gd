## Builds Radio Shack's standalone items (workstream D, Nov 1 2026; design/storefronts/radio-shack.md)
## from tools/stores/radioshack_items/spec.json (paint_items.py): one mesh, one scene and one
## 256 px icon per item, in res://items/radioshack/. Each scene's root is a Node3D named after the
## item id, with the item's id, name and class in its metadata; its origin is the item's bottom
## centre and its front faces +z. The pick-up code is workstream B+C's (data/items/radioshack.json).
##
## Run (the icons need a renderer, so not --headless):
##   xvfb-run -a godot --path . --rendering-driver opengl3 --script res://tools/stores/radioshack_items/make_items.gd
## after `python3 tools/stores/radioshack_items/paint_items.py` and an import (godot --headless --import).
extends SceneTree

const SPEC = "res://tools/stores/radioshack_items/spec.json"
const OUT = "res://items/radioshack/"
const ICON = 256

var items = []
var mats = {}
var vp: SubViewport
var holder: Node3D
var cam: Camera3D
var idx = -1
var wait = 0

func _initialize():
	var J = JSON.parse_string(FileAccess.get_file_as_string(SPEC))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT + "icons"))
	for it in J.items:
		var mesh = build_mesh(it)
		var mp = OUT + it.file + ".res"
		ResourceSaver.save(mesh, mp)
		var root = Node3D.new()
		root.name = it.id
		root.set_meta("item_id", it.id)
		root.set_meta("item_name", it.name)
		root.set_meta("item_class", it["class"])
		var mi = MeshInstance3D.new()
		mi.name = "Mesh"
		mi.mesh = load(mp)
		root.add_child(mi)
		mi.owner = root
		var ps = PackedScene.new()
		ps.pack(root)
		ResourceSaver.save(ps, OUT + it.file + ".tscn")
		root.free()
		items.append(it)
		print("item ", it.id, ": ", mesh.get_surface_count(), " surfaces")
	# the icon studio: a transparent 256 px viewport, a key and a fill light
	vp = SubViewport.new()
	vp.size = Vector2i(ICON, ICON)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var env = WorldEnvironment.new()
	var e = Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.8, 0.8, 0.82)
	e.ambient_light_energy = 0.55
	env.environment = e
	vp.add_child(env)
	var key = DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-40, 30, 0)
	key.light_energy = 1.3
	vp.add_child(key)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, -140, 0)
	fill.light_energy = 0.45
	vp.add_child(fill)
	cam = Camera3D.new()
	cam.fov = 30.0
	vp.add_child(cam)
	holder = Node3D.new()
	vp.add_child(holder)

func _process(_delta):
	if wait > 0:
		wait -= 1
		return false
	if idx >= 0:
		var im = vp.get_texture().get_image()
		im.save_png(ProjectSettings.globalize_path(OUT + "icons/" + items[idx].file + ".png"))
		print("icon ", items[idx].file)
	idx += 1
	if idx >= items.size():
		print("ITEMS OK ", items.size())
		quit()
		return true
	for c in holder.get_children():
		c.queue_free()
	var inst = load(OUT + items[idx].file + ".tscn").instantiate()
	holder.add_child(inst)
	# frame the item: a three-quarter view from the front, above
	var ab = inst.get_node("Mesh").get_aabb()
	var c = ab.get_center()
	var rad = ab.size.length() * 0.5
	var dir = Vector3(0.55, 0.5, 1.0).normalized()
	var dist = rad / sin(deg_to_rad(cam.fov * 0.5)) * 1.05
	cam.position = c + dir * dist
	cam.look_at(c, Vector3.UP)
	cam.near = dist * 0.05
	cam.far = dist * 4.0
	wait = 4
	return false

# ------------------------------------------------------------------ meshes
func mat(name, tex_path):
	var key = name if name != "tex" else tex_path
	if mats.has(key):
		return mats[key]
	var m = StandardMaterial3D.new()
	m.resource_name = name
	match name:
		"tex":
			m.albedo_texture = load(tex_path)
			m.roughness = 0.5
			m.metallic_specular = 0.45
			m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
		"rubber":
			m.albedo_color = Color("#1a1a1c"); m.roughness = 0.85
		"knob":
			m.albedo_color = Color("#2c2c30"); m.roughness = 0.4; m.metallic_specular = 0.6
		"chrome":
			m.albedo_color = Color("#d4d6da"); m.metallic = 0.9; m.roughness = 0.2
		"black_plastic":
			m.albedo_color = Color("#1e1e22"); m.roughness = 0.45
		_:
			push_error("unknown item material " + name)
	mats[key] = m
	return m

## The faces of a box in its own frame: [normal, right (image +u), up (image -v)].
const FACES = {
	"+z": [Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
	"-z": [Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
	"+x": [Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)],
	"-x": [Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
	"+y": [Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)],
	"-y": [Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
}

func build_mesh(it):
	var groups = {}   # material key -> [SurfaceTool, material]
	var get_st = func(name):
		var m = mat(name, it.tex)
		var k = m.resource_name + "|" + str(m.get_instance_id())
		if not groups.has(k):
			var s = SurfaceTool.new()
			s.begin(Mesh.PRIMITIVE_TRIANGLES)
			s.set_material(m)
			groups[k] = s
		return groups[k]
	for p in it.parts:
		if p.type == "box":
			var c = Vector3(p.c[0], p.c[1], p.c[2])
			var h = Vector3(p.s[0], p.s[1], p.s[2]) * 0.5
			for fk in FACES:
				var F = FACES[fk]
				var nrm: Vector3 = F[0]
				var rgt: Vector3 = F[1]
				var up: Vector3 = F[2]
				var uvr = p.faces.get(fk, p.get("default"))
				var mname = p.mat
				if mname == "tex" and uvr == null:
					mname = "black_plastic"
				var s = get_st.call(mname)
				var fc = c + nrm * h.abs().dot(nrm.abs())
				var hr = (rgt * h).length()
				var hu = (up * h).length()
				var pts = [fc - rgt * hr - up * hu, fc + rgt * hr - up * hu, fc + rgt * hr + up * hu, fc - rgt * hr + up * hu]
				var uv = [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
				if uvr != null:
					uv = [Vector2(uvr[0], uvr[3]), Vector2(uvr[2], uvr[3]), Vector2(uvr[2], uvr[1]), Vector2(uvr[0], uvr[1])]
				for tri in [[0, 1, 2], [0, 2, 3]]:
					# counter-clockwise seen from outside is Godot's front face... set winding by normal
					var a = pts[tri[0]]; var b = pts[tri[1]]; var cc = pts[tri[2]]
					var order = tri
					if (b - a).cross(cc - a).dot(nrm) > 0.0:
						order = [tri[0], tri[2], tri[1]]
					for k in order:
						s.set_normal(nrm)
						s.set_uv(uv[k])
						s.add_vertex(pts[k])
		elif p.type == "cyl":
			var s = get_st.call(p.mat)
			var base = Vector3(p.c[0], p.c[1], p.c[2])
			var ax = Vector3.UP if p.axis == "y" else Vector3(0, 0, 1)
			var u = Vector3(1, 0, 0)
			var v = ax.cross(u).normalized()
			var seg = int(p.seg)
			for i in seg:
				var a0 = TAU * i / seg
				var a1 = TAU * (i + 1) / seg
				var d0 = u * cos(a0) + v * sin(a0)
				var d1 = u * cos(a1) + v * sin(a1)
				var q = [base + d0 * p.r, base + d1 * p.r, base + ax * p.h + d1 * p.r_top, base + ax * p.h + d0 * p.r_top]
				var nn = [d0, d1, d1, d0]
				for tri in [[0, 1, 2], [0, 2, 3]]:
					var order = tri
					var fn = (d0 + d1).normalized()
					if (q[tri[1]] - q[tri[0]]).cross(q[tri[2]] - q[tri[0]]).dot(fn) > 0.0:
						order = [tri[0], tri[2], tri[1]]
					for k in order:
						s.set_normal(nn[k]); s.set_uv(Vector2(0.5, 0.5)); s.add_vertex(q[k])
				# the end cap
				var tc = base + ax * p.h
				var cq = [tc, tc + d0 * p.r_top, tc + d1 * p.r_top]
				var co = [0, 1, 2]
				if (cq[1] - cq[0]).cross(cq[2] - cq[0]).dot(ax) > 0.0:
					co = [0, 2, 1]
				for k in co:
					s.set_normal(ax); s.set_uv(Vector2(0.5, 0.5)); s.add_vertex(cq[k])
	var mesh = ArrayMesh.new()
	for k in groups:
		var s = groups[k]
		s.generate_tangents()
		s.commit(mesh)
	return mesh
