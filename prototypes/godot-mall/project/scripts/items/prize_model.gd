## One Pocket Change prize as an item model (workstream R, Nov 2 2026; design/godot-prize-counter.md
## "Redemption"), for the prizes of scripts/prizes.json that had no item of their own: the item scenes
## scripts/items/pc_*.tscn set `kind` and this builds that prize exactly as the counter shows it, with
## scripts/prizes.gd's own meshes, materials and builders (one unit instead of a binful). Nothing new is
## drawn here: the counter and the bag show the same thing.
## Origin on the floor at the item's foot, +z its front (the item scene contract, design/godot-interaction.md).
extends Node3D

@export var kind := ""

func _ready() -> void:
	var P: Node3D = load("res://scripts/prizes.gd").new()     # not in the tree: its _ready never runs
	P._shaders()
	P._kinds()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1995
	var r := Basis(Vector3(0, 0, 1), PI * 0.5)                  # a tube lying along x
	match kind:
		"jelly_trap":
			P.add("jelly", Transform3D(r, Vector3(0, 0.0085, 0)), Color(1.0, 0.235, 0.588, 0.78))
		"chew":
			# a little heap of chews (one is 3.6 cm)
			for k in 5:
				var a := TAU * k / 5.0 + 0.3
				var p := Vector3(cos(a) * 0.016, 0.0075 + (0.012 if k == 4 else 0.0), sin(a) * 0.016) if k < 4 else Vector3(0, 0.02, 0)
				P.add("chew", Transform3D(Basis(Vector3.UP, a * 1.7) * r, p))
		"candy_cig":
			var c := Transform3D(Basis(), Vector3(0, 0.0375, 0))
			P.add("cbox", c)
			P.add("cface", c * Transform3D(Basis(), Vector3(0, 0, 0.0072)))
		"vpet":
			var c := Transform3D(Basis(), Vector3(0, 0.03, 0))
			var col := Color("#ff8cc0")
			P.add("egg", c * Transform3D(Basis().scaled(Vector3(0.05, 0.058, 0.024)), Vector3.ZERO), col)
			P.add("lcd", c * Transform3D(Basis(), Vector3(0, 0.005, 0.0122)))
			for bx in [-0.009, 0.0, 0.009]:
				P.add("btn", c * Transform3D(Basis(), Vector3(bx, -0.0135 - (0.003 if bx == 0.0 else 0.0), 0.0105)), Color("#d8d8d8"))
			P.add("loop", c * Transform3D(Basis(Vector3(1, 0, 0), PI * 0.5), Vector3(0, 0.034, 0)), Color("#c8c8cc"))
		"alien":
			P._alien(Transform3D(), 0.4, false, rng)
		"big_dice":
			# the wall's pair: two giant dice on a cord
			var col := Color.WHITE
			var a := Vector3(-0.075, 0.07, 0)
			var b := Vector3(0.08, 0.07, 0.02)
			P.add("bigdie", Transform3D(Basis(Vector3.UP, -0.15), a), col)
			P.add("bigdie", Transform3D(Basis(Vector3.UP, 0.55) * Basis(Vector3(1, 0, 0), PI * 0.5), b), col)
			P.add("cord", P._rod(a + Vector3(0, 0.07, 0), (a + b) * 0.5 + Vector3(0, 0.16, 0), 1.0))
			P.add("cord", P._rod(b + Vector3(0, 0.07, 0), (a + b) * 0.5 + Vector3(0, 0.16, 0), 1.0))
		"ball":
			P.add("ball", Transform3D(Basis(), Vector3(0, 0.12, 0)))
		_:
			# PRIZES (Nov 3): the added prizes, one unit as the counter shows it (scripts/prize_units.gd)
			var PU = load("res://scripts/prize_units.gd")
			if PU.SPEC.has(kind) or PU.BOX_ART.has(kind) or PU.BLENDER.has(kind) or kind in ["play_ball", "bubbles"]:
				PU.unit(P, kind, Transform3D(), 0, rng)
			else:
				push_warning("prize_model: unknown kind '%s'" % kind)
	P._flush()
	for c in P.get_children():
		P.remove_child(c)
		if c is GeometryInstance3D:
			c.visibility_range_end = 0.0
		add_child(c)
	P.free()
