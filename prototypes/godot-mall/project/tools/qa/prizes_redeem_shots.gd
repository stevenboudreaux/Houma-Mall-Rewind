## Native, unbaked check and shots of a prize counter in the game (workstream PRIZES; design/godot-prize-counter.md
## "PRIZES"): the "Redeem tickets" prompt at a case, the redemption screen with that year's stock, a buy that
## spends only that year's tickets, the "You received" card, and the closer look.
##   xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 \
##     --script res://tools/qa/prizes_redeem_shots.gd -- --year=2026 --out=/tmp/pz/gi
## --year=1995 does Pocket Change (wing2.tscn), 2026 games, inc. (wing2_2026.tscn). Prints REDEEM SHOTS OK (n).
extends SceneTree

var out := "/tmp/pz/redeem"
var year := 2026
var scn: Node
var player: Node3D
var pz: Node
var rd: Node
var step := 0
var clock := 0.0
var errors := []
var oks := 0
var want := ""          # the item bought
var t0 := 0

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="): out = a.substr(6)
		elif a.begins_with("--year="): year = int(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_state_2026", "")
	# CHAR-STRIP: the player's record (scripts/cast.gd), first person, the default cast member
	Cast.save_player({"cast": str(Cast.roster().default), "view": "first"})
	# standing at the first case's front, facing it (+x in both years' wing 2)
	var at := Vector3(-113.05, 0, 62.4) if year == 2026 else Vector3(-104.8, 0, 64.2)
	Engine.set_meta("mall_xfer", {"x": at.x, "z": at.z, "yaw": deg_to_rad(-90.0), "pitch": deg_to_rad(-20.0)})
	scn = load("res://wing2_2026.tscn" if year == 2026 else "res://wing2.tscn").instantiate()
	root.add_child(scn)
	current_scene = scn
	var lm = scn.find_child("LightmapGI", true, false)
	if lm: lm.get_parent().remove_child(lm); lm.free()
	load("res://scripts/time_of_day.gd").apply(scn, "night")
	player = scn.get_node("Player")

func _check(ok: bool, what: String) -> void:
	printerr(("ok   " if ok else "FAIL ") + what)
	if ok: oks += 1
	else: errors.append(what)

func _shot(name: String) -> void:
	root.get_texture().get_image().save_png("%s-%s.png" % [out, name])

func _process(dt: float) -> bool:
	clock += dt
	if pz == null:
		pz = scn.get_node_or_null("Prizes")
		clock = 0.0
		return false
	match step:
		0:
			if clock > 4.0:
				var gi: bool = pz.get_script().resource_path.ends_with("prizes_gi.gd")
				_check(gi == (year == 2026), "%d: the counter is %s" % [year, "games, inc.'s (prizes_gi.gd)" if year == 2026 else "Pocket Change's (prizes.gd)"])
				_check(pz.items.size() > 40, "%d: the counter has its prizes and tags (%d)" % [year, pz.items.size()])
				rd = player.mall.redemption
				var other := 1995 if year == 2026 else 2026
				# this year's tickets, and some in the other year that must not move
				player.mall.tickets = 2500
				player.mall.bank().set_tickets(other, 777)
				t0 = 777
				_check(pz.prompt.visible, "%d: standing at the case, the prompt shows (Redeem tickets)" % year)
				_shot("prompt")
				pz.redeem()
				step = 1; clock = 0.0
		1:
			if clock > 1.0:
				_check(rd.is_open, "%d: the prompt opens the redemption screen" % year)
				var names: Array = rd.stock.map(func(s): return str(s.item))
				var foreign := names.filter(func(i): var y := str(rd.db.get_item(i).get("year", "")); return y != "both" and int(float(y)) != year)
				_check(foreign.is_empty(), "%d: the screen shows only this year's prizes %s" % [year, str(foreign)])
				_check(rd.stock.size() >= 35, "%d: the stock is full (%d prizes)" % [year, rd.stock.size()])
				_shot("screen")
				# buy the dearest prize the 2,500 tickets cover
				var best := -1
				for i in rd.stock.size():
					if rd.can_buy(i) and (best < 0 or rd.price(i) >= rd.price(best)):
						best = i
				want = str(rd.stock[best].item)
				var price: int = rd.price(best)
				_check(rd.buy(best) and player.mall.tickets == 2500 - price and player.mall.count(want) == 1,
					"%d: buying %s (%d) spends this year's tickets (%d left) into this year's bag" % [year, want, price, player.mall.tickets])
				step = 2; clock = 0.0
		2:
			if clock > 0.8:
				_shot("bought")
				# the other year's tickets: read from the shared bank keys
				var other := 1995 if year == 2026 else 2026
				var v: int = player.mall.bank().tickets(other)
				_check(v == t0, "%d: the other year's tickets didn't move (%d)" % [year, v])
				# dismiss the card, close the screen, the closer look
				var pop = null
				for c in player.get_node("Interact").get_children():
					if c.has_method("show_item"): pop = c
				if pop: pop.dismiss()
				rd.close()
				step = 3; clock = 0.0
		3:
			if clock > 0.8:
				if pop_open():
					return false
				pz.open_look(0)
				step = 4; clock = 0.0
		4:
			if clock > 1.4:
				_check(pz.looking, "%d: the closer look opens" % year)
				_shot("look")
				pz.step_view(4 if year == 2026 else 5)
				step = 5; clock = 0.0
		5:
			if clock > 1.4:
				_shot("look-wall")
				pz.close_look()
				step = 6; clock = 0.0
		6:
			if clock > 1.0:
				_check(not pz.looking and not player.frozen, "%d: Back returns to walking" % year)
				if errors.is_empty():
					print("REDEEM SHOTS OK (%d)" % oks)
				else:
					print("REDEEM SHOTS FAILED %d\n  %s" % [errors.size(), "\n  ".join(errors)])
				quit(0 if errors.is_empty() else 1)
				return true
	return false

func pop_open() -> bool:
	return player.mall.get_meta("popup_open", false)
