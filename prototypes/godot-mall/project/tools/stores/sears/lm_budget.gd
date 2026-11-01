## Workstream E: lightmap budget of a wing's static meshes. Sums every gen/<dir>/*.res (not dyn_*)
## lightmap_size_hint (texels from the unwrap at the build's texel size) and lists the biggest.
##   godot --headless --path . --script res://tools/stores/sears/lm_budget.gd -- w1 [prefix-filter]
extends SceneTree

func _initialize():
	var args = OS.get_cmdline_user_args()
	var dir = "res://gen/%s/" % args[0]
	var filt = args[1] if args.size() > 1 else ""
	var tot = 0
	var sub = 0
	var rows = []
	for f in DirAccess.get_files_at(dir):
		if not f.ends_with(".res") or f.begins_with("dyn_"):
			continue
		var m = load(dir + f)
		if m is ArrayMesh:
			var s = m.lightmap_size_hint
			tot += s.x * s.y
			rows.append([s.x * s.y, f, s])
			if filt != "" and f.begins_with(filt):
				sub += s.x * s.y
	rows.sort_custom(func(a, b): return a[0] > b[0])
	print("LM %s total texels %d (%.2f Mpx, ~%d px square); %s: %d" % [args[0], tot, tot / 1e6, int(sqrt(tot)), filt, sub])
	for r in rows.slice(0, 6):
		print("   ", r[1], " ", r[2])
	quit()
