## Lynn's Interiors (2026) furniture from Blender: places the models listed in data/lynns/placements.json
## (zones and groups from design/lynns/layout.md; families and frames: design/lynns/inventory.md).
## Workstream LYNNS (Nov 4 2026). Called from store.gd dress_2026(); the generic box dressing there skips
## any spot inside a rect this file has claimed, so the two never overlap.
##
## Each placement is [model, x, z, yaw_degrees] (or [..., y] for a piece standing on another) in world metres (+x east, +z south); yaw 0 = the piece's
## front faces +z (south, toward the mall), 90 = faces +x (east), -90 = faces west, 180 = faces north.
## The models are dynamic (no lightmap UV2): lit by the wing's lightmap probes, their contact shadows baked
## into their own albedo (META ao). Each piece is also a walk obstacle (its footprint, from "size").

const PLACEMENTS = "res://data/lynns/placements.json"

static var _data = null

static func data():
	if _data == null:
		var t = FileAccess.get_file_as_string(PLACEMENTS)
		_data = JSON.parse_string(t) if t != "" else {"models": {}, "groups": []}
	return _data

## True when the pack furniture (pass 2, design/lynns/layout.md) replaces store.gd's old box dressing.
static func replaces_boxes():
	return bool(data().get("replace_boxes", false))

## True when (x, z) is inside a group rect this file dresses (store.gd's box dressing skips it).
static func claimed(x, z, pad = 0.0):
	for g in data().groups:
		var r = g.rect
		if x > r[0] - pad and x < r[2] + pad and z > r[1] - pad and z < r[3] + pad:
			return true
	return false

static func place(b):
	var D = data()
	var holder = null
	if b.mall != null:
		holder = b.mall.get_node_or_null("LynnsFurniture")
		if holder == null:
			holder = Node3D.new()
			holder.name = "LynnsFurniture"
			b.mall.add_child(holder)
			holder.owner = b.mall
	var n = 0
	var missing = {}
	for g in D.groups:
		if g.has("rug"):
			rug(b, g.rug)
		for it in g.items:
			var m = D.models.get(it[0])
			if m == null:
				push_warning("lynns: no model " + str(it[0]))
				continue
			var yaw = deg_to_rad(float(it[3]))
			# a 5th value is a height: the piece stands on another one (a lamp on an end table)
			var y = float(it[4]) if it.size() > 4 else 0.0
			var at = Vector3(float(it[1]), y, float(it[2]))
			# the footprint as an obstacle (rotated half-sizes); rugs (walk) and pieces on top are not obstacles
			if y == 0.0 and not m.get("walk", false):
				var hw = m.size[0] * 0.5
				var hd = m.size[1] * 0.5
				var ex = abs(cos(yaw)) * hw + abs(sin(yaw)) * hd
				var ez = abs(sin(yaw)) * hw + abs(cos(yaw)) * hd
				b.obst(["rect", at.x - ex, at.z - ez, at.x + ex, at.z + ez])
			if holder == null or not ResourceLoader.exists(m.scene):
				missing[m.scene] = true
				continue
			var inst = load(m.scene).instantiate()
			inst.name = "%s_%d" % [it[0], n]
			inst.transform = Transform3D(Basis(Vector3.UP, yaw), at)
			holder.add_child(inst)
			inst.owner = b.mall
			n += 1
	for s in missing:
		push_warning("lynns: model not imported yet: " + s)
	print("LYNNS placed %d pieces" % n)

## A flat area rug: [x0, z0, x1, z1, "#hex"] (a vertex-coloured quad, a stand-in until the RUG family).
static func rug(b, r):
	b.cur_color = Color(r[4])
	b.quad("sr_dress", "vcolor_matte", [Vector3(r[0], 0.006, r[1]), Vector3(r[2], 0.006, r[1]), Vector3(r[2], 0.006, r[3]), Vector3(r[0], 0.006, r[3])], Vector3.UP, [], true)
	b.cur_color = Color.WHITE
