## COIN COMET's six play positions (workstream P, Nov 2026; design/storefronts/pocket-change.md
## "COIN COMET is playable"). Made by scripts/signs.gd under its node when the wing has the
## cabinet's sign record ("pc.pusher.1", gen/w2/signs.json). One interactable Node3D per position
## (B+C's contract, scripts/interact.gd: group "interactable", interact_prompt(), interact()),
## standing on the cabinet's front face at the position's centre, so a player within 1.6 m and
## facing the machine sees "Play COIN COMET" (E / X / the touch Use button) and the page
## play/pusher.html?pos=<1..6> opens in the same full-window frame as WHIRLWIND and the other
## games (web/shell.html window.mallRoms, "emu-close" to come back). Positions 1-3 are the side
## whose marquee faces +x (the cabinet's first half in tools/stores/pocket_change/pusher.gd),
## 4-6 the other side; each keeps its own saved machine in the browser.
## When the page closes, the carried state is re-read (scripts/inventory.gd load_saved()): the
## page pays the quarters in and out of the same "mall-state-<year>" record.
extends Node

const PX := [-0.527, 0.0, 0.527]   # the positions' centres along the cabinet (pusher.gd PX)
const Z_M := 0.29                  # the marquee face is this far behind the cabinet's front face

var signs: Node                    # the Signs node (recs, text_of)
var open_pos := 0                  # the position whose page is open, 0 when none
var poll := 0.0


class Position:
	extends Node3D
	var pos := 1
	var owner_node: Node

	func interact_prompt() -> String:
		return "Play " + owner_node.title()

	func interact(player: Node) -> void:
		owner_node.play(pos, player)


func _ready() -> void:
	signs = get_parent()
	if signs == null or not ("recs" in signs) or not signs.recs.has("pc.pusher.1"):
		return
	# the double cabinet writes one record per side under the same id (signs.gd keeps the last),
	# so the faces come from the wing's own list (res://gen/w<n>/signs.json)
	var faces: Array = []
	var gen: String = signs.get_parent().get_meta("gen", "res://gen/") if signs.get_parent() else "res://gen/"
	var J = JSON.parse_string(FileAccess.get_file_as_string(gen + "signs.json")) if FileAccess.file_exists(gen + "signs.json") else null
	if J is Dictionary:
		for r in J.get("signs", []):
			if str(r.get("id", "")) == "pc.pusher.1":
				faces.append(r.faces[0])
	if faces.is_empty():
		faces = signs.recs["pc.pusher.1"].faces
	faces.sort_custom(func(a, b): return a.n[0] > b.n[0])     # positions 1-3 on the side facing +x
	for k in mini(2, faces.size()):
		var f = faces[k]
		var n := Vector3(f.n[0], 0.0, f.n[2]).normalized()
		var c := Vector3.ZERO
		for p in f.p:
			c += Vector3(p[0], 0.0, p[2])
		c *= 0.25
		var front := c + n * Z_M
		for j in 3:
			var node := Position.new()
			node.pos = k * 3 + j + 1
			node.owner_node = self
			node.name = "PusherPos%d" % node.pos
			# the cabinet's local x runs along -z for the side facing +x, +z for the other (pusher.gd X())
			node.position = Vector3(front.x, 1.0, front.z - n.x * PX[j])
			node.add_to_group("interactable")
			add_child(node)


func title() -> String:
	return signs.text_of("pc.pusher.1") if signs and signs.has_method("text_of") else "COIN COMET"


## Open the page for position pos in the mall's game frame (web only).
func play(pos: int, player: Node) -> void:
	if not OS.has_feature("web"):
		print("COIN COMET: would open play/pusher.html?pos=%d" % pos)
		return
	var year := 1995
	if player and "mall" in player and player.mall != null:
		year = int(player.mall.year)
	var q := "pusher.html?pos=%d&year=%d&name=%s" % [pos, year, title().uri_encode()]
	JavaScriptBridge.eval("window.mallRoms && window.mallRoms.open(" + JSON.stringify(q) + ")")
	open_pos = pos


## While the page is open, watch for it closing; then re-read the carried state (the quarters).
func _process(dt: float) -> void:
	if open_pos == 0 or not OS.has_feature("web"):
		return
	poll += dt
	if poll < 0.5:
		return
	poll = 0.0
	var o = JavaScriptBridge.eval("window.mallRoms ? window.mallRoms.isOpen() : '0'")
	if str(o) == "1":
		return
	open_pos = 0
	var player = get_tree().get_first_node_in_group("player") if get_tree() else null
	if player == null:
		var root = get_parent().get_parent() if get_parent() else null
		player = root.get_node_or_null("Player") if root else null
	if player and "mall" in player and player.mall != null:
		player.mall.load_saved()
