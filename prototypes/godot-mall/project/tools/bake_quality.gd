## Lightmap bake settings as data (design/godot-bake-quality.md, Nov 4 2026): reads
## tools/bake_quality.json and answers tools/build_mall.gd's questions: the lightmap texel of each mesh
## group, whether own floors get a mesh of their own, and the LightmapGI settings. Replaces the
## constants that lived in build_mall.gd (TEXEL = 0.16 and the per-group multipliers), whose values
## are kept as the "d51" profile.
extends RefCounted

const PATH = "res://tools/bake_quality.json"
const BASE = "d51"

var cfg: Dictionary
var name: String
var p: Dictionary      # the effective profile for this scene
var base: Dictionary   # the d51 profile, for the never-lower check

## scene: "wing1", "wing1_2026" ...; profile: "" for the file's "active" one.
func _init(scene: String, profile := ""):
	cfg = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	name = profile
	if name == "":
		name = OS.get_environment("MALL_BAKE_PROFILE")
	if name == "":
		name = cfg.active
	if not cfg.profiles.has(name):
		push_error("bake_quality: no profile " + name)
		name = BASE
	p = cfg.profiles[name].duplicate()
	var wings: Dictionary = cfg.get("wings", {})
	for key in [scene.trim_suffix("_2026"), scene]:
		if wings.has(key):
			for k in wings[key]:
				p[k] = wings[key][k]
	base = cfg.profiles[BASE]
	_check_not_lower()

## Metres per lightmap texel for a mesh group. standin: a zone of the other wing; floor: an own
## floor split out by floor_group().
func texel(gname: String, standin := false, floor := false) -> float:
	for r in cfg.rules:
		if _matches(r, gname, standin, floor):
			if r.has("texel_key"):
				return float(p[r.texel_key])
			return float(p.texel) * float(r.mult)
	return float(p.texel)

## The d51 texel of the same group (for reports and the never-lower check).
func texel_d51(gname: String, standin := false, floor := false) -> float:
	for r in cfg.rules:
		if _matches(r, gname, standin, floor):
			if r.has("texel_key"):
				var v = base[r.texel_key]
				return float(base.texel) if v == null else float(v)
			return float(base.texel) * float(r.mult)
	return float(base.texel)

## True when own hall and court floors get their own mesh ("<zone>_fl") at floor_texel.
func floor_group() -> bool:
	return p.get("floor_texel") != null

func setup_lightmap(lmg: LightmapGI) -> void:
	lmg.quality = {"low": LightmapGI.BAKE_QUALITY_LOW, "medium": LightmapGI.BAKE_QUALITY_MEDIUM,
		"high": LightmapGI.BAKE_QUALITY_HIGH, "ultra": LightmapGI.BAKE_QUALITY_ULTRA}[str(p.quality)]
	lmg.bounces = int(p.bounces)
	lmg.use_denoiser = bool(p.denoiser)
	lmg.denoiser_strength = float(p.denoiser_strength)
	lmg.max_texture_size = int(p.max_texture_size)
	lmg.generate_probes_subdiv = {4: LightmapGI.GENERATE_PROBES_SUBDIV_4, 8: LightmapGI.GENERATE_PROBES_SUBDIV_8,
		16: LightmapGI.GENERATE_PROBES_SUBDIV_16, 32: LightmapGI.GENERATE_PROBES_SUBDIV_32}[int(p.probes_subdiv)]

func describe() -> String:
	return "bake profile %s: texel %.3f m, floors %s, stand-ins %.2f m, %s, %d bounces, denoiser %s %.2f, max %d" % [
		name, float(p.texel), ("%.3f m" % float(p.floor_texel)) if floor_group() else "in the zone mesh",
		float(p.standin_texel), p.quality, int(p.bounces), p.denoiser, float(p.denoiser_strength), int(p.max_texture_size)]

func _matches(r: Dictionary, g: String, standin: bool, floor: bool) -> bool:
	if r.has("standin"):
		return standin
	if r.has("floor"):
		return floor
	if standin or floor:
		return false
	if r.has("suffix") and not g.ends_with(r.suffix):
		return false
	if r.has("exact") and g != r.exact:
		return false
	if r.has("prefix"):
		var ok = false
		for pre in (r.prefix if r.prefix is Array else [r.prefix]):
			if g.begins_with(pre):
				ok = true
		if not ok:
			return false
	if r.has("contains") and not g.contains(r.contains):
		return false
	return true

## Steven: no lower picture quality without before/after shots and his yes. A profile that is coarser
## or lower than d51 anywhere is refused (falls back to d51) unless it says allow_lower: true.
func _check_not_lower() -> void:
	if p.get("allow_lower", false):
		return
	var bad = []
	if float(p.texel) > float(base.texel): bad.append("texel")
	if p.get("floor_texel") != null and float(p.floor_texel) > float(base.texel): bad.append("floor_texel")
	if float(p.standin_texel) > float(base.standin_texel): bad.append("standin_texel")
	var order = ["low", "medium", "high", "ultra"]
	if order.find(str(p.quality)) < order.find(str(base.quality)): bad.append("quality")
	if int(p.bounces) < int(base.bounces): bad.append("bounces")
	if int(p.max_texture_size) < int(base.max_texture_size): bad.append("max_texture_size")
	if int(p.probes_subdiv) < int(base.probes_subdiv): bad.append("probes_subdiv")
	if base.denoiser and not p.denoiser: bad.append("denoiser")
	if bad.size() > 0:
		push_error("bake_quality: profile %s is lower than d51 in %s; using d51 (set allow_lower after Steven's yes)" % [name, bad])
		p = base.duplicate()
		name = BASE
