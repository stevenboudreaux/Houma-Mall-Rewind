## Headless checks of Pocket Change's redemption (workstream R; design/godot-prize-counter.md "Redemption"):
## the stock, buying with enough and with too few tickets, the inventory and ticket round trip, saving and
## loading, the pop-up contract (mall.received) and the pop-up's queue, and the empty Pocket Change floor.
##   godot --headless --path . --script res://tools/qa/redemption_test.gd
## Prints REDEMPTION TEST OK (n checks), or the failed checks.
extends SceneTree

const ItemDB = preload("res://scripts/items/item_db.gd")
const Inventory = preload("res://scripts/inventory.gd")
const Redemption = preload("res://scripts/redemption.gd")
const ReceivedPopup = preload("res://scripts/received_popup.gd")

## Pocket Change, wing 2 (1995): the shop floor in front of and behind the counter (x, z bounds, metres).
const PC_BOX := [-113.0, -99.0, 56.0, 78.0]

var errors := []
var oks := 0
var frames := 0
var pop
var mall2

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _initialize() -> void:
	var db = ItemDB.new().load_dir()
	# ---- the floor: nothing to pick up at Pocket Change; the stick stays in the stockrooms
	var at_pc := []
	for id in db.order:
		var e: Dictionary = db.get_item(id)
		var p = e.get("place", null)
		if p is Dictionary and int(p.get("wing", 0)) == 2:
			var x := float(p.pos[0]); var z := float(p.pos[2])
			if x > PC_BOX[0] and x < PC_BOX[1] and z > PC_BOX[2] and z < PC_BOX[3]:
				at_pc.append(id)
		if str(e.get("store", "")) == "POCKET CHANGE" and e.has("place"):
			at_pc.append(id)
	_check(at_pc.is_empty(), "nothing placed at Pocket Change %s" % str(at_pc))
	_check(db.get_item("folse_stick").has("place"), "Martin Folse's stick is still placed (stockrooms)")
	# ---- the stock
	var stock: Array = Redemption.read_stock(db, 1995)
	var pj = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/prizes.json"))
	var sj = JSON.parse_string(FileAccess.get_file_as_string("res://scripts/redemption.json"))
	var covered := {}
	for s in sj.stock:
		if s.has("prize"): covered[str(s.prize)] = true
	var missing := []
	for k in pj.items:
		if not covered.has(k): missing.append(k)
	_check(missing.is_empty(), "every prizes.json prize is in the stock %s" % str(missing))
	_check(stock.size() == sj.stock.size(), "every stock entry resolves to a 1995 item (%d of %d)" % [stock.size(), sj.stock.size()])
	var bad := []
	var by_id := {}
	for s in stock:
		by_id[s.item] = s
		var e: Dictionary = db.get_item(s.item)
		if not ResourceLoader.exists(s.icon) or not ResourceLoader.exists(str(e.scene)) or int(s.tickets) <= 0:
			bad.append(s.item)
	_check(bad.is_empty(), "every stock item has an icon, a scene and a price %s" % str(bad))
	for k in ["bl_pc_fingertrap", "bl_pc_plush_bear", "bl_pc_plush_bunny", "bl_pc_plush_dog", "bl_pc_boombox"]:
		_check(by_id.has(k), "the Blender prize %s is in the stock" % k)
	_check(by_id.has("bl_pc_boombox") and int(by_id.bl_pc_boombox.tickets) == 5000, "the boom box costs 5,000 tickets (ECON, Nov 3: the wall tags)")
	_check(by_id.has("pogs") and int(by_id.pogs.tickets) == int(pj.items.pogs.tickets), "prices come from prizes.json (Pog pack %d)" % int(pj.items.pogs.tickets))
	_check(Redemption.read_stock(db, 2026).is_empty(), "no 1995 prize in the 2026 stock")
	# ---- buying
	var store := {}
	var m = Inventory.new()
	m.backend = store
	var got := []
	m.received.connect(func(id): got.append(id))
	var r = Redemption.new().setup(null, m, db)
	_check(m.redemption == r, "mall.redemption is the screen")
	var bb := -1
	var plush := -1
	for i in r.stock.size():
		if r.stock[i].item == "bl_pc_boombox": bb = i
		if r.stock[i].item == "bl_pc_plush_bear": plush = i
	m.tickets = 0
	_check(not r.can_buy(bb) and not r.buy(bb) and m.tickets == 0 and not m.has("bl_pc_boombox") and got.is_empty(), "0 tickets: can't buy the boom box, nothing changes")
	m.tickets = 5100
	_check(r.can_buy(bb) and r.buy(bb), "5,100 tickets: the boom box can be bought")
	_check(m.tickets == 100, "tickets go down by the price (5,100 - 5,000 = %d)" % m.tickets)
	_check(m.count("bl_pc_boombox") == 1 and m.hand == "", "the boom box is in the bag, put away (not in the hand)")
	_check(got == ["bl_pc_boombox"], "mall.received fired once for it %s" % str(got))
	_check(not r.buy(plush) and m.tickets == 100 and not m.has("bl_pc_plush_bear"), "100 tickets: the plush (700) is refused, nothing changes")
	var cheap := 0
	_check(r.buy(cheap) and m.tickets == 100 - r.price(cheap), "the cheapest prize (%s, %d) can still be bought" % [r.stock[cheap].name, r.price(cheap)])
	_check(r.buy(cheap) and m.count(str(r.stock[cheap].item)) == 2, "buying twice counts up")
	# ---- saved and read back (a reload or a wing load)
	var n = Inventory.new()
	n.backend = store
	_check(n.load_saved() and n.tickets == m.tickets and n.count("bl_pc_boombox") == 1 and n.count(str(r.stock[cheap].item)) == 2,
		"a buy is saved: tickets %d and the bag come back" % n.tickets)
	# ---- the pop-up contract: moves between hand and bag are quiet; picking up is not
	got.clear()
	m.hold("bl_pc_boombox")
	m.put_away()
	_check(got.is_empty(), "hold and put away don't show the pop-up")
	m.take("pogs", false)
	m.take("spring", true)
	m.take("dice", true)       # the spring goes into the bag quietly
	_check(got == ["pogs", "spring", "dice"], "picking up shows it (pocket and hand) %s" % str(got))
	m.add("candy_neck")
	_check(got.back() == "candy_neck", "a give (mall.add) shows it")
	# ---- the pop-up itself (in the tree, no player)
	mall2 = Inventory.new()
	mall2.backend = {}
	pop = ReceivedPopup.new().setup(null, mall2, db)
	root.add_child(pop)
	mall2.add("bl_pc_boombox")
	mall2.add("pogs")
	_check(pop.is_showing() and pop.current == "bl_pc_boombox" and pop.queue == ["pogs"], "the pop-up shows the first and queues the second")
	_check(pop.name_l.text == "Boom box" and pop.line_l.text == "You received Boom box" and pop.icon_r.texture != null, "the card: icon, name, 'You received Boom box'")
	_check(mall2.get_meta("popup_open", false), "mall meta popup_open while it shows")

func _process(dt: float) -> bool:
	frames += 1
	if frames == 2:
		var ev := InputEventKey.new()
		ev.pressed = true; ev.physical_keycode = KEY_SPACE; ev.keycode = KEY_SPACE
		pop._input(ev)
		_check(pop.current == "bl_pc_boombox", "a press before the minimum time doesn't dismiss it")
		pop.shown_for = ReceivedPopup.MIN_TIME + 0.01
		pop._input(ev)
		_check(pop.current == "pogs", "after it, a press shows the next")
		pop.shown_for = ReceivedPopup.MIN_TIME + 0.01
		pop._input(ev)
		_check(not pop.is_showing() and not pop.ui.visible and not mall2.get_meta("popup_open", true), "and the last press closes it")
		printerr("REDEMPTION TEST OK (%d checks)" % oks if errors.is_empty() else "REDEMPTION TEST FAILED: " + str(errors))
		return true
	return false
