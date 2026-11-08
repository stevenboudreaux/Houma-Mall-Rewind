## Workstream FOOD3D (Nov 8 2026; design/godot-blender-pipeline.md "FOOD3D"): Blender food and counter props
## placed by the store build scripts. A kit .glb (tools/blender/assets_src/_kit.py) holds one node per piece,
## each with its own mesh on the kit's one atlas; `multi()` instances one piece many times (a MultiMesh per
## kind: one draw call for a tray-full case; built at run time by scripts/food3d_multi.gd). Everything goes under the mall's "Food3D" node, dynamic GI
## (probe-lit, like the hand items) and no shadows, so placing food needs no rebake.

const UP = Vector3.UP
static var _cache = {}

## {piece name: Mesh} of a kit .glb ({} when the file is missing, e.g. a preview without the import).
static func meshes(path) -> Dictionary:
	if _cache.has(path):
		return _cache[path]
	var out = {}
	if ResourceLoader.exists(path):
		var root = load(path).instantiate()
		for c in root.find_children("*", "MeshInstance3D", true, false):
			out[str(c.name)] = c.mesh
		root.free()
	_cache[path] = out
	return out

static func holder(b, name := "Food3D") -> Node3D:
	var h = b.mall.get_node_or_null(name)
	if h == null:
		h = Node3D.new()
		h.name = name
		b.mall.add_child(h)
		h.owner = b.mall
	return h

## One MultiMeshInstance3D of `mesh` at every Transform3D in `xf` (world space).
static func multi(b, mesh, xf: Array, label := "food", shadow := false):
	if b.mall == null or mesh == null or xf.is_empty():
		return null
	# scripts/food3d_multi.gd builds the MultiMesh at run time (the headless build cannot store its transforms)
	var mi = MultiMeshInstance3D.new()
	mi.set_script(load("res://scripts/food3d_multi.gd"))
	mi.piece = mesh
	var arr: Array[Transform3D] = []
	for x in xf:
		arr.append(x)
	mi.xforms = arr
	mi.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var h = holder(b)
	mi.name = "%s_%d" % [label, h.get_child_count()]
	h.add_child(mi)
	mi.owner = b.mall
	return mi

## A single instance of a whole .glb scene (a model that is not a kit), dynamic, at xf.
static func one(b, path, xf: Transform3D, label := "") -> Node3D:
	if b.mall == null or not ResourceLoader.exists(path):
		return null
	var inst = load(path).instantiate()
	var h = holder(b)
	inst.name = "%s_%d" % [label if label != "" else path.get_file().get_basename(), h.get_child_count()]
	inst.transform = xf
	h.add_child(inst)
	inst.owner = b.mall
	for c in inst.find_children("*", "GeometryInstance3D", true, false):
		c.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	return inst

## A flat-lying piece's basis: yaw about UP, uniform scale s.
static func flat(yaw: float, s := 1.0) -> Basis:
	return Basis(UP, yaw).scaled(Vector3.ONE * s)
