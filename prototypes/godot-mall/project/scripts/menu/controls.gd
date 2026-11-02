## Workstream M (design/godot-menu.md): the game's controls as Godot InputMap actions, remappable at
## runtime from the menu's CONTROLS tab, saved in localStorage "mall-controls-1".
##
## scripts/menu/actions.json lists every action with its DEFAULT keys and gamepad buttons. setup()
## makes an InputMap action "mall_<id>" for each and applies the player's saved changes, so the
## CONTROLS table (which reads the InputMap) always shows what is bound now.
##
## How a remap reaches code that was written for fixed keys (player.gd, interact.gd, avatar.gd and
## whatever other workstreams add) without rewriting it:
##   - kind "poll" (walking, running): player.gd reads the InputMap action every frame.
##   - kind "event" (E, V, C, I, Y, J, R, G and their pad buttons): filter() runs before every other
##     input handler (menu.gd's catcher sits last under the root). A key or button now bound to an
##     action is re-sent as the action's DEFAULT key / button (Input.parse_input_event, deferred, the
##     copy tagged "mall_synth" so it passes), and the original is swallowed; a default key that
##     the player moved away from its action is swallowed too, so it does nothing.
##   - kind "menu": menu.gd reads the InputMap itself.
## A key can be bound to one action per context ("game", or "menu" for the in-menu tab keys).
extends RefCounted

const ACTIONS := "res://scripts/menu/actions.json"
const STORE_KEY := "mall-controls-1"
const PREFIX := "mall_"
## Never bindable: they always do their own thing (close, confirm, the arrow keys walk and move
## through lists).
const RESERVED := [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]
const PAD_NAMES := {0: "A", 1: "B", 2: "X", 3: "Y", 4: "Back / Select", 5: "Guide", 6: "Start",
	7: "Left stick click", 8: "Right stick click", 9: "LB", 10: "RB", 11: "D-pad up",
	12: "D-pad down", 13: "D-pad left", 14: "D-pad right"}

var list: Array = []          # the actions.json entries, in order, with "dkeys" (keycodes) added
var by_id := {}
var saved := {}               # id -> {"keys": [int], "pad": [int]}: only the changed ones
var backend = null            # a Dictionary in unit tests; else localStorage / Engine meta

func setup() -> void:
	list = []
	by_id = {}
	var j = JSON.parse_string(FileAccess.get_file_as_string(ACTIONS)) if FileAccess.file_exists(ACTIONS) else null
	if j is Dictionary:
		for a in j.get("actions", []):
			if not (a is Dictionary) or str(a.get("id", "")) == "":
				continue
			var e: Dictionary = a.duplicate(true)
			var dk: Array = []
			for k in e.get("keys", []):
				var c := OS.find_keycode_from_string(str(k))
				if c != KEY_NONE:
					dk.append(int(c))
			e["dkeys"] = dk
			var dp: Array = []
			for b in e.get("pad", []):
				dp.append(int(b))
			e["dpad"] = dp
			list.append(e)
			by_id[str(e.id)] = e
	_load()
	apply()

func remappable(id: String) -> bool:
	return by_id.has(id) and str(by_id[id].get("kind", "")) != "fixed"

## The gamepad column can be remapped for buttons the code listens for ("event", "menu"); walking is
## the left stick, which stays as it is.
func pad_remappable(id: String) -> bool:
	return by_id.has(id) and str(by_id[id].get("kind", "")) in ["event", "menu"]

func context(id: String) -> String:
	return "menu" if id == "tab_prev" or id == "tab_next" else "game"

## The keycodes bound to action id right now.
func keys(id: String) -> Array:
	if saved.has(id) and saved[id].has("keys"):
		return saved[id].keys
	return by_id[id].dkeys if by_id.has(id) else []

func pads(id: String) -> Array:
	if saved.has(id) and saved[id].has("pad"):
		return saved[id].pad
	return by_id[id].dpad if by_id.has(id) else []

## (Re)make every InputMap action from the defaults and the saved changes.
func apply() -> void:
	for e in list:
		var act: String = PREFIX + str(e.id)
		if InputMap.has_action(act):
			InputMap.erase_action(act)
		InputMap.add_action(act, 0.2)
		for k in keys(str(e.id)):
			var ev := InputEventKey.new()
			ev.physical_keycode = int(k)
			InputMap.action_add_event(act, ev)
		for b in pads(str(e.id)):
			var pb := InputEventJoypadButton.new()
			pb.button_index = int(b)
			pb.device = -1     # any pad
			InputMap.action_add_event(act, pb)

## Shown in the table: the InputMap's keys for id (read back from the InputMap), then also_keys.
func key_text(id: String) -> String:
	var out: Array = []
	for ev in InputMap.action_get_events(PREFIX + id) if InputMap.has_action(PREFIX + id) else []:
		if ev is InputEventKey:
			out.append(key_name(ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode))
	var also := str(by_id.get(id, {}).get("also_keys", ""))
	if also != "":
		out.append(also)
	return ", ".join(out) if not out.is_empty() else "—"

func pad_text(id: String) -> String:
	var out: Array = []
	for ev in InputMap.action_get_events(PREFIX + id) if InputMap.has_action(PREFIX + id) else []:
		if ev is InputEventJoypadButton:
			out.append(pad_name(ev.button_index))
	var also := str(by_id.get(id, {}).get("also_pad", ""))
	if also != "":
		out.append(also)
	return ", ".join(out) if not out.is_empty() else "—"

static func key_name(k: int) -> String:
	var s := OS.get_keycode_string(k)
	return s if s != "" else "key %d" % k

static func pad_name(b: int) -> String:
	return PAD_NAMES.get(b, "button %d" % b)

## Bind action id's keyboard (kind "key", code = a physical keycode) or gamepad (kind "pad", code =
## a JOY_BUTTON_*) to that one key / button. "" when done; otherwise why not (nothing changes).
func rebind(id: String, kind: String, code: int) -> String:
	if not remappable(id) or (kind == "pad" and not pad_remappable(id)):
		return "That one can't be changed."
	if kind == "key" and code in RESERVED:
		return "%s is kept for its own job." % key_name(code)
	for e in list:
		var o := str(e.id)
		if o == id or context(o) != context(id) and o != "menu" and id != "menu":
			continue
		if (kind == "key" and code in keys(o)) or (kind == "pad" and code in pads(o)):
			return "%s is already %s." % [key_name(code) if kind == "key" else pad_name(code), str(e.label)]
	var ch: Dictionary = saved.get(id, {})
	ch["keys" if kind == "key" else "pad"] = [code]
	# a change back to exactly the default is no change
	if ch.get("keys", by_id[id].dkeys) == by_id[id].dkeys:
		ch.erase("keys")
	if ch.get("pad", by_id[id].dpad) == by_id[id].dpad:
		ch.erase("pad")
	if ch.is_empty():
		saved.erase(id)
	else:
		saved[id] = ch
	apply()
	save()
	return ""

func reset() -> void:
	saved = {}
	apply()
	save()

func is_default() -> bool:
	return saved.is_empty()

# ------------------------------------------------------------------ the translation layer
## Called by menu.gd for every input event while the menu is closed. True: the event was used
## (swallowed, maybe re-sent as the default key); the caller marks it handled.
func filter(e: InputEvent) -> bool:
	if saved.is_empty() or e.has_meta("mall_synth"):
		return false
	if e is InputEventKey:
		var k: int = e.physical_keycode if e.physical_keycode != KEY_NONE else e.keycode
		var to := _route(k, "key")
		if to == -2:
			return false
		if to >= 0:
			var ev := InputEventKey.new()
			ev.physical_keycode = to as Key
			ev.keycode = to as Key
			ev.pressed = e.pressed
			ev.echo = e.echo
			ev.set_meta("mall_synth", true)
			Input.parse_input_event.call_deferred(ev)
		return true
	if e is InputEventJoypadButton:
		var to := _route(e.button_index, "pad")
		if to == -2:
			return false
		if to >= 0:
			var pb := InputEventJoypadButton.new()
			pb.button_index = to as JoyButton
			pb.device = e.device
			pb.pressed = e.pressed
			pb.pressure = e.pressure
			pb.set_meta("mall_synth", true)
			Input.parse_input_event.call_deferred(pb)
		return true
	return false

## -2: leave the event alone; -1: swallow it; else re-send it as this code.
func _route(code: int, kind: String) -> int:
	var bound_event := ""      # the "event" action code is bound to now, if any
	for e in list:
		var id := str(e.id)
		if context(id) != "game":
			continue
		var now: Array = keys(id) if kind == "key" else pads(id)
		if code in now:
			if str(e.kind) == "event":
				bound_event = id
	if bound_event != "":
		var d: Array = by_id[bound_event].dkeys if kind == "key" else by_id[bound_event].dpad
		if d.is_empty() or code in d:
			return -2       # its own default: nothing to translate
		return int(d[0])
	# a default key / button of an "event" action that was moved off it: it does nothing now
	for e in list:
		var id := str(e.id)
		if str(e.kind) != "event":
			continue
		var d: Array = by_id[id].dkeys if kind == "key" else by_id[id].dpad
		var now: Array = keys(id) if kind == "key" else pads(id)
		if code in d and not (code in now):
			return -1
	return -2   # bound to a walking / running key, or nobody's: as it is

# ------------------------------------------------------------------ storage
func save() -> void:
	var s := JSON.stringify(saved)
	if backend is Dictionary:
		backend[STORE_KEY] = s
	elif OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s)}catch(e){}})()" % [JSON.stringify(STORE_KEY), JSON.stringify(s)], true)
	else:
		Engine.set_meta("mall_controls", s)

func _load() -> void:
	var s = ""
	if backend is Dictionary:
		s = str(backend.get(STORE_KEY, ""))
	elif OS.has_feature("web"):
		s = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||''}catch(e){return ''}})()" % JSON.stringify(STORE_KEY), true)
	else:
		s = str(Engine.get_meta("mall_controls", ""))
	saved = {}
	var d = JSON.parse_string(s) if s is String and s != "" else null
	if not (d is Dictionary):
		return
	for id in d:
		if not remappable(str(id)) or not (d[id] is Dictionary):
			continue
		if not pad_remappable(str(id)):
			d[id].erase("pad")
		var ch := {}
		for f in ["keys", "pad"]:
			if d[id].get(f) is Array and not d[id][f].is_empty():
				var arr: Array = []
				for v in d[id][f]:
					arr.append(int(v))
				ch[f] = arr
		if not ch.is_empty():
			saved[str(id)] = ch
