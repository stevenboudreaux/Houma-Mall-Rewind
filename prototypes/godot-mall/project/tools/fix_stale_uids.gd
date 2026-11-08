extends SceneTree
## Drops stale `uid="…"` attributes from the wing scenes' ext_resource lines (workstream PACKS, Nov 8 2026;
## design/godot-build-hosting.md "Stale UIDs drop files from the packs").
##
## Why: Demo 52's wing scenes were saved by the editor on Steven's Mac after the bake, and the editor wrote a
## uid="…" on references to the generated meshes in gen/ (the Mac's own UID cache knew them). The committed
## gen/*.res files carry no UID, so on any other machine those UIDs are unknown. Godot still loads the scene
## ("invalid UID … using text path instead"), but the web export's dependency walk resolves the UID, finds
## nothing and leaves the file out of the pack: 81 meshes (store signs, 3D letters, shop stock, Sears' and
## Dillard's outside faces, the 2026 entrance) were missing from Demo 52.
##
## A uid is kept when this project's UID cache maps it to the same path; otherwise only the attribute goes
## (the path stays, which is what the loader falls back to anyway), so the scene is unchanged in content and
## needs no rebake. Run after an import, so the UID cache is current.
##
## usage: godot --headless --path . --script res://tools/fix_stale_uids.gd -- [--check] [scene.tscn …]
##   no scenes: every wing*.tscn at the project root. --check: change nothing, exit 1 if any are stale.

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var check := args.has("--check")
	var scenes: Array[String] = []
	for a in args:
		if a != "--check":
			scenes.append(a if a.begins_with("res://") else "res://" + a)
	if scenes.is_empty():
		for f in DirAccess.get_files_at("res://"):
			if f.begins_with("wing") and f.ends_with(".tscn"):
				scenes.append("res://" + f)
	scenes.sort()
	var re := RegEx.create_from_string('^(\\[ext_resource [^\\]]*?)uid="(uid://[a-z0-9]+)" ([^\\]]*path="(res://[^"]+)")')
	var total := 0
	for s in scenes:
		var text := FileAccess.get_file_as_string(s)
		if text.is_empty():
			push_error("fix_stale_uids: cannot read " + s); quit(2); return
		var lines := text.split("\n")
		var stale := 0
		for i in lines.size():
			var m := re.search(lines[i])
			if m == null:
				continue
			var id := ResourceUID.text_to_id(m.get_string(2))
			if ResourceUID.has_id(id) and ResourceUID.get_id_path(id) == m.get_string(4):
				continue
			stale += 1
			print("  stale ", m.get_string(2), " -> ", m.get_string(4))
			lines[i] = m.get_string(1) + m.get_string(3) + lines[i].substr(m.get_end())
		if stale > 0:
			total += stale
			print(s, ": ", stale, " stale uid(s)", " (not changed: --check)" if check else " removed")
			if not check:
				var f := FileAccess.open(s, FileAccess.WRITE)
				f.store_string("\n".join(lines))
				f.close()
	print("fix_stale_uids: ", total, " stale uid(s) in ", scenes.size(), " scene(s)")
	quit(1 if check and total > 0 else 0)
