## B2 (design/godot-character-editor.md), reworked by CHARS (Nov 3 2026, design/godot-build-hosting.md
## "Shared packs"): the character packs. The B1 bodies, hair and pieces are not in the wing packs. They
## ship as shared packs (tools/shared_packs.py): "chars" (both bodies, the player's wardrobe, the
## clothed defaults: every map) and "chars_<map>" (only the pieces that map's presets add). On the web
## the page fetches them once the mall is running (web/shell.html, through its cache) and copies them
## into the engine's file system; this node waits for that (SharedPacks.later_paths("chars")), mounts
## them, then:
##   - every counter attendant with "look": "preset" puts its preset body on (until then it shows its
##     Mixamo skin, the fallback),
##   - the avatar becomes the player's preset body (scripts/avatar.gd chars_ready()),
##   - the menu's AVATAR tab opens the character editor from then on.
## Off the web (native runs, tests) the files are in res:// already: ready at once.
## Made by scripts/player.gd as its child "CharPack" (before CharOwner).
##
## The Nov 2 bug ("the character pack doesn't mount", a page error "null function"): this node fetched
## the pack itself with HTTPRequest.download_file into user://. The page now does the fetch (cached)
## and copies the bytes into the engine's file system; no HTTPRequest is used for packs.
extends Node

signal ready_now

const POLL_S := 0.5
const GIVE_UP_S := 600.0

var player: Node3D
var is_ready := false
var _wait := 0.0
var _waited := 0.0

func _ready() -> void:
	set_process(false)
	if AvatarChar.available() and not Engine.has_meta("qa_late_chars"):   # (qa: tools/qa/char_avatar_test.gd --late=1)
		_done.call_deferred()
		return
	if not OS.has_feature("web") or get_node_or_null("/root/SharedPacks") == null:
		return            # a native build without the files: everyone stays on the fallbacks
	set_process(true)

func _process(dt: float) -> void:
	_wait -= dt
	_waited += dt
	if _wait > 0.0:
		return
	_wait = POLL_S
	var st = get_node("/root/SharedPacks").later_paths("chars")
	if st == null:
		if _waited > GIVE_UP_S:
			push_warning("char_pack: the character packs did not arrive: characters stay on their fallbacks")
			set_process(false)
		return
	set_process(false)
	if not (st is Array):
		push_warning("char_pack: the page could not fetch the character packs: characters stay on their fallbacks")
		return
	for p in st:
		get_node("/root/SharedPacks").mount(str(p))
	print("char_pack: mounted %d character pack(s)" % st.size())
	_done()

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
