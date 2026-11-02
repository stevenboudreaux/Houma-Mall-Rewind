## B2 (design/godot-character-editor.md): the character pack. The B1 bodies, hair and pieces are not
## in the wing packs (wing 2 alone is ~96 MB); each map has its own pack with only its presets' files
## and the player's wardrobe (tools/chars/export_chars.sh): chars_w<n>[y26].<desktop|mobile>.pck next to
## the game. On the web this node fetches the one for this map (through the page's cache,
## web/shell.html), mounts it, then:
##   - every counter attendant with "look": "preset" puts its preset body on (until then it shows its
##     Mixamo skin, the fallback),
##   - the avatar becomes the player's preset body (scripts/avatar.gd chars_ready()),
##   - the menu's AVATAR tab opens the character editor from then on.
## Off the web (native runs, tests) the files are in res:// already: ready at once.
## Made by scripts/player.gd as its child "CharPack" (before CharOwner).
extends Node

signal ready_now

var player: Node3D
var is_ready := false
var _http: HTTPRequest

func _ready() -> void:
	if AvatarChar.available():
		_done.call_deferred()
		return
	if not OS.has_feature("web"):
		return            # a native build without the files: everyone stays on the fallbacks
	var name_ := str(JavaScriptBridge.eval("'chars_w' + window.__mallWing + (window.__mallYear || '') + '.' + window.__mallPack + '.pck'"))
	var url := str(JavaScriptBridge.eval("new URL(%s, location.href).toString()" % JSON.stringify(name_)))
	_http = HTTPRequest.new()
	_http.download_file = "user://" + name_
	_http.use_threads = false
	add_child(_http)
	_http.request_completed.connect(func(result: int, code: int, _h, _b):
		if result != HTTPRequest.RESULT_SUCCESS or code != 200:
			push_warning("char_pack: could not fetch %s (%d / %d): characters stay on their fallbacks" % [name_, result, code])
			return
		if not ProjectSettings.load_resource_pack("user://" + name_, false):
			push_warning("char_pack: could not mount " + name_)
			return
		print("char_pack: mounted %s" % name_)
		_done())
	var err := _http.request(url)
	if err != OK:
		push_warning("char_pack: request failed %d" % err)

func _done() -> void:
	CharPreset._have.clear()
	if not AvatarChar.available():
		push_warning("char_pack: mounted, but no bodies in it")
		return
	is_ready = true
	for a in get_tree().get_nodes_in_group("talker"):
		if a.has_method("chars_ready"): a.chars_ready()
	if player and player.get("avatar") != null and player.avatar.has_method("chars_ready"):
		player.avatar.chars_ready()
	ready_now.emit()
