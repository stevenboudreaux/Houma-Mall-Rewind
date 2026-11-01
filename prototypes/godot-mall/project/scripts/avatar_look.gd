## Workstream V (design/godot-avatar.md): the player's avatar as data, and where it is kept.
##
## A look is one JSON object, saved in localStorage "mall-avatar-1" on the web (Engine metadata
## "mall_avatar" off the web, so a wing change in one run keeps it):
##   {"v": 1, "done": true, "view": "first"|"third",
##    "body": "Ch21", "skin": "#c68e6a", "hair": "#2a1d14",
##    "y1995": {"top": "#1f6f6a", "bottom": "#6f8db5", "words": "HOUMA"},
##    "y2026": {"top": "#efe9dc", "bottom": "#23262d", "words": ""}}
## Body, skin and hair are the same person in both years; clothes and shirt words are per year, so
## 1995 shows only 1995 colours and 2026 its own. An empty colour ("") keeps the body's own colour.
## The palettes are below: the 1995 ones are mid-90s mall clothes (jewel tones, teal, plum, hunter
## green, mustard, stonewash denim, khaki), the 2026 ones what the Oct 23 footage's shoppers wear
## (neutrals, sage, rust, black, light-wash denim). Both are guesses written down in the design note.
## scripts/avatar_bodies.json (tools/avatar/analyze_bodies.gd) lists the bodies.
extends RefCounted

const VERSION := 1
const KEY := "mall-avatar-1"
const BODIES := "res://scripts/avatar_bodies.json"
const DEFAULT_BODY := "Ch01"

const SKIN := ["", "#f1d6c6", "#e2bba3", "#cc9f85", "#ad7f63", "#8a5e47", "#673f30", "#462b22"]
const HAIR := {
	1995: ["", "#151210", "#3b2619", "#6a4127", "#8a3f1f", "#b8894f", "#e0c58a", "#9a9590"],
	2026: ["", "#151210", "#3b2619", "#6a4127", "#8a3f1f", "#c9a46a", "#e8dcc0", "#a7a7a7", "#d77fa1"]}
const TOP := {
	1995: ["", "#f2efe6", "#1c1c1f", "#8d8e90", "#1f6f6a", "#5b2a5e", "#2f4a2e", "#7a1f2b", "#c79a2c", "#24346b", "#b8352f"],
	2026: ["", "#f4f2ec", "#151517", "#5d6168", "#e6dccb", "#8fa38a", "#a8522f", "#22324f", "#b9a5cf", "#c8383a"]}
const BOTTOM := {
	1995: ["", "#8fb0d3", "#5a7aa5", "#273a5c", "#18181b", "#c4ad85", "#56603d", "#e9e4d8"],
	2026: ["", "#a9c1da", "#2c3a55", "#151517", "#c2b08e", "#59613f", "#7d7f84"]}
const WORDS := {
	1995: ["", "HOUMA", "BAYOU", "CAJUN", "TERREBONNE", "LOUISIANA"],
	2026: ["", "HOUMA", "BAYOU", "GEAUX", "985", "LOUISIANA"]}
const WORDS_MAX := 12

static var _bodies: Array = []

## The bodies the creator offers (avatar_bodies.json), in file order.
static func bodies() -> Array:
	if _bodies.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string(BODIES)) if FileAccess.file_exists(BODIES) else null
		_bodies = j.get("bodies", []) if j is Dictionary else []
	return _bodies

static func body(id: String) -> Dictionary:
	for b in bodies():
		if str(b.id) == id:
			return b
	return bodies()[0] if not bodies().is_empty() else {}

static func year_key(year: int) -> String:
	return "y2026" if year == 2026 else "y1995"

static func pal_year(year: int) -> int:
	return 2026 if year == 2026 else 1995

## The look a Skip gives: the default body in its own colours, first person.
static func default_look() -> Dictionary:
	return {"v": VERSION, "done": false, "view": "first", "body": DEFAULT_BODY, "skin": "", "hair": "",
		"y1995": {"top": "", "bottom": "", "words": ""}, "y2026": {"top": "", "bottom": "", "words": ""}}

## Fix a look read from storage (missing fields, colours not in this year's palette).
static func sanitize(d) -> Dictionary:
	var L := default_look()
	if not (d is Dictionary) or int(d.get("v", 0)) != VERSION:
		return L
	L.done = bool(d.get("done", false))
	L.view = "third" if str(d.get("view", "first")) == "third" else "first"
	var bid := str(d.get("body", DEFAULT_BODY))
	L.body = bid if not body(bid).is_empty() and str(body(bid).get("id", "")) == bid else DEFAULT_BODY
	L.skin = _in(str(d.get("skin", "")), SKIN)
	L.hair = _in(str(d.get("hair", "")), HAIR[1995] + HAIR[2026])
	for y in [1995, 2026]:
		var yk := year_key(y)
		var c = d.get(yk, {})
		if c is Dictionary:
			L[yk] = {"top": _in(str(c.get("top", "")), TOP[y]), "bottom": _in(str(c.get("bottom", "")), BOTTOM[y]),
				"words": clean_words(str(c.get("words", "")))}
	return L

static func _in(c: String, pal: Array) -> String:
	return c if pal.has(c) else ""

## Shirt words: printable, upper case, at most WORDS_MAX characters.
static func clean_words(s: String) -> String:
	var o := ""
	for ch in s.strip_edges().to_upper():
		if ch.unicode_at(0) >= 32 and ch.unicode_at(0) < 127:
			o += ch
	return o.left(WORDS_MAX)

static func load_look() -> Dictionary:
	var s := ""
	if OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||''}catch(e){return ''}})()" % JSON.stringify(KEY), true)
		s = v if v is String else ""
	else:
		s = str(Engine.get_meta("mall_avatar", ""))
	return sanitize(JSON.parse_string(s) if s != "" else null)

static func save_look(L: Dictionary) -> void:
	var s := JSON.stringify(L)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s)}catch(e){}})()" % [JSON.stringify(KEY), JSON.stringify(s)], true)
	else:
		Engine.set_meta("mall_avatar", s)

## A random look in this year's palettes.
static func random_look(year: int, rng: RandomNumberGenerator) -> Dictionary:
	var L := default_look()
	var y := pal_year(year)
	var bs := bodies()
	if not bs.is_empty():
		L.body = str(bs[rng.randi() % bs.size()].id)
	L.skin = SKIN[1 + rng.randi() % (SKIN.size() - 1)]
	L.hair = HAIR[y][1 + rng.randi() % (HAIR[y].size() - 1)]
	var c := {"top": TOP[y][1 + rng.randi() % (TOP[y].size() - 1)], "bottom": BOTTOM[y][1 + rng.randi() % (BOTTOM[y].size() - 1)],
		"words": WORDS[y][rng.randi() % WORDS[y].size()]}
	L[year_key(y)] = c
	return L
