## Owner-editable signs: the names on Pocket Change's video cabinets, basketball games
## and claw machines, and the department boards in Kay-Bee Toys.
##
## The build (tools/build_mall.gd sign_add) lists every such sign in res://gen/signs.json
## with its faces in world space. The painted texture keeps the original words; when a sign
## has new text, this script lays a word-free copy of its art over it and draws the new text
## with a Label3D, so a rename needs no rebuild and no rebake. A sign may have several faces
## (a video cabinet: marquee, lower front, panel lip, bezel strip); a face can carry its own
## word-free art ("tex"), the band its title was painted in ("band", "span"), its own "look"
## and "lit" (a painted, unlit-from-within face); all faces of a sign change together.
##
## Where the text comes from, in order:
##   1. the published list, play/signs.json next to the game ({"signs": {id: text}});
##   2. on the owner's browser, unpublished edits kept in localStorage "southland-signs-draft".
##
## The owner is the browser the mall editor was unlocked in (localStorage "southland-editor",
## set by the main game's secret code), or any visit with ?owner=1. The owner gets two
## buttons: "Edit signs" (then tap or click a sign to retype it) and "Publish signs", which
## writes play/signs.json to GitHub with the token the main game's Publish already keeps in
## this browser (localStorage "southland-gh"); shell.html holds that code. No secret is in
## the repo: without a token, publishing asks for one and does not keep it.
extends Node

const DRAFT_KEY := "southland-signs-draft"
const PICK_RANGE := 16.0

## The look of each sign kind. Arcade titles follow each marquee's painted title colours.
const PC_STYLE := [
	{"font": "sans_italic", "fill": "#fff3a0", "outline": "#2a0400"},   # 0 THUNDER DOJO
	{"font": "sans", "fill": "#eef2fa", "outline": "#0a0a0e"},          # 1 IRON ALLEY
	{"font": "serif", "fill": "#ffffff", "outline": "#aa1414"},         # 2 BULLSEYE PATROL
	{"font": "sans_italic", "fill": "#c8f0ff", "outline": "#2048c8"},   # 3 ORBIT RAIDER
	{"font": "sans", "fill": "#ffffff", "outline": "#0a0a0a"},          # 4 FOURTH & GOAL
	{"font": "sans_italic", "fill": "#fff6d8", "outline": "#c01880"},   # 5 LUCKY LANES
	{"font": "sans_italic", "fill": "#fff4c0", "outline": "#0a0a0a"},   # 6 RED LINE RUSH
	{"font": "sans", "fill": "#fff6dc", "outline": "#c02818"},          # 7 PADDLE PANIC
]
const KB_STYLE := {"font": "sans", "fill": "#b0f03c", "outline": ""}

## The twelve playable cabinets (Steven, Oct 6: "3 Atari, 3 NES, 3 Genesis, 3 SNES",
## sprinkled round the room): video cabinets with joysticks, picked to spread across
## Pocket Change. Each takes one system's ROMs (play/emu.html); play/roms.json says which
## ROM each one has. Values are EmulatorJS core names.
const ARCADE := {"pc.video.33": "atari2600", "pc.video.37": "nes", "pc.video.03": "segaMD", "pc.video.62": "snes",
	"pc.video.11": "atari2600", "pc.video.46": "nes", "pc.video.17": "segaMD", "pc.video.52": "snes",
	"pc.video.22": "atari2600", "pc.video.54": "nes", "pc.video.29": "segaMD", "pc.video.67": "snes"}
const SYS_NAME := {"atari2600": "Atari 2600", "nes": "NES", "segaMD": "Genesis", "snes": "Super NES"}
const SYS_COL := {"atari2600": "#e8742a", "nes": "#d8202a", "segaMD": "#2a5ad8", "snes": "#8a4ad0"}
const FONT_FILES := {"sans": "sans.otf", "sans_italic": "sans_italic.otf", "serif": "serif.ttf", "script": "script.ttf"}

var recs := {}          # id -> record from gen/signs.json
var order: Array = []   # ids in build order
var published := {}     # id -> text, from play/signs.json
var draft := {}         # id -> text, the owner's unpublished edits
var made := {}          # id -> [nodes]
var mats := {}
var fonts := {}
var is_owner := false
var editing := false
var web := false
var ui: CanvasLayer
var b_edit: Button
var b_pub: Button
var status: Label
var press_at := Vector2.ZERO
var press_t := 0
var pressed := false
var publishing := false
var poll_t := 0.0
var roms := {}          # cabinet id -> {file, core, name, title} from play/roms.json
var arcade_mode := false
var b_arc: Button
var play_ui: CanvasLayer
var b_play: Button
var play_id := ""
var near_t := 0.0
var sys_tags := []      # owner-only labels naming each playable cabinet's system

func _ready() -> void:
	web = OS.has_feature("web")
	# each wing's build writes its own list (res://gen/w1/signs.json, ...; tools/build_mall.gd)
	var gen: String = get_parent().get_meta("gen", "res://gen/") if get_parent() else "res://gen/"
	if FileAccess.file_exists(gen + "signs.json"):
		var J = JSON.parse_string(FileAccess.get_file_as_string(gen + "signs.json"))
		if J is Dictionary:
			for r in J.get("signs", []):
				recs[r.id] = r
				order.append(r.id)
	if not web:
		return
	_stickers()
	_build_play_ui()
	_fetch_roms()
	var o = JavaScriptBridge.eval("(function(){try{var q=new URLSearchParams(location.search).get('owner');if(q==='1')localStorage.setItem('southland-editor','1');return localStorage.getItem('southland-editor')==='1'?'1':'0'}catch(e){return '0'}})()")
	is_owner = str(o) == "1"
	if is_owner:
		var d = JavaScriptBridge.eval("(function(){try{return localStorage.getItem('" + DRAFT_KEY + "')||''}catch(e){return ''}})()")
		if d is String and d != "":
			var dj = JSON.parse_string(d)
			if dj is Dictionary:
				draft = dj
		_build_ui()
	_fetch_published()
	_apply_all()

# ------------------------------------------------------------------ loading
func _fetch_published() -> void:
	var url = JavaScriptBridge.eval("new URL('signs.json', location.href).href")
	if not (url is String):
		return
	var h := HTTPRequest.new()
	add_child(h)
	h.request_completed.connect(func(result, code, _headers, body):
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var j = JSON.parse_string(body.get_string_from_utf8())
			if j is Dictionary and j.get("signs") is Dictionary:
				published = j.signs
				_apply_all()
		h.queue_free())
	h.request(url + "?t=" + str(Time.get_unix_time_from_system()))

func _fetch_roms() -> void:
	var url = JavaScriptBridge.eval("new URL('roms.json', location.href).href")
	if not (url is String):
		return
	var h := HTTPRequest.new()
	add_child(h)
	h.request_completed.connect(func(result, code, _headers, body):
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var j = JSON.parse_string(body.get_string_from_utf8())
			if j is Dictionary and j.get("cabinets") is Dictionary:
				roms = j.cabinets
		h.queue_free())
	h.request(url + "?t=" + str(Time.get_unix_time_from_system()))

## A small "PLAYABLE" sticker under each playable cabinet's marquee, in its system's colour.
func _stickers() -> void:
	if not fonts.has("sans"):
		fonts["sans"] = load("res://fonts/sans.otf")
	for id in ARCADE:
		if not recs.has(id):
			continue
		var f = recs[id].faces[0]
		var P = []
		for p in f.p:
			P.append(Vector3(p[0], p[1], p[2]))
		var n = Vector3(f.n[0], f.n[1], f.n[2])
		var right = (P[1] - P[0]).normalized()
		var up = (P[3] - P[0]).normalized()
		var c = (P[0] + P[1]) * 0.5 - up * 0.05 + n * 0.012
		var lab := Label3D.new()
		lab.font = fonts["sans"]
		lab.font_size = 64
		lab.text = "PLAYABLE"
		lab.modulate = Color.WHITE
		lab.outline_size = 22
		lab.outline_modulate = Color(SYS_COL[ARCADE[id]])
		lab.pixel_size = 0.0006
		lab.shaded = false
		lab.double_sided = false
		lab.basis = Basis(right, up, n.normalized())
		lab.position = c
		add_child(lab)

# ------------------------------------------------------------------ the arcade
func _build_play_ui() -> void:
	play_ui = CanvasLayer.new()
	play_ui.layer = 21
	add_child(play_ui)
	b_play = Button.new()
	b_play.text = "PLAY"
	b_play.custom_minimum_size = Vector2(260, 64)
	b_play.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b_play.focus_mode = Control.FOCUS_NONE
	b_play.add_theme_font_size_override("font_size", 26)
	b_play.visible = false
	play_ui.add_child(b_play)

## Whether the player stands at a playable cabinet that has a game: within 1.6 m of its
## front and facing it. Sets play_id and shows the Play button.
func _near_check() -> void:
	var cam := get_viewport().get_camera_3d()
	# V (design/godot-avatar.md): in third person the view camera is behind the avatar; standing at a
	# cabinet is judged from the player's eye (player.gd cam), as in first person
	var _pl = get_tree().get_first_node_in_group("mall_player")
	if _pl and "cam" in _pl and _pl.cam:
		cam = _pl.cam
	var found = ""
	var fwd = null
	if cam != null:
		fwd = -cam.global_transform.basis.z
		fwd.y = 0.0
		fwd = fwd.normalized()
	if cam != null and not roms.is_empty():
		for id in ARCADE:
			if not roms.has(id) or not recs.has(id):
				continue
			var f = recs[id].faces[0]
			var c = Vector3.ZERO
			for p in f.p:
				c += Vector3(p[0], 0.0, p[2])
			c *= 0.25
			var n = Vector3(f.n[0], 0.0, f.n[2]).normalized()
			var spot = c + n * 0.9
			var me = Vector3(cam.global_position.x, 0.0, cam.global_position.z)
			if me.distance_to(spot) < 1.6 and fwd.dot(-n) > 0.3:
				found = id
				break
	if found == "" and cam != null:
		found = _near_whirlwind(cam, fwd if fwd != null else Vector3.ZERO)
	if found == "" and cam != null:
		found = _near_skee(cam, fwd if fwd != null else Vector3.ZERO)
	if found == "" and cam != null:
		found = _near_crane(cam, fwd if fwd != null else Vector3.ZERO)
	play_id = found
	if b_play == null:
		return
	b_play.visible = found != ""
	if found != "":
		var t = ""
		if found.begins_with("pc.cyclone"):
			t = text_of(found)
		elif found.begins_with("pc.skee"):
			t = "SKEE-BALL"
		elif found.begins_with("pc.crane"):
			t = text_of(found)
		else:
			t = str(roms[found].get("title", ""))
			if t == "" or t == str(recs[found].title):
				t = text_of(found)
		b_play.text = "PLAY  " + t
		var vs = get_viewport().get_visible_rect().size
		b_play.size = Vector2(max(260.0, 22.0 * b_play.text.length()), 64)
		b_play.position = Vector2((vs.x - b_play.size.x) * 0.5, vs.y - 150)

## The WHIRLWIND light-ring ticket game (play/whirlwind.html, Steven Oct 9): standing at its
## console (the front, 0.9 m out, within 1.4 m) and facing it. The cabinet's sign record has
## the left, right and back decals; the console is D = 1.30 m in front of the back one.
func _near_whirlwind(cam: Camera3D, fwd: Vector3) -> String:
	var me = Vector3(cam.global_position.x, 0.0, cam.global_position.z)
	for id in order:
		if not str(id).begins_with("pc.cyclone") or not recs.has(id):
			continue
		var faces = recs[id].faces
		if faces.size() < 3:
			continue
		var f = faces[2]
		var c = Vector3.ZERO
		for p in f.p:
			c += Vector3(p[0], 0.0, p[2])
		c *= 0.25
		var nb = Vector3(f.n[0], 0.0, f.n[2]).normalized()
		var spot = c - nb * (1.30 + 0.9)
		if me.distance_to(spot) < 1.4 and fwd.dot(nb) > 0.3:
			return id
	return ""

## The four skee-ball alleys (play/skeeball.html, Steven Oct 11): standing at an alley's front
## (0.15 to 1.6 m out, within its 0.76 m width) and facing up it. The alleys have no sign records,
## so their places come from the layout: tools/stores/pocket_change/store.gd puts them against the
## right wall (u = SIDE + skee.gd D = 3.27 m from the store's corner, x = -110 + 3.27) from
## d = SKEE_D = 7.8 m (z = 60 + 7.8), 0.76 m apart, numbered 1..4, facing -x. Only Pocket Change's
## wing has the cyclone's record, so that is the check that this wing has the alleys.
const SKEE_FRONT_X = -106.73
const SKEE_Z0 = 67.8
const SKEE_W = 0.76

func _near_skee(cam: Camera3D, fwd: Vector3) -> String:
	if not recs.has("pc.cyclone.1"):
		return ""
	var dx = cam.global_position.x - SKEE_FRONT_X
	if dx < 0.15 or dx > 1.6 or fwd.dot(Vector3(-1, 0, 0)) < 0.3:
		return ""
	var k = int(floor((cam.global_position.z - SKEE_Z0) / SKEE_W))
	if k < 0 or k > 3:
		return ""
	return "pc.skee.%d" % (k + 1)

## The three claw machines (play/claw.html, Steven Oct 11): standing at a crane's control panel
## (0.9 m out from its header marquee, within 1.4 m) and facing it. The record's face is the
## front marquee; the machine's number is the record's.
func _near_crane(cam: Camera3D, fwd: Vector3) -> String:
	var me = Vector3(cam.global_position.x, 0.0, cam.global_position.z)
	var best = ""
	var best_d = 1.2
	for id in order:
		if not str(id).begins_with("pc.crane.") or not recs.has(id):
			continue
		var f = recs[id].faces[0]
		var c = Vector3.ZERO
		for p in f.p:
			c += Vector3(p[0], 0.0, p[2])
		c *= 0.25
		var n = Vector3(f.n[0], 0.0, f.n[2]).normalized()
		var spot = c + n * 0.9
		var d = me.distance_to(spot)
		if d < best_d and fwd.dot(-n) > 0.3:
			best = id
			best_d = d
	return best

func _play(id: String) -> void:
	if id.begins_with("pc.crane."):
		JavaScriptBridge.eval("window.mallRoms && window.mallRoms.open('claw.html?machine=" + id.get_slice(".", 2) + "&name=' + encodeURIComponent(" + JSON.stringify(text_of(id)) + "))")
		return
	if id.begins_with("pc.skee."):
		JavaScriptBridge.eval("window.mallRoms && window.mallRoms.open('skeeball.html?lane=" + id.get_slice(".", 2) + "')")
		return
	if id.begins_with("pc.cyclone"):
		JavaScriptBridge.eval("window.mallRoms && window.mallRoms.open('whirlwind.html?name=' + encodeURIComponent(" + JSON.stringify(text_of(id)) + "))")
		return
	JavaScriptBridge.eval("window.mallRoms && window.mallRoms.open('emu.html?id=' + encodeURIComponent(" + JSON.stringify(id) + "))")

func _arcade_setup(id: String) -> void:
	var q = "emu.html?setup=" + id.uri_encode() + "&sys=" + str(ARCADE[id]) + "&title=" + text_of(id).uri_encode()
	JavaScriptBridge.eval("window.mallRoms && window.mallRoms.open(" + JSON.stringify(q) + ")")

## In Arcade mode the owner sees which system each playable cabinet takes.
func _show_sys_tags(on: bool) -> void:
	for l in sys_tags:
		l.queue_free()
	sys_tags.clear()
	if not on:
		return
	for id in ARCADE:
		if not recs.has(id):
			continue
		var f = recs[id].faces[0]
		var c = Vector3.ZERO
		for p in f.p:
			c += Vector3(p[0], p[1], p[2])
		c *= 0.25
		var lab := Label3D.new()
		lab.font = fonts["sans"]
		lab.font_size = 64
		lab.text = SYS_NAME[ARCADE[id]] + ("\n" + str(roms[id].get("name", "")) if roms.has(id) else "\n(empty)")
		lab.modulate = Color.WHITE
		lab.outline_size = 18
		lab.outline_modulate = Color(SYS_COL[ARCADE[id]])
		lab.pixel_size = 0.0015
		lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lab.no_depth_test = true
		lab.position = c + Vector3(0, 0.45, 0)
		add_child(lab)
		sys_tags.append(lab)

## The text a sign shows now: the owner's draft, else the published text, else the original.
func text_of(id: String) -> String:
	if draft.has(id):
		return str(draft[id])
	if published.has(id):
		return str(published[id])
	return str(recs[id].title)

func _apply_all() -> void:
	for id in order:
		_apply(id)

func _apply(id: String) -> void:
	var r = recs[id]
	var txt = text_of(id)
	if made.has(id):
		for nd in made[id]:
			nd.queue_free()
		made.erase(id)
	if txt == str(r.title):
		return   # the painted original shows
	var nodes = []
	for f in r.faces:
		var P = []
		for p in f.p:
			P.append(Vector3(p[0], p[1], p[2]))
		var n = Vector3(f.n[0], f.n[1], f.n[2])
		nodes.append(_overlay(r, f, P, f.uv, n))
		if txt.strip_edges() != "":
			nodes.append(_label(r, f, P, n, txt))
	made[id] = nodes

## A word-free copy of the sign's art laid just in front of it. A face may name its own art
## ("tex"); a "lit" face (painted, not backlit: a cabinet's lower front, panel lip, bezel)
## gets a shaded copy so it takes the room's light like the face under it.
func _overlay(r, f, P: Array, uv: Array, n: Vector3) -> MeshInstance3D:
	var key = str(f.get("tex", r.get("tex", "")))
	if key == "":
		key = "res://tex/pc/video_marquees_blank.png" if r.kind == "pc_marquee" else "res://tex/kb/dept_blank.png"
	var lit = bool(f.get("lit", false))
	var mk = key + ("|lit" if lit else "")
	if not mats.has(mk):
		var m := StandardMaterial3D.new()
		if lit:
			m.roughness = 0.5
		else:
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.albedo_texture = load(key)
		if r.kind == "kb_dept":
			m.albedo_color = Color(0.92, 0.92, 0.92)
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		mats[mk] = m
	var am := ArrayMesh.new()
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var v := PackedVector3Array()
	var t := PackedVector2Array()
	var nn := PackedVector3Array()
	for i in 4:
		v.append(P[i] + n * 0.003)
		t.append(Vector2(uv[i][0], uv[i][1]))
		nn.append(n)
	arr[Mesh.ARRAY_VERTEX] = v
	arr[Mesh.ARRAY_TEX_UV] = t
	arr[Mesh.ARRAY_NORMAL] = nn
	arr[Mesh.ARRAY_INDEX] = PackedInt32Array([0, 2, 1, 0, 3, 2])
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mats[mk]
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if lit:
		mi.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC   # lit by the lightmap's probes
	add_child(mi)
	return mi

## The new words, centred on the face and fitted to it; or, on a face with a "band"
## ([top, bottom] as fractions of the face from its top edge, where the painted title was),
## centred in that band, the capitals as tall as the band, within the face's "span"
## ([left, right] fractions of its width).
func _label(r, f, P: Array, n: Vector3, txt: String) -> Label3D:
	var st = KB_STYLE
	if f.has("look"):
		st = f.look
	elif r.has("look"):
		st = r.look
	elif r.kind == "pc_marquee":
		st = PC_STYLE[clampi(int(r.style), 0, PC_STYLE.size() - 1)]
	var right = (P[1] - P[0])
	var w = right.length()
	var up = (P[3] - P[0])
	var h = up.length()
	# a flared marquee is narrower at the bottom: fit to the narrow edge
	w = min(w, (P[2] - P[3]).length())
	var lab := Label3D.new()
	if not fonts.has(st.font):
		fonts[st.font] = load("res://fonts/" + FONT_FILES[st.font])
	lab.font = fonts[st.font]
	lab.font_size = 96
	lab.text = txt
	lab.modulate = Color(st.fill)
	if st.outline != "":
		lab.outline_size = int(st.get("osz", 14))
		lab.outline_modulate = Color(st.outline)
	else:
		lab.outline_size = 0
	lab.shaded = bool(f.get("lit", false))
	if lab.shaded:
		lab.gi_mode = GeometryInstance3D.GI_MODE_DYNAMIC
	lab.double_sided = false
	lab.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sz = lab.font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 96)
	sz.x += lab.outline_size * 2
	lab.basis = Basis(right.normalized(), up.normalized(), n.normalized())
	if f.has("band"):
		var bd = f.band
		var sp = f.get("span", [0.07, 0.93])
		var bh = h * (float(bd[1]) - float(bd[0]))
		# capitals are about 0.73 em; the band is the painted capitals plus their outline
		lab.pixel_size = min(w * (float(sp[1]) - float(sp[0])) / max(sz.x, 1.0), bh / (96.0 * 0.73 + lab.outline_size))
		var asc = lab.font.get_ascent(96)
		var dsc = lab.font.get_descent(96)
		# Label3D centres the line box; drop it so the capitals' middle sits on the band's
		var drop = (96.0 * 0.73 * 0.5 - (asc - dsc) * 0.5) * lab.pixel_size
		var t = (float(bd[0]) + float(bd[1])) * 0.5
		var cu = (float(sp[0]) + float(sp[1])) * 0.5
		var pb = P[0] + (P[3] - P[0]) * (1.0 - t)
		var pt = P[1] + (P[2] - P[1]) * (1.0 - t)
		lab.position = pb.lerp(pt, cu) - up.normalized() * drop + n * 0.006
		add_child(lab)
		return lab
	var fw = 0.9 if r.kind == "kb_dept" else 0.86
	var fh = 0.7 if r.kind == "kb_dept" else 0.62
	lab.pixel_size = min(w * fw / max(sz.x, 1.0), h * fh / max(sz.y, 1.0))
	var c = (P[0] + P[1] + P[2] + P[3]) * 0.25
	lab.position = c + n * 0.006
	add_child(lab)
	return lab

# ------------------------------------------------------------------ owner UI
func _build_ui() -> void:
	ui = CanvasLayer.new()
	ui.layer = 20
	add_child(ui)
	b_edit = _btn("Edit signs", Vector2(12, 132))
	b_edit.toggle_mode = true
	b_pub = _btn("Publish signs", Vector2(12, 182))
	b_arc = _btn("Arcade", Vector2(12, 232))
	b_arc.toggle_mode = true
	status = Label.new()
	status.position = Vector2(14, 280)
	status.add_theme_font_size_override("font_size", 18)
	status.add_theme_color_override("font_color", Color.WHITE)
	status.add_theme_color_override("font_outline_color", Color.BLACK)
	status.add_theme_constant_override("outline_size", 5)
	ui.add_child(status)
	_refresh_ui()

func _btn(txt: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = txt
	b.position = pos
	b.custom_minimum_size = Vector2(170, 42)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE   # taps are hit-tested in _input (touch skips mouse emulation)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 18)
	ui.add_child(b)
	return b

func _refresh_ui() -> void:
	if ui == null:
		return
	b_edit.button_pressed = editing
	b_arc.button_pressed = arcade_mode
	b_pub.disabled = draft.is_empty() or publishing
	b_pub.text = "Publish signs (%d)" % draft.size() if not draft.is_empty() else "Publish signs"
	if publishing:
		status.text = "Publishing..."
	elif editing:
		status.text = "Tap a sign to change its words"
	elif arcade_mode:
		status.text = "Tap a PLAYABLE cabinet to put a game on it"
	elif status.text.begins_with("Tap"):
		status.text = ""

func _input(e: InputEvent) -> void:
	var pos = null
	var down = false
	var up = false
	if e is InputEventScreenTouch:
		pos = e.position; down = e.pressed; up = not e.pressed
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position; down = e.pressed; up = not e.pressed
	if b_play != null and b_play.visible and play_id != "":
		var go := false
		if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode in [KEY_E, KEY_ENTER, KEY_KP_ENTER]:
			go = true
		elif e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A:
			go = true
		if go:
			get_viewport().set_input_as_handled()
			_play(play_id)
			return
	if pos == null:
		return
	if down and b_play != null and b_play.visible and b_play.get_global_rect().has_point(pos):
		get_viewport().set_input_as_handled()
		_play(play_id)
		return
	if not is_owner:
		return
	if down:
		for b in [b_edit, b_pub, b_arc]:
			if b.get_global_rect().has_point(pos):
				get_viewport().set_input_as_handled()
				if b == b_edit:
					editing = not editing
					if editing and arcade_mode:
						arcade_mode = false
						_show_sys_tags(false)
				elif b == b_arc:
					arcade_mode = not arcade_mode
					if arcade_mode:
						editing = false
					_show_sys_tags(arcade_mode)
				elif not b.disabled:
					_publish()
				_refresh_ui()
				return
		pressed = true
		press_at = pos
		press_t = Time.get_ticks_msec()
	elif up and pressed:
		pressed = false
		# a tap (not a walk or look drag) while editing picks a sign
		if (editing or arcade_mode) and pos.distance_to(press_at) < 14.0 and Time.get_ticks_msec() - press_t < 450:
			var id = _pick(pos)
			if id != "" and editing:
				_retype(id)
			elif id != "" and ARCADE.has(id):
				_arcade_setup(id)
			elif id != "":
				status.text = "That one isn't a playable cabinet: look for the PLAYABLE stickers"

## The sign under the screen point: the nearest one whose face contains it.
func _pick(sp: Vector2) -> String:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return ""
	var best = ""
	var best_d = 1e9
	for id in order:
		for f in recs[id].faces:
			var P = []
			var behind = false
			for p in f.p:
				var v = Vector3(p[0], p[1], p[2])
				if cam.is_position_behind(v):
					behind = true
				P.append(v)
			if behind:
				continue
			var n = Vector3(f.n[0], f.n[1], f.n[2])
			var c = (P[0] + P[1] + P[2] + P[3]) * 0.25
			var dist = cam.global_position.distance_to(c)
			if dist > PICK_RANGE or n.dot(cam.global_position - c) <= 0.0:
				continue
			var poly = PackedVector2Array()
			for v in P:
				poly.append(cam.unproject_position(v))
			# a little slack around small, far signs
			var hit = Geometry2D.is_point_in_polygon(sp, poly)
			if not hit:
				var cc = cam.unproject_position(c)
				hit = sp.distance_to(cc) < 40.0
			if hit and dist < best_d:
				best_d = dist
				best = id
	return best

func _retype(id: String) -> void:
	var cur = text_of(id)
	var q = "Words for this sign (" + id + "). Leave empty to restore \"" + str(recs[id].title) + "\"."
	var res = JavaScriptBridge.eval("(function(){var r=prompt(" + JSON.stringify(q) + "," + JSON.stringify(cur) + ");return r===null?'__CANCEL__':r})()")
	if not (res is String) or res == "__CANCEL__":
		return
	var txt = res.strip_edges().to_upper() if recs[id].kind == "kb_dept" else res.strip_edges()
	if txt == "":
		txt = str(recs[id].title)
	if txt == str(published.get(id, recs[id].title)):
		draft.erase(id)
	else:
		draft[id] = txt
	_save_draft()
	_apply(id)
	_refresh_ui()

func _save_draft() -> void:
	JavaScriptBridge.eval("(function(){try{localStorage.setItem('" + DRAFT_KEY + "'," + JSON.stringify(JSON.stringify(draft)) + ")}catch(e){}})()")

# ------------------------------------------------------------------ publishing
## Hands the draft to shell.html's mallSigns.publish(), which merges it into the live
## play/signs.json on GitHub; then polls its status.
func _publish() -> void:
	if draft.is_empty() or publishing:
		return
	var ok = JavaScriptBridge.eval("(function(){if(!window.mallSigns)return '0';window.mallSigns.publish(" + JSON.stringify(JSON.stringify(draft)) + ");return '1'})()")
	if str(ok) != "1":
		status.text = "Publishing isn't available on this page"
		return
	publishing = true
	poll_t = 0.0
	_refresh_ui()

func _process(dt: float) -> void:
	if web:
		near_t += dt
		if near_t > 0.2:
			near_t = 0.0
			_near_check()
	if not publishing:
		return
	poll_t += dt
	if poll_t < 0.5:
		return
	poll_t = 0.0
	var s = JavaScriptBridge.eval("window.mallSigns ? window.mallSigns.status : 'error: no publisher'")
	if not (s is String) or s == "busy":
		return
	publishing = false
	if s == "ok":
		for id in draft:
			published[id] = draft[id]
		draft.clear()
		_save_draft()
		status.text = "Published. Everyone sees it in about a minute."
	else:
		status.text = "Not published: " + s.trim_prefix("error:").strip_edges()
	_refresh_ui()
