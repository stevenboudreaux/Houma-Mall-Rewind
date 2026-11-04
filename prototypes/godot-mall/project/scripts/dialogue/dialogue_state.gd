## What a .dialogue file can see and do (workstream Q, design/godot-dialogue.md "Grammar").
## Passed to Dialogue Manager as its only extra game state; the addon itself keeps no state, the
## flags live in mall.flags (scripts/flags.gd) and the things in mall (scripts/inventory.gd).
##
##   flags          any flag name reads as its value (false when never set);
##                  `set some_flag = true` / `$> some_flag = false` writes mall.flags
##   name           the player's name: mall.player_name (session M), "friend" while it is ""
##   has("id")      the item is carried (bag or hand)
##   holding("id")  the item is in the hand right now
##   give("id")     mall.inventory gets one (session R adds the "You received …" pop-up)
##   take("id")     one is taken (from the bag first, else from the hand); false if not carried
##   unlock("flag") sets a gate's flag true (scripts/dialogue/gate.gd reopens at once)
##   lock("flag")   sets it false
extends RefCounted

var mall                     # scripts/inventory.gd (with .flags); null in some tests
var flags                    # scripts/flags.gd
var known: Array = []        # flag names the file mentions: they read as false before being set
var log: Array = []          # every effect, for tests and the debug print: ["give", "pogs"], …
var say: Callable            # optional: a notice on screen (player._say)

func _init(m = null, f = null) -> void:
	mall = m
	flags = f if f != null else (m.flags if m != null and "flags" in m else null)

# ------------------------------------------------------------------ flags as properties
func _get_property_list() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var seen := {}
	var all: Array = known.duplicate()
	if flags:
		all.append_array(flags.names())
	for n in all:
		if seen.has(n):
			continue
		seen[n] = true
		out.append({"name": n, "type": TYPE_NIL, "usage": PROPERTY_USAGE_SCRIPT_VARIABLE})
	return out

func _get(prop: StringName) -> Variant:
	var n := str(prop)
	if n == "name":
		return player_name()
	if flags and (n in known or flags.flags.has(n)):
		var v = flags.get_flag(n, false)
		return v
	return null

func _set(prop: StringName, value: Variant) -> bool:
	var n := str(prop)
	if n == "name" or flags == null:
		return false
	if n in known or flags.flags.has(n) or flags.valid_name(n):
		flags.set_flag(n, value)
		log.append(["set", n, value])
		return true
	return false

# ------------------------------------------------------------------ the player
func player_name() -> String:
	# M: mall.player_name, set by the menu's AVATAR tab ("" until typed)
	if mall != null and str(mall.player_name) != "":
		return str(mall.player_name)
	return "friend"

## The item in the hand: M's mall.held_id() ("" when nothing is held).
func held() -> String:
	if mall == null:
		return ""
	return str(mall.held_id())

# ------------------------------------------------------------------ conditions
func has(id: String) -> bool:
	if mall == null:
		return false
	return mall.has(id) if mall.has_method("has") else false

func holding(id: String) -> bool:
	return held() == id

# ------------------------------------------------------------------ effects
func give(id: String) -> void:
	log.append(["give", id])
	if mall == null:
		return
	# R owns the "You received …" pop-up; until it lands a plain notice
	if mall.has_method("add"):
		mall.add(id)
	if mall.has_method("save"):
		mall.save()
	if say.is_valid():
		say.call("Received: " + _item_name(id))

func take(id: String) -> bool:
	log.append(["take", id])
	if mall == null:
		return false
	var ok := false
	if mall.has_method("remove") and mall.remove(id):
		ok = true
	elif held() == id:
		mall.hand = ""
		mall.changed.emit()
		ok = true
	if ok and mall.has_method("save"):
		mall.save()
	return ok

func unlock(flag: String) -> void:
	log.append(["unlock", flag])
	if flags:
		flags.set_flag(flag, true)

func lock(flag: String) -> void:
	log.append(["lock", flag])
	if flags:
		flags.set_flag(flag, false)

var item_names := {}         # id -> name, filled by the story node from the item files
func _item_name(id: String) -> String:
	return str(item_names.get(id, id))

# --- CUCOS (design/godot-cucos.md): a gesture, and buying (the shop stub, scripts/story/shop_stub.gd)
##   act("thinking")      the NPC talking plays a one-shot clip (stage directions: "she looks confused")
##   can_afford(200)      the wallet holds at least 200 cents
##   buy("cu_beer", 200)  200 cents out of the wallet, then give("cu_beer"); false (nothing changes)
##                        when the wallet doesn't cover it
var act_cb: Callable
func act(clip: String) -> void:
	log.append(["act", clip])
	if act_cb.is_valid():
		act_cb.call(clip)

func can_afford(cents: int) -> bool:
	return mall != null and mall.has_method("can_afford") and mall.can_afford(cents)

func buy(id: String, cents: int) -> bool:
	log.append(["buy", id, cents])
	if mall == null or not mall.has_method("spend") or not mall.spend(cents, "Shop: " + id):
		return false
	give(id)
	return true
# --- end CUCOS
