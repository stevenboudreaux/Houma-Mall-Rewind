## OWNER (Steven, Nov 4 2026; design/godot-owner-mode.md "Pictures"): the owner's own pictures on the
## mall's posters and ad panels. Made by scripts/player.gd as the scene's child "Pictures" (every wing,
## both years).
##
## The surfaces ("slots") are found in the wing's own meshes when it loads, by material name
## (scripts/pictures.json), so they need no rebuild and no rebake:
##   framed  the framed newspaper ads (tools/stores/posters/posters.gd, one "ad_<name>" surface each in
##           Dynamic/dyn_posters). id "ad.<name>". A new picture gets a new frame wrapped round its own
##           aspect (the longer side of the print stays 1.15 m, the same mat and rails); the old frame,
##           mat and print are taken out of the mesh (a filtered copy; the original is kept to restore).
##   panel   poster and ad panels (window posters, the lit poster stands in front of Spencer's, wall
##           poster slots). Each flat patch of a listed material at least min_side across is one slot,
##           id "<year>:<material>@<x>,<y>,<z>" (its centre, 0.1 m), stable while the store's build
##           keeps it in place. A new picture is fitted inside the panel, on a dark backing that covers
##           the old art, 4 mm in front of it.
##
## Where a picture comes from, in order: the owner's unpublished draft in this browser (localStorage
## "southland-pictures-draft": {id: {data: <JPEG data URL>, w, h} | {reset: true}}), then the published
## list play/posters.json ({"pictures": {id: {file: "posters/<name>.jpg", w, h}}}, next to the game),
## else the original art. Publishing (web/shell.html window.mallPictures) uploads each new picture as
## a JPEG (at most 1024 px on its longer side) to prototypes/godot-mall/play/posters/ on main through
## the GitHub contents API, with the token the mall editor keeps (localStorage "southland-gh"), then
## merges posters.json with the live copy. Everyone sees it about a minute later, once Pages updates.
##
## The owner: Edit pictures (the menu's OWNER tab), tap a poster within 16 m, choose a picture from the
## device in the page's own dialog (a real file input, so it works on an iPhone), or "Original picture"
## to put the original back. It shows at once.
extends Node

const CFG := "res://scripts/pictures.json"
const DRAFT_KEY := "southland-pictures-draft"
const UP := Vector3.UP

var player: Node3D
var cfg: Dictionary = {}
var web := false
var is_owner := false
var editing := false
var publishing := false
var slots := {}            # id -> slot (see _add_slot)
var order: Array = []      # slot ids in the order found
var published := {}        # id -> {file, w, h}
var draft := {}            # id -> {data, w, h} | {reset: true}
var tex := {}              # id -> Texture2D shown now (draft or published)
var made := {}             # id -> [nodes] laid over the scene for that slot
var framed_mi: MeshInstance3D = null
var framed_orig: Mesh = null
var ui: CanvasLayer
var status: Label
var press_at := Vector2.ZERO
var press_t := 0
var pressed := false
var picking := ""          # the slot id whose picture dialog is open
var poll_t := 0.0
## Tests: how the owner's picture is chosen (picker_fn.call(id) -> {data, w, h} | {reset: true} | {}),
## and how a draft is published (publisher_fn.call(draft) -> "ok" | "error: ...").
var picker_fn: Callable
var publisher_fn: Callable

func _ready() -> void:
	web = OS.has_feature("web")
	if FileAccess.file_exists(CFG):
		var j = JSON.parse_string(FileAccess.get_file_as_string(CFG))
		if j is Dictionary:
			cfg = j
	if web:
		is_owner = str(JavaScriptBridge.eval("(function(){try{return localStorage.getItem('southland-editor')==='1'?'1':'0'}catch(e){return '0'}})()")) == "1"
	else:
		is_owner = bool(Engine.get_meta("mall_owner", false))
	if is_owner:
		draft = _load_draft()
		_build_ui()
	_find_slots.call_deferred()

func _year() -> int:
	return int(player.year) if player and "year" in player else 1995

# ------------------------------------------------------------------ finding the slots
func _find_slots() -> void:
	var scn: Node = get_parent()
	if scn == null:
		return
	var panels: Array = cfg.get("panels", [])
	var fr: Dictionary = cfg.get("framed", {})
	var stack: Array = [scn]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n == player or n == self:
			continue
		for c in n.get_children():
			stack.append(c)
		if not (n is MeshInstance3D) or n.mesh == null or not (n.mesh is ArrayMesh):
			continue
		var mi := n as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m = mi.mesh.surface_get_material(i)
			if m == null:
				continue
			var mn: String = m.resource_name
			if mi.name == str(fr.get("node", "dyn_posters")) and mn.begins_with(str(fr.get("print_prefix", "ad_"))):
				_add_framed(mi, i, mn)
			elif mn in panels:
				_add_panels(mi, i, mn)
	print("pictures: ", order.size(), " slots")
	if web:
		_fetch_published()
	_apply_all()

## The world-space triangles of surface i: [[a, b, c, normal], ...].
func _tris(mi: MeshInstance3D, i: int) -> Array:
	var arr: Array = mi.mesh.surface_get_arrays(i)
	var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var idx = arr[Mesh.ARRAY_INDEX]
	if idx == null or idx.size() == 0:
		idx = PackedInt32Array(range(v.size()))
	var N = arr[Mesh.ARRAY_NORMAL]
	var UV = arr[Mesh.ARRAY_TEX_UV]
	var xf := mi.global_transform
	var out: Array = []
	for k in range(0, idx.size() - 2, 3):
		var a: Vector3 = xf * v[idx[k]]
		var b: Vector3 = xf * v[idx[k + 1]]
		var c: Vector3 = xf * v[idx[k + 2]]
		var nn := (b - a).cross(c - a)
		if nn.length() < 1e-8:
			continue
		nn = nn.normalized()
		# the face's own normal (the way it faces), when the mesh has normals
		if N != null and N.size() > idx[k]:
			var fn: Vector3 = (xf.basis * N[idx[k]]).normalized()
			if fn.dot(nn) < 0.0:
				nn = -nn
		var uv := [Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]
		if UV != null and UV.size() > idx[k + 2]:
			uv = [UV[idx[k]], UV[idx[k + 1]], UV[idx[k + 2]]]
		out.append([a, b, c, nn, uv])
	return out

## A slot's plane axes for normal n: right as the viewer facing it sees it, and up.
static func axes(n: Vector3) -> Array:
	var r := (-n).cross(UP)
	if r.length() < 0.1:
		r = Vector3.RIGHT        # a flat (floor / ceiling) panel
	r = r.normalized()
	return [r, n.cross(r).normalized() if absf(n.y) > 0.9 else UP]

## The rectangle round points P in the plane of n: [centre, w, h, right, up].
static func rect_of(P: Array, n: Vector3) -> Array:
	var ax := axes(n)
	var r: Vector3 = ax[0]
	var u: Vector3 = ax[1]
	var o: Vector3 = P[0]
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	var dn := 0.0
	for p in P:
		var q := Vector2((p - o).dot(r), (p - o).dot(u))
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
		dn += (p - o).dot(n)
	var mid := (lo + hi) * 0.5
	var c: Vector3 = o + r * mid.x + u * mid.y + n * (dn / P.size())
	return [c, hi.x - lo.x, hi.y - lo.y, r, u]

func _add_framed(mi: MeshInstance3D, i: int, mn: String) -> void:
	var tris := _tris(mi, i)
	if tris.is_empty():
		return
	var P: Array = []
	for t in tris:
		P.append_array([t[0], t[1], t[2]])
	var n: Vector3 = tris[0][3]
	var rc := rect_of(P, n)
	var id := "ad." + mn.substr(str(cfg.get("framed", {}).get("print_prefix", "ad_")).length())
	framed_mi = mi
	if framed_orig == null:
		framed_orig = mi.mesh
	_add_slot(id, {"kind": "framed", "c": rc[0], "n": n, "r": rc[3], "u": rc[4], "w": rc[1], "h": rc[2],
		"mi": mi, "surf": i, "mat": mi.mesh.surface_get_material(i), "label": mn.substr(3).replace("_", " ").capitalize() + " ad"})

## Splits a surface into flat patches (triangles sharing an edge, same facing): one slot each.
func _add_panels(mi: MeshInstance3D, i: int, mn: String) -> void:
	var tris := _tris(mi, i)
	var parent := range(tris.size())
	# a corner's key: where it is and which part of the art it shows, so two posters side by side on
	# one wall (an atlas, the shared edge showing different art) stay two slots
	var key := func(p: Vector3, t: Vector2) -> String: return "%d,%d,%d|%d,%d" % [roundi(p.x * 500.0), roundi(p.y * 500.0), roundi(p.z * 500.0), roundi(t.x * 1000.0), roundi(t.y * 1000.0)]
	var edges := {}
	for k in tris.size():
		var t: Array = tris[k]
		for e in [[t[0], t[1], t[4][0], t[4][1]], [t[1], t[2], t[4][1], t[4][2]], [t[2], t[0], t[4][2], t[4][0]]]:
			var ka: String = key.call(e[0], e[2])
			var kb: String = key.call(e[1], e[3])
			var ek := [ka, kb] if ka < kb else [kb, ka]
			var es := str(ek)
			if edges.has(es):
				var o: int = edges[es]
				if (tris[o][3] as Vector3).dot(t[3]) > 0.99:
					var ra := _root_of(parent, o)
					var rb := _root_of(parent, k)
					if ra != rb:
						parent[rb] = ra
			else:
				edges[es] = k
	var groups := {}
	for k in tris.size():
		var r := _root_of(parent, k)
		if not groups.has(r):
			groups[r] = []
		groups[r].append(k)
	var min_side := float(cfg.get("min_side", 0.25))
	var src = mi.mesh.surface_get_material(i)
	var lit: bool = src is BaseMaterial3D and (src.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or src.emission_enabled)
	for g in groups.values():
		var P: Array = []
		for k in g:
			P.append_array([tris[k][0], tris[k][1], tris[k][2]])
		var n: Vector3 = tris[g[0]][3]
		var rc := rect_of(P, n)
		if rc[1] < min_side or rc[2] < min_side or maxf(rc[1], rc[2]) > float(cfg.get("max_aspect", 4.0)) * minf(rc[1], rc[2]):
			continue     # a box's edge, or a long frieze of posters
		var c: Vector3 = rc[0]
		var id := "%d:%s@%.1f,%.1f,%.1f" % [_year(), mn, c.x, c.y, c.z]
		if slots.has(id):
			continue
		_add_slot(id, {"kind": "panel", "c": c, "n": n, "r": rc[3], "u": rc[4], "w": rc[1], "h": rc[2],
			"mi": mi, "surf": i, "lit": lit, "label": "poster panel (" + mn + ")"})

static func _root_of(parent: Array, k: int) -> int:
	while parent[k] != k:
		parent[k] = parent[parent[k]]
		k = parent[k]
	return k

func _add_slot(id: String, s: Dictionary) -> void:
	s["id"] = id
	slots[id] = s
	order.append(id)

func slot_count() -> int:
	return order.size()

func draft_count() -> int:
	return draft.size()

# ------------------------------------------------------------------ what each slot shows
func _fetch_published() -> void:
	var url = JavaScriptBridge.eval("new URL('posters.json', location.href).href")
	if not (url is String):
		return
	var h := HTTPRequest.new()
	add_child(h)
	h.request_completed.connect(func(result, code, _headers, body):
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var j = JSON.parse_string(body.get_string_from_utf8())
			if j is Dictionary and j.get("pictures") is Dictionary:
				set_published(j.pictures)
		h.queue_free())
	h.request(url + "?t=" + str(Time.get_unix_time_from_system()))

## The published list arrived (or changed after a publish): fetch the pictures it names.
func set_published(p: Dictionary) -> void:
	published = p
	for id in published:
		if slots.has(id) and not draft.has(id):
			_fetch_picture(id, str(published[id].get("file", "")))
	_apply_all()

func _fetch_picture(id: String, file: String) -> void:
	if file == "" or not web:
		return
	var url = JavaScriptBridge.eval("new URL(%s, location.href).href" % JSON.stringify(file))
	if not (url is String):
		return
	var h := HTTPRequest.new()
	add_child(h)
	h.request_completed.connect(func(result, code, _headers, body):
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var im := decode(body)
			if im != null and not draft.has(id) and str(published.get(id, {}).get("file", "")) == file:
				tex[id] = ImageTexture.create_from_image(im)
				apply(id)
		h.queue_free())
	h.request(url)

## A JPEG or PNG from its bytes (or null).
static func decode(b: PackedByteArray) -> Image:
	var im := Image.new()
	var err := ERR_FILE_UNRECOGNIZED
	if b.size() > 3 and b[0] == 0xFF and b[1] == 0xD8:
		err = im.load_jpg_from_buffer(b)
	elif b.size() > 8 and b[0] == 0x89 and b[1] == 0x50:
		err = im.load_png_from_buffer(b)
	elif b.size() > 12 and b[8] == 0x57 and b[9] == 0x45:
		err = im.load_webp_from_buffer(b)
	if err != OK:
		return null
	im.generate_mipmaps()
	return im

## A picture from a data URL ("data:image/jpeg;base64,...") or bare base64.
static func decode_data(d: String) -> Image:
	var b64 := d.substr(d.find(",") + 1) if d.begins_with("data:") else d
	return decode(Marshalls.base64_to_raw(b64))

## What slot id shows: "draft", "published" or "original".
func source_of(id: String) -> String:
	if draft.has(id):
		return "original" if draft[id].get("reset", false) else "draft"
	if published.has(id):
		return "published"
	return "original"

func _apply_all() -> void:
	for id in order:
		apply(id, false)
	_rebuild_framed()

## Shows slot id as it should be now. A framed ad also rebuilds the framed mesh (unless told not to,
## when several change at once).
func apply(id: String, framed_too := true) -> void:
	var s = slots.get(id)
	if s == null:
		return
	for nd in made.get(id, []):
		if is_instance_valid(nd):
			nd.queue_free()
	made.erase(id)
	var src := source_of(id)
	var t: Texture2D = tex.get(id) if src != "original" else null
	if t != null:
		made[id] = _frame_nodes(s, t) if s.kind == "framed" else _panel_nodes(s, t)
	if s.kind == "framed" and framed_too:
		_rebuild_framed()

## Whether slot id shows a custom picture now (tests).
func is_custom(id: String) -> bool:
	return made.has(id) and not made[id].is_empty()

# ------------------------------------------------------------------ the framed ads
## dyn_posters without the frames, mats and prints of the ads that show a custom picture.
func _rebuild_framed() -> void:
	if framed_mi == null or framed_orig == null:
		return
	var gone: Array = []
	for id in order:
		if slots[id].kind == "framed" and is_custom(id):
			gone.append(slots[id])
	if gone.is_empty():
		framed_mi.mesh = framed_orig
		return
	var fr: Dictionary = cfg.get("framed", {})
	var pad := float(fr.get("mat_w", 0.06)) + float(fr.get("frame_w", 0.045)) + 0.01
	var deep := float(fr.get("deep", 0.032))
	var am := ArrayMesh.new()
	var inv := framed_mi.global_transform.affine_inverse()
	for i in framed_orig.get_surface_count():
		var m = framed_orig.surface_get_material(i)
		var skip := false
		for s in gone:
			if s.mat == m:
				skip = true
		if skip:
			continue
		var arr: Array = framed_orig.surface_get_arrays(i)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx = arr[Mesh.ARRAY_INDEX]
		if idx == null or idx.size() == 0:
			idx = PackedInt32Array(range(v.size()))
		var keep := PackedInt32Array()
		for k in range(0, idx.size() - 2, 3):
			var cen: Vector3 = framed_mi.global_transform * ((v[idx[k]] + v[idx[k + 1]] + v[idx[k + 2]]) / 3.0)
			var inside := false
			for s in gone:
				var d: Vector3 = cen - s.c
				# s.c is the print's face (0.015 m off the wall); the frame reaches deep off the wall
				var off: float = d.dot(s.n) + 0.015
				if absf(d.dot(s.r)) <= s.w * 0.5 + pad and absf(d.dot(s.u)) <= s.h * 0.5 + pad and off > -0.01 and off < deep + 0.01:
					inside = true
					break
			if not inside:
				keep.append_array([idx[k], idx[k + 1], idx[k + 2]])
		if keep.is_empty():
			continue
		arr[Mesh.ARRAY_INDEX] = keep
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		am.surface_set_material(am.get_surface_count() - 1, m)
	framed_mi.mesh = am

## The material of surface name mn in the original framed mesh.
func _framed_mat(mn: String) -> Material:
	if framed_orig:
		for i in framed_orig.get_surface_count():
			var m = framed_orig.surface_get_material(i)
			if m and m.resource_name == mn:
				return m
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color.BLACK if mn == "black" else Color("#f4efe4")
	return sm

## A new frame round picture t: the print's longer side is "long" m, the same mat and rails as the
## build (tools/stores/posters/posters.gd poster()), centred where the old print was.
func _frame_nodes(s: Dictionary, t: Texture2D) -> Array:
	var fr: Dictionary = cfg.get("framed", {})
	var LONG := float(fr.get("long", 1.15))
	var MAT := float(fr.get("mat_w", 0.06))
	var FRAME := float(fr.get("frame_w", 0.045))
	var DEEP := float(fr.get("deep", 0.032))
	var sz := t.get_size()
	var k := LONG / maxf(sz.x, sz.y)
	var w := sz.x * k
	var h := sz.y * k
	var n: Vector3 = s.n
	var r: Vector3 = s.r
	var c: Vector3 = s.c - n * 0.015          # the wall point behind the print
	var hw := w * 0.5 + MAT; var hh := h * 0.5 + MAT
	var fw := hw + FRAME; var fh := hh + FRAME
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cz := c + n * (DEEP * 0.5)
	_box(st, cz + UP * (fh - FRAME * 0.5), r, n, Vector3(2.0 * fw, FRAME, DEEP))
	_box(st, cz - UP * (fh - FRAME * 0.5), r, n, Vector3(2.0 * fw, FRAME, DEEP))
	_box(st, cz + r * (fw - FRAME * 0.5), r, n, Vector3(FRAME, 2.0 * hh, DEEP))
	_box(st, cz - r * (fw - FRAME * 0.5), r, n, Vector3(FRAME, 2.0 * hh, DEEP))
	var nodes: Array = []
	nodes.append(_mesh_node(st, _framed_mat(str(fr.get("frame", "black"))), "PicFrame_" + s.id))
	var m := c + n * 0.012
	nodes.append(_quad_node(m, r, UP, n, hw * 2.0, hh * 2.0, _framed_mat(str(fr.get("mat", "poster_mat"))), "PicMat_" + s.id))
	# the print: a copy of the ad's own material (matte newsprint with its day / night glow) with the picture
	var pm: StandardMaterial3D = (s.mat as StandardMaterial3D).duplicate() if s.mat is StandardMaterial3D else StandardMaterial3D.new()
	pm.albedo_texture = t
	if pm.emission_enabled:
		pm.emission_texture = t
	pm.resource_name = "pic_" + s.id
	nodes.append(_quad_node(c + n * 0.015, r, UP, n, w, h, pm, "PicPrint_" + s.id))
	return nodes

# ------------------------------------------------------------------ the panels
## The picture fitted inside the panel (its aspect kept) on a dark backing over the old art.
func _panel_nodes(s: Dictionary, t: Texture2D) -> Array:
	var sz := t.get_size()
	var k := minf(s.w / sz.x, s.h / sz.y)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.06, 0.06, 0.065)
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var pm := StandardMaterial3D.new()
	pm.albedo_texture = t
	pm.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if s.get("lit", false):
		pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED     # a backlit poster
	else:
		pm.roughness = 0.6
		pm.emission_enabled = true; pm.emission_texture = t; pm.emission = Color.WHITE
		pm.emission_energy_multiplier = 0.35
	pm.resource_name = "pic_" + s.id
	return [_quad_node(s.c + s.n * 0.004, s.r, s.u, s.n, s.w, s.h, bm, "PicBack_" + s.id),
		_quad_node(s.c + s.n * 0.006, s.r, s.u, s.n, sz.x * k, sz.y * k, pm, "PicPrint_" + s.id)]

# ------------------------------------------------------------------ geometry
func _quad_node(c: Vector3, r: Vector3, u: Vector3, n: Vector3, w: float, h: float, m: Material, nm: String) -> MeshInstance3D:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := c - r * w * 0.5 + u * h * 0.5      # top left: UV (0, 0)
	var b := c + r * w * 0.5 + u * h * 0.5
	var d := c + r * w * 0.5 - u * h * 0.5
	var e := c - r * w * 0.5 - u * h * 0.5
	for p in [[a, Vector2(0, 0)], [b, Vector2(1, 0)], [d, Vector2(1, 1)], [a, Vector2(0, 0)], [d, Vector2(1, 1)], [e, Vector2(0, 1)]]:
		st.set_normal(n)
		st.set_uv(p[1])
		st.add_vertex(p[0])
	return _mesh_node(st, m, nm, true)

## A box centred at c, size.x along r, size.y up, size.z along n.
func _box(st: SurfaceTool, c: Vector3, r: Vector3, n: Vector3, size: Vector3) -> void:
	var ax := [r * size.x * 0.5, UP * size.y * 0.5, n * size.z * 0.5]
	for f in 3:
		for sg in [-1.0, 1.0]:
			var nn: Vector3 = ax[f].normalized() * sg
			var o: Vector3 = c + ax[f] * sg
			var p: Vector3 = ax[(f + 1) % 3]
			var q: Vector3 = ax[(f + 2) % 3]
			var quad := [o - p - q, o + p - q, o + p + q, o - p + q]
			# wind so the face points along nn
			if (quad[1] - quad[0]).cross(quad[2] - quad[0]).dot(nn) > 0.0:
				quad = [quad[0], quad[3], quad[2], quad[1]]
			for i in [0, 1, 2, 0, 2, 3]:
				st.set_normal(nn)
				st.add_vertex(quad[i])

func _mesh_node(st: SurfaceTool, m: Material, nm: String, wind_check := false) -> MeshInstance3D:
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = nm.validate_node_name()
	mi.set_meta("pic_part", nm.get_slice("_", 0))
	mi.mesh = mesh
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	if wind_check and m is BaseMaterial3D:
		(m as BaseMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	add_child(mi)
	return mi

# ------------------------------------------------------------------ the owner's editing
func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	status = Label.new()
	status.position = Vector2(14, 320)
	status.add_theme_font_size_override("font_size", 18)
	status.add_theme_color_override("font_color", Color.WHITE)
	status.add_theme_color_override("font_outline_color", Color.BLACK)
	status.add_theme_constant_override("outline_size", 5)
	ui.add_child(status)

func _say(t: String) -> void:
	if status:
		status.text = t

## The OWNER tab's Edit pictures switch.
func set_editing(on: bool) -> void:
	if not is_owner:
		return
	editing = on
	if on:
		var sg = get_parent().get_node_or_null("Signs") if get_parent() else null
		if sg and sg.has_method("set_editing"):
			sg.set_editing(false)
			sg.set_arcade(false)
		_say("Tap a poster or ad panel to put your picture on it" if not order.is_empty() else "No posters or ad panels in this part of the mall")
	elif status and status.text.begins_with("Tap"):
		_say("")

func _input(e: InputEvent) -> void:
	if not is_owner or not editing or picking != "":
		return
	var pos = null
	var down := false
	if e is InputEventScreenTouch:
		pos = e.position; down = e.pressed
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position; down = e.pressed
	if pos == null:
		return
	if down:
		pressed = true
		press_at = pos
		press_t = Time.get_ticks_msec()
	elif pressed:
		pressed = false
		if pos.distance_to(press_at) < 14.0 and Time.get_ticks_msec() - press_t < 450:
			var id := pick_at(pos)
			if id != "":
				get_viewport().set_input_as_handled()
				choose(id)

## The slot under screen point sp: the nearest one in range, facing the camera, containing it.
func pick_at(sp: Vector2) -> String:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return ""
	var best := ""
	var best_d := 1e9
	var rng := float(cfg.get("pick_range", 16.0))
	for id in order:
		var s: Dictionary = slots[id]
		var c: Vector3 = s.c
		var dist := cam.global_position.distance_to(c)
		if dist > rng or (s.n as Vector3).dot(cam.global_position - c) <= 0.0:
			continue
		var hw: float = s.w * 0.5
		var hh: float = s.h * 0.5
		var poly := PackedVector2Array()
		var behind := false
		for q in [[-1, 1], [1, 1], [1, -1], [-1, -1]]:
			var p: Vector3 = c + s.r * hw * q[0] + s.u * hh * q[1]
			if cam.is_position_behind(p):
				behind = true
			poly.append(cam.unproject_position(p))
		if behind:
			continue
		if Geometry2D.is_point_in_polygon(sp, poly) and dist < best_d:
			best_d = dist
			best = id
	return best

## The owner tapped slot id: ask for a picture (the page's dialog; tests: picker_fn).
func choose(id: String) -> void:
	var s = slots.get(id)
	if s == null:
		return
	if picker_fn.is_valid():
		got_pick(id, picker_fn.call(id))
		return
	if not web:
		return
	var spec := {"id": id, "title": str(s.label), "custom": source_of(id) != "original", "max": int(cfg.get("max_px", 1024))}
	var ok = JavaScriptBridge.eval("(function(){if(!window.mallPictures)return '0';window.mallPictures.pick(" + JSON.stringify(JSON.stringify(spec)) + ");return '1'})()")
	if str(ok) != "1":
		_say("Pictures can't be chosen on this page")
		return
	picking = id
	poll_t = 0.0

## The dialog's answer for slot id: {data, w, h} (a new picture), {reset: true} or {} (cancel).
func got_pick(id: String, res) -> void:
	picking = ""
	if not (res is Dictionary) or res.is_empty() or res.get("cancel", false):
		return
	if res.get("reset", false):
		if published.has(id):
			draft[id] = {"reset": true}
		else:
			draft.erase(id)
		tex.erase(id)
		_save_draft()
		apply(id)
		_say("The original picture is back (publish to make it so for everyone)" if published.has(id) else "The original picture is back")
		return
	var im := decode_data(str(res.get("data", "")))
	if im == null:
		_say("That picture couldn't be read")
		return
	draft[id] = {"data": str(res.data), "w": im.get_width(), "h": im.get_height()}
	tex[id] = ImageTexture.create_from_image(im)
	_save_draft()
	apply(id)
	_say("Your picture is up here. Publish pictures (menu, OWNER) to show it to everyone.")

# ------------------------------------------------------------------ the draft
func _load_draft() -> Dictionary:
	var d = ""
	if web:
		d = JavaScriptBridge.eval("(function(){try{return localStorage.getItem('" + DRAFT_KEY + "')||''}catch(e){return ''}})()")
	else:
		d = str(Engine.get_meta("mall_pictures_draft", ""))
	var out := {}
	if d is String and d != "":
		var j = JSON.parse_string(d)
		if j is Dictionary:
			out = j
	for id in out:
		if out[id] is Dictionary and out[id].has("data"):
			var im := decode_data(str(out[id].data))
			if im != null:
				tex[id] = ImageTexture.create_from_image(im)
	return out

func _save_draft() -> void:
	var s := JSON.stringify(draft)
	if web:
		var ok = JavaScriptBridge.eval("(function(){try{if(" + ("false" if draft.is_empty() else "true") + ")localStorage.setItem('" + DRAFT_KEY + "'," + JSON.stringify(s) + ");else localStorage.removeItem('" + DRAFT_KEY + "');return '1'}catch(e){return '0'}})()")
		if str(ok) != "1":
			_say("This browser is out of room for unpublished pictures: publish them now (they show until you reload)")
	else:
		Engine.set_meta("mall_pictures_draft", s if not draft.is_empty() else "")

# ------------------------------------------------------------------ publishing
## The OWNER tab's Publish pictures: hands the draft to web/shell.html mallPictures.publish() (tests:
## publisher_fn), which uploads the pictures and merges play/posters.json; then polls its status.
func publish() -> void:
	if draft.is_empty() or publishing:
		return
	if publisher_fn.is_valid():
		_published(str(publisher_fn.call(draft.duplicate(true))))
		return
	if not web:
		_say("Publishing isn't available here")
		return
	var ok = JavaScriptBridge.eval("(function(){if(!window.mallPictures)return '0';window.mallPictures.publish(" + JSON.stringify(JSON.stringify(draft)) + ");return '1'})()")
	if str(ok) != "1":
		_say("Publishing isn't available on this page")
		return
	publishing = true
	poll_t = 0.0
	_say("Publishing pictures...")

func _published(st: String, live = null) -> void:
	publishing = false
	if st != "ok":
		_say("Not published: " + st.trim_prefix("error:").strip_edges())
		return
	if live is Dictionary:
		published = live
	else:
		for id in draft:
			if draft[id].get("reset", false):
				published.erase(id)
			else:
				published[id] = {"file": "posters/(new)", "w": draft[id].get("w", 0), "h": draft[id].get("h", 0)}
	draft.clear()
	_save_draft()
	_say("Published. Everyone sees the pictures in about a minute.")

func _process(dt: float) -> void:
	if picking == "" and not publishing:
		return
	poll_t += dt
	if poll_t < 0.25:
		return
	poll_t = 0.0
	if picking != "":
		var r = JavaScriptBridge.eval("window.mallPictures ? window.mallPictures.take() : '{\"cancel\":1}'")
		if r is String and r != "":
			var j = JSON.parse_string(r)
			got_pick(picking, j if j is Dictionary else {})
		return
	var s = JavaScriptBridge.eval("window.mallPictures ? window.mallPictures.status : 'error: no publisher'")
	if not (s is String) or s == "busy":
		return
	var live = null
	if s == "ok":
		var lj = JSON.parse_string(str(JavaScriptBridge.eval("window.mallPictures.published || '{}'")))
		if lj is Dictionary:
			live = lj
	_published(s, live)
