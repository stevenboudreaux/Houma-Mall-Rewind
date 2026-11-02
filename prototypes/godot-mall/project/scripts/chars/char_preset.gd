## B2 (design/godot-character-editor.md): character PRESETS as data, and the loader that dresses a
## CharBody (scripts/char_body.gd, B1) from one.
##
## A preset is data/characters/<id>.json:
##   {"id", "name", "body": "female"|"male", "keys": {slider: value}, "skin": "#hex", "iris": "#hex",
##    "hair": {"id": "hair_long" | "", "color": "#hex"},
##    "outfit": {"base_top", "base_bottom", "under", "top", "bottom", "full", "outer", "shoes",
##               "extras": [ids], "colors": {piece base_id: {region: "#hex"}},
##               "patterns": {piece base_id: "stripes"}}}
## Piece ids are B1's base ids (characters.json "pieces" base_id: "top_tee", not "top_tee_female").
## "" = nothing in that slot. Unknown keys are kept (so a later field survives a round trip).
##
## The base-layer rule is enforced in normalize() and again by CharBody itself (ensure_base, take_off):
## female presets always have a base top and a base bottom (a missing one gets the default), male
## presets always a base bottom; a male base top is optional. Nothing here can remove a female base top.
##
## Owner edits are kept per browser in localStorage "mall-char-<id>" (get_preset() prefers them, so Steven
## sees his edit in the mall at once); the repo copy changes only when Steven commits the downloaded
## file into data/characters/. The player's own preset is "mall-avatar-preset-1".
class_name CharPreset
extends RefCounted

const DIR := "res://data/characters/"
const LOCAL_PREFIX := "mall-char-"
const PLAYER_KEY := "mall-avatar-preset-1"
const VERSION := 1

## The editor's outfit slots, in the order the OUTFIT tab lists them (layer by layer).
## slot: the editor slot; from: B1 slots whose pieces it offers; layer: B1 layers it offers (-1 any);
## as_layer: the layer the piece is worn on in this slot (-1 its own).
const SLOTS := [
	{"slot": "under", "label": "Underlayer", "from": ["top"], "only": ["top_tee", "top_tank", "top_babytee"], "as_layer": 1},
	{"slot": "top", "label": "Top", "from": ["top"], "layer": 2},
	{"slot": "bottom", "label": "Bottom", "from": ["bottom"]},
	{"slot": "full", "label": "Full outfit", "from": ["full"]},
	{"slot": "outer", "label": "Outerwear", "from": ["outer", "top"], "layer": 3},
	{"slot": "shoes", "label": "Shoes", "from": ["shoes"]},
	{"slot": "hat", "label": "Hat", "from": ["hat"], "extra": true},
	{"slot": "glasses", "label": "Glasses", "from": ["glasses"], "extra": true},
	{"slot": "watch", "label": "Watch", "from": ["watch"], "extra": true},
]
const BASE_SLOTS := [
	{"slot": "base_top", "label": "Base top", "from": ["base_top", "base_full"]},
	{"slot": "base_bottom", "label": "Base bottom", "from": ["base_bottom", "base_full"]},
]
const OUTFIT_KEYS := ["base_top", "base_bottom", "under", "top", "bottom", "full", "outer", "shoes"]

# ------------------------------------------------------------------ the data
static func man() -> Dictionary:
	return CharBody.cman()

## A new preset: the body at neutral in its base layer only (female: base top + bottom).
static func blank(sex := "female") -> Dictionary:
	var p := {"id": "", "name": "", "body": sex, "keys": {}, "skin": "#c99a7c", "iris": "#5a3a22",
		"hair": {"id": "", "color": "#3a2a1e"}, "outfit": {}}
	return normalize(p)

## Every preset id shipped in data/characters/ (file names without .json).
static func list_ids() -> Array:
	var out := []
	var d := DirAccess.open(DIR)
	if d == null: return out
	for f in d.get_files():
		var n := str(f).trim_suffix(".remap")
		if n.ends_with(".json") and not n.begins_with("_"): out.append(n.trim_suffix(".json"))
	out.sort()
	return out

## The repo copy of a preset (data/characters/<id>.json), normalized; {} if there is none.
static func load_repo(id: String) -> Dictionary:
	var path := DIR + id + ".json"
	if not FileAccess.file_exists(path): return {}
	var j = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not (j is Dictionary): return {}
	j.id = id
	return normalize(j)

## A preset as the game uses it: this browser's saved edit when there is one, else the repo copy.
static func get_preset(id: String, use_local := true) -> Dictionary:
	if use_local:
		var s := local_get(LOCAL_PREFIX + id)
		if s != "":
			var j = JSON.parse_string(s)
			if j is Dictionary:
				j.id = id
				return normalize(j)
	return load_repo(id)

## Make a preset valid: known sex, sliders in range and for this body, colours as #hex, every slot
## present, pieces that exist for this body, and THE BASE RULE (see the top of this file).
static func normalize(src: Dictionary) -> Dictionary:
	var p: Dictionary = src.duplicate(true)
	var sex := str(p.get("body", "female"))
	if sex != "female" and sex != "male": sex = "female"
	p.body = sex
	p.version = VERSION
	p.id = str(p.get("id", ""))
	p.name = str(p.get("name", ""))
	var keys := {}
	var kin = p.get("keys", {})
	if kin is Dictionary:
		for sl in man().sliders:
			if sl.has("sex") and str(sl.sex) != sex: continue
			if kin.has(sl.name):
				var x := clampf(float(kin[sl.name]), float(sl.range[0]), float(sl.range[1]))
				if absf(x) > 0.0005: keys[sl.name] = snappedf(x, 0.001)
	p.keys = keys
	p.skin = _hex(p.get("skin", ""), "#c99a7c")
	p.iris = _hex(p.get("iris", ""), "#5a3a22")
	var h = p.get("hair", {})
	if not (h is Dictionary): h = {"id": str(h)}
	var hid := str(h.get("id", ""))
	if hid != "" and (_entry(sex, hid).is_empty() or not in_pack(_entry(sex, hid))): hid = ""
	p.hair = {"id": hid, "color": _hex(h.get("color", ""), "#3a2a1e")}
	var o = p.get("outfit", {})
	if not (o is Dictionary): o = {}
	var out := {}
	for k in OUTFIT_KEYS:
		var v := str(o.get(k, ""))
		if v != "" and not slot_offers(sex, k, v): v = ""
		out[k] = v
	var ex := []
	for v in o.get("extras", []):
		var e := _entry(sex, str(v))
		if not e.is_empty() and in_pack(e) and not ex.has(str(e.base_id)): ex.append(str(e.base_id))
	out.extras = ex
	# full outfits replace top / bottom / underlayer (CharBody.CLASHES)
	if out.full != "":
		out.top = ""; out.bottom = ""; out.under = ""
	if out.under != "" and out.under == out.top: out.under = ""
	# the one-piece is both base slots
	if _is_full_base(sex, out.base_top) or _is_full_base(sex, out.base_bottom):
		var one: String = out.base_top if _is_full_base(sex, out.base_top) else out.base_bottom
		out.base_top = one; out.base_bottom = one
	# ---- THE BASE RULE (Steven, Nov 2). No flag or option skips it.
	var dflt: Dictionary = CharBody.BASE_DEFAULT[sex]
	for sl in CharBody.base_required(sex):
		if str(out[sl]) == "": out[sl] = str(dflt[sl])
	var cols := {}
	var cin = o.get("colors", {})
	if cin is Dictionary:
		for k in cin:
			if cin[k] is Dictionary:
				var c := {}
				for r in cin[k]: c[str(r)] = _hex(cin[k][r], "#808080")
				cols[str(k)] = c
	out.colors = cols
	var pats := {}
	var pin = o.get("patterns", {})
	if pin is Dictionary:
		for k in pin: pats[str(k)] = str(pin[k])
	out.patterns = pats
	p.outfit = out
	return p

static func _is_full_base(sex: String, id: String) -> bool:
	if id == "": return false
	var e := _entry(sex, id)
	return not e.is_empty() and str(e.slot) == "base_full"

static func _hex(v, fallback: String) -> String:
	var s := str(v)
	if s == "" or s == "<null>": return fallback
	var c := Color.from_string(s, Color(-1, 0, 0))
	if c.r < 0.0: return fallback
	return "#" + c.to_html(false)

## The manifest entry of a base id for a body ({} if it doesn't exist for that body).
static func _entry(sex: String, id: String) -> Dictionary:
	for e in man().pieces:
		if str(e.body) == sex and (str(e.base_id) == id or str(e.id) == id): return e
	return {}

## The editor slot description (SLOTS / BASE_SLOTS) of a slot name, or {}.
static func slot_info(slot: String) -> Dictionary:
	for s in SLOTS + BASE_SLOTS:
		if s.slot == slot: return s
	if slot == "hair": return {"slot": "hair", "label": "Hair", "from": ["hair"]}
	return {}

## The pieces (manifest entries) an editor slot offers for a body, in manifest order.
static func options(sex: String, slot: String) -> Array:
	var si := slot_info(slot)
	if si.is_empty(): return []
	var out := []
	for e in man().pieces:
		if str(e.body) != sex or not (si.from as Array).has(str(e.slot)): continue
		if si.has("layer") and int(e.layer) != int(si.layer): continue
		if si.has("only") and not (si.only as Array).has(str(e.base_id)): continue
		if not in_pack(e): continue
		out.append(e)
	return out

## Whether this pack ships a piece (each wing / year pack ships only its presets' pieces and the
## player's wardrobe, tools/chars/pack_list.py). Cached.
static var _have := {}
static func in_pack(e: Dictionary) -> bool:
	var g := str(e.glb)
	if not _have.has(g): _have[g] = ResourceLoader.exists(g)
	return _have[g]

static func slot_offers(sex: String, slot: String, id: String) -> bool:
	for e in options(sex, slot):
		if str(e.base_id) == id: return true
	return false

## The entry to wear for a piece in an editor slot: the manifest entry with the slot (and layer)
## that slot wears it as (an underlayer tee is layer 1, slot "under"; a flannel slot "outer").
static func worn_entry(sex: String, slot: String, id: String) -> Dictionary:
	var e := _entry(sex, id)
	if e.is_empty(): return {}
	var si := slot_info(slot)
	if slot in ["under", "outer"]:
		e = e.duplicate(true)
		e.slot = slot
		if int(si.get("as_layer", -1)) >= 0: e.layer = int(si.as_layer)
	return e

## Every piece entry a preset wears, base layer first.
static func worn(p: Dictionary) -> Array:
	var sex: String = p.body
	var o: Dictionary = p.outfit
	var out := []
	var seen := {}
	for k in OUTFIT_KEYS:
		var id := str(o.get(k, ""))
		if id == "" or seen.has(id): continue
		seen[id] = true
		var e := worn_entry(sex, k, id)
		if not e.is_empty(): out.append(e)
	for id in o.get("extras", []):
		var e := _entry(sex, str(id))
		if not e.is_empty(): out.append(e)
	if str(p.hair.id) != "":
		var e := _entry(sex, str(p.hair.id))
		if not e.is_empty(): out.append(e)
	return out

## Strip to base: the preset with only its base layer (and hair) left. For a female preset that is
## exactly a base top + a base bottom (or the one-piece); for a male one a base bottom (+ the base
## top if one was chosen).
static func stripped(p: Dictionary) -> Dictionary:
	var q: Dictionary = p.duplicate(true)
	for k in ["under", "top", "bottom", "full", "outer", "shoes"]: q.outfit[k] = ""
	q.outfit.extras = []
	return normalize(q)

# ------------------------------------------------------------------ dressing a body
## Dress body cb (a CharBody already in the tree) as preset p: remake it if the sex differs, swap
## pieces to exactly the preset's, set the sliders, paint every colour. live_hi: the close-up body.
static func dress(cb: CharBody, p: Dictionary, hi := false) -> void:
	p = normalize(p)
	if cb.sk == null or cb.sex != str(p.body) or bool(cb.get_meta("hi", false)) != hi:
		cb.make(str(p.body), hi)
		cb.set_meta("hi", hi)
	var want := worn(p)
	var want_ids := {}
	for e in want: want_ids[str(e.id)] = e
	# off: anything not wanted, or wanted in another slot (an underlayer tee made a top)
	for k in cb.pieces.keys():
		if not want_ids.has(k) or str(want_ids[k].slot) != str(cb.pieces[k].slot):
			cb._remove(k)
	var add := []
	for e in want:
		if not cb.pieces.has(str(e.id)): add.append(e)
	cb.values = p.keys.duplicate()
	cb.weights = CharBody.shape_weights(cb.values, cb.sex)
	if not add.is_empty():
		cb.wear_many(add)      # bones + layers once
	cb.apply(p.keys)           # weights on every mesh (new pieces too), bones, layers
	paint(cb, p)

## A new NPC body dressed as preset p (not yet in the tree; add it, as NpcBody.set_skin allows).
## bake_it: bake the blend shapes into fixed meshes (NPCs in the mall); false for live editing.
static func body_for(p: Dictionary, bake_it := true) -> CharBody:
	var cb := CharBody.new()
	dress(cb, p)
	cb.set_meta("preset", str(p.get("id", "")))
	if bake_it:
		var ms := bake(cb)
		print("char_preset: %s dressed and baked (%d tris, %.0f ms)" % [p.get("id", "?"), tris(cb), ms])
	return cb

## Every colour of a preset onto a dressed body.
static func paint(cb: CharBody, p: Dictionary) -> void:
	cb.paint("skin_", Color.from_string(str(p.skin), Color.WHITE))
	cb.paint("eye_iris", Color.from_string(str(p.iris), Color.BROWN))
	var hc := Color.from_string(str(p.hair.color), Color.BLACK)
	cb.paint("hair_", hc)
	cb.paint("lashes", hc.darkened(0.3))
	var cols: Dictionary = p.outfit.colors
	var pats: Dictionary = p.outfit.patterns
	for k in cb.pieces:
		var e: Dictionary = cb.pieces[k]
		var bid := str(e.base_id)
		var mine: Dictionary = cols.get(bid, {})
		for r in e.get("materials", {}):
			if str(r) == "hair": continue
			var hexs := str(mine.get(r, e.materials[r].get("default", "")))
			if hexs == "": continue
			cb.paint(str(e.id) + "_" + str(r), Color.from_string(hexs, Color.GRAY))
		if e.get("patterns", false):
			pattern(cb, e, str(pats.get(bid, "solid")))

## A base-layer piece's pattern (characters.json "patterns"): the main region's albedo map swapped
## for pattern_<name>.png (solid = the piece's own fabric).
static func pattern(cb: CharBody, e: Dictionary, pname: String) -> void:
	var path := "res://models/characters/pattern_%s.png" % pname
	for mi in cb.sk.find_children("*", "MeshInstance3D", true, false):
		if str(mi.get_meta("piece", "")) != str(e.id) or mi.mesh == null: continue
		for i in range(mi.mesh.get_surface_count()):
			var m = mi.get_surface_override_material(i)
			if not (m is ShaderMaterial) or not str(m.resource_name).ends_with("_main"): continue
			if not m.has_meta("own_tex"):
				m.set_meta("own_tex", m.get_shader_parameter("albedo_tex"))
			if pname == "solid" or not ResourceLoader.exists(path):
				m.set_shader_parameter("albedo_tex", m.get_meta("own_tex"))
			else:
				m.set_shader_parameter("albedo_tex", load(path))
				m.set_shader_parameter("has_albedo", true)

## The pattern names B1 painted (characters.json "patterns" or the files).
static func pattern_names() -> Array:
	var p = man().get("patterns", [])
	return p if p is Array and not p.is_empty() else ["solid", "stripes", "dots", "floral", "check"]

# ------------------------------------------------------------------ baking (NPCs)
## Bake: every blend shape at its current weight is applied into a new fixed mesh (positions and
## normals), so no blend shapes run per frame. Bones keep the preset's joint offsets (set by
## CharBody._bones before). The editor never bakes (it needs the live shapes). Returns ms spent.
static func bake(cb: CharBody) -> float:
	var t0 := Time.get_ticks_usec()
	for mi in cb.sk.find_children("*", "MeshInstance3D", true, false):
		bake_mesh(mi)
	cb.set_meta("baked", true)
	return float(Time.get_ticks_usec() - t0) / 1000.0

static func bake_mesh(mi: MeshInstance3D) -> void:
	var m := mi.mesh as ArrayMesh
	if m == null or m.get_blend_shape_count() == 0: return
	var w := PackedFloat32Array()
	for i in range(m.get_blend_shape_count()):
		w.append(mi.get_blend_shape_value(i))
	var relative := m.blend_shape_mode == Mesh.BLEND_SHAPE_MODE_RELATIVE
	var nm := ArrayMesh.new()
	var overrides := []
	for s in range(m.get_surface_count()):
		overrides.append(mi.get_surface_override_material(s))
		var arr := m.surface_get_arrays(s)
		var bsa := m.surface_get_blend_shape_arrays(s)
		var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var n: PackedVector3Array = arr[Mesh.ARRAY_NORMAL] if arr[Mesh.ARRAY_NORMAL] != null else PackedVector3Array()
		var v0 := v.duplicate()
		var n0 := n.duplicate()
		var has_n := n.size() == v.size()
		for i in range(w.size()):
			var wi := w[i]
			if absf(wi) < 0.0001 or i >= bsa.size(): continue
			var bv: PackedVector3Array = bsa[i][Mesh.ARRAY_VERTEX]
			var bn = bsa[i][Mesh.ARRAY_NORMAL]
			var nn := has_n and bn is PackedVector3Array and (bn as PackedVector3Array).size() == v.size()
			if relative:
				for k in range(v.size()):
					v[k] += bv[k] * wi
				if nn:
					for k in range(n.size()): n[k] += (bn as PackedVector3Array)[k] * wi
			else:
				for k in range(v.size()):
					v[k] += (bv[k] - v0[k]) * wi
				if nn:
					for k in range(n.size()): n[k] += ((bn as PackedVector3Array)[k] - n0[k]) * wi
		if has_n:
			for k in range(n.size()): n[k] = n[k].normalized()
			arr[Mesh.ARRAY_NORMAL] = n
		arr[Mesh.ARRAY_VERTEX] = v
		var fmt := m.surface_get_format(s)
		var flags := fmt & Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS
		nm.add_surface_from_arrays(m.surface_get_primitive_type(s), arr, [], {}, flags)
		nm.surface_set_material(s, m.surface_get_material(s))
		nm.surface_set_name(s, m.surface_get_name(s))
	nm.resource_name = m.resource_name + "_baked"
	mi.mesh = nm
	for s in range(overrides.size()):
		if overrides[s] != null: mi.set_surface_override_material(s, overrides[s])

## Triangles drawn by a body (every mesh under the skeleton).
static func tris(cb: CharBody) -> int:
	var t := 0
	for mi in cb.sk.find_children("*", "MeshInstance3D", true, false):
		if mi.mesh == null: continue
		for s in range(mi.mesh.get_surface_count()):
			var a: Array = mi.mesh.surface_get_arrays(s)
			var idx = a[Mesh.ARRAY_INDEX]
			t += (idx.size() if idx != null else (a[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return t

# ------------------------------------------------------------------ saving
## The preset as the JSON text a file in data/characters/ holds (sorted keys, tabs).
static func to_json(p: Dictionary) -> String:
	var q := normalize(p)
	q["_"] = "B2 character preset (design/godot-character-editor.md). Edited in the owner's character editor; commit this file as data/characters/%s.json." % str(q.id)
	return JSON.stringify(q, "\t", true) + "\n"

## Keep an owner's edit in this browser (the game loads it in place of the repo copy).
static func save_local(id: String, p: Dictionary) -> void:
	local_set(LOCAL_PREFIX + id, JSON.stringify(normalize(p)))

static func forget_local(id: String) -> void:
	local_set(LOCAL_PREFIX + id, "")

static func has_local(id: String) -> bool:
	return local_get(LOCAL_PREFIX + id) != ""

## Offer the file for download (web), or write it to user://characters/ (native; the path is returned).
static func download(id: String, p: Dictionary) -> String:
	var txt := to_json(p)
	var fname := (id if id != "" else "preset") + ".json"
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(txt.to_utf8_buffer(), fname, "application/json")
		return fname
	DirAccess.make_dir_recursive_absolute("user://characters")
	var f := FileAccess.open("user://characters/" + fname, FileAccess.WRITE)
	if f == null: return ""
	f.store_string(txt)
	f.close()
	return ProjectSettings.globalize_path("user://characters/" + fname)

## The player's own preset ({} until one is saved).
static func player_preset() -> Dictionary:
	var s := local_get(PLAYER_KEY)
	if s == "": return {}
	var j = JSON.parse_string(s)
	return normalize(j) if j is Dictionary else {}

static func save_player(p: Dictionary) -> void:
	var q := normalize(p)
	q.id = "player"
	local_set(PLAYER_KEY, JSON.stringify(q))

# localStorage on the web, Engine meta elsewhere (tests)
static func local_get(k: String) -> String:
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||''}catch(e){return ''}})()" % JSON.stringify(k))
		return str(v) if v != null else ""
	return str(Engine.get_meta("ls_" + k.replace("-", "_"), ""))

static func local_set(k: String, v: String) -> void:
	if OS.has_feature("web"):
		if v == "":
			JavaScriptBridge.eval("(function(){try{localStorage.removeItem(%s)}catch(e){}})()" % JSON.stringify(k))
		else:
			JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s)}catch(e){}})()" % [JSON.stringify(k), JSON.stringify(v)])
		return
	Engine.set_meta("ls_" + k.replace("-", "_"), v)
