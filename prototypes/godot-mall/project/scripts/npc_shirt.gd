extends Node
## Words on an NPC's shirt, painted at load time and editable by the owner (Steven, Oct 16 2026).
##
## scripts/npc_shirt.json says which skin, which atlas, where on it (the chest front's UV island,
## in atlas pixels) and the shipped words. play/shirt_text.json, published from this page with the
## mall editor's GitHub token (web/shell.html mallShirtText), overrides the words for everyone
## without a rebuild, the same way Pocket Change's prize words work (scripts/prizes.gd).
##
## How it paints: a SubViewport draws the skin's atlas and a Label over it, the result becomes the
## albedo of every material that used that atlas (the skin's mesh resources are shared, so the
## shopper wearing it updates in place). The atlas itself ships word-free.
##
## Owner (localStorage southland-editor = 1): a "Shirt words" button top right opens the same form
## as the prize words (mallPrizeEdit); Save paints it here and publishes it for everyone.

const CFG := "res://scripts/npc_shirt.json"
const PUBLISHED := "shirt_text.json"   # next to the wing's index.html, in play/
const FONT_FILES := {"forza": "forza.ttf", "sans": "sans.otf", "sans_italic": "sans_italic.otf", "serif": "serif.ttf", "script": "script.ttf"}

var player: Node
var cfg := {}
var shipped := {}       # the words as shipped (npc_shirt.json "text")
var pub := {}           # the published words (play/shirt_text.json "text"[id]), may be empty
var is_owner := false
var btn: Button
var dialog_open := false
var publishing := false
var poll_t := 0.0
var painting := false
var paint_again := false
var fonts := {}
var painted: ImageTexture
var _keep: Node      # an instance of the skin, never in the tree: it keeps the shared mesh and
                     # materials cached, so a shopper who spawns later gets the painted atlas too

func _exit_tree() -> void:
	if _keep:
		_keep.free()
		_keep = null

func _ready() -> void:
	var j = JSON.parse_string(FileAccess.get_file_as_string(CFG))
	if not (j is Dictionary):
		push_warning("npc_shirt: no " + CFG); return
	cfg = j
	shipped = cfg.get("text", {}).duplicate()
	if OS.has_feature("web"):
		is_owner = str(JavaScriptBridge.eval("(function(){try{return localStorage.getItem('southland-editor')==='1'?'1':'0'}catch(e){return '0'}})()")) == "1"
		_fetch_published()
	paint()
	_owner_ui()

## The words visitors see now: the published fields over the shipped ones.
func words() -> Dictionary:
	var d := shipped.duplicate()
	d.merge(pub, true)
	return d

func _font(name: String) -> Font:
	if not FONT_FILES.has(name):
		name = "sans"
	if not fonts.has(name):
		fonts[name] = load("res://fonts/" + FONT_FILES[name])
	return fonts[name]

# ---- painting
func paint() -> void:
	if painting:
		paint_again = true
		return
	painting = true
	var atlas_path := str(cfg.get("atlas", ""))
	var atlas = load(atlas_path) if atlas_path != "" else null
	if atlas == null:
		push_warning("npc_shirt: no atlas " + atlas_path); painting = false; return
	var w: int = atlas.get_width()
	var h: int = atlas.get_height()
	var vp := SubViewport.new()
	vp.size = Vector2i(w, h)
	vp.disable_3d = true
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var tr := TextureRect.new()
	tr.texture = atlas
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.size = Vector2(w, h)
	vp.add_child(tr)
	vp.add_child(_label(words(), cfg.get("rect", [0, 0, w, h])))
	add_child(vp)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var img: Image = vp.get_texture().get_image()
	vp.queue_free()
	if img:
		img.generate_mipmaps()
		painted = ImageTexture.create_from_image(img)
		_apply(atlas_path, painted)
	painting = false
	if paint_again:
		paint_again = false
		paint()

## Every material of the skin's scene that used the atlas now uses the painted copy. The scene's
## mesh resources are shared with the shopper wearing it, so she changes too, and the instance is
## kept (off the tree) so the resources stay cached for a shopper who spawns later.
func _apply(atlas_path: String, tex: Texture2D) -> void:
	var ps = load(str(cfg.get("scn", "")))
	if not (ps is PackedScene):
		push_warning("npc_shirt: no scene " + str(cfg.get("scn", ""))); return
	var tmp: Node = ps.instantiate()
	var n := 0
	for mi in tmp.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var m = mi.mesh.surface_get_material(i)
			if m is StandardMaterial3D and m.albedo_texture and m.albedo_texture.resource_path == atlas_path:
				m.albedo_texture = tex
				if m.emission_enabled and m.emission_texture:
					m.emission_texture = tex
				n += 1
	if _keep:
		_keep.free()
	_keep = tmp
	if n == 0:
		push_warning("npc_shirt: nothing used " + atlas_path)

## One Label, shrunk until the words fit the rect (atlas pixels).
func _label(st: Dictionary, rect: Array) -> Label:
	var l := Label.new()
	l.position = Vector2(rect[0], rect[1])
	l.size = Vector2(rect[2], rect[3])
	var txt := str(st.get("text", ""))
	l.text = txt
	var f := _font(str(st.get("font", "sans")))
	var sz := clampi(int(st.get("size", 60)), 6, 200)
	var oc := str(st.get("outline", ""))
	var has_ol := oc != ""
	var w := float(rect[2]) - 4.0
	var h := float(rect[3])
	while sz > 7:
		var osz := maxi(2, sz / 9) if has_ol else 0
		var one := f.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, sz)
		if one.x + osz * 2 <= w and f.get_height(sz) <= h + 6:
			break
		sz -= 1
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", Color.from_string(str(st.get("fill", "#ffffff")), Color.WHITE))
	if has_ol:
		l.add_theme_color_override("font_outline_color", Color.from_string(oc, Color.BLACK))
		l.add_theme_constant_override("outline_size", maxi(2, sz / 9) * 2)
	return l

func _fetch_published() -> void:
	var url = JavaScriptBridge.eval("new URL('" + PUBLISHED + "', location.href).href")
	if not (url is String):
		return
	var hr := HTTPRequest.new()
	add_child(hr)
	hr.request_completed.connect(func(result, code, _headers, body):
		if result == HTTPRequest.RESULT_SUCCESS and code == 200:
			var j = JSON.parse_string(body.get_string_from_utf8())
			var id := str(cfg.get("id", "shirt"))
			if j is Dictionary and j.get("text") is Dictionary and j.text.get(id) is Dictionary:
				pub = j.text[id]
				paint()
		hr.queue_free())
	hr.request(url + "?t=" + str(Time.get_unix_time_from_system()))

# ---- the owner's editing
func _owner_ui() -> void:
	if not is_owner or player == null or not ("hud" in player):
		return
	btn = Button.new()
	btn.text = "Shirt words"
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_filter = Control.MOUSE_FILTER_IGNORE   # hit-tested in _input (touch skips mouse emulation)
	btn.add_theme_font_size_override("font_size", 14)
	btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	btn.offset_left = -200; btn.offset_right = -10
	btn.offset_top = int(cfg.get("button_top", 128)); btn.offset_bottom = btn.offset_top + 32
	player.hud.get_parent().add_child(btn)

func _input(e: InputEvent) -> void:
	if btn == null or dialog_open:
		return
	var pos = null
	if e is InputEventScreenTouch and e.pressed:
		pos = e.position
	elif e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position
	if pos != null and btn.is_visible_in_tree() and btn.get_global_rect().has_point(pos):   # OWNER: tucked into the menu
		get_viewport().set_input_as_handled()
		_open_dialog()

func _open_dialog() -> void:
	var st := words()
	var id := str(cfg.get("id", "shirt"))
	var spec := {"title": str(cfg.get("title", "the shirt")), "fonts": FONT_FILES.keys(),
		"fields": [{"id": id, "label": str(cfg.get("label", "Words")), "text": str(st.get("text", "")), "style": true,
			"font": str(st.get("font", "sans")), "size": int(st.get("size", 60)),
			"fill": _hex(str(st.get("fill", "#ffffff"))), "outline": str(st.get("outline", ""))}]}
	var ok = JavaScriptBridge.eval("(function(){if(!window.mallPrizeEdit)return '0';window.mallPrizeEdit.open(" + JSON.stringify(JSON.stringify(spec)) + ");return '1'})()")
	if str(ok) != "1":
		btn.text = "No editor on this page"
		return
	dialog_open = true

func _hex(c: String) -> String:
	return "#" + Color.from_string(c, Color.BLACK).to_html(false)

func _process(dt: float) -> void:
	if dialog_open:
		_poll_dialog()
	if publishing:
		_poll_publish(dt)

func _poll_dialog() -> void:
	var r = JavaScriptBridge.eval("window.mallPrizeEdit ? window.mallPrizeEdit.result : '{\"cancel\":1}'")
	if not (r is String) or r == "":
		return
	dialog_open = false
	var j = JSON.parse_string(r)
	if not (j is Dictionary):
		return
	var id := str(cfg.get("id", "shirt"))
	var want := {}
	if j.get("save") is Dictionary and j.save.get(id) is Dictionary:
		want = j.save[id]
	elif j.get("reset") is Array:
		want = shipped.duplicate()
	else:
		return
	pub = {}
	for k in ["text", "font", "size", "fill", "outline"]:
		if want.has(k) and want[k] != null:
			pub[k] = int(want[k]) if k == "size" else str(want[k])
	paint()
	_publish()

## Everyone's words become these: play/shirt_text.json on GitHub, through the page's publisher.
func _publish() -> void:
	var id := str(cfg.get("id", "shirt"))
	var draft := {}
	draft[id] = pub
	var ok = JavaScriptBridge.eval("(function(){if(!window.mallShirtText)return '0';window.mallShirtText.publish(" + JSON.stringify(JSON.stringify(draft)) + ");return '1'})()")
	if str(ok) != "1":
		btn.text = "No publisher on this page"
		return
	publishing = true
	poll_t = 0.0
	btn.text = "Publishing..."

func _poll_publish(dt: float) -> void:
	poll_t += dt
	if poll_t < 0.5:
		return
	poll_t = 0.0
	var s = JavaScriptBridge.eval("window.mallShirtText ? window.mallShirtText.status : 'error: no publisher'")
	if not (s is String) or s == "busy":
		return
	publishing = false
	if s == "ok":
		btn.text = "Shirt words: published"
	else:
		btn.text = str(s).left(28)
		push_warning("npc_shirt: " + str(s))
	get_tree().create_timer(4.0).timeout.connect(_reset_button)

func _reset_button() -> void:
	if btn:
		btn.text = "Shirt words"
