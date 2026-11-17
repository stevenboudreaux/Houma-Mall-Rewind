## PHONE-MEMORY stage 2 (Nov 17 2026; production/qa/evidence/wsPHONE-MEMORY-options.md): matched shots of the phone
## texture options, natively (opengl3 under xvfb, the baked lightmaps on), every variant from the same camera.
##   xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 \
##     --script res://tools/qa/phone_options_shots.gd -- --wing=1 [--year=2026] --need=1,2,4 --out=/path/prefix \
##     --variants=base,astc_t1,astc_t12,etc2_t12,half_t1 --cams="name:x,z,yaw,pitch;..." [--focus="name:substring;..."]
## Waits until the wings in --need are in (streaming on, desktop behaviour), then per variant puts the textures back,
## swaps the chosen ones and renders every camera to <out>-<cam>-<variant>.jpg.
## Variants (tiers as tools/qa/packmemory.py's inventory sorts them; the same rules as the options doc):
##   base      the textures as they ship (lossless WebP decoded)
##   astc_t1   group 1 (Blender items, cast, plain building materials: no lettering) as ASTC 4x4 (1 byte a pixel)
##   astc_t12  groups 1 and 2 (plus shop stock, racks, fixtures) as ASTC 4x4
##   etc2_t12  groups 1 and 2 as ETC2 (RGB 0.5 / RGBA 1 byte a pixel)
##   half_t1   group 1 at half width and height, uncompressed (the same memory as ASTC 4x4)
## Signs, the directory, ads, posters, marquees, stand-ins and UI are never changed. On this renderer ASTC and ETC2
## are decoded on the CPU before upload, so the picture shows the formats' own loss, as a phone would draw it.
## --focus: a camera 1.6 m in front of the first mesh that uses a texture whose path contains the substring.
extends SceneTree

const KEEP := "^(tex/sg/|tex/dir/|tex/standin/|tex/ads/|tex/items/|addons/|fonts/|tex/y95/)|sign|logo|letter|marquee|poster|menu|header|title|text|word|lease|cards|plaque|banner"
const T1 := "^(models/bl_|cast/|npc/)|brick|block|concrete|stucco|grey_tile|buff_tile|terrazzo|carpet|ceiling|marble|stone|wood|metal|_normal|_orm|floor|wall_|_wall|plaster|tile"
var wing := 1
var year := 1995
var need := [1, 2]
var out := "/tmp/phone"
var cams := []
var focus := []
var variants := ["base"]
var ws
var t := 0.0
var ci := -1
var vi := 0
var frames := 0
var slots := []          # [object, property or "shader:<name>", original texture, source path]
var cache := {}          # "<variant>|<path>" -> texture
var re_keep := RegEx.new()
var re_t1 := RegEx.new()

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--wing="): wing = int(a.substr(7))
		elif a.begins_with("--year="): year = int(a.substr(7))
		elif a.begins_with("--need="): need = Array(a.substr(7).split(",")).map(func(v): return int(v))
		elif a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--variants="): variants = Array(a.substr(11).split(","))
		elif a.begins_with("--cams="):
			for c in a.substr(7).split(";"):
				var v := c.get_slice(":", 1).split(",")
				cams.append([c.get_slice(":", 0), float(v[0]), float(v[1]), float(v[2]), float(v[3])])
		elif a.begins_with("--focus="):
			for c in a.substr(8).split(";"):
				focus.append([c.get_slice(":", 0), c.get_slice(":", 1)])
	re_keep.compile("(?i)" + KEEP)
	re_t1.compile("(?i)" + T1)
	Engine.set_meta("mall_state_%d" % year, "")
	Engine.set_meta("mall_stream", true)
	Engine.set_meta("mall_stream_kind", "desktop")
	Engine.set_meta("mall_upfront", false)
	Engine.set_meta("mall_flags", {"v": 1, "flags": {"cinema_unlocked": true}})
	var scn: Node = load(("res://wing%d_2026.tscn" if year == 2026 else "res://wing%d.tscn") % wing).instantiate()
	root.add_child(scn)
	current_scene = scn

func _tier(path: String) -> String:
	var s := path.trim_prefix("res://")
	if re_keep.search(s): return "keep"
	if re_t1.search(s): return "t1"
	return "t2"

func _all(n: Node) -> Array:
	var o := [n]
	for c in n.get_children():
		o.append_array(_all(c))
	return o

## every material slot in the tree that holds a lossless picture (a .png / .jpg source)
func _collect() -> void:
	slots.clear()
	var seen := {}
	var mats := []
	for n in _all(root):
		if n is GeometryInstance3D:
			if n.material_override: mats.append(n.material_override)
			if n.material_overlay: mats.append(n.material_overlay)
		if n is MeshInstance3D and n.mesh:
			for i in n.mesh.get_surface_count():
				if n.mesh.surface_get_material(i): mats.append(n.mesh.surface_get_material(i))
			for i in n.get_surface_override_material_count():
				if n.get_surface_override_material(i): mats.append(n.get_surface_override_material(i))
	while not mats.is_empty():
		var m: Material = mats.pop_back()
		if m == null or seen.has(m.get_instance_id()): continue
		seen[m.get_instance_id()] = true
		if m.next_pass: mats.append(m.next_pass)
		if m is ShaderMaterial and m.shader:
			for u in m.shader.get_shader_uniform_list():
				var v = m.get_shader_parameter(u.name)
				if v is Texture2D and _src(v) != "":
					slots.append([m, "shader:" + u.name, v, _src(v)])
		else:
			for pr in m.get_property_list():
				if pr.type == TYPE_OBJECT:
					var v = m.get(pr.name)
					if v is Texture2D and _src(v) != "":
						slots.append([m, pr.name, v, _src(v)])

func _src(tx: Texture2D) -> String:
	var p := tx.resource_path
	if p.get_extension().to_lower() in ["png", "jpg", "jpeg", "webp"] and not ("::" in p):
		return p
	return ""

func _put_tex(sl: Array, tx: Texture2D) -> void:
	var prop: String = sl[1]
	if prop.begins_with("shader:"):
		(sl[0] as ShaderMaterial).set_shader_parameter(prop.substr(7), tx)
	else:
		sl[0].set(prop, tx)

func _variant_tex(v: String, path: String, orig: Texture2D) -> Texture2D:
	var key := v + "|" + path
	if cache.has(key): return cache[key]
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null or img.is_empty():
		cache[key] = orig
		return orig
	var had_mips := orig.get_image() != null and orig.get_image().has_mipmaps()
	if img.get_format() != Image.FORMAT_RGBA8 and img.get_format() != Image.FORMAT_RGB8:
		img.convert(Image.FORMAT_RGBA8 if img.detect_alpha() != Image.ALPHA_NONE else Image.FORMAT_RGB8)
	if v.begins_with("half"):
		img.resize(maxi(1, img.get_width() / 2), maxi(1, img.get_height() / 2), Image.INTERPOLATE_LANCZOS)
	if had_mips: img.generate_mipmaps()
	if v.begins_with("astc"):
		img.compress(Image.COMPRESS_ASTC, Image.COMPRESS_SOURCE_GENERIC, Image.ASTC_FORMAT_4x4)
	elif v.begins_with("etc2"):
		img.compress(Image.COMPRESS_ETC2, Image.COMPRESS_SOURCE_GENERIC)
	var tx := ImageTexture.create_from_image(img)
	cache[key] = tx
	return tx

func _apply(v: String) -> void:
	var n := 0
	for sl in slots:
		_put_tex(sl, sl[2])
	if v == "base": return
	var want := ["t1"] if v.ends_with("_t1") else ["t1", "t2"]
	for sl in slots:
		if _tier(sl[3]) in want:
			_put_tex(sl, _variant_tex(v, sl[3], sl[2]))
			n += 1
	print("variant %s: %d slots changed" % [v, n])

## the first mesh using a texture whose path contains sub: a camera 1.6 m in front of it, at eye height
func _focus_cam(nm: String, sub: String) -> Array:
	for n in _all(root):
		if not (n is MeshInstance3D) or n.mesh == null or not n.is_visible_in_tree(): continue
		var hit := false
		for sl in slots:
			if sub in str(sl[3]):
				for i in n.mesh.get_surface_count():
					if n.mesh.surface_get_material(i) == sl[0] or n.get_surface_override_material(i) == sl[0] or n.material_override == sl[0]:
						hit = true
		if hit:
			var aabb: AABB = n.global_transform * n.get_aabb()
			var c := aabb.get_center()
			var from := c + Vector3(1.6, 0, 0.6)
			var d := c - from
			var yaw := rad_to_deg(atan2(-d.x, -d.z))
			var pitch := rad_to_deg(atan2(c.y - 1.6, Vector2(d.x, d.z).length()))
			print("focus %s: %s at %s" % [nm, n.name, str(c)])
			return [nm, from.x, from.z, yaw, pitch]
	print("focus %s: nothing uses %s" % [nm, sub])
	return []

func _process(dt: float) -> bool:
	t += dt
	ws = root.get_node_or_null("WingStream")
	var p = current_scene.get_node_or_null("Player") if current_scene else null
	if ws == null or p == null: return false
	if ci == -1:
		ws.cfg["start_delay_s"] = 0.0
		var ok := t > 3.0
		for w in need:
			if not (w == ws.home_wing or ws.is_in(w)): ok = false
		if ws._span_changed(): ok = false
		if ok or t > 1500.0:
			if not ok: print("NOT ALL IN: ", ws.span())
			_collect()
			print("%d lossless slots" % slots.size())
			for f in focus:
				var fc := _focus_cam(f[0], f[1])
				if not fc.is_empty(): cams.append(fc)
			ci = 0; vi = 0; frames = 0
			_apply(variants[0])
		return false
	if vi >= variants.size():
		print("PHONE SHOTS DONE")
		return true
	if ci >= cams.size():
		vi += 1; ci = 0; frames = 0
		if vi < variants.size(): _apply(variants[vi])
		return false
	var c: Array = cams[ci]
	if frames == 0:
		p.position = Vector3(c[1], 0, c[2]); p.yaw = deg_to_rad(c[3]); p.pitch = deg_to_rad(c[4]); p._apply_rot()
		p.hint.visible = false
	frames += 1
	if frames >= 40:
		root.get_texture().get_image().save_jpg("%s-%s-%s.jpg" % [out, c[0], variants[vi]], 0.9)
		print("wrote %s-%s-%s.jpg" % [out, c[0], variants[vi]])
		ci += 1; frames = 0
	return false
