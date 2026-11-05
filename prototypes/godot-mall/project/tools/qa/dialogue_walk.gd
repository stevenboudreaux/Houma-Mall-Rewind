## Walks every PLACEHOLDER .dialogue file through every branch, headless, through the real
## Dialogue Manager and the game's dialogue state (flags, items): design/godot-dialogue.md.
##   godot --headless --path . --script res://tools/qa/dialogue_walk.gd
## Each path starts from a fresh mall (scripts/inventory.gd) and fresh flags (scripts/flags.gd),
## picks one response at every branch, and records the lines, the effects and the end state.
## Prints DIALOGUE WALK OK (n checks), or the failed checks. Exit code 0 / 1.
extends SceneTree

const Runner = preload("res://scripts/dialogue/dialogue_runner.gd")
const State = preload("res://scripts/dialogue/dialogue_state.gd")
const Flags = preload("res://scripts/flags.gd")
const Inventory = preload("res://scripts/inventory.gd")
const ItemDB = preload("res://scripts/items/item_db.gd")
const DIR := "res://data/story/placeholder/"

var oks := 0
var errors: Array = []
var db

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok:
		oks += 1
	else:
		errors.append(what)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	db = ItemDB.new().load_dir()
	Runner.manager(self)
	await process_frame
	_test_preprocess()
	var att = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/attendants.json"))
	for e in att.attendants:
		if str(e.get("dialogue", "")) == "" and str(e.get("shop", "")) != "":
			continue   # SHOPS: a shop's attendant opens its list (tools/qa/shop_test.gd), no dialogue
		await _test_attendant(str(e.dialogue), str(e.name))
	await _test_book()
	await _test_grammar()
	_test_all_placeholder()
	printerr("DIALOGUE WALK OK (%d checks)" % oks if errors.is_empty() else "DIALOGUE WALK FAILED: " + str(errors))
	quit(0 if errors.is_empty() else 1)

## A fresh world: the carried state and the flags, in memory.
func _world(setup := Callable()) -> Array:
	var m = Inventory.new()
	m.year = 1995
	m.backend = {}
	m.flags = Flags.new()
	m.flags.backend = {}
	if setup.is_valid():
		setup.call(m)
	return [m]

## Follow one path: `choices` are the response indexes to take, in order. Returns
## {lines: [[character, text]], branches: [n responses at each branch], state, mall, ended}.
func _walk(path: String, choices: Array, setup := Callable()) -> Dictionary:
	var res = Runner.load_dialogue(path)
	var m = _world(setup)[0]
	var st = State.new(m)
	st.known = res.get_meta("flag_names", [])
	var out := {"lines": [], "branches": [], "state": st, "mall": m, "ended": false, "short": false, "bad": false}
	var id := Runner.first_cue(res)
	var k := 0
	for guard in 200:
		if id == "" or id.begins_with("END"):
			out.ended = true
			break
		var l = await Runner.next_line(self, res, id, st)
		if l == null:
			out.ended = true
			break
		out.lines.append([str(l.character), str(l.text)])
		if l.responses.size() > 0:
			out.branches.append(l.responses.size())
			if k >= choices.size():
				out.short = true      # the caller asked for fewer choices than there are branches
				break
			if int(choices[k]) >= l.responses.size():
				out.bad = true        # asked for a response that isn't shown
				break
			id = str(l.responses[choices[k]].next_id)
			k += 1
		else:
			id = str(l.next_id)
	return out

## Every complete path through a file: [[choices], result].
func _all_paths(path: String, setup := Callable()) -> Array:
	var done := []
	var todo := [[]]
	while not todo.is_empty():
		var ch: Array = todo.pop_front()
		var r = await _walk(path, ch, setup)
		if r.short:
			for i in r.branches[ch.size()]:
				todo.append(ch + [i])
		else:
			done.append([ch, r])
	return done

func _test_preprocess() -> void:
	var t := Runner.preprocess("give pogs\n\tunlock dillards_unlocked\nif has pogs and not holding dice\n- A [if has pogs /]\nX: I has pogs")
	_check(t == "$> give(\"pogs\")\n\t$> unlock(\"dillards_unlocked\")\nif has(\"pogs\") and not holding(\"dice\")\n- A [if has(\"pogs\") /]\nX: I has pogs", "shorthands rewritten, spoken text untouched: " + t.c_escape())
	var n := Runner.flag_names("set a_flag = true\nif b_flag and has(\"pogs\")\n- R [if not c_flag /]\n$> unlock(\"d_flag\")\nX: e_word")
	n.sort()
	_check(n == ["a_flag", "b_flag", "c_flag", "d_flag"], "flag names found: " + str(n))

func _test_attendant(path: String, speaker: String) -> void:
	var f := path.get_file()
	_check(Runner.load_dialogue(path) != null, f + " compiles")
	var paths = await _all_paths(path)
	_check(paths.size() == 5, f + ": 5 complete paths (3 + 3 - 1): " + str(paths.size()))
	var right := []
	for p in paths:
		var r: Dictionary = p[1]
		_check(r.ended, f + " path %s ends" % str(p[0]))
		for l in r.lines:
			if l[0] != speaker or not str(l[1]).begins_with("PLACEHOLDER"):
				_check(false, f + " line not PLACEHOLDER / wrong speaker: " + str(l))
		var gave := []
		for e in r.state.log:
			if e[0] == "give":
				gave.append(e[1])
		if not gave.is_empty():
			right.append([p[0], gave, r])
	_check(right.size() == 1, f + ": exactly one path gives something")
	if right.size() == 1:
		var r: Dictionary = right[0][2]
		var item: String = right[0][1][0]
		_check(right[0][0] == [1, 1], f + ": the right path is response 2 then 2.2: " + str(right[0][0]))
		_check(r.branches == [3, 3], f + ": two levels of three responses: " + str(r.branches))
		_check(r.mall.has(item), f + ": the item is in the bag after: " + item)
		_check(ItemDB.in_year(db.get_item(item), 1995), f + ": the given item exists in 1995: " + item)
		var fl: Array = r.mall.flags.names()
		_check(fl.size() == 1 and r.mall.flags.has(fl[0]), f + ": its done-flag is set: " + str(fl))
		_check(str(r.lines[0][1]).contains("friend"), f + ": {{name}} reads 'friend' until M lands: " + str(r.lines[0][1]))
		# talking again once done: the short line, nothing given twice
		var again = await _walk(path, [], func(m): m.flags.set_flag(fl[0]))
		_check(again.ended and again.lines.size() == 1 and str(again.lines[0][1]).contains("already done"), f + ": a second talk after the right path is the 'already done' line")

func _test_book() -> void:
	var path := DIR + "PLACEHOLDER_book.dialogue"
	var paths = await _all_paths(path)
	_check(paths.size() == 2, "book: two branches: " + str(paths.size()))
	for p in paths:
		var r: Dictionary = p[1]
		_check(r.ended and r.mall.flags.has("placeholder_book_finished"), "book branch %s reaches the ending and sets placeholder_book_finished" % str(p[0]))
		_check(str(r.lines[r.lines.size() - 1][1]).contains("last page"), "book branch %s ends on the last page" % str(p[0]))
		_check(r.lines.size() == (5 if p[0] == [0] else 4), "book branch %s page count %d" % [str(p[0]), r.lines.size()])

func _test_grammar() -> void:
	var path := DIR + "PLACEHOLDER_grammar.dialogue"
	# nothing carried: the "neither" line; the hidden response stays hidden
	var r = await _walk(path, [0])
	_check(str(r.lines[1][1]).contains("neither"), "grammar: neither has nor holding")
	_check(r.branches == [1], "grammar: [if holding dice /] hides a response: " + str(r.branches))
	_check(r.mall.flags.has("placeholder_gate") and r.mall.flags.get("placeholder_off") == false, "grammar: unlock sets, $> flag = false sets false")
	# a Pog pack in the bag: has + take
	r = await _walk(path, [0], func(m): m.add("pogs"))
	_check(str(r.lines[1][1]).contains("has") and not r.mall.has("pogs") and r.mall.flags.has("placeholder_saw_has"), "grammar: if has pogs, take pogs")
	# the spring in the hand, the dice in the bag: holding wins; the dice response shows
	r = await _walk(path, [0], func(m): m.hand = "spring"; m.add("dice", 1, true))
	_check(str(r.lines[1][1]).contains("holding") and r.mall.flags.has("placeholder_saw_holding"), "grammar: if holding spring")
	_check(r.branches == [1], "grammar: dice in the bag is not 'holding dice' (the response stays hidden): " + str(r.branches))
	r = await _walk(path, [1], func(m): m.hand = "dice")
	_check(r.branches == [2] and r.mall.flags.get("placeholder_gate") == false, "grammar: [if holding dice /] shows it; lock sets false")
	# the player's name from mall.player_name when M provides it
	var st = State.new(null)
	_check(st.player_name() == "friend", "grammar: name falls back to 'friend'")

func _test_all_placeholder() -> void:
	for f in DirAccess.get_files_at(DIR):
		if f.ends_with(".dialogue"):
			_check(f.begins_with("PLACEHOLDER"), "file name marked PLACEHOLDER: " + f)
