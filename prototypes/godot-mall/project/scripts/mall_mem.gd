## PHONE-MEMORY (Nov 16 2026; production/qa/evidence/wsPHONE-MEMORY-findings.md, design/godot-wings.md
## "Seamless streaming"): what the game holds in memory, for a phone held in the hand.
##
## Made by scripts/wing_stream.gd as its child "MallMem", only with ?qa=1 on the web (or Engine meta
## "mall_mem" in a native test). Changes nothing the player sees: no text on the game screen. The readout
## is the menu's QA tab (scripts/menu/menu.gd, only while this node exists) and window.__mallMem for scripts.
##
## Once a second it reads:
## - the engine's own counters (Performance): texture memory, mesh/buffer memory, all video memory, objects,
##   resources, nodes; static memory (0 in a release export: the engine counts it only in debug builds);
## - which wings are in, and each streamed wing's state (scripts/wing_stream.gd nb);
## - from the page: the wasm heap's size (it only grows; Safari must find one block of that size), the pack
##   bytes the page holds, the canvas's drawing size, the GPU's name and compressed formats (ASTC profiles,
##   ETC2, S3TC), WebGL context losses, performance.memory where the browser has it (not Safari).
## And it keeps a crumb in localStorage "mall-mem-last" (the last sample and the last 40 events: wing states,
## heap growth, context loss), marked clean when the page is left normally. After Safari reloads a crashed
## tab, the QA tab and window.__mallMem.last show what the page held just before.
extends Node

const KEY := "mall-mem-last"
var stream: Node                 # the WingStream (parent)
var _t := 0.0
var _states := {}                # wing -> last state seen (events on change)
var _peak := {}
var sample := {}                 # the last sample (native and web)

func _ready() -> void:
	stream = get_parent()
	if OS.has_feature("web"):
		JavaScriptBridge.eval(_JS, true)
	_sample()

func _process(dt: float) -> void:
	_t += dt
	if _t >= 1.0:
		_t = 0.0
		_sample()

func _mb(v: float) -> float:
	return snappedf(v / 1048576.0, 0.1)

func _sample() -> void:
	var s := {
		"t": snappedf(Time.get_ticks_msec() / 1000.0, 0.1),
		"tex_mb": _mb(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)),
		"buf_mb": _mb(Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED)),
		"video_mb": _mb(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)),
		"static_mb": _mb(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"static_max_mb": _mb(Performance.get_monitor(Performance.MEMORY_STATIC_MAX)),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources": int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"fps": int(Performance.get_monitor(Performance.TIME_FPS)),
	}
	var wings := []
	var states := {}
	if stream and stream.get("enabled") != null:
		s["streaming"] = bool(stream.enabled)
		s["kind"] = str(stream.kind)
		s["home"] = int(stream.home_wing)
		s["year"] = int(stream.year)
		if stream.enabled:
			wings = stream.span()
			for w in stream.nb:
				states[str(w)] = str(stream.nb[w].get("state", ""))
		else:
			wings = [int(stream.home_wing)]
	s["wings"] = wings
	s["states"] = states
	var ev := []
	for w in states:
		if _states.get(w, "") != states[w]:
			ev.append("wing %s %s" % [w, states[w]])
	for w in _states:
		if not states.has(w):
			ev.append("wing %s gone" % w)
	_states = states
	for k in ["tex_mb", "buf_mb", "video_mb"]:
		_peak[k] = maxf(float(_peak.get(k, 0.0)), float(s[k]))
	s["peak"] = _peak.duplicate()
	sample = s
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.__mallMemPush && window.__mallMemPush(%s, %s);" % [JSON.stringify(s), JSON.stringify(ev)], true)
		var j = JavaScriptBridge.eval("JSON.stringify(window.__mallMem || {})", true)
		if j is String and j != "":
			var d = JSON.parse_string(j)
			if d is Dictionary:
				sample = d

## The QA tab's text (scripts/menu/menu.gd).
func report() -> String:
	var s := sample
	var L := PackedStringArray()
	L.append("MEMORY  (?qa=1; window.__mallMem)")
	L.append("wings in: %s   home %s   year %s   %s pack   streaming %s" % [
		str(s.get("wings", [])), str(s.get("home", "?")), str(s.get("year", "?")), str(s.get("kind", "?")),
		"on" if s.get("streaming", false) else "off"])
	if not (s.get("states", {}) as Dictionary).is_empty():
		L.append("streamed: %s" % str(s.get("states")))
	var pk: Dictionary = s.get("peak", {})
	L.append("textures %s MB (peak %s)   meshes/buffers %s MB (peak %s)" % [
		str(s.get("tex_mb", "?")), str(pk.get("tex_mb", "?")), str(s.get("buf_mb", "?")), str(pk.get("buf_mb", "?"))])
	L.append("all video memory %s MB (peak %s)" % [str(s.get("video_mb", "?")), str(pk.get("video_mb", "?"))])
	var st := float(s.get("static_mb", 0.0))
	L.append("static %s" % (("%s MB (max %s)" % [str(st), str(s.get("static_max_mb", "?"))]) if st > 0.0 else "n/a (release build)"))
	L.append("objects %s   resources %s   nodes %s   fps %s" % [
		str(s.get("objects", "?")), str(s.get("resources", "?")), str(s.get("nodes", "?")), str(s.get("fps", "?"))])
	if s.has("wasm_mb"):
		L.append("wasm heap %s MB (peak %s, grew %s times)   streamed pack bytes fetched %s MB" % [
			str(s.get("wasm_mb")), str(s.get("wasm_peak_mb", "?")), str(s.get("wasm_grew", 0)), str(s.get("packs_mb", "?"))])
		if s.get("js_heap_mb", null) != null:
			L.append("JS heap %s MB (limit %s)" % [str(s.get("js_heap_mb")), str(s.get("js_limit_mb", "?"))])
		else:
			L.append("JS heap: not told (Safari)")
		L.append("canvas %s   device pixel ratio %s" % [str(s.get("canvas", "?")), str(s.get("dpr", "?"))])
		L.append("GPU %s   max texture %s" % [str(s.get("gpu", "?")), str(s.get("max_tex", "?"))])
		L.append("formats: %s" % str(s.get("formats", "?")))
		L.append("WebGL context lost %s times" % str(s.get("lost", 0)))
		L.append("device memory %s   cores %s" % [str(s.get("device_mem", "not told")), str(s.get("cores", "?"))])
		L.append("since the page started %s s" % str(s.get("page_s", "?")))
		var last = s.get("last", null)
		if last is Dictionary and not last.is_empty():
			L.append("")
			L.append("LAST VISIT: %s" % ("left normally" if last.get("clean", false) else "did NOT end normally (a crash or a killed tab)"))
			var ls = last.get("s", {})
			if ls is Dictionary:
				L.append("  at %s s: wings %s %s, textures %s MB, video %s MB, wasm heap %s MB, packs %s MB, lost %s" % [
					str(ls.get("page_s", "?")), str(ls.get("wings", "?")), str(ls.get("states", {})), str(ls.get("tex_mb", "?")),
					str(ls.get("video_mb", "?")), str(ls.get("wasm_mb", "?")), str(ls.get("packs_mb", "?")), str(ls.get("lost", 0))])
			for e in last.get("ev", []):
				L.append("  " + str(e))
	return "\n".join(L)

const _JS := """
(function () {
	if (window.__mallMemPush) { return; }
	const KEY = 'mall-mem-last';
	let last = null;
	try { last = JSON.parse(localStorage.getItem(KEY) || 'null'); } catch (e) { last = null; }
	const M = { lost: 0, restored: 0, grew: 0, wasmPeak: 0, wasmLast: 0, ev: [] };
	const cv = document.querySelector('canvas');
	const info = {};
	try {
		const gl = cv && cv.getContext('webgl2');
		if (gl) {
			const dbg = gl.getExtension('WEBGL_debug_renderer_info');
			info.gpu = dbg ? gl.getParameter(dbg.UNMASKED_RENDERER_WEBGL) : gl.getParameter(gl.RENDERER);
			info.max_tex = gl.getParameter(gl.MAX_TEXTURE_SIZE);
			const f = [];
			const astc = gl.getExtension('WEBGL_compressed_texture_astc');
			if (astc) { f.push('ASTC ' + ((astc.getSupportedProfiles && astc.getSupportedProfiles().join('+')) || 'ldr')); }
			if (gl.getExtension('WEBGL_compressed_texture_etc')) { f.push('ETC2'); }
			if (gl.getExtension('WEBGL_compressed_texture_s3tc')) { f.push('S3TC'); }
			if (gl.getExtension('EXT_texture_compression_bptc')) { f.push('BPTC'); }
			if (gl.getExtension('EXT_texture_compression_rgtc')) { f.push('RGTC'); }
			info.formats = f.join(', ') || 'none';
		}
	} catch (e) { info.gpu = 'unknown (' + e + ')'; }
	const note = (s) => { M.ev.push(Math.round(performance.now() / 100) / 10 + ' s ' + s); if (M.ev.length > 40) { M.ev.shift(); } };
	if (cv) {
		cv.addEventListener('webglcontextlost', () => { M.lost++; note('WebGL context LOST'); save(false); });
		cv.addEventListener('webglcontextrestored', () => { M.restored++; note('WebGL context restored'); });
	}
	const mb = (b) => Math.round(b / 104857.6) / 10;
	let cur = {};
	const save = (clean) => {
		try { localStorage.setItem(KEY, JSON.stringify({ clean: clean, s: cur, ev: M.ev, at: Date.now() })); } catch (e) { /* full or blocked */ }
	};
	window.addEventListener('pagehide', () => { note('page left'); save(true); });
	note('page start' + (last && !last.clean ? ' (the last visit did not end normally)' : ''));
	window.__mallMemPush = function (g, ev) {
		(ev || []).forEach(note);
		const s = Object.assign({}, g);
		try {
			const heap = engine.rtenv.HEAP8.buffer.byteLength;
			if (M.wasmLast && heap > M.wasmLast) { M.grew++; note('wasm heap grew to ' + mb(heap) + ' MB'); }
			M.wasmLast = heap; M.wasmPeak = Math.max(M.wasmPeak, heap);
			s.wasm_mb = mb(heap); s.wasm_peak_mb = mb(M.wasmPeak); s.wasm_grew = M.grew;
		} catch (e) { s.wasm_mb = 'unknown'; }
		let held = 0;
		Object.keys(window.__mallStreamBytes || {}).forEach((w) => { held += window.__mallStreamBytes[w] || 0; });
		s.packs_mb = mb(held);
		if (performance.memory) { s.js_heap_mb = mb(performance.memory.usedJSHeapSize); s.js_limit_mb = mb(performance.memory.jsHeapSizeLimit); }
		s.canvas = cv ? (cv.width + 'x' + cv.height) : '?';
		s.dpr = window.devicePixelRatio;
		s.gpu = info.gpu; s.max_tex = info.max_tex; s.formats = info.formats;
		s.lost = M.lost;
		s.device_mem = navigator.deviceMemory || null; s.cores = navigator.hardwareConcurrency || null;
		s.page_s = Math.round(performance.now() / 100) / 10;
		s.pack = window.__mallPack || '';
		cur = Object.assign({}, s); delete cur.last;
		s.last = last; s.events = M.ev.slice();
		window.__mallMem = s;
		save(false);
	};
}());
"""
