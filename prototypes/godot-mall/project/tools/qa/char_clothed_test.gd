## B-FIX (Steven, Nov 2, final): in the live game ALL characters are clothed AT ALL TIMES.
## Walks every slider of both bodies (each end, adult and child), every preset (the repo's, B1's shape
## presets and extremes), a hand-written preset JSON that tries to bypass the editor
## (tools/qa/fixtures/char_bypass_preset.json) through every load path, the CharBody API directly, and
## the editor's own rows; asserts every body is fully clothed (a closed top and a bottom, or a full
## outfit), child bodies wear only CharBody.CHILD_ALLOW pieces, refused pieces are refused, the base
## layer is painted and the lingerie / base-layer pieces are gone. No rendering, no screenshots.
##   godot --headless --path . --script res://tools/qa/char_clothed_test.gd
## Prints CHAR CLOTHED OK (n checks) or CHAR CLOTHED FAILED (...), exit code 0 / 1.
extends SceneTree

const FIXTURE := "res://tools/qa/fixtures/char_bypass_preset.json"
const EDITOR := "res://scripts/chars/char_editor.gd"
## Adult-only pieces a child must never wear (CHILD_ALLOW is the rule; these are spot checks).
const ADULT_ONLY := ["bot_shortshorts", "top_babytee", "top_tank", "bot_skirt", "full_cheer", "full_waitress",
	"full_football", "full_coveralls", "full_storevest", "full_storeapron"]
const GONE := ["base_lacebra", "base_panties", "base_bikinitop", "base_bikinibottom", "base_onepiece", "base_camisole",
	"base_sportsbra", "base_briefs", "base_boyshorts", "base_boxerbriefs", "base_mbriefs", "base_boxers",
	"base_swimtrunks", "base_tank", "base_fittedtee"]

var host: Node3D
var errors := []
var oks := 0
var quiet := 0

func _initialize() -> void:
	host = Node3D.new()
	root.add_child(host)
	await process_frame
	_assets()
	_presets_data()
	await _bodies_api()
	await _sliders()
	await _presets_dressed()
	await _bypass_paths()
	await _editor()
	if errors.is_empty() and oks > 0:
		print("CHAR CLOTHED OK (%d checks, %d of them in loops not printed)" % [oks, quiet])
	else:
		print("CHAR CLOTHED FAILED (%d of %d): %s" % [errors.size(), errors.size() + oks, " | ".join(errors)])
	quit(0 if errors.is_empty() and oks > 0 else 1)

func _check(ok: bool, what: String, loud := true) -> void:
	if ok:
		oks += 1
		if loud: print("ok   " + what)
		else: quiet += 1
	else:
		print("FAIL " + what)
		errors.append(what)

func _wait(n: int) -> void:
	for i in n: await process_frame

# ------------------------------------------------------------------ helpers
func _ids(cb: CharBody) -> Array:
	var a := []
	for k in cb.pieces: a.append(str(cb.pieces[k].base_id))
	a.sort()
	return a

## Every rule on one live body: clothed; nothing from the base layer; a child wears only allowed pieces
## and has no bust shape.
func _body_ok(cb: CharBody, what: String, loud := false) -> void:
	_check(cb.is_clothed(), "%s: clothed %s" % [what, _ids(cb)], loud)
	var bad := []
	for k in cb.pieces:
		var e: Dictionary = cb.pieces[k]
		if str(e.slot).begins_with("base_"): bad.append(k)
		if CharBody.is_child(cb.values) and not CharBody.child_ok(e): bad.append(k)
	_check(bad.is_empty(), "%s: no refused piece worn %s" % [what, bad], loud)
	if CharBody.is_child(cb.values):
		var w := 0.0
		for n in ["bust+", "bust-", "bust_lift+", "bust_lift-"]: w += float(cb.weights.get(n, 0.0))
		_check(w == 0.0, "%s: child body has no bust shape" % what, loud)

## Every rule on one preset dictionary (after normalize()).
func _preset_ok(p: Dictionary, what: String, loud := false) -> void:
	var o: Dictionary = p.outfit
	var clothed := CharBody.covers({"base_id": o.full}) == "full" or \
		((CharBody.covers({"base_id": o.top}) == "top" or CharBody.covers({"base_id": o.under}) == "top")
			and CharBody.covers({"base_id": o.bottom}) == "bottom")
	_check(clothed, "%s: preset clothed (top %s, under %s, bottom %s, full %s)" % [what, o.top, o.under, o.bottom, o.full], loud)
	var all := []
	for k in CharPreset.OUTFIT_KEYS: all.append(str(o.get(k, "")))
	all += o.extras
	var bad := []
	for k in o:
		if str(k).begins_with("base_"): bad.append(str(k))
	for id in all:
		if str(id).begins_with("base_"): bad.append(str(id))
		if id != "" and CharBody.is_child(p.keys) and not CharBody.CHILD_ALLOW.has(str(id)): bad.append(str(id))
	if str(p.hair.id) != "" and not str(p.hair.id).begins_with("hair_"): bad.append(str(p.hair.id))
	_check(bad.is_empty(), "%s: preset holds no refused piece %s" % [what, bad], loud)
	if CharBody.is_child(p.keys):
		_check(not p.keys.has("bust") and not p.keys.has("bust_lift"), "%s: child preset has no bust keys" % what, loud)

# ------------------------------------------------------------------ the tests
func _assets() -> void:
	var man := CharBody.cman()
	var base := []
	for e in man.pieces:
		if str(e.slot).begins_with("base_"): base.append(str(e.id))
	_check(base.is_empty(), "manifest lists no base-layer / lingerie / swimwear pieces %s" % [base])
	var left := []
	for id in GONE:
		for s in ["female", "male"]:
			var f := "res://models/characters/%s_%s.glb" % [id, s]
			if ResourceLoader.exists(f) or FileAccess.file_exists(f): left.append(f.get_file())
	_check(left.is_empty(), "no base-layer .glb in models/characters %s" % [left])
	if CharBody.is_ubc():
		# CHARS-UBC: the kit's bodies carry painted underwear in their skin map, and the shader's base layer
		# paints chest, pelvis and crotch as fabric (base_mask): every one of those regions must exist
		for s in ["female", "male"]:
			var sc: Node3D = load(str(man.bodies[s].glb)).instantiate()
			var bm: MeshInstance3D = sc.find_child("body", true, false)
			var uv2: PackedVector2Array = bm.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]
			var have := {}
			for u in uv2: have[int(u.x + 0.5)] = true
			var miss := []
			for r in CharBody.BASE_REGIONS:
				if not have.has(man.regions.find(r)): miss.append(r)
			_check(miss.is_empty(), "%s (UBC): the base layer's regions are all on the body (missing %s)" % [s, miss])
			sc.free()
	else:
		for s in ["female", "male"]:
			for k in ["glb", "glb_hi"]:
				var path := str(man.bodies[s][k])
				var head := FileAccess.get_file_as_bytes(path).slice(20, 400000).get_string_from_ascii()
				_check(head.contains("bfix_flattened"), "%s: chest and groin flattened (tools/blender/characters/flatten.py)" % path.get_file())
		_check(FileAccess.file_exists("res://models/characters/skin_base_painted.txt"), "skin maps carry the painted base layer")
	_check(CharBody.base_mask() != 0, "base_mask covers %s" % [CharBody.BASE_REGIONS])

func _presets_data() -> void:
	_check(not CharPreset.OUTFIT_KEYS.has("base_top") and not CharPreset.OUTFIT_KEYS.has("base_bottom"), "no base slots in a preset")
	for s in ["female", "male"]:
		_preset_ok(CharPreset.blank(s), "blank %s" % s, true)
		var empty := CharPreset.normalize({"body": s, "outfit": {"top": "", "bottom": "", "full": "", "under": ""}})
		_preset_ok(empty, "%s preset with every slot empty" % s, true)
		var no_bottom := CharPreset.normalize({"body": s, "outfit": {"top": "top_polo"}})
		_check(no_bottom.outfit.top == "top_polo" and no_bottom.outfit.bottom != "", "%s: a top alone gets a bottom (%s)" % [s, no_bottom.outfit.bottom])
		var open_only := CharPreset.normalize({"body": s, "outfit": {"outer": "top_flannel", "bottom": "bot_jeans"}})
		_check(CharBody.covers({"base_id": open_only.outfit.top}) == "top", "%s: an open flannel alone gets a closed top under it (%s)" % [s, open_only.outfit.top])
		var vest := CharPreset.normalize({"body": s, "outfit": {"full": "full_storevest"}})
		_preset_ok(vest, "%s: a store vest asked for as a full outfit" % s, true)
		var st := CharPreset.stripped(CharPreset.normalize({"body": s, "outfit": {"under": "top_tee", "outer": "top_flannel", "bottom": "bot_khakis", "shoes": "shoe_boots", "extras": ["x_watch"]}}))
		_preset_ok(st, "%s: basics only" % s, true)
		_check(st.outfit.outer == "" and st.outfit.shoes == "" and st.outfit.extras.is_empty(), "%s: basics only drops outerwear, shoes, extras" % s)
		for slot in ["top", "bottom", "full", "under", "outer"]:
			for e in CharPreset.options(s, slot):
				_check(not str(e.slot).begins_with("base_"), "%s %s offers %s" % [s, slot, e.id], false)
			for e in CharPreset.options(s, slot, true):
				_check(CharBody.child_ok(e), "%s child %s offers only allowed pieces (%s)" % [s, slot, e.id], false)
	var kid := CharPreset.normalize({"body": "female", "keys": {"youth_small": 0.2}, "outfit": {"full": "full_cheer"}})
	_preset_ok(kid, "child preset asking for a cheer outfit", true)
	_check(kid.outfit.full == "" and kid.outfit.top != "" and kid.outfit.bottom != "", "child: cheer refused, plain top and bottom instead (%s / %s)" % [kid.outfit.top, kid.outfit.bottom])

func _bodies_api() -> void:
	for s in ["female", "male"]:
		var cb := CharBody.new()
		host.add_child(cb)
		cb.make(s)
		await _wait(1)
		_body_ok(cb, "CharBody.make(%s)" % s, true)
		# the skin draws the base layer (untinted fabric over chest / groin)
		var masked := false
		for mi in cb.sk.find_children("*", "MeshInstance3D", true, false):
			if str(mi.get_meta("piece", "")) != "" or mi.mesh == null: continue
			for i in range(mi.mesh.get_surface_count()):
				var m = mi.get_surface_override_material(i)
				if m is ShaderMaterial and str(m.resource_name) == "skin_body":
					masked = int(m.get_shader_parameter("base_mask")) == CharBody.base_mask()
		_check(masked, "%s: skin_body draws the painted base layer (base_mask)" % s)
		for id in GONE:
			_check(not cb.wear(id), "%s: wear(%s) refused" % [s, id], false)
		_check(cb.wear({"id": "fake_bra", "base_id": "base_x", "slot": "base_top", "layer": 0, "glb": "res://models/characters/top_tee_%s.glb" % s}) == false,
			"%s: a hand-made base-layer entry is refused even when its glb exists" % s)
		_body_ok(cb, "%s after the refused base pieces" % s, true)
		# take_off refuses the only top / bottom / full outfit
		var top := ""; var bot := ""
		for k in cb.pieces:
			match CharBody.covers(cb.pieces[k]):
				"top": top = k
				"bottom": bot = k
		_check(not cb.take_off(top), "%s: take_off refuses the only top (%s)" % [s, top])
		_check(not cb.take_off(bot), "%s: take_off refuses the only bottom (%s)" % [s, bot])
		cb.wear("full_coveralls")
		_body_ok(cb, "%s in coveralls" % s, true)
		var full := ""
		for k in cb.pieces:
			if CharBody.covers(cb.pieces[k]) == "full": full = k
		if CharPreset._entry(s, "full_coveralls").is_empty():
			_check(full == "", "%s (UBC: no full outfits made yet): none worn" % s)
		else:
			_check(full != "" and not cb.take_off(full), "%s: take_off refuses the only full outfit" % s)
		cb.wear("top_sweatshirt")
		_body_ok(cb, "%s: a top over a full outfit replaces it and gets a bottom" % s, true)
		cb.wear_many(["top_flannel", "shoe_boots", "x_cap_fwd", "base_lacebra", "bot_slacks"])
		_body_ok(cb, "%s after wear_many with a refused piece in it" % s, true)
		cb.wear("top_polo")
		var two_tops := cb.take_off("top_sweatshirt") or not cb.pieces.has("top_sweatshirt_" + s)
		_check(two_tops and cb.is_clothed(), "%s: a spare top can come off, the body stays clothed" % s)
		cb.strip_to_base()
		_body_ok(cb, "%s: strip_to_base" % s, true)
		var hairless := cb.pieces.keys().filter(func(k): return str(cb.pieces[k].slot) != "hair")
		_check(hairless.size() == 2, "%s: strip_to_base leaves exactly a top and a bottom %s" % [s, hairless])
		# a direct _remove (a bug elsewhere) is put right by the next apply()
		for k in cb.pieces.keys(): cb._remove(k)
		_check(not cb.is_clothed(), "%s: (setup) every piece removed behind CharBody's back" % s)
		cb.apply(cb.values)
		_body_ok(cb, "%s: the next apply() dresses it again" % s, true)
		# child: adult-only pieces refused and taken off when a slider makes the body a child
		cb.wear_many(["bot_shortshorts", "top_babytee", "shoe_sandals"])
		var adult_ids := _ids(cb)
		cb.apply({"youth": 0.5})
		_body_ok(cb, "%s: youth 0.5 after %s" % [s, adult_ids], true)
		for id in (ADULT_ONLY if _has_youth() else []):
			_check(not cb.wear(id), "%s child: wear(%s) refused" % [s, id], false)
		if _has_youth():
			_check(cb.wear("top_flannel") and cb.wear("bot_overalls"), "%s child: plain pieces still wear (flannel, overalls)" % s)
		else:
			_check(not CharBody.is_child(cb.values), "%s (UBC: no child bodies): youth is not a slider here" % s)
		_body_ok(cb, "%s child dressed in plain pieces" % s, true)
		cb.apply({"youth": 1.0, "youth_small": 0.4, "bust": 1.0, "bust_lift": 1.0})
		_body_ok(cb, "%s: child 7 with bust sliders pushed" % s, true)
		cb.queue_free()
	await _wait(2)

func _sliders() -> void:
	var n := 0
	for s in ["female", "male"]:
		var cb := CharBody.new()
		host.add_child(cb)
		cb.make(s)
		for sl in CharBody.cman().sliders:
			if sl.has("sex") and str(sl.sex) != s: continue
			for x in [float(sl.range[0]), float(sl.range[1])]:
				for kid in [{}, {"youth": 1.0}, {"youth": 1.0, "youth_small": 1.0}, {"youth_small": 0.01}]:
					var vals: Dictionary = kid.duplicate()
					vals[str(sl.name)] = x
					# dress it in adult pieces first, so the child rule has something to take off
					if not CharBody.is_child(cb.values):
						cb.wear_many(["top_babytee" if s == "female" else "top_tank", "bot_shortshorts"])
					cb.apply(vals)
					_body_ok(cb, "%s %s=%s %s" % [s, sl.name, x, kid])
					n += 1
		cb.queue_free()
	print("ok   slider walk: %d slider settings on both bodies, every one clothed" % n)
	await _wait(2)

func _presets_dressed() -> void:
	var n := 0
	var ps := []
	for id in CharPreset.list_ids():
		ps.append([id, CharPreset.get_preset(id, false)])
	var man: Dictionary = CharBody.cman().presets
	for group in man:
		for name_ in man[group]:
			var sexes := [str(group)] if str(group) in ["female", "male"] else ["female", "male"]
			for s in sexes:
				ps.append(["%s/%s/%s" % [group, name_, s], {"body": s, "keys": man[group][name_],
					"outfit": {"top": "top_babytee" if s == "female" else "top_tank", "bottom": "bot_shortshorts", "extras": ["x_watch"]}}])
	for it in ps:
		var p := CharPreset.normalize(it[1])
		_preset_ok(p, "preset " + str(it[0]))
		var cb := CharPreset.body_for(p, false)
		host.add_child(cb)
		_body_ok(cb, "preset %s dressed" % it[0])
		var baked := CharPreset.body_for(p, true)
		host.add_child(baked)
		_body_ok(baked, "preset %s dressed and baked" % it[0])
		cb.queue_free(); baked.queue_free()
		n += 1
	print("ok   presets: %d (repo files, shape presets, extremes incl. the child), every one clothed live and baked" % n)
	await _wait(2)

func _bypass_paths() -> void:
	var raw = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	_check(raw is Dictionary, "the bypass fixture parses")
	if not (raw is Dictionary): return
	# 1. normalize directly
	var p := CharPreset.normalize(raw)
	_preset_ok(p, "bypass JSON through normalize()", true)
	_check(not p.outfit.has("base_top") and not p.outfit.has("base_full") and str(p.hair.id) == "", "bypass: base slots dropped, lingerie as hair dropped")
	# 2. as an owner edit saved in this browser (localStorage path)
	CharPreset.local_set(CharPreset.LOCAL_PREFIX + "bypass", JSON.stringify(raw))
	_preset_ok(CharPreset.get_preset("bypass"), "bypass JSON as a saved owner edit", true)
	CharPreset.forget_local("bypass")
	# 3. as the player's saved avatar
	CharPreset.local_set(CharPreset.PLAYER_KEY, JSON.stringify(raw))
	_preset_ok(CharPreset.player_preset(), "bypass JSON as the player's saved avatar", true)
	CharPreset.local_set(CharPreset.PLAYER_KEY, "")
	# 4. handed raw to the loader (dress() / body_for())
	var cb := CharBody.new()
	host.add_child(cb)
	CharPreset.dress(cb, raw)
	_body_ok(cb, "bypass JSON handed raw to CharPreset.dress()", true)
	var baked := CharPreset.body_for(raw, true)
	host.add_child(baked)
	_body_ok(baked, "bypass JSON through body_for() (baked NPC)", true)
	# 5. the same file as an adult (youth removed): still no base layer, still clothed
	var adult: Dictionary = raw.duplicate(true)
	adult.keys.erase("youth")
	var pa := CharPreset.normalize(adult)
	_preset_ok(pa, "bypass JSON as an adult", true)
	CharPreset.dress(cb, adult)
	_body_ok(cb, "bypass JSON as an adult, dressed", true)
	# 6. saving it writes a clean file
	var txt := CharPreset.to_json(raw)
	_check(not txt.contains("base_lacebra") and not txt.contains("base_panties") and not txt.contains("\"base_top\""),
		"bypass JSON saved back (to_json) holds no base-layer piece")
	cb.queue_free(); baked.queue_free()
	await _wait(2)

func _editor() -> void:
	var E = load(EDITOR)
	for mode in ["owner", "player"]:
		var ed = E.new()
		ed.setup(mode, CharPreset.get_preset("kay_bee", false) if mode == "owner" else CharPreset.blank("male"))
		ed.advanced = true
		root.add_child(ed)
		await _wait(2)
		_check(not ("base" in ed.tabs), "%s editor: no base-layer tab %s" % [mode, ed.tabs])
		var texts := []
		var nones := []
		for t in ed.tabs:
			ed._go_tab(t)
			for r in ed._rows:
				for k in ["label"]:
					if r.has(k): texts.append(str(r[k]))
				for k in ["items", "opts"]:
					for it in r.get(k, []): texts.append(str(it[0]))
				if str(r.kind) == "choice" and str(r.label) in ["Top", "Bottom"]:
					for o in r.opts:
						if str(o[1]) == "": nones.append(str(r.label))
		var joined := " | ".join(texts)
		_check(not joined.contains("A-pose") and not joined.to_lower().contains("base layer") and not joined.contains("Strip to base"),
			"%s editor: no A-pose view, no base-layer rows, no strip to base" % mode)
		_check(nones.is_empty(), "%s editor: no 'none' in the top or bottom slot %s" % [mode, nones])
		# the UI's own setters can't undress it either
		ed._go_tab("outfit")
		ed._slot_set("top", ""); ed._slot_set("bottom", ""); ed._slot_set("under", ""); ed._slot_set("full", "")
		_preset_ok(ed.preset, "%s editor: every slot set to none by code" % mode, true)
		ed._strip()
		ed._push()
		_body_ok(ed.pv, "%s editor: basics only on the turntable" % mode, true)
		# a slider that makes it a child takes the adult-only pieces off, on the preset and the body
		ed._slot_set("bottom", "bot_shortshorts")
		ed._push()
		ed._set_key(0.5, "youth")
		ed._push()
		_preset_ok(ed.preset, "%s editor: youth slider to 0.5" % mode, true)
		_body_ok(ed.pv, "%s editor: youth slider to 0.5, turntable body" % mode, true)
		ed._go_tab("outfit")
		var offered := []
		for r in ed._rows:
			if str(r.kind) == "choice" and r.has("opts"):
				for o in r.opts:
					if str(o[1]) != "" and str(r.label) != "Hair style" and not CharBody.CHILD_ALLOW.has(str(o[1])): offered.append(str(o[1]))
		if _has_youth():
			_check(offered.is_empty(), "%s editor: a child is offered only plain pieces %s" % [mode, offered])
		else:
			_check(not CharBody.is_child(ed.preset.keys), "%s editor (UBC: no child bodies): a youth key is refused" % mode)
		ed.queue_free()
		await _wait(2)


## CHARS-UBC: the UBC bodies have no youth sliders (no child bodies); the child checks then check that.
func _has_youth() -> bool:
	for sl in CharBody.cman().sliders:
		if str(sl.name) == "youth": return true
	return false
