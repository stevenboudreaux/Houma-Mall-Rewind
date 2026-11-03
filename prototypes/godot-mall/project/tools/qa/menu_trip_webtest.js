// MENU2 (design/godot-menu.md "Time travel at the directory"): the year toggle on a mall directory, in
// the web build, headless Chromium (swiftshader), Node Playwright (async; the sync Python API deadlocks
// on a screencast that runs across a page reload). One trip each way at the H2 kiosk (wing 1):
//   1995 -> 2026: stand 1.2 m in front of the kiosk (interact.gd REACH is 1.6 m), E opens the
//                 directory, Y (its toggle) travels;
//   2026 -> 1995: the same from where you landed.
// Each trip checks:
//   - the load screen (#load-card) is never visible on any animation frame of the page that loads the
//     other year (a watcher installed in every page records every frame: it only runs between the
//     engine's start-up stalls, so it samples tens of frames), and no frame of the screencast (the
//     compositor's output, captured through those stalls too) looks like it: the load card is a black
//     screen, so a frame more than LOAD_BLACK near-black is counted;
//   - the vortex veil (#tt-veil) covered the reload;
//   - you land within 1 m of the kiosk's twin spot (data/directory_twins.json, the same maths as
//     scripts/timetravel_trip.gd landing()), facing the same way (within 2 degrees), in the other year;
//   - 0 console errors.
// A frame sequence of the transition (CDP screencast, through the reload): <out>-<leg>-NNN.jpg and
// <out>-<leg>-frames.json (file, seconds after the toggle).
//
// Usage (a server on :8765 serving the repo root):
//   node tools/qa/menu_trip_webtest.js <url-path-to-index.html> <out-prefix>
// Prints MENU TRIP WEB OK, or the failures.
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

const [urlPath, out] = process.argv.slice(2);
const BASE = 'http://127.0.0.1:8765/' + urlPath;
const TWINS = JSON.parse(fs.readFileSync(path.join(__dirname, '..', '..', 'data', 'directory_twins.json'), 'utf8'));
const K = TWINS.kiosks[0];    // H2 north, wing 1
const fails = [];
let oks = 0;
const check = (ok, what) => { console.log((ok ? 'ok   ' : 'FAIL ') + what); if (ok) oks++; else fails.push(what); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const LOAD_BLACK = 0.5;     // share of near-black pixels that marks a frame as the load card (the vortex: < 0.05)

// The share of near-black pixels of each JPEG frame, decoded in a page.
async function blackShares(b, files) {
	const pg = await (await b.newContext()).newPage();
	const out = [];
	for (const f of files) {
		const url = 'data:image/jpeg;base64,' + fs.readFileSync(f).toString('base64');
		out.push(await pg.evaluate(async (u) => {
			const im = new Image(); im.src = u; await im.decode();
			const c = document.createElement('canvas'); c.width = 64; c.height = 36;
			const g = c.getContext('2d'); g.drawImage(im, 0, 0, 64, 36);
			const d = g.getImageData(0, 0, 64, 36).data; let n = 0;
			for (let i = 0; i < d.length; i += 4) if (d[i] < 14 && d[i + 1] < 14 && d[i + 2] < 14) n++;
			return n / (64 * 36);
		}, url));
	}
	await pg.context().close();
	return out;
}

// = scripts/timetravel_trip.gd landing()
function landing(frm, px, pz, yawDeg) {
	const to = frm === '1995' ? '2026' : '1995';
	const h = K[frm], t = K[to] || K[frm];
	const a = Math.atan2(t.face[1], t.face[0]) - Math.atan2(h.face[1], h.face[0]);
	const rx = px - h.x, rz = pz - h.z;
	return [t.x + rx * Math.cos(a) - rz * Math.sin(a), t.z + rx * Math.sin(a) + rz * Math.cos(a), yawDeg - a * 180 / Math.PI];
}

const WATCH = `(() => {
  const W = window.__ttWatch = {frames: 0, loadShown: 0, veil: 0, tt: 0};
  const vis = (el) => { if (!el) return false; const s = getComputedStyle(el); return s.display !== 'none' && s.visibility !== 'hidden' && parseFloat(s.opacity) > 0.01; };
  const tick = () => {
    W.frames++;
    const card = document.getElementById('load-card'), st = document.getElementById('status');
    if (card && vis(card) && vis(st)) W.loadShown++;
    if (document.getElementById('tt-veil')) W.veil++;
    if (document.documentElement.classList.contains('tt')) W.tt++;
    requestAnimationFrame(tick);
  };
  requestAnimationFrame(tick);
})();`;

(async () => {
	const b = await chromium.launch({ args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--ignore-gpu-blocklist'] });
	const ctx = await b.newContext({ viewport: { width: 1280, height: 720 } });
	await ctx.addInitScript(WATCH);
	const pg = await ctx.newPage();
	const logs = [];
	pg.on('console', (m) => logs.push(m.text()));
	const cdp = await ctx.newCDPSession(pg);
	let frames = [];
	cdp.on('Page.screencastFrame', (ev) => {
		frames.push([Date.now(), ev.data]);
		cdp.send('Page.screencastFrameAck', { sessionId: ev.sessionId }).catch(() => {});
	});
	const ready = async (t = 300000) => {
		const t0 = Date.now();
		while (Date.now() - t0 < t) {
			try { if (await pg.evaluate("!document.getElementById('status') && !!window.__mallControlAt")) return (Date.now() - t0) / 1000; } catch (e) { /* navigating */ }
			await sleep(500);
		}
		return null;
	};
	const h = K['1995'], f = h.face;
	const sx = h.x + f[0] * 1.2 - f[1] * 0.25, sz = h.z + f[1] * 1.2 + f[0] * 0.25;
	const syaw = Math.atan2(f[0], f[1]) * 180 / Math.PI;
	await pg.goto(`${BASE}?wing=${K.wing}&cam=${sx.toFixed(2)},${sz.toFixed(2)},${syaw.toFixed(1)},-4`);
	console.log('1995 ready_s', await ready());
	await sleep(8000);
	await pg.mouse.click(640, 700); await sleep(800);
	let pos = [sx, sz, syaw], year = '1995';
	for (const leg of ['1995-2026', '2026-1995']) {
		const to = year === '1995' ? '2026' : '1995';
		const before = logs.length;
		await pg.keyboard.press('e'); await sleep(2500);
		await pg.screenshot({ path: `${out}-${leg}-directory.png`, timeout: 180000 });
		frames = [];
		await cdp.send('Page.startScreencast', { format: 'jpeg', quality: 70, maxWidth: 640, maxHeight: 360, everyNthFrame: 1 });
		const t0 = Date.now();
		await pg.keyboard.press('y');
		let landed = null;
		while (Date.now() - t0 < 360000) {
			await sleep(250);
			for (const l of logs.slice(before)) {
				const m = l.match(/time travel: arrived in (\d+) at (-?[\d.]+),(-?[\d.]+) yaw (-?[\d.]+)/);
				if (m) landed = m;
			}
			if (landed) break;
		}
		await sleep(1500);
		await cdp.send('Page.stopScreencast').catch(() => {});
		const dt = (Date.now() - t0) / 1000;
		check(!!landed, `${leg}: the trip arrives (${dt.toFixed(0)} s)`);
		let w = null;
		try { w = await pg.evaluate('window.__ttWatch'); } catch (e) { w = null; }
		console.log(`${leg}: watcher`, JSON.stringify(w));
		check(w && w.frames > 5 && w.loadShown === 0, `${leg}: the load screen never shows (${w && w.loadShown} of ${w && w.frames} sampled frames)`);
		check(w && w.veil > 0, `${leg}: the vortex veil covered the reload (${w && w.veil} frames)`);
		check(logs.slice(before).some((l) => l.indexOf(`time travel: ${year} -> ${to}`) >= 0), `${leg}: the trip began in ${year}`);
		if (landed) {
			const [ex, ez, eyaw] = landing(year, pos[0], pos[1], pos[2]);
			const ax = +landed[2], az = +landed[3], ayaw = +landed[4];
			const d = Math.hypot(ax - ex, az - ez);
			const dy = Math.abs((((ayaw - eyaw + 180) % 360) + 360) % 360 - 180);
			check(landed[1] === to, `${leg}: in ${to} (got ${landed[1]})`);
			check(d < 1.0, `${leg}: landed within 1 m of the twin spot (${d.toFixed(2)} m; at ${ax.toFixed(2)},${az.toFixed(2)}, twin spot ${ex.toFixed(2)},${ez.toFixed(2)})`);
			check(dy < 2.0, `${leg}: the same facing (${ayaw.toFixed(1)} vs ${eyaw.toFixed(1)})`);
			pos = [ax, az, ayaw];
		}
		check(pg.url().includes('year=2026') === (to === '2026'), `${leg}: the page is the ${to} file (${pg.url().split('?')[1]})`);
		const errs = logs.slice(before).filter((l) => /ERROR/i.test(l));
		check(errs.length === 0, `${leg}: no console errors (${errs.slice(0, 2)})`);
		const kept = frames.map(([ts, data], i) => {
			const fn = `${out}-${leg}-${String(i).padStart(3, '0')}.jpg`;
			fs.writeFileSync(fn, Buffer.from(data, 'base64'));
			return [fn, (ts - t0) / 1000];
		});
		fs.writeFileSync(`${out}-${leg}-frames.json`, JSON.stringify(kept));
		const shares = await blackShares(b, kept.map((k) => k[0]));
		const dark = shares.filter((x) => x > LOAD_BLACK).length;
		check(kept.length > 20 && dark === 0, `${leg}: no screencast frame looks like the load screen (${dark} of ${kept.length}; darkest ${Math.max(0, ...shares).toFixed(3)} near-black)`);
		console.log(`${leg}: ${kept.length} frames over ${dt.toFixed(1)} s`);
		await pg.screenshot({ path: `${out}-${leg}-arrived.png`, timeout: 180000 });
		year = to;
		await sleep(3000);
		await pg.mouse.click(640, 700); await sleep(500);
	}
	await b.close();
	console.log('checks ok:', oks);
	if (fails.length) { console.log('MENU TRIP WEB FAILED:', JSON.stringify(fails)); process.exit(1); }
	console.log(`MENU TRIP WEB OK (${oks} checks)`);
})().catch((e) => { console.error(e); process.exit(2); });
