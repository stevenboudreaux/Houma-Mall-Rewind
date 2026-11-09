## CHAR-STRIP (Nov 8 2026; design/godot-avatar.md, design/godot-characters-research.md section 3): the cast,
## and the ONE way the game makes a person. Every view that shows a cast member calls Cast.body(id):
## the player's body in the world (scripts/avatar.gd), the menu's portrait and its chooser row
## (scripts/menu/portrait.gd), the counter attendants (scripts/attendants/attendant.gd; the talk camera
## frames that same body). Nothing else builds, dresses or swaps a person.
##
## The roster is data/cast.json. A member's file is either "glb" (CHAR-BUILD's baked person,
## res://cast/<id>.glb) or, until CHAR-BUILD delivers, "stub" (a Mixamo crowd skin): the choice is
## written in the data, never made by asking at runtime whether a file is there. A missing file is an
## error: no body (null), an error in the log, and the person is not shown. There is no fallback body
## and no later swap. The files are in the wing pack and are warmed behind the loading card with the
## shoppers (scripts/npc_warmup.gd skin_paths()), so a body is whole the first frame it is seen.
##
## The player's choice is one saved record, "mall-player-2" = {"v": 2, "cast": "<id>", "view":
## "first"|"third"} (localStorage on the web, Engine metadata off it, a Dictionary in unit tests:
## scripts/bank.gd's storage). The name stays in "mall.player_name" and the money in "mall.money"
## (scripts/inventory.gd, scripts/bank.gd), where the arcade pages read them too.
## Before CHAR-STRIP the player had two records, "mall-avatar-1" (V's look) and "mall-avatar-preset-1"
## (B2's preset), and owner edits under "mall-char-<id>". migrate() reads the old two once, for the
## name only, and deletes all of them.
class_name Cast
extends RefCounted

const ROSTER := "res://data/cast.json"
const KEY := "mall-player-2"
const OLD_KEYS := ["mall-avatar-1", "mall-avatar-preset-1"]
const OLD_PREFIX := "mall-char-"           # B2's per-attendant owner edits (gone with the editor)
const NAME_KEY := "mall.player_name"

static var _roster := {}
## A Dictionary backend for unit tests (String -> String); null = localStorage / Engine metadata.
static var backend = null

# ------------------------------------------------------------------ the roster
static func roster() -> Dictionary:
	if _roster.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(ROSTER)) if FileAccess.file_exists(ROSTER) else null
		if j is Dictionary:
			_roster = j
		else:
			push_error("cast: %s is missing or not JSON" % ROSTER)
			_roster = {"cast": {}, "player": [], "default": ""}
	return _roster

## One member's entry ({} and an error when the id is not in the roster).
static func entry(id: String) -> Dictionary:
	var e = roster().get("cast", {}).get(id, null)
	if not (e is Dictionary):
		push_error("cast: no member \"%s\" in %s" % [id, ROSTER])
		return {}
	return e

static func has(id: String) -> bool:
	return roster().get("cast", {}).has(id)

## The ids the menu's chooser offers, in order.
static func player_ids() -> Array:
	return (roster().get("player", []) as Array).duplicate()

static func display_name(id: String) -> String:
	return str(roster().get("cast", {}).get(id, {}).get("name", id))

## The scene file a member is made from (its .glb, or its stub skin while it has none).
static func file(id: String) -> String:
	var e := entry(id)
	if e.has("glb"):
		return str(e.glb)
	return str(e.get("stub", ""))

## True when this member is still a stand-in Mixamo skin (CHAR-BUILD has not delivered it).
static func is_stub(id: String) -> bool:
	return not entry(id).has("glb")

## Every cast file (for the warm-up and the packs).
static func paths() -> Array[String]:
	var out: Array[String] = []
	for id in roster().get("cast", {}):
		var p := file(str(id))
		if p != "" and not (p in out):
			out.append(p)
	return out

# ------------------------------------------------------------------ the one loader
## The body of cast member `id`: an NpcBody playing the shared clips through NpcRig, standing idle,
## meta "cast" = id. Not yet in the tree (the caller adds it). null (and an error) when the id is
## unknown or its file is missing: the person is then not shown.
static func body(id: String) -> NpcBody:
	var e := entry(id)
	if e.is_empty():
		return null
	var path := file(id)
	if path == "" or not ResourceLoader.exists(path):
		push_error("cast: the file of \"%s\" (%s) is not in this pack: not shown" % [id, path])
		return null
	var b: NpcBody
	if e.has("glb") and CastGlb.exists(id):
		# int-53: a baked person (CHAR-BUILD, scripts/cast_glb.gd): LODs, morphs, eye bones come with it
		b = CastGlb.body(id)
		if b == null:
			return null
	else:
		b = NpcBody.new()
		b.name = "Cast_" + id
		b.set_meta("cast", id)
		b.set_skin({"id": id, "scn": path, "hips": float(e.get("hips", 1.0)), "height_m": float(e.get("height_m", 1.7))})
	if b.skin == null:
		push_error("cast: \"%s\" (%s) did not load: not shown" % [id, path])
		b.free()
		return null
	b.walk_clip = "walk_f" if str(e.get("sex", "m")) == "f" else "walk_m"
	# a new AnimationPlayer: start the idle now, so the body is never seen in its bind pose
	b.clip = ""
	b.play("idle", 0.0, false)
	return b

## A counter attendant's body: its cast member when attendants.json says "look": "cast", else the
## Mixamo skin the entry names ("look": "mixamo", written in the data for attendants without a cast
## member yet). Same rule as body(): a missing file is null and an error, never a stand-in.
static func attendant_body(a: Dictionary) -> NpcBody:
	var look := str(a.get("look", ""))
	if look == "cast":
		return body(str(a.get("cast", "")))
	if look != "mixamo":
		push_error("cast: attendant %s has look \"%s\" (want \"cast\" or \"mixamo\")" % [a.get("id"), look])
		return null
	var sk := {}
	for s in NpcBody.manifest().get("skins", []):
		if str(s.id) == str(a.get("skin", "")):
			sk = s
	if sk.is_empty() or not ResourceLoader.exists(str(sk.get("scn", ""))):
		push_error("cast: attendant %s: skin %s is not in this pack: not shown" % [a.get("id"), a.get("skin")])
		return null
	var b := NpcBody.new()
	b.set_skin(sk)
	b.walk_clip = str(a.get("walk", "walk_f" if str(a.get("sex", "m")) == "f" else "walk_m"))
	return b

# ------------------------------------------------------------------ the player's record
## {"v": 2, "cast": id, "view": "first"|"third"}; a new player gets the roster's default, first person.
static func player() -> Dictionary:
	migrate()
	var d = JSON.parse_string(str(_kv_get(KEY))) if _kv_get(KEY) != null else null
	var out := {"v": 2, "cast": str(roster().get("default", "")), "view": "first"}
	if d is Dictionary:
		if has(str(d.get("cast", ""))):
			out.cast = str(d.cast)
		out.view = "third" if str(d.get("view", "first")) == "third" else "first"
	return out

static func player_id() -> String:
	return str(player().cast)

static func save_player(d: Dictionary) -> void:
	_kv_set(KEY, JSON.stringify({"v": 2, "cast": str(d.get("cast", "")), "view": str(d.get("view", "first"))}))

static func set_player_id(id: String) -> void:
	if not has(id):
		push_error("cast: no member \"%s\"" % id)
		return
	var d := player()
	d.cast = id
	save_player(d)

static func set_view(v: String) -> void:
	var d := player()
	d.view = "third" if v == "third" else "first"
	save_player(d)

## Once: the old avatar records give the name (if none is saved yet), then they are deleted.
static func migrate() -> void:
	var had := false
	var nm := ""
	for k in OLD_KEYS:
		var s = _kv_get(k)
		if s == null:
			continue
		had = true
		var d = JSON.parse_string(str(s))
		if d is Dictionary and nm == "":
			nm = str(d.get("name", "")).strip_edges()
		_kv_del(k)
	_del_prefix(OLD_PREFIX)
	if had:
		var cur = _kv_get(NAME_KEY)
		if nm != "" and (cur == null or str(cur) == ""):
			_kv_set(NAME_KEY, nm.left(20))
		print("cast: the old avatar records were read for the name (%s) and deleted" % ("\"%s\"" % nm if nm != "" else "none"))

# ------------------------------------------------------------------ storage (as scripts/bank.gd)
## Off the web each old record had its own Engine metadata name (avatar_look.gd, char_preset.gd,
## inventory.gd); everything else is in "mall_kv", as scripts/bank.gd keeps it.
const NATIVE_META := {"mall-avatar-1": "mall_avatar", "mall-avatar-preset-1": "ls_mall_avatar_preset_1",
	"mall.player_name": "mall_player_name"}

static func _kv_get(k: String):
	if backend is Dictionary:
		return backend.get(k, null)
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)}catch(e){return null}})()" % JSON.stringify(k), true)
		return v if v is String else null
	if NATIVE_META.has(k):
		var m := str(Engine.get_meta(NATIVE_META[k], ""))
		return null if m == "" else m
	return (Engine.get_meta("mall_kv", {}) as Dictionary).get(k, null)

static func _kv_set(k: String, v: String) -> void:
	if backend is Dictionary:
		backend[k] = v
	elif OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s)}catch(e){}})()" % [JSON.stringify(k), JSON.stringify(v)], true)
	elif NATIVE_META.has(k):
		Engine.set_meta(NATIVE_META[k], v)
	else:
		var d: Dictionary = Engine.get_meta("mall_kv", {})
		d[k] = v
		Engine.set_meta("mall_kv", d)

static func _kv_del(k: String) -> void:
	if backend is Dictionary:
		backend.erase(k)
	elif OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.removeItem(%s)}catch(e){}})()" % JSON.stringify(k), true)
	elif NATIVE_META.has(k):
		if Engine.has_meta(NATIVE_META[k]): Engine.remove_meta(NATIVE_META[k])
	else:
		var d: Dictionary = Engine.get_meta("mall_kv", {})
		d.erase(k)
		Engine.set_meta("mall_kv", d)

static func _del_prefix(p: String) -> void:
	if backend is Dictionary:
		for k in backend.keys():
			if str(k).begins_with(p): backend.erase(k)
	elif OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{var d=[];for(var i=0;i<localStorage.length;i++){var k=localStorage.key(i);if(k&&k.indexOf(%s)===0)d.push(k)}d.forEach(function(k){localStorage.removeItem(k)})}catch(e){}})()" % JSON.stringify(p), true)
	else:
		var d: Dictionary = Engine.get_meta("mall_kv", {})
		for k in d.keys():
			if str(k).begins_with(p): d.erase(k)
		Engine.set_meta("mall_kv", d)
		var mp := "ls_" + p.replace("-", "_")
		for m in Engine.get_meta_list():
			if str(m).begins_with(mp): Engine.remove_meta(m)
