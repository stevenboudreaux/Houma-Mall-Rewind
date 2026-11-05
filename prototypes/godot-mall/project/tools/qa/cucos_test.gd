## Workstream CUCOS checks, headless (design/godot-cucos.md "Checks"):
##   godot --headless --path . --script res://tools/qa/cucos_test.gd
## Through the real Dialogue Manager and the game's state (scripts/inventory.gd, scripts/flags.gd,
## scripts/bank.gd on an in-memory backend): every branch of the football lady's tree with Steven's
## exact lines, the repeat visits, the coupon once only, the bartender's coupon path and the doubloon
## once only, buying with money through the shop stub (and not without it), the bartender's choice
## between the coupon and the shop, the doubloon travelling to 2026, the data files.
## Prints CUCOS TEST OK (n checks) or the failures. Exit code 0 / 1.
extends SceneTree

const Runner = preload("res://scripts/dialogue/dialogue_runner.gd")
const State = preload("res://scripts/dialogue/dialogue_state.gd")
const Flags = preload("res://scripts/flags.gd")
const Inventory = preload("res://scripts/inventory.gd")
const ItemDB = preload("res://scripts/items/item_db.gd")
const ShopStub = preload("res://scripts/story/shop_stub.gd")
const LADY := "res://data/story/cucos/football_lady.dialogue"
const BAR := "res://data/story/cucos/bartender.dialogue"

# Steven's lines (the brief, Nov 3 2026), word for word
const Q1 := "Oh, hey, did you watch the game last night?"
const A1 := ["Sure did. Wow, what a win.", "Yeah, I did. Tough loss, but we'll get 'em next time.", "No, I don't watch football."]
const MAD := "Is that supposed to be some kind of a joke or something? You clearly didn't watch the game, or at least the end of it, when we lost in overtime. Makes me mad just thinking about it."
const MAD_AGAIN := "I'm still mad about the game."
const COLD := "Don't watch sports? Well, what else is there to life than family, country and football? I don't understand you."
const COLD_AGAIN := ["Well, what are we supposed to talk about if you don't watch football?", "I don't want to talk to you."]
const Q2 := "I know, right? Breaks my heart when we lose in overtime like that. But we'll get 'em next time. What are you doing for the rest of the day?"
const A2 := ["Watching another football game, of course.", "Go see a movie, because the last thing I want to do is think about football again.", "Just hang out at the mall, I guess."]
const BYE2 := "Well, have fun with that. Who dat?"
const Q3 := "Ain't that the truth? Another chance for our team to let us down. AGAIN. Ha ha ha ha ha. Where are you watching the game?"
const A3 := ["At my house, on my couch with my wife and a beer.", "My podnas are watching the game on the east side, so I'm going there.", "I think I'm going to watch it at Cuco's, but I haven't decided yet."]
const BYE3 := "Well, have fun. Let's get that W. Who dat?"
const COUPON := "Hey, well, you're in Cuco's, huh? Well, you're actually in luck. I have a coupon for a free top-shelf margarita at Cuco's. They normally charge $10 for it. It's free."
const BAR1 := "Oh, wow, you have a top-shelf margarita coupon. That's great. Let me get that for you."
const BAR2 := "Here you go."
const GREETING := "Welcome to Cuco's. What can I get for you today?"

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
	await _test_lady_tree()
	await _test_lady_repeats()
	await _test_coupon_once()
	await _test_bartender()
	await _test_shop()
	_test_bartender_choice()
	_test_travel()
	_test_data()
	printerr("CUCOS TEST OK (%d checks)" % oks if errors.is_empty() else "CUCOS TEST FAILED: " + str(errors))
	quit(0 if errors.is_empty() else 1)

# ------------------------------------------------------------------ helpers
## A fresh mall: bag, flags and wallet in memory.
func _mall(year := 1995):
	var m = Inventory.new()
	m.year = year
	m.backend = {}
	m.flags = Flags.new()
	m.flags.backend = {}
	return m

## Follow one path from cue "start" (or res's first) with mall m: choices = response indexes.
## {lines: [[who, text]], responses: [[texts]], state, ended, short, bad}
func _walk(res, m, choices: Array) -> Dictionary:
	var st = State.new(m)
	st.known = res.get_meta("flag_names", [])
	for id in db.order:
		st.item_names[id] = str(db.get_item(id).get("name", id))
	var out := {"lines": [], "responses": [], "state": st, "ended": false, "short": false, "bad": false}
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
			out.responses.append(l.responses.map(func(r): return str(r.text)))
			if k >= choices.size():
				out.short = true
				break
			if int(choices[k]) >= l.responses.size():
				out.bad = true
				break
			id = str(l.responses[choices[k]].next_id)
			k += 1
		else:
			id = str(l.next_id)
	return out

func _texts(r: Dictionary) -> Array:
	return r.lines.map(func(l): return l[1])

func _gave(r: Dictionary) -> Array:
	var g := []
	for e in r.state.log:
		if e[0] == "give":
			g.append(e[1])
	return g

# ------------------------------------------------------------------ the lady
func _test_lady_tree() -> void:
	var res = Runner.load_dialogue(LADY)
	_check(res != null, "football_lady.dialogue compiles")
	# every complete path from a fresh start
	var done := []
	var todo := [[]]
	while not todo.is_empty():
		var ch: Array = todo.pop_front()
		var r = await _walk(res, _mall(), ch)
		if r.short:
			for i in r.responses[ch.size()].size():
				todo.append(ch + [i])
		else:
			done.append([ch, r])
	var by := {}
	for d in done:
		by[str(d[0])] = d[1]
	_check(done.size() == 7, "the tree has 7 complete paths (3 + 3 + 3 - 2): " + str(by.keys()))
	for d in done:
		_check(d[1].ended and not d[1].bad, "path %s ends" % str(d[0]))
		for l in d[1].lines:
			if l[0] != "":
				_check(false, "she has no speaker name (Steven gave none): " + str(l))
	var first = await _walk(res, _mall(), [])
	_check(first.lines.size() == 1 and first.lines[0][1] == Q1, "she opens: " + str(_texts(first)))
	_check(first.responses[0] == A1, "the three first answers, as written: " + str(first.responses[0]))
	var r: Dictionary = by.get("[0]", {})
	_check(_texts(r) == [Q1, MAD], "A (what a win): her angry line, then it ends: " + str(_texts(r)))
	_check(r.state.mall.flags.has("cu_lady_mad") and _gave(r).is_empty(), "A: mad for good (cu_lady_mad), nothing given")
	r = by.get("[2]", {})
	_check(_texts(r) == [Q1, COLD], "C (no football): her confused line, then it ends: " + str(_texts(r)))
	_check(r.state.log.has(["act", "thinking"]), "C: she looks confused (the 'thinking' gesture)")
	_check(r.state.mall.flags.has("cu_lady_cold"), "C: cold for good (cu_lady_cold)")
	for i in [1, 2]:
		r = by.get("[1, %d]" % i, {})
		_check(_texts(r) == [Q1, Q2, BYE2], "B then %s: 'have fun with that. Who dat?': %s" % ["BC"[i - 1], str(_texts(r))])
		_check(r.responses[1] == A2, "the rest-of-the-day answers, as written")
		_check(r.state.mall.flags.names().is_empty() and _gave(r).is_empty(), "B then %s: no flag, nothing given" % "BC"[i - 1])
	for i in [0, 1]:
		r = by.get("[1, 0, %d]" % i, {})
		_check(_texts(r) == [Q1, Q2, Q3, BYE3], "B, A, then %s: 'Let's get that W. Who dat?': %s" % ["AB"[i], str(_texts(r))])
		_check(r.responses[2] == A3, "the where-are-you-watching answers, as written")
		_check(_gave(r).is_empty(), "B, A, then %s: nothing given" % "AB"[i])
	r = by.get("[1, 0, 2]", {})
	_check(_texts(r) == [Q1, Q2, Q3, COUPON], "B, A, C (Cuco's): the coupon line: " + str(_texts(r)))
	_check(_gave(r) == ["cu_coupon"] and r.state.mall.count("cu_coupon") == 1, "the coupon is in the bag (cu_coupon)")
	_check(r.state.mall.flags.has("cu_coupon_given"), "cu_coupon_given is set")

func _test_lady_repeats() -> void:
	var res = Runner.load_dialogue(LADY)
	# after A: every later visit is the one line
	var m = _mall()
	await _walk(res, m, [0])
	for v in 3:
		var r = await _walk(res, m, [])
		_check(_texts(r) == [MAD_AGAIN] and r.ended, "after A, visit %d: %s" % [v + 2, str(_texts(r))])
	# after C: later visits cycle between her two lines
	m = _mall()
	await _walk(res, m, [2])
	var seen := []
	for v in 4:
		var r = await _walk(res, m, [])
		seen.append(_texts(r)[0] if r.lines.size() == 1 else "?")
	_check(seen == [COLD_AGAIN[0], COLD_AGAIN[1], COLD_AGAIN[0], COLD_AGAIN[1]], "after C, visits cycle: " + str(seen))
	# after a friendly ending: the conversation starts over
	m = _mall()
	await _walk(res, m, [1, 1])
	var r = await _walk(res, m, [])
	_check(_texts(r) == [Q1], "after B then B, the next visit starts over: " + str(_texts(r)))
	# a saved flag survives a reload (the flags' storage round trip)
	m = _mall()
	await _walk(res, m, [0])
	var f2 = Flags.new()
	f2.backend = m.flags.backend
	f2.load_saved()
	_check(f2.has("cu_lady_mad"), "cu_lady_mad is saved and reads back after a reload")

func _test_coupon_once() -> void:
	var res = Runner.load_dialogue(LADY)
	var m = _mall()
	await _walk(res, m, [1, 0, 2])
	var r = await _walk(res, m, [1, 0, 2])
	_check(m.count("cu_coupon") == 1 and _gave(r).is_empty(), "the coupon is given once only (a second Cuco's answer gives nothing): %d" % m.count("cu_coupon"))
	_check(str(_texts(r)[-1]).begins_with("PLACEHOLDER"), "the second time she says the PLACEHOLDER line: " + str(_texts(r)[-1]))
	# even after it is used up (ws/items: a given coupon is in the hand; put it away first)
	m.put_away()
	m.remove("cu_coupon")
	r = await _walk(res, m, [1, 0, 2])
	_check(m.count("cu_coupon") == 0 and _gave(r).is_empty(), "no new coupon after the first is used up")

# ------------------------------------------------------------------ the bartender (the coupon)
func _test_bartender() -> void:
	var res = Runner.load_dialogue(BAR)
	_check(res != null, "bartender.dialogue compiles")
	var m = _mall()
	m.add("cu_coupon")
	m.hold("cu_coupon")
	var money0: int = m.money
	var r = await _walk(res, m, [])
	var t := _texts(r)
	_check(t.size() == 3 and t[0] == BAR1 and t[1] == BAR2 and str(t[2]).begins_with("PLACEHOLDER"), "holding the coupon: Steven's two lines, then the PLACEHOLDER gift line: " + str(t))
	_check(r.lines[0][0].begins_with("PLACEHOLDER"), "the bartender's name is a PLACEHOLDER: " + str(r.lines[0][0]))
	_check(not m.has("cu_coupon"), "the coupon is used up")
	_check(m.count("cu_topshelf") == 1 and m.count("cu_doubloon") == 1, "a top-shelf margarita AND a doubloon, two items")
	_check(_gave(r) == ["cu_topshelf", "cu_doubloon"], "given in that order: " + str(_gave(r)))
	_check(m.money == money0, "the coupon costs nothing: " + str(m.money))
	_check(m.flags.has("cu_coupon_used") and m.flags.has("cu_doubloon_given"), "cu_coupon_used and cu_doubloon_given are set")
	# a second coupon (can't happen in play; the doubloon must still come once)
	m.add("cu_coupon")
	m.hold("cu_coupon")
	r = await _walk(res, m, [])
	_check(m.count("cu_doubloon") == 1 and _gave(r) == ["cu_topshelf"], "the doubloon is given once only: " + str(_gave(r)))
	# the coupon in the bag, not the hand: the file says nothing (the shop opens instead)
	m = _mall()
	m.add("cu_coupon", 1, true)     # ws/items: straight into the bag (a received one goes into the hand)
	r = await _walk(res, m, [])
	_check(r.lines.is_empty() and m.count("cu_coupon") == 1, "the coupon in the bag (not held): no coupon lines, nothing taken")

# ------------------------------------------------------------------ buying (the shop stub)
func _shop_res(m) -> Resource:
	var names := {}
	for id in db.order:
		names[id] = str(db.get_item(id).get("name", id))
	var res = Runner.compile_text(ShopStub.text(ShopStub.entry("cucos"), m.money, names, "PLACEHOLDER Cuco's bartender"), "shop://cucos")
	if res:
		res.set_meta("flag_names", [])
	return res

func _test_shop() -> void:
	var m = _mall()
	_check(m.money == 10000, "a new player has $100.00")
	var res := _shop_res(m)
	_check(res != null, "the stub's shop conversation compiles")
	var r = await _walk(res, m, [])
	_check(_texts(r) == [GREETING], "the greeting is Steven's line: " + str(_texts(r)))
	_check(r.responses[0] == ["Draft beer, $2.00", "Margarita, $3.00", "Top-shelf margarita, $10.00", "Back"], "the list: " + str(r.responses[0]))
	var cases := [[0, "cu_beer", 200], [1, "cu_margarita", 300], [2, "cu_topshelf", 1000]]
	for c in cases:
		m = _mall()
		r = await _walk(_shop_res(m), m, [c[0]])
		_check(m.money == 10000 - int(c[2]) and m.count(c[1]) == 1, "buy %s: %s taken, one in the bag (wallet %s)" % [c[1], Inventory.money_text(c[2]), Inventory.money_text(m.money)])
		_check(str(_texts(r)[-1]).begins_with("PLACEHOLDER"), "  its ready line (PLACEHOLDER): " + str(_texts(r)[-1]))
	m = _mall()
	r = await _walk(_shop_res(m), m, [3])
	_check(m.money == 10000 and m.inventory.is_empty() and r.lines.size() == 1, "Back: nothing bought")
	# not enough money
	m = _mall()
	m.spend(9500, "test")
	r = await _walk(_shop_res(m), m, [2])
	_check(m.money == 500 and not m.has("cu_topshelf"), "$5.00 can't buy the $10.00 margarita; nothing changes")
	_check(_texts(r)[-1] == "You need $10.00. You have $5.00.", "  the 'you need' line: " + str(_texts(r)[-1]))
	r = await _walk(_shop_res(m), m, [0])
	_check(m.money == 300 and m.count("cu_beer") == 1, "but a $2.00 beer, yes (wallet $3.00)")

# ------------------------------------------------------------------ the bartender's choice
class FakeStory extends Node:
	var player
	var talks: Array = []
	func talk(_npc, path: String, _cue := "") -> void:
		talks.append(path)

class FakePlayer extends Node3D:
	var mall
	var interact = null
	var year := 1995
	var wing := 1

func _test_bartender_choice() -> void:
	var p := FakePlayer.new()
	p.mall = _mall()
	var st := FakeStory.new()
	st.player = p
	var b = load("res://scripts/story/bartender.gd").new()
	b.story = st
	b.entry = {"shop": "cucos"}
	b.dialogue = BAR
	b.display_name = "PLACEHOLDER Cuco's bartender"
	b.interact(p)
	_check(st.talks == ["shop://cucos"], "no coupon held: the shop opens (the stub, mall.shop absent): " + str(st.talks))
	p.mall.add("cu_coupon", 1, true)     # ws/items: into the bag, not the hand
	b.interact(p)
	_check(st.talks.size() == 2 and st.talks[1] == "shop://cucos", "the coupon in the bag: still the shop")
	p.mall.hold("cu_coupon")
	b.interact(p)
	_check(st.talks.size() == 3 and st.talks[2] == BAR, "the coupon in the hand: the coupon conversation")
	b.free(); st.free(); p.free()

# ------------------------------------------------------------------ the doubloon across years
func _test_travel() -> void:
	var Cucos = load("res://scripts/story/cucos.gd")
	var shared := {}
	var f = Flags.new()
	f.backend = shared
	var m95 = _mall(1995)
	m95.flags = f
	m95.backend = shared
	m95.add("cu_doubloon")
	f.set_flag("cu_doubloon_given")
	m95.save()
	var m26 = _mall(2026)
	m26.backend = shared
	m26.flags = f
	var p := FakePlayer.new()
	p.mall = m26
	p.year = 2026
	var c = Cucos.new()
	c.player = p
	c.cfg = JSON.parse_string(FileAccess.get_file_as_string(c.CFG))
	_check(c.travel() == 1 and m26.count("cu_doubloon") == 1, "2026: the doubloon is in the bag")
	_check(c.travel() == 0 and m26.count("cu_doubloon") == 1, "2026: only one, however often the wing loads")
	var m26b = _mall(2026)
	m26b.backend = shared
	m26b.load_saved()
	_check(m26b.count("cu_doubloon") == 1, "2026: saved in 2026's bag (mall-state-2026)")
	_check(ItemDB.in_year(db.get_item("cu_doubloon"), 2026), "cu_doubloon exists in 2026 (year 'both')")
	# dropped on 2026's floor: not added again
	m26.drop("cu_doubloon", 1, Vector3.ZERO, 0.0)
	_check(c.travel() == 0, "2026: dropped on the floor, not added again")
	# never received: nothing
	var m = _mall(2026)
	p.mall = m
	_check(c.travel() == 0 and not m.has("cu_doubloon"), "no doubloon in 2026 before the bartender gave it")
	c.free(); p.free()

# ------------------------------------------------------------------ data
func _test_data() -> void:
	var e := ShopStub.entry("cucos")
	_check(str(e.get("attendant", "")) == "cucos_bartender" and str(e.get("greeting", "")) == GREETING, "shops.json 'cucos': attendant, greeting")
	var prices := {}
	for it in e.get("items", []):
		prices[str(it.item)] = int(it.price_cents)
		_check(it.has("ready_line"), "  %s has a ready_line" % it.item)
		_check(not db.get_item(str(it.item)).is_empty(), "  %s is an item" % it.item)
	_check(prices == {"cu_beer": 200, "cu_margarita": 300, "cu_topshelf": 1000}, "prices: beer $2, margarita $3, top-shelf $10: " + str(prices))
	for id in ["cu_coupon", "cu_beer", "cu_margarita", "cu_topshelf", "cu_doubloon"]:
		var it: Dictionary = db.get_item(id)
		_check(not it.is_empty() and ResourceLoader.exists(str(it.get("scene", ""))) and ResourceLoader.exists(str(it.get("icon", ""))), id + ": item, scene and icon")
	_check(str(db.get_item("cu_coupon").get("class", "")) == "hand", "cu_coupon can be held (class hand)")
	var cfg = JSON.parse_string(FileAccess.get_file_as_string("res://data/story/cucos/cucos.json"))
	_check(cfg.lady.skin == "Ch02", "the lady is skin Ch02")
	var npcs = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/npcs.json"))
	_check("Ch02" in npcs.get("always", []), "npcs.json keeps Ch02 in the crowd ('always')")
