## Writes tools/stores/directory/map.json (both years' directory data, map_data.gd) for the panel
## painter, paint_dir.py, and prints the stores with no entry in directory_data.json.
##   godot --headless --path . --script res://tools/stores/directory/make_data.gd
extends SceneTree

func _initialize():
	var d: Dictionary = load("res://tools/stores/directory/map_data.gd").compute()
	var f = FileAccess.open("res://tools/stores/directory/map.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(d, " "))
	f.close()
	for y in d.years:
		var miss = []
		for s in d.years[y].stalls:
			if not s.known and not s.vacant:
				miss.append(s.name)
		print(y, ": ", d.years[y].stalls.size(), " stalls; not in directory_data.json: ", miss)
	print("MAP DATA OK")
	quit()
