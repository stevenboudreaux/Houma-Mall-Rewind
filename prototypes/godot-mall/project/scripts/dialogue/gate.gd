## A locked place (workstream Q, design/godot-quests.md): a node in group "gate" holding a flag name.
## While mall.flags.has(flag) is false:
##  - the player's walk grid is closed over `rect` (world metres, snapped out to whole 2 m tiles), so
##    walking stops there, and walking into it shows `message` (bottom middle, as other notices);
##  - the exterior doors in `doors` (exterior.json "store" keys, e.g. "s2e") do not open: player.gd's
##    _cross() asks locks_door(); the press shows `door_message`.
## When the flag is set (a dialogue's `unlock`, the console) the tiles reopen at once.
## Made by scripts/dialogue/story.gd from data/story/gates.json; no geometry, nothing baked.
extends Node3D

var player: Node3D
var flag := ""
var rect := Rect2()          # x, z in metres (empty: no walk-grid part, doors only)
var doors: Array = []
var message := ""
var door_message := ""
var _saved := {}             # Vector2i tile -> original char
var _closed := false
var _said_t := 0.0
var _near := false

func setup(p: Node3D, e: Dictionary, in_wing: bool) -> void:
	player = p
	name = "Gate_" + str(e.get("id", flag))
	flag = str(e.get("flag", ""))
	doors = e.get("doors", [])
	message = str(e.get("message", "Locked."))
	door_message = str(e.get("door_message", message))
	var r: Array = e.get("rect", [])
	if in_wing and r.size() == 4:
		rect = Rect2(float(r[0]), float(r[1]), float(r[2]) - float(r[0]), float(r[3]) - float(r[1]))
		position = Vector3(rect.get_center().x, 0, rect.get_center().y)
	add_to_group("gate")

func _ready() -> void:
	var f = _flags()
	if f:
		f.changed.connect(func(_n, _v): refresh())
	refresh()

func _flags():
	return player.mall.flags if player and player.mall and player.mall.flags else null

func locked() -> bool:
	var f = _flags()
	return f == null or not f.has(flag)

## Close or reopen the walk-grid tiles to match the flag.
func refresh() -> void:
	var want := locked() and rect.size != Vector2.ZERO
	if want == _closed or player == null:
		return
	var rows: PackedStringArray = player.walk_rows
	var o: Vector2 = player.map_origin
	var s: float = player.map_scale
	var tx0 := int(floor(rect.position.x / s + o.x)); var tx1 := int(ceil(rect.end.x / s + o.x))
	var ty0 := int(floor(rect.position.y / s + o.y)); var ty1 := int(ceil(rect.end.y / s + o.y))
	for ty in range(maxi(ty0, 0), mini(ty1, rows.size())):
		var row := rows[ty]
		for tx in range(maxi(tx0, 0), mini(tx1, row.length())):
			var k := Vector2i(tx, ty)
			var ch := ""
			if want:
				_saved[k] = row.substr(tx, 1)
				ch = "0"
			elif _saved.has(k):
				ch = _saved[k]
			if ch != "":
				row = row.substr(0, tx) + ch + row.substr(tx + 1)
		rows[ty] = row
	if not want:
		_saved.clear()
	player.walk_rows = rows
	_closed = want

## player.gd: is this exterior door (its "store" key) locked by this gate?
func locks_door(store_key: String) -> bool:
	return locked() and store_key in doors

func say_locked(door := false) -> void:
	var t := door_message if door else message
	var st = player.get_node_or_null("Story") if player else null
	if st and st.has_method("say"):
		st.say(t)
	elif player and player.has_method("_say"):
		player._say(t)

func _process(dt: float) -> void:
	_said_t = maxf(0.0, _said_t - dt)
	if not _closed or player == null:
		return
	# walking into the closed tiles: the player stops RADIUS short of them
	var p := Vector2(player.position.x, player.position.z)
	var near := rect.grow(0.55).has_point(p)
	if near and not _near and _said_t <= 0.0:
		say_locked()
		_said_t = 4.0
	if near:
		_near = true
	elif not rect.grow(1.6).has_point(p):
		_near = false     # walked away: the next approach says it again
