## Loads .dialogue files and steps through them with Nathan Hoad's Dialogue Manager
## (addons/dialogue_manager, MIT, v4.2.0), keeping it stateless (workstream Q;
## design/godot-dialogue.md). Used by the conversation UI, the book reader and the headless tree
## walker (tools/qa/dialogue_walk.gd).
##
## The addon's editor plugin is NOT enabled: the files are compiled from their text at run time
## (DMCompiler), so they ship as plain files (export include filter `data/story/*`) and nothing has
## to be imported. If the plugin is enabled later and the files get imported, load() still works.
##
## The small shorthands of design/godot-dialogue.md are rewritten before compiling:
##   give pogs        ->  $> give("pogs")        (also take, unlock, lock)
##   if has pogs      ->  if has("pogs")         (also holding; in if/elif/while lines and [if …] tags)
extends RefCounted

const DM_SCRIPT := "res://addons/dialogue_manager/dialogue_manager.gd"

static var _cache := {}      # path -> DialogueResource

## The Dialogue Manager node (an Engine singleton it registers itself). Made under the tree's root
## on first use when the plugin's autoload isn't there.
static func manager(tree: SceneTree) -> Node:
	if Engine.has_singleton("DialogueManager"):
		return Engine.get_singleton("DialogueManager")
	var dm: Node = load(DM_SCRIPT).new()
	dm.name = "DialogueManager"
	tree.root.add_child(dm)    # its _ready registers the singleton
	return dm

static func read_text(path: String) -> String:
	if FileAccess.file_exists(path):
		return FileAccess.get_file_as_string(path)
	return ""

## The rewrites above. Text lines (what people say) are left alone except inside [if …] tags.
static func preprocess(text: String) -> String:
	var eff := RegEx.create_from_string("^(\\s*)(?:\\$>\\s*|do\\s+)?(give|take|unlock|lock)\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*$")
	var cond_line := RegEx.create_from_string("^\\s*(if|elif|while)\\s")
	var word := RegEx.create_from_string("\\b(has|holding)\\s+([A-Za-z_][A-Za-z0-9_]*)\\b(?!\\s*\\()")
	var tag := RegEx.create_from_string("\\[if [^\\]]*\\]")
	var out := PackedStringArray()
	for line in text.split("\n"):
		var m := eff.search(line)
		if m:
			out.append("%s$> %s(\"%s\")" % [m.get_string(1), m.get_string(2), m.get_string(3)])
			continue
		if cond_line.search(line):
			line = word.sub(line, "$1(\"$2\")", true)
		elif line.find("[if ") >= 0:
			var parts := ""
			var at := 0
			for t in tag.search_all(line):
				parts += line.substr(at, t.get_start() - at) + word.sub(t.get_string(), "$1(\"$2\")", true)
				at = t.get_end()
			line = parts + line.substr(at)
		out.append(line)
	return "\n".join(out)

## Flag names a file mentions (set lines, mutations, conditions), so they read as false before they
## are ever set instead of stopping the conversation as "missing".
static func flag_names(text: String) -> Array:
	var names := {}
	var setre := RegEx.create_from_string("^\\s*(?:set|\\$>|do)\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*=[^=]")
	var callre := RegEx.create_from_string("\\b(?:unlock|lock)\\s*\\(\\s*\"([A-Za-z_][A-Za-z0-9_]*)\"")
	var condre := RegEx.create_from_string("^\\s*(?:if|elif|while|match)\\s+(.*)$")
	var tagre := RegEx.create_from_string("\\[if ([^\\]/]*)/?\\]")
	var ident := RegEx.create_from_string("(?<![\\w.\"])([A-Za-z_][A-Za-z0-9_]*)(?![\\w\"(])")
	var skip := ["and", "or", "not", "true", "false", "null", "has", "holding", "name", "in", "if", "elif", "else", "when"]
	for line in text.split("\n"):
		var exprs := []
		var m := setre.search(line)
		if m:
			names[m.get_string(1)] = true
		for c in callre.search_all(line):
			names[c.get_string(1)] = true
		m = condre.search(line)
		if m:
			exprs.append(m.get_string(1))
		for t in tagre.search_all(line):
			exprs.append(t.get_string(1))
		for ex in exprs:
			# drop quoted strings first
			var s: String = RegEx.create_from_string("\"[^\"]*\"").sub(ex, "\"\"", true)
			for i in ident.search_all(s):
				var n := i.get_string(1)
				if not (n in skip) and not n.is_valid_float():
					names[n] = true
	return names.keys()

## The compiled resource for a .dialogue path (cached). null, with the errors printed, when it
## doesn't compile.
static func load_dialogue(path: String) -> Resource:
	if _cache.has(path):
		return _cache[path]
	var text := read_text(path)
	var res: Resource = null
	if text != "":
		res = compile_text(preprocess(text), path)
	elif ResourceLoader.exists(path):
		res = load(path)          # imported by the editor plugin
	if res:
		res.set_meta("flag_names", flag_names(text))
		_cache[path] = res
	return res

static func compile_text(text: String, label := "") -> Resource:
	var result = load("res://addons/dialogue_manager/compiler/compiler.gd").compile_string(text, label)
	if result.errors.size() > 0:
		for e in result.errors:
			push_error("dialogue %s line %d: %s" % [label, int(e.line_number) + 1, load("res://addons/dialogue_manager/constants.gd").get_error_message(e.error)])
		return null
	var r = load("res://addons/dialogue_manager/dialogue_resource.gd").new()
	r.using_states = result.using_states
	r.cues = result.cues
	r.first_cue = result.first_cue
	r.character_names = result.character_names
	r.lines = result.lines
	return r

## The next line from cue / line id, with the responses whose [if … /] fails left out (Dialogue
## Manager 4 returns them marked is_allowed = false). null at the end.
static func next_line(tree: SceneTree, res: Resource, id: String, state) -> Variant:
	var l = await manager(tree).get_next_dialogue_line(res, id, [state])
	if l != null and l.responses.size() > 0:
		l.responses = l.responses.filter(func(r): return r.is_allowed)
	return l

## The first cue of a file ("start" when there is one).
static func first_cue(res: Resource) -> String:
	if res == null:
		return ""
	if "start" in res.cues:
		return "start"
	return str(res.first_cue)
