## Shared packs (workstream CHARS, Nov 3 2026; design/godot-build-hosting.md "Shared packs"): files
## that ship once for the whole mall instead of inside each wing pack (the Blender items, the
## character bodies and pieces; tools/shared_packs.py). Autoload "SharedPacks".
##
## On the web the page (web/shell.html) downloads them and copies them into the engine's file system:
##   - "start" packs (the items) with the wing pack, before the engine runs: their paths are in
##     window.__mallMountNow and are mounted here, in _init, before the wing's scene loads (scenes and
##     data/items refer to them by res:// path);
##   - "later" packs (the characters) once the mall runs: window.__mallLater[group] becomes a list of
##     paths when they are all in, or "failed"; scripts/chars/char_pack.gd asks later_paths("chars").
## Off the web (native runs, tests, the editor) every file is in res:// already and nothing is mounted.
## Packs are mounted with replace_files = false: a file the wing pack has wins over a shared copy.
extends Node

## path -> true when mounted, false when the mount failed
var mounted := {}

func _init() -> void:
	if not OS.has_feature("web"):
		return
	for p in _js_list("window.__mallMountNow || []"):
		mount(str(p))

## Mount one pack file from the engine's file system. True on success (or already mounted).
func mount(path: String) -> bool:
	if mounted.get(path, false):
		return true
	var ok := ProjectSettings.load_resource_pack(path, false)
	mounted[path] = ok
	if ok:
		print("shared_packs: mounted %s" % path)
	else:
		push_warning("shared_packs: could not mount %s" % path)
	return ok

## A "later" group's state on the web: null while it is still coming, an Array of pack paths when all
## of it is in the file system, "failed" when it could not be fetched. Off the web: [] (nothing to do).
func later_paths(group: String) -> Variant:
	if not OS.has_feature("web"):
		return []
	var v = JSON.parse_string(str(JavaScriptBridge.eval("JSON.stringify((window.__mallLater || {})[%s] || null)" % JSON.stringify(group))))
	return v

func _js_list(expr: String) -> Array:
	var v = JSON.parse_string(str(JavaScriptBridge.eval("JSON.stringify(%s)" % expr)))
	return v if v is Array else []
