## The story machinery in one wing (workstream Q, Nov 2 2026; design/godot-dialogue.md,
## design/godot-quests.md). Made by player.gd as its child "Story", every wing and year, after
## Interact (it needs mall.flags). Steven writes the story; this node only runs what the data says:
##  - gates (data/story/gates.json): locked places, scripts/dialogue/gate.gd;
##  - counter attendants (data/story/attendants.json): scripts/attendants/attendant.gd;
##  - the conversation screen (scripts/dialogue/dialogue_ui.gd) for anything in group "talker";
##  - the book reader (scripts/dialogue/book_ui.gd) for the items in data/story/books.json.
## API for other code:
##   story.talk(npc: Node3D, path: String, cue := "")   # any NPC with optional talk_begin/talk_end/face_point
##   story.read_item(item_id) -> bool                    # open the book an item is
##   story.book_for(item_id) -> String                   # its .dialogue path, "" when not a book
##   story.make_state(res)                               # what a .dialogue file sees (dialogue_state.gd)
extends Node

const State = preload("res://scripts/dialogue/dialogue_state.gd")
const Gate = preload("res://scripts/dialogue/gate.gd")
const Attendant = preload("res://scripts/attendants/attendant.gd")
const GATES := "res://data/story/gates.json"
const ATTENDANTS := "res://data/story/attendants.json"
const BOOKS := "res://data/story/books.json"

var player: Node3D
var ui: CanvasLayer
var book: CanvasLayer
var books := {}
var attendants: Array = []
var gates: Array = []

func _ready() -> void:
	var b = _json(BOOKS)
	if b is Dictionary:
		books = b.get("books", {})
	ui = load("res://scripts/dialogue/dialogue_ui.gd").new()
	ui.name = "DialogueUI"; ui.player = player; ui.story = self
	add_child(ui)
	book = load("res://scripts/dialogue/book_ui.gd").new()
	book.name = "BookUI"; book.player = player; book.story = self
	add_child(book)
	_spawn_gates()
	_spawn_attendants.call_deferred()

static func _json(path: String):
	if not FileAccess.file_exists(path):
		return null
	return JSON.parse_string(FileAccess.get_file_as_string(path))

static func in_year(years, year: int) -> bool:
	if years == null or str(years) == "both":
		return true
	if years is Array:
		for y in years:
			if int(y) == year:
				return true
		return false
	return int(years) == year

# ------------------------------------------------------------------ gates
## Now, not deferred: the shoppers (scripts/npcs.gd) copy the walk grid when they start, so a
## locked store is closed to them too.
func _spawn_gates() -> void:
	var j = _json(GATES)
	if not (j is Dictionary):
		return
	for e in j.get("gates", []):
		if not in_year(e.get("years", "both"), int(player.year)):
			continue
		var here: bool = int(e.get("wing", 0)) == int(player.wing) or int(player.wing) == 0
		if not here and e.get("doors", []).is_empty():
			continue
		var g := Gate.new()
		g.setup(player, e, here)
		add_child(g)
		gates.append(g)

## player.gd's _cross(): the gate that locks this exterior door, or null.
func door_gate(store_key: String):
	for g in gates:
		if is_instance_valid(g) and g.locks_door(store_key):
			return g
	return null

# ------------------------------------------------------------------ attendants
func _spawn_attendants() -> void:
	await get_tree().process_frame     # the shoppers are added deferred too: reserve skins after
	var j = _json(ATTENDANTS)
	if not (j is Dictionary):
		return
	var crowd = player.get_parent().get_node_or_null("Shoppers")
	for e in j.get("attendants", []):
		if int(e.get("wing", 0)) != int(player.wing) and int(player.wing) != 0:
			continue
		if not in_year(e.get("years", [1995]), int(player.year)):
			continue
		var a := Attendant.new()
		add_child(a)
		if not a.setup(player, self, e):
			a.queue_free()
			continue
		attendants.append(a)
		# one of each character: keep the crowd from wearing the same person
		if crowd and "in_use" in crowd:
			crowd.in_use[str(e.get("skin", ""))] = true

# ------------------------------------------------------------------ talking and reading
func make_state(res: Resource):
	var s = State.new(player.mall)
	s.known = res.get_meta("flag_names", []) if res else []
	s.say = Callable(player, "_say") if player.has_method("_say") else Callable()
	var it = player.interact
	if it and it.get("db"):
		for id in it.db.ids_for_year(int(player.year)):
			s.item_names[id] = str(it.db.get_item(id).get("name", id))
	return s

func talk(npc: Node3D, path: String, cue := "") -> void:
	if busy():
		return
	ui.talk(npc, path, cue)

func busy() -> bool:
	return (ui and ui.active) or (book and book.active)

func book_for(item_id: String) -> String:
	return str(books.get(item_id, ""))

func read_item(item_id: String) -> bool:
	var p := book_for(item_id)
	if p == "" or busy():
		return false
	var title := item_id
	var it = player.interact
	if it and it.get("db"):
		title = str(it.db.get_item(item_id).get("name", item_id))
	return book.open(p, title)
