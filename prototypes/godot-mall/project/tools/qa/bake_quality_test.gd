## Checks tools/bake_quality.gd against tools/bake_quality.json (design/godot-bake-quality.md):
## the "d51" profile gives exactly the Demo 51 texels that were constants in build_mall.gd, the active
## profile only raises, the wing 3 override holds, and a lower profile is refused.
## godot --headless --path . --script res://tools/qa/bake_quality_test.gd   ->  "BAKE QUALITY OK" or FAIL lines
extends SceneTree

var fails := 0

func _check(what: String, got, want) -> void:
	var ok: bool = abs(float(got) - float(want)) < 1e-6 if (got is float or got is int) else got == want
	if not ok:
		fails += 1
		print("FAIL ", what, ": got ", got, " want ", want)

func _initialize() -> void:
	var BQ = load("res://tools/bake_quality.gd")
	# Demo 51 (the constants build_mall.gd had until Nov 4 2026): TEXEL 0.16 and its multipliers
	var d = BQ.new("wing1", "d51")
	var t = 0.16
	var cases = {"H3": t, "kb_shell": t, "pc_mach": t * 1.5, "sr_ceil0_1": t * 2.0, "sr_floor0_1": t * 1.25,
		"dl_wall_x": t * 1.25, "kbf_props": t * 0.6, "lanterns": t * 0.6, "outside": t * 4.0,
		"ex_ground": t * 10.0, "ex_far": t * 6.0, "ex_lot_lines": t * 2.5}
	for g in cases:
		_check("d51 " + g, d.texel(g), cases[g])
	_check("d51 stand-in", d.texel("C3", true), 0.40)
	_check("d51 floor group", d.floor_group(), false)
	# the active profile never coarser than Demo 51, anywhere
	var a = BQ.new("wing1")
	for g in cases:
		if a.texel(g) > d.texel(g) + 1e-6:
			fails += 1; print("FAIL active coarser than d51: ", g)
	if a.texel("C3", true) > 0.40 + 1e-6:
		fails += 1; print("FAIL active stand-in coarser than d51")
	if a.floor_group() and a.texel("H3_fl", false, true) > a.texel("H3") + 1e-6:
		fails += 1; print("FAIL floor coarser than its hall")
	print(a.describe())
	# wing 3 (the outside) keeps the Demo 51 texels in every profile, so it needs no rebake
	for y in ["wing3", "wing3_2026"]:
		var w = BQ.new(y)
		for g in ["outside", "ex_ground", "ex_far", "ex_wall"]:
			_check(y + " " + g, w.texel(g), d.texel(g))
		_check(y + " stand-in", w.texel("H3", true), 0.40)
		_check(y + " floor group", w.floor_group(), false)
	# a profile lower than d51 is refused (falls back to d51)
	var low = BQ.new("wing1", "d51")
	low.p = low.p.duplicate()
	low.p.texel = 0.2
	low.name = "test_low"
	low._check_not_lower()
	_check("lower profile refused", low.name, "d51")
	# LightmapGI settings
	var lmg = LightmapGI.new()
	a.setup_lightmap(lmg)
	_check("quality", lmg.quality, LightmapGI.BAKE_QUALITY_ULTRA)
	_check("bounces >= 3", lmg.bounces >= 3, true)
	_check("denoiser", lmg.use_denoiser, true)
	lmg.free()
	print("BAKE QUALITY OK" if fails == 0 else "BAKE QUALITY FAILED (%d)" % fails)
	quit(0 if fails == 0 else 1)
