## A STUB for workstream SHOPS's mall.shop.open(id) (workstream CUCOS, Nov 3 2026;
## design/godot-cucos.md "The shop contract"). Delete when SHOPS lands: scripts/story/bartender.gd
## calls mall.shop.open(id) whenever mall.shop exists.
##
## Runs a data/story/shops.json entry as a conversation with its attendant: the greeting, one
## response per item ("Beer, $2.00"), and "Back". Choosing an item: when the wallet covers it,
## mall.spend(price) then the item into the bag and the ready_line; otherwise the economy's
## "You need $2.00. You have $0.10." line and nothing changes (design/godot-economy.md).
extends RefCounted

const Runner = preload("res://scripts/dialogue/dialogue_runner.gd")
const Inventory = preload("res://scripts/inventory.gd")
const SHOPS := "res://data/story/shops.json"

## The entry for shop id, or {}.
static func entry(id: String) -> Dictionary:
	if not FileAccess.file_exists(SHOPS):
		return {}
	var j = JSON.parse_string(FileAccess.get_file_as_string(SHOPS))
	if not (j is Dictionary):
		return {}
	for e in j.get("shops", []):
		if e is Dictionary and str(e.get("id", "")) == id:
			return e
	return {}

## The conversation text for a shop, given the wallet now (cents) and the item names.
static func text(e: Dictionary, money: int, names := {}, speaker := "") -> String:
	var who := (speaker if speaker != "" else "Attendant") + ": "
	var out := PackedStringArray(["~ start", who + str(e.get("greeting", ""))])
	for it in e.get("items", []):
		var id := str(it.get("item", ""))
		var cents := int(it.get("price_cents", 0))
		var price := Inventory.money_text(cents)
		out.append("- %s, %s" % [str(names.get(id, id)), price])
		out.append("\tif can_afford(%d)" % cents)
		out.append("\t\t$> buy(\"%s\", %d)" % [id, cents])
		out.append("\t\t" + who + str(it.get("ready_line", "")))
		out.append("\telse")
		out.append("\t\tYou need %s. You have %s." % [price, Inventory.money_text(money)])
		out.append("\t=> END")
	out.append("- Back")
	out.append("\t=> END")
	return "\n".join(out)

## Open shop id with this attendant (an Attendant: talk camera, name).
static func open(story: Node, attendant: Node3D, id: String) -> bool:
	var e := entry(id)
	if e.is_empty() or story == null:
		push_warning("shop stub: no shop " + id)
		return false
	var names := {}
	var it = story.player.interact if story.player else null
	if it and it.get("db"):
		for x in e.get("items", []):
			names[str(x.item)] = str(it.db.get_item(str(x.item)).get("name", x.item))
	var m = story.player.mall if story.player else null
	var t := text(e, int(m.money) if m else 0, names, str(attendant.get("display_name")))
	var res = Runner.compile_text(t, "shop://" + id)
	if res == null:
		return false
	res.set_meta("flag_names", [])
	var path := "shop://" + id
	Runner._cache[path] = res
	story.talk(attendant, path)
	return true
