## Unit checks for the quest flags (scripts/flags.gd) and the gate's walk-grid lock
## (scripts/dialogue/gate.gd), headless, no wing: design/godot-quests.md.
##   godot --headless --path . --script res://tools/qa/flags_test.gd
## Prints FLAGS TEST OK (n checks), or the failed checks. Exit code 0 / 1.
extends SceneTree

const Flags = preload("res://scripts/flags.gd")
const Gate = preload("res://scripts/dialogue/gate.gd")

var oks := 0
var errors: Array = []

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok:
		oks += 1
	else:
		errors.append(what)

func _initialize() -> void:
	_run.call_deferred()      # nodes added from _initialize get _ready only once the loop runs

func _run() -> void:
	_test_set_get()
	_test_signal()
	_test_round_trip()
	_test_engine_meta()
	_test_bad()
	_test_gate()
	_test_gates_json()
	printerr("FLAGS TEST OK (%d checks)" % oks if errors.is_empty() else "FLAGS TEST FAILED: " + str(errors))
	quit(0 if errors.is_empty() else 1)

func _fresh(store := {}):
	var f = Flags.new()
	f.backend = store
	return f

func _test_set_get() -> void:
	var f = _fresh()
	_check(not f.has("a") and f.get("a") == null, "unset flag: has false, get null")
	f.set_flag("a")
	_check(f.has("a") and f.get("a") == true, "set_flag(name) sets true")
	f.set("b", false)
	_check(not f.has("b") and f.get("b") == false, "set(name, false): has false, get false")
	f.set("c", 3)
	_check(f.has("c") and float(f.get("c")) == 3.0, "a number is kept (as a float)")
	f.set("d", "")
	_check(not f.has("d"), "an empty string is not set")
	f.set("e", "yes")
	_check(f.has("e") and f.get("e") == "yes", "a string is kept")
	_check(f.get_flag("zz", 7) == 7, "get_flag default")
	f.clear("a")
	_check(not f.has("a") and f.get("a") == null, "clear forgets")
	_check(f.names() == ["b", "c", "d", "e"], "names sorted: " + str(f.names()))

func _test_signal() -> void:
	var f = _fresh()
	var got := []
	f.changed.connect(func(n, v): got.append([n, v]))
	f.set_flag("x", true)
	f.set_flag("x", true)        # unchanged: no signal
	f.set_flag("x", false)
	f.clear("x")
	_check(got == [["x", true], ["x", false], ["x", null]], "changed(name, value) once per real change: " + str(got))

func _test_round_trip() -> void:
	var store := {}
	var f = _fresh(store)
	f.set_flag("dillards_unlocked")
	f.set_flag("count", 2)
	f.set_flag("word", "hi")
	_check(store.has(Flags.KEY), "saved under " + Flags.KEY + " on every change")
	var g = _fresh(store)
	_check(g.load_saved(), "a second object reads it back")
	_check(g.has("dillards_unlocked") and float(g.get("count")) == 2.0 and g.get("word") == "hi", "same values after the round trip")
	_check(g.to_json() == f.to_json(), "JSON identical after the round trip")

func _test_engine_meta() -> void:
	# off the web, no backend: Engine metadata (a wing change in one run keeps it)
	if Engine.has_meta("mall_flags"):
		Engine.remove_meta("mall_flags")
	var f = Flags.new()
	f.set_flag("meta_test")
	var g = Flags.new()
	_check(g.load_saved() and g.has("meta_test"), "Engine metadata keeps flags across objects (a wing load)")
	Engine.remove_meta("mall_flags")

func _test_bad() -> void:
	var f = _fresh()
	_check(not f.from_json("") and not f.from_json("[]") and not f.from_json("{\"v\":2,\"flags\":{}}"), "bad or other-version saves are refused")
	_check(f.from_json("{\"v\":1,\"flags\":{\"ok\":true,\"bad name\":true,\"o\":{}}}") and f.names() == ["ok"], "bad names and values are dropped")
	f.set_flag("no spaces", true)
	_check(not f.has("no spaces"), "a bad name is refused")

## A stand-in player: the walk grid and mall.flags, enough for the gate.
class FakeMall:
	var flags
class FakePlayer extends Node3D:
	var walk_rows := PackedStringArray()
	var map_origin := Vector2(148, 100)
	var map_scale := 2.0
	var mall
	var said := []
	func _say(t: String) -> void:
		said.append(t)

func _test_gate() -> void:
	var p := FakePlayer.new()
	var rows := PackedStringArray()
	for i in 150:
		rows.append("1".repeat(160))
	p.walk_rows = rows
	p.mall = FakeMall.new()
	p.mall.flags = _fresh()
	root.add_child(p)
	var g = Gate.new()
	g.setup(p, {"id": "t", "flag": "dillards_unlocked", "rect": [-10.0, 80.0, 2.0, 82.0], "doors": ["s2e"], "message": "PLACEHOLDER locked", "door_message": "PLACEHOLDER door"}, true)
	root.add_child(g)
	# tiles 143..148 of row 140
	_check(p.walk_rows[140].substr(143, 6) == "000000" and p.walk_rows[140][142] == "1" and p.walk_rows[140][149] == "1", "locked: exactly the opening's tiles are closed")
	_check(p.walk_rows[139] == "1".repeat(160), "the row before is untouched")
	_check(g.locks_door("s2e") and not g.locks_door("s39"), "listed door locked, others not")
	_check(g.is_in_group("gate"), "in group gate")
	p.position = Vector3(-4, 0, 79.6)
	g._process(0.1)
	_check(p.said == ["PLACEHOLDER locked"], "walking into it shows the message")
	g._process(0.1)
	_check(p.said.size() == 1, "once per approach")
	p.mall.flags.set_flag("dillards_unlocked")
	_check(p.walk_rows[140] == "1".repeat(160), "the flag reopens the tiles at once")
	_check(not g.locks_door("s2e"), "and the door")
	p.mall.flags.set_flag("dillards_unlocked", false)
	_check(p.walk_rows[140].substr(143, 6) == "000000", "unsetting closes them again")
	g.free()
	p.free()

func _test_gates_json() -> void:
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/gates.json"))
	_check(j is Dictionary and j.get("gates") is Array, "data/story/gates.json reads")
	# INT (Demo 49): Dillard's stays open (Steven, Nov 2); the one gate is the cinema's (S)
	var dl := {}
	for e in j.gates:
		_check(str(e.get("id")) != "dillards", "no Dillard's gate")
		if str(e.get("id")) == "cinema":
			dl = e
	_check(dl.get("flag") == "cinema_unlocked" and int(dl.get("threshold", 0)) == 6 and dl.get("key_item") == "folse_stick" and dl.get("doors", []).is_empty(), "the cinema gate: flag, threshold 6, key folse_stick, no doors")
	_check(str(dl.get("message", "")).begins_with("PLACEHOLDER"), "its message is a PLACEHOLDER")
