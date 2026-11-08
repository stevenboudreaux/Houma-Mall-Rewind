## ws/interiors (Nov 4 2026; design/godot-shops.md): an unbaked shot of a counter shop's list open, over the
## store built by the probe-lit preview (tools/qa/preview.gd), without loading a whole wing: the store, its
## attendant from data/story/attendants.json (the preset body, wandering its area) and the real shop screen
## (scripts/shop.gd) opened with a fresh wallet. The camera is placed by the caller (stand at the attendant's
## talk_at, 1.6 m up, look at the area). The screen is opened without the attendant node (that path drives the
## player's camera), so the speaker label is set to the attendant's name by hand.
##   MALL_YEAR=2026 PREVIEW_SCRIPT=res://tools/qa/shop_panel_shots.gd tools/qa/preview.sh "store:SPENCER'S" \
##     <out-prefix> "<x,y,z,yaw,pitch;...>" '{"shop": "spencers"}' lit
## Prints SHOP PANEL: <shop> open, <n> things (or FAILED ...).
extends "res://tools/qa/preview.gd"

const Inventory = preload("res://scripts/inventory.gd")
const ItemDB = preload("res://scripts/items/item_db.gd")
const Shop = preload("res://scripts/shop.gd")
const Attendant = preload("res://scripts/attendants/attendant.gd")

var _att := {}
var _who = null

func _initialize():
	super._initialize()
	var args = OS.get_cmdline_user_args()
	var opts = JSON.parse_string(args[2]) if args.size() > 2 and args[2] != "" else {}
	var shop_id := str(opts.get("shop", ""))
	var shops := Shop.read_shops()
	if not shops.has(shop_id):
		printerr("SHOP PANEL FAILED: no shop ", shop_id)
		return
	var att := {}
	for a in JSON.parse_string(FileAccess.get_file_as_string("res://data/story/attendants.json")).attendants:
		if str(a.id) == str(shops[shop_id].attendant):
			att = a
	_att = att
	var m = Inventory.new()
	m.year = YEAR
	m.backend = {}
	var sh = Shop.new()
	root.add_child(sh)
	sh.setup(null, m, ItemDB.new().load_dir())
	if sh.open(shop_id):
		sh.speaker = str(att.get("name", ""))
		sh._refresh()
		printerr("SHOP PANEL: %s open, %d things" % [shop_id, sh.stock.size()])
	else:
		printerr("SHOP PANEL FAILED: %s did not open in %d" % [shop_id, YEAR])

## The attendant is made on the first frame, once the tree is running (its body is placed by global position).
func _process(d):
	if _who == null and not _att.is_empty():
		_who = Attendant.new()
		root.add_child(_who)
		var ok = _who.setup(null, null, _att)
		printerr("SHOP PANEL: attendant %s %s, in tree %s, look %s, body %s at %s" % [_att.id, "made" if ok else "FAILED",
			_who.is_inside_tree(), _att.get("look", "?"), _who.body, _who.body.global_position if _who.body else Vector3.ZERO])
	return super._process(d)
