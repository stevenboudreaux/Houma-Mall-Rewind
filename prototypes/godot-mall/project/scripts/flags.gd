## Quest flags, "mall.flags" (workstream Q, Nov 2 2026; design/godot-quests.md).
## Pure data, no nodes. interact.gd makes one beside the carried state (mall.flags = this) in every
## wing and year; dialogue files, gates and the book reader read and write it. Steven writes the
## story; this file is only the machinery.
##
##   mall.flags.has(name) -> bool          # set and truthy (a flag never set is false)
##   mall.flags.get(name) -> Variant       # its value, null when never set
##   mall.flags.set(name, value)           # Godot's own Object.set(name, value) shape: value required
##   mall.flags.set_flag(name, value=true) # the same, with the default the brief asked for
##   mall.flags.get_flag(name, default)    # get() with a default
##   mall.flags.clear(name)                # forget it (has() false, get() null)
##   signal changed(name, value)           # after every change (value null when cleared)
##
## Why set() has no default: GDScript refuses a method named set() whose signature differs from
## Object.set(StringName, Variant). Calls through an untyped variable (mall.flags.set("x", true))
## reach this script; calls through a variable typed as Object/RefCounted reach the engine's own
## set() and do nothing here: use set_flag() from typed code.
##
## Saved after every change, ONE store for both years (a guess, design/godot-quests.md):
##   web: localStorage "mall-flags-1"   (JSON {"v": 1, "flags": {name: value}})
##   elsewhere: Engine metadata "mall_flags" (survives a wing change in the editor or a test)
##   tests: a Dictionary given as `backend`.
## Values are JSON values (bool, number, string). Names: letters, digits, underscores.
extends RefCounted

signal changed(name: String, value: Variant)

const VERSION := 1
const KEY := "mall-flags-1"

var flags := {}
## null: localStorage on the web, else Engine metadata. A Dictionary: kept in it (unit tests).
var backend = null
## false: changes are not written (tests that only check the data).
var autosave := true

func has(name: String) -> bool:
	var v = flags.get(name, null)
	if v == null:
		return false
	if v is bool:
		return v
	if v is float or v is int:
		return v != 0
	if v is String:
		return v != ""
	return true

@warning_ignore("native_method_override")
func get(name: StringName) -> Variant:
	return flags.get(str(name), null)

func get_flag(name: String, default: Variant = null) -> Variant:
	return flags.get(name, default)

@warning_ignore("native_method_override")
func set(name: StringName, value: Variant) -> void:
	set_flag(str(name), value)

func set_flag(name: String, value: Variant = true) -> void:
	if not valid_name(name):
		push_warning("flags: bad flag name '%s'" % name)
		return
	if value is int:
		value = float(value)      # JSON round trip: numbers come back as floats
	if flags.has(name) and typeof(flags[name]) == typeof(value) and flags[name] == value:
		return
	flags[name] = value
	if autosave:
		save()
	changed.emit(name, value)

func clear(name: String) -> void:
	if not flags.has(name):
		return
	flags.erase(name)
	if autosave:
		save()
	changed.emit(name, null)

## Every flag name, sorted.
func names() -> Array:
	var a := flags.keys()
	a.sort()
	return a

static func valid_name(name: String) -> bool:
	if name == "":
		return false
	for i in name.length():
		var c := name.unicode_at(i)
		var ok := (c >= 97 and c <= 122) or (c >= 65 and c <= 90) or c == 95 or (i > 0 and c >= 48 and c <= 57)
		if not ok:
			return false
	return true

# ------------------------------------------------------------------ JSON
func to_json() -> String:
	return JSON.stringify({"v": VERSION, "flags": flags})

func from_json(s: String) -> bool:
	if s == "":
		return false
	var d = JSON.parse_string(s)
	if not (d is Dictionary) or int(d.get("v", 0)) != VERSION or not (d.get("flags") is Dictionary):
		return false
	flags = {}
	for k in d.flags:
		var v = d.flags[k]
		if valid_name(str(k)) and (v is bool or v is float or v is int or v is String):
			flags[str(k)] = float(v) if v is int else v
	return true

# ------------------------------------------------------------------ storage
func save() -> void:
	var s := to_json()
	if backend is Dictionary:
		backend[KEY] = s
	elif OS.has_feature("web"):
		JavaScriptBridge.eval("(function(){try{localStorage.setItem(%s,%s)}catch(e){}try{window.mall=window.mall||{};window.mall.flags=JSON.parse(%s).flags}catch(e){}})()" % [JSON.stringify(KEY), JSON.stringify(s), JSON.stringify(s)], true)
	else:
		Engine.set_meta("mall_flags", s)

## Read the saved flags. True when some were read.
func load_saved() -> bool:
	var s := ""
	if backend is Dictionary:
		s = str(backend.get(KEY, ""))
	elif OS.has_feature("web"):
		var v = JavaScriptBridge.eval("(function(){try{return localStorage.getItem(%s)||''}catch(e){return ''}})()" % JSON.stringify(KEY), true)
		s = v if v is String else ""
	else:
		s = str(Engine.get_meta("mall_flags", ""))
	return from_json(s)

## The owner's debug list: on the web (owner mode only) `mallFlags()` in the browser console prints
## the table, `mallFlags('name', value)` sets one (reload to see it in the game); natively, the
## same list is printed.
func install_debug(owner: bool) -> void:
	if not owner:
		return
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""(function(){var K=%s;window.mallFlags=function(n,v){var d={v:1,flags:{}};try{d=JSON.parse(localStorage.getItem(K))||d}catch(e){}if(n!==undefined){if(v===undefined)v=true;if(v===null)delete d.flags[n];else d.flags[n]=v;localStorage.setItem(K,JSON.stringify(d));console.log('flag',n,'=',v,'(reload to apply)')}console.table(d.flags);return d.flags}})()""" % JSON.stringify(KEY), true)
	else:
		print("flags: ", to_json())
