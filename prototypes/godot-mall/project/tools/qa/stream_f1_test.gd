## TEST-DEBT F1 (fixed by PHONE-MEMORY, Nov 17 2026; scripts/wing_stream.gd _resync): a wing that comes in while the
## player is in the Stockrooms (a level built far off: |x| or |z| > 1000) must not resync then (that would re-show what
## the Stockrooms hid); the resync runs on the way back.
##   godot --headless --path . --script res://tools/qa/stream_f1_test.gd
## 1. wing 1, streaming on, the neighbour held back; the player is moved 2 km away (as the Stockrooms do);
## 2. wing 2 is let in: it comes in, the resync is put off (pending), wing 1's copy of wing 2's halls is still shown;
## 3. the player comes back: the resync runs (not pending), wing 1's copy of wing 2's halls is hidden.
## Prints STREAM F1 TEST OK, or the failures.
extends SceneTree

var scn: Node
var ws
var step := 0
var frames := 0
var t := 0.0
var errs := []

func _initialize() -> void:
	Engine.set_meta("mall_state_1995", "")
	Engine.set_meta("mall_stream", true)
	Engine.set_meta("mall_stream_kind", "mobile")
	Engine.set_meta("mall_upfront", false)
	scn = load("res://wing1.tscn").instantiate()
	root.add_child(scn)
	current_scene = scn

func _fail(s: String) -> void:
	errs.append(s)
	print("FAIL ", s)

## wing 1's own copy of a wing 2 hall (zone H5) is shown
func _copy_shown() -> bool:
	var st := scn.get_node_or_null("Static")
	if st == null:
		return false
	for c in st.get_children():
		if str(c.name).trim_suffix("_fl") == "H5" and c.visible:
			return true
	return false

func _process(dt: float) -> bool:
	t += dt
	frames += 1
	ws = root.get_node_or_null("WingStream")
	var p: Node3D = current_scene.get_node_or_null("Player") if current_scene else null
	match step:
		0:
			if ws:
				ws.cfg["start_delay_s"] = 100000.0
			if ws and p and frames > 5:
				ws.cfg["borders"] = [{"a": 1, "b": 2, "kind": "seam", "years": [1995]}]
				ws.cfg["near_m"] = {"desktop": 100000, "mobile": 100000}
				ws.cfg["far_m"] = {"desktop": 100000, "mobile": 100000}
				p.position = Vector3(2000, 0, 2000)     # "in the Stockrooms"
				step = 1; frames = 0
		1:
			if frames > 10:
				if not _copy_shown():
					_fail("before: wing 1's copy of wing 2's halls should be shown while wing 2 is not in")
				ws.cfg["start_delay_s"] = 0.0
				step = 2; t = 0.0
		2:
			if ws.is_in(2):
				step = 3; frames = 0
			elif t > 900.0:
				_fail("wing 2 never came in"); step = 9
		3:
			if frames > 5:
				if not ws._resync_pending:
					_fail("away: the resync should be put off while the player is in the Stockrooms")
				if not _copy_shown():
					_fail("away: wing 1's copy of wing 2's halls was changed while away")
				p = current_scene.get_node_or_null("Player")
				p.position = Vector3(-9.0, 0, 40.0)    # back in the mall
				step = 4; frames = 0
		4:
			if frames > 10:
				if ws._resync_pending:
					_fail("back: the resync should have run on the way back")
				if _copy_shown():
					_fail("back: wing 1's copy of wing 2's halls should be hidden once wing 2 is in")
				step = 9
		9:
			print("STREAM F1 TEST OK" if errs.is_empty() else "STREAM F1 TEST FAILED (%d)" % errs.size())
			quit(0 if errs.is_empty() else 1)
	return false
