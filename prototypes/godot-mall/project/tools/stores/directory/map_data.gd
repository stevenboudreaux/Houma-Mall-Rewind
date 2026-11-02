## The mall directory's data (design/godot-directory.md): every stall of both years, computed from
## the layout files the wings are built from (layout_mall.json, layout_2026.json), plus the
## hand-kept categories, numbers and names in directory_data.json. Written by the wing build to
## GEN/directory.json (read by scripts/directory_ui.gd) and by make_data.gd to map.json (read by
## paint_dir.py, which paints the kiosks' lit panels), so the map always matches the build.
##
## A stall's shape: the tiles behind its frontages that are not hall floor, shared out between
## neighbouring stores by growing every frontage inward at the same pace (a stall never grows past
## its frontage's ends or its depth in the layout), then merged into rectangles.
extends RefCounted

const LAYOUTS := {"1995": "res://layout_mall.json", "2026": "res://layout_2026.json"}
const DATA := "res://tools/stores/directory/directory_data.json"
## Same as WING2_ZONES in tools/build_mall.gd: a stall's wing is the wing of the floor its jump
## spot stands on.
const WING2_ZONES := ["C3", "H8", "H5", "C4", "H6", "H7"]
const STAND_OUT := 2.2     # metres out from the frontage where a jump puts the player
## Workstream S (Nov 2 2026, design/godot-wings.md "Wings 4-6"): the anchors that are wings of their
## own are jumped into: STAND_OUT inside the mall opening (tools/build_mall.gd ROOM_WINGS thr), facing
## in. Sears / Lynn's (s1) -> wing 4, Dillard's (s2) -> wing 5. [wing, x, z, yaw_deg]
const ROOM_JUMPS := {"s1": [4, -4.0, -98.2, 0.0], "s2": [5, -4.0, 82.2, 180.0]}

## Returns {"years": {"1995": {...}, "2026": {...}}}. Each year: title, cats [[id, title, colour]],
## stalls [{id, name, num, cats, rects [[x0,z0,x1,z1]], label [x,z], jump [wing,x,z,yaw_deg],
## vacant, kiosk}], halls [[x0,z0,x1,z1]], places [[letter, name, x, z]], kiosks [{x,z,face,where}].
static func compute() -> Dictionary:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	var out := {"years": {}}
	for y in LAYOUTS:
		var L: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LAYOUTS[y]))
		out.years[y] = _year(L, data.get(y, {}))
	return out

static func _year(L: Dictionary, D: Dictionary) -> Dictionary:
	var S := float(L.scale)
	var ox := float(L.origin[0])
	var oy := float(L.origin[1])
	var rows: Array = L.walk
	var H := rows.size()
	var W := String(rows[0]).length()
	# hall floor: walkable tiles inside a zone or a leftover patch (walk-in interiors are not hall)
	var hall := PackedByteArray()
	hall.resize(W * H)
	for ty in H:
		var row: String = rows[ty]
		for tx in W:
			if row[tx] != "1":
				continue
			var cx := (tx - ox + 0.5) * S
			var cz := (ty - oy + 0.5) * S
			if _zone_at(L, cx, cz) != "" or _in_leftover(L, cx, cz):
				hall[ty * W + tx] = 1
	# grow every store frontage inward, all at the same pace
	var owner := PackedInt32Array()
	owner.resize(W * H)
	owner.fill(-1)
	var edges := []
	for e in L.edges:
		if e.get("kind", "") == "store" and e.has("store") and L.stores.has(e.store):
			edges.append(e)
	var q := []
	for ei in edges.size():
		var e = edges[ei]
		var a := Vector2(e.a[0], e.a[1])
		var b := Vector2(e.b[0], e.b[1])
		var n := Vector2(e.n[0], e.n[1]).normalized()
		var tv := (b - a).normalized()
		var lo := Vector2(min(a.x, b.x), min(a.y, b.y)) - n * float(e.depth)
		var hi := Vector2(max(a.x, b.x), max(a.y, b.y)) - n * float(e.depth)
		lo = Vector2(min(lo.x, a.x, b.x), min(lo.y, a.y, b.y))
		hi = Vector2(max(hi.x, a.x, b.x), max(hi.y, a.y, b.y))
		for ty in range(max(0, int(floor(lo.y / S + oy))), min(H, int(ceil(hi.y / S + oy)) + 1)):
			for tx in range(max(0, int(floor(lo.x / S + ox))), min(W, int(ceil(hi.x / S + ox)) + 1)):
				var p := Vector2((tx - ox + 0.5) * S, (ty - oy + 0.5) * S)
				var s := (p - a).dot(tv)
				var d := -(p - a).dot(n)
				if s > 0.0 and s < (b - a).length() and d > 0.0 and d < S * 1.5 and hall[ty * W + tx] == 0 and owner[ty * W + tx] == -1:
					owner[ty * W + tx] = ei
					q.append(Vector2i(tx, ty))
	var qi := 0
	while qi < q.size():
		var c: Vector2i = q[qi]
		qi += 1
		var ei: int = owner[c.y * W + c.x]
		var e = edges[ei]
		var a := Vector2(e.a[0], e.a[1])
		var b := Vector2(e.b[0], e.b[1])
		var n := Vector2(e.n[0], e.n[1]).normalized()
		var tv := (b - a).normalized()
		for dv in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var t2: Vector2i = c + dv
			if t2.x < 0 or t2.y < 0 or t2.x >= W or t2.y >= H:
				continue
			var k := t2.y * W + t2.x
			if owner[k] != -1 or hall[k] == 1:
				continue
			var p := Vector2((t2.x - ox + 0.5) * S, (t2.y - oy + 0.5) * S)
			var s := (p - a).dot(tv)
			var d := -(p - a).dot(n)
			if s > 0.0 and s < (b - a).length() and d > 0.0 and d < float(e.depth):
				owner[k] = ei
				q.append(t2)
	# per store: its tiles, merged into rectangles; its longest frontage for the jump
	var cats := {}
	for c in D.get("cats", []):
		cats[c[0]] = c
	var names: Dictionary = D.get("stores", {})
	var stalls := []
	var by_store := {}
	for ei in edges.size():
		var sid: String = edges[ei].store
		if not by_store.has(sid):
			by_store[sid] = []
		by_store[sid].append(ei)
	var next_num := 100
	var sids := by_store.keys()
	sids.sort()
	for sid in sids:
		var st: Dictionary = L.stores[sid]
		var nm := String(st.get("name", ""))
		var vacant := bool(st.get("vacant", false)) or nm == ""
		var rects := _merge(owner, by_store[sid], W, H, S, ox, oy)
		if rects.is_empty():
			continue
		var best = null
		var best_len := -1.0
		for ei in by_store[sid]:
			var e = edges[ei]
			var ln := Vector2(e.a[0], e.a[1]).distance_to(Vector2(e.b[0], e.b[1]))
			if ln > best_len:
				best_len = ln
				best = e
		var info: Array = names.get(nm, [])
		var num := int(info[0]) if info.size() > 0 else 0
		var cl: Array = String(info[1]).split(",") if info.size() > 1 else (["vacant"] if vacant else ["other"])
		var disp: String = info[2] if info.size() > 2 else (("Vacant" if vacant else _title(nm)))
		if num == 0 and not vacant and D.has("title") and String(D.title).begins_with("Merchant"):
			num = next_num
			next_num += 1
		var fm := (Vector2(best.a[0], best.a[1]) + Vector2(best.b[0], best.b[1])) * 0.5 + Vector2(best.n[0], best.n[1]) * 1.0
		stalls.append({"id": sid, "name": disp, "num": num, "cats": cl, "rects": rects, "vacant": vacant,
			"label": _label_at(rects), "jump": ROOM_JUMPS.get(sid, _jump(L, best, hall, W, H, S, ox, oy)), "known": info.size() > 0,
			"layout_name": nm, "front": [best.a[0], best.a[1], best.b[0], best.b[1], best.n[0], best.n[1]],
			"zone": _zone_at(L, fm.x, fm.y)})
	for x in D.get("extras", []):
		var hw := float(x.w) * 0.5
		var hd := float(x.d) * 0.5
		var r := [x.x - hw, x.z - hd, x.x + hw, x.z + hd]
		# the jump spot: on the island's south side, facing it (looking north, yaw 0)
		var sp := Vector2(x.x, x.z + hd + 1.6)
		stalls.append({"id": "x_" + String(x.name).to_lower().replace(" ", "_").replace(".", ""), "name": x.name,
			"num": int(x.get("num", 0)), "cats": [x.cat], "rects": [r], "vacant": false, "label": [x.x, x.z],
			"jump": [_wing_at(L, sp.x, sp.y), snappedf(sp.x, 0.01), snappedf(sp.y, 0.01), 0.0], "known": true, "kiosk": true})
	var halls := []
	var hb := PackedInt32Array()
	hb.resize(W * H)
	for i in W * H:
		hb[i] = 0 if hall[i] == 1 else -1
	halls = _merge(hb, [0], W, H, S, ox, oy)
	return {"title": D.get("title", ""), "cats": D.get("cats", []), "stalls": stalls, "halls": halls,
		"places": D.get("places", []), "kiosks": D.get("kiosks", []),
		"bounds": _bounds(stalls, halls)}

static func _bounds(stalls: Array, halls: Array) -> Array:
	var b := [1e9, 1e9, -1e9, -1e9]
	for list in [halls]:
		for r in list:
			b = [min(b[0], r[0]), min(b[1], r[1]), max(b[2], r[2]), max(b[3], r[3])]
	for s in stalls:
		for r in s.rects:
			b = [min(b[0], r[0]), min(b[1], r[1]), max(b[2], r[2]), max(b[3], r[3])]
	return b

## Tiles owned by any of the given ids, merged into rectangles (row runs, then stacked runs).
static func _merge(owner: PackedInt32Array, ids: Array, W: int, H: int, S: float, ox: float, oy: float) -> Array:
	var runs := {}     # "x0,x1" -> [y0, y1] currently open
	var rects := []
	for ty in H + 1:
		var row_runs := {}
		if ty < H:
			var tx := 0
			while tx < W:
				if owner[ty * W + tx] in ids:
					var x0 := tx
					while tx < W and owner[ty * W + tx] in ids:
						tx += 1
					row_runs["%d,%d" % [x0, tx]] = true
				else:
					tx += 1
		for k in runs.keys():
			if not row_runs.has(k):
				var xs = k.split(",")
				var yr: Array = runs[k]
				rects.append([(int(xs[0]) - ox) * S, (yr[0] - oy) * S, (int(xs[1]) - ox) * S, (yr[1] + 1 - oy) * S])
				runs.erase(k)
		for k in row_runs:
			if runs.has(k):
				runs[k][1] = ty
			else:
				runs[k] = [ty, ty]
	return rects

static func _label_at(rects: Array) -> Array:
	var best = rects[0]
	for r in rects:
		if (r[2] - r[0]) * (r[3] - r[1]) > (best[2] - best[0]) * (best[3] - best[1]):
			best = r
	return [(best[0] + best[2]) * 0.5, (best[1] + best[3]) * 0.5]

## Where a jump to this store puts the player: on the hall floor STAND_OUT in front of the middle
## of its longest frontage, facing it. Returns [wing, x, z, yaw_deg].
static func _jump(L: Dictionary, e, hall: PackedByteArray, W: int, H: int, S: float, ox: float, oy: float) -> Array:
	var a := Vector2(e.a[0], e.a[1])
	var b := Vector2(e.b[0], e.b[1])
	var n := Vector2(e.n[0], e.n[1]).normalized()
	var m := (a + b) * 0.5
	var sp := m + n * STAND_OUT
	for out in [STAND_OUT, 1.6, 3.0, 4.0, 1.2]:
		var p: Vector2 = m + n * out
		var tx := int(floor(p.x / S + ox))
		var ty := int(floor(p.y / S + oy))
		if tx >= 0 and ty >= 0 and tx < W and ty < H and hall[ty * W + tx] == 1:
			sp = p
			break
	# yaw 0 looks along -z, 90 along -x (scripts/player.gd); face the store: look along -n
	var yaw := rad_to_deg(atan2(n.x, n.y))
	return [_wing_at(L, sp.x, sp.y), snappedf(sp.x, 0.01), snappedf(sp.y, 0.01), snappedf(yaw, 0.1)]

static func _wing_at(L: Dictionary, x: float, z: float) -> int:
	var zid := _zone_at(L, x, z)
	if zid != "":
		return 2 if zid in WING2_ZONES else 1
	# outside every zone (a leftover patch): by the seam's side (build_mall.gd, edge_wing)
	return 2 if (z > 48.0 or x < -20.0) else 1

static func _zone_at(L: Dictionary, x: float, z: float) -> String:
	for zn in L.zones:
		var r = zn.rect
		if x >= r[0] and x <= r[2] and z >= r[1] and z <= r[3]:
			return zn.id
	return ""

static func _in_leftover(L: Dictionary, x: float, z: float) -> bool:
	for r in L.get("leftovers", []):
		if x >= r[0] and x <= r[2] and z >= r[1] and z <= r[3]:
			return true
	for t in L.get("leftover_tris", []):
		if Geometry2D.point_is_inside_triangle(Vector2(x, z), Vector2(t[0][0], t[0][1]), Vector2(t[1][0], t[1][1]), Vector2(t[2][0], t[2][1])):
			return true
	return false

static func _title(n: String) -> String:
	var out := []
	for w in n.to_lower().split(" "):
		out.append(w.capitalize() if w.length() > 0 else w)
	return " ".join(out)
