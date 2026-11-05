// ARCADE-NES (Steven, Nov 4 2026; design/godot-arcade-roms.md): every playable cabinet in Pocket Change
// is an NES. Checks scripts/signs.gd ARCADE (12 cabinets, all "nes") and play/emu.html in Chromium,
// served locally with the GitHub API and the emulator's CDN mocked (no network, no ROM shipped: the
// test's ".nes" file is a few made-up bytes): the setup page says NES and accepts only .nes/.fds/.unf
// whatever system the link names, refuses another system's file, and an upload writes an NES entry and
// drops entries for other systems; a cabinet with an old non-NES entry has no game to play.
//   node tools/qa/arcade_nes_webtest.js [evidence-dir]   -> ARCADE NES WEBTEST OK (n checks)
'use strict';
const fs = require('fs');
const path = require('path');
const os = require('os');
const http = require('http');
const { chromium } = require('playwright');

const PLAY = path.join(__dirname, '../../../play');
const shots = process.argv[2] || '';
let oks = 0; const errors = [];
function check(ok, what) { console.error((ok ? 'ok   ' : 'FAIL ') + what); if (ok) oks++; else errors.push(what); }

// ---- signs.gd
const signs = fs.readFileSync(path.join(__dirname, '../../scripts/signs.gd'), 'utf8');
const arc = /const ARCADE := \{([^}]*)\}/.exec(signs)[1];
const pairs = [...arc.matchAll(/"(pc\.video\.\d+)":\s*"([A-Za-z0-9]+)"/g)].map((m) => [m[1], m[2]]);
check(pairs.length === 12, 'signs.gd ARCADE: 12 playable cabinets (' + pairs.length + ')');
check(pairs.every((p) => p[1] === 'nes'), 'every one is an NES (' + [...new Set(pairs.map((p) => p[1]))].join(', ') + ')');
const roms = JSON.parse(fs.readFileSync(path.join(PLAY, 'roms.json'), 'utf8'));
check(Object.values(roms.cabinets || {}).every((c) => c.core === 'nes'), 'play/roms.json: no non-NES entries (' + Object.keys(roms.cabinets || {}).length + ' entries)');
const shipped = fs.readdirSync(path.join(PLAY, 'roms')).filter((f) => f !== '.gitkeep');
check(shipped.length === 0, 'no ROM files shipped in play/roms/ (' + shipped.join(', ') + ')');

(async () => {
	const server = http.createServer((req, res) => {
		const u = new URL(req.url, 'http://x');
		if (u.pathname === '/roms.json') {
			res.writeHead(200, { 'Content-Type': 'application/json' });
			res.end(JSON.stringify({ cabinets: { 'pc.video.03': { file: 'roms/old.md', core: 'segaMD', name: 'old.md' }, 'pc.video.37': { file: 'roms/mine.nes', core: 'nes', name: 'mine.nes' } } }));
			return;
		}
		const f = path.join(PLAY, path.normalize(u.pathname).replace(/^(\.\.[/\\])+/, ''));
		if (!f.startsWith(PLAY) || !fs.existsSync(f) || fs.statSync(f).isDirectory()) { res.writeHead(404); res.end(); return; }
		res.writeHead(200, { 'Content-Type': f.endsWith('.html') ? 'text/html' : 'application/octet-stream' });
		res.end(fs.readFileSync(f));
	});
	await new Promise((r) => server.listen(0, '127.0.0.1', r));
	const base = 'http://127.0.0.1:' + server.address().port + '/';
	const browser = await chromium.launch();
	const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
	const puts = [];
	let liveList = { cabinets: { 'pc.video.03': { file: 'roms/old.md', core: 'segaMD', name: 'old.md' }, 'pc.video.62': { file: 'roms/x.sfc', core: 'snes', name: 'x.sfc' }, 'pc.video.37': { file: 'roms/mine.nes', core: 'nes', name: 'mine.nes' } } };
	await ctx.route('https://api.github.com/**', async (route) => {
		const req = route.request();
		const p = decodeURIComponent(new URL(req.url()).pathname);
		if (req.method() === 'GET') {
			if (p.endsWith('/play/roms.json')) return route.fulfill({ status: 200, contentType: 'application/json', body: JSON.stringify({ sha: 'live', content: Buffer.from(JSON.stringify(liveList)).toString('base64') }) });
			return route.fulfill({ status: 404, body: '{}' });
		}
		puts.push({ path: p, body: JSON.parse(req.postData()) });
		return route.fulfill({ status: 201, contentType: 'application/json', body: '{}' });
	});
	let cdn = 0;
	await ctx.route('https://cdn.emulatorjs.org/**', (route) => { cdn++; return route.fulfill({ status: 200, contentType: 'text/javascript', body: '' }); });
	const page = await ctx.newPage();
	await page.addInitScript(() => { try { localStorage.setItem('southland-gh', JSON.stringify({ token: 'tok-test', repo: 'stevenboudreaux/Houma-Mall-Rewind' })); } catch (e) {} });
	// the setup page, opened with an old link naming another system
	await page.goto(base + 'emu.html?setup=pc.video.62&sys=snes&title=' + encodeURIComponent('ORBIT RAIDER'));
	await page.waitForSelector('#setup:not([hidden])');
	const sysText = await page.textContent('#s-sys');
	check(/NES cabinet/.test(sysText) && !/Super/.test(sysText), 'the setup page says NES (' + sysText + ')');
	check(await page.getAttribute('#file', 'accept') === '.nes,.fds,.unf', 'the file picker accepts only .nes, .fds, .unf');
	check(/Nothing on this cabinet/.test(await page.textContent('#current')), 'an old non-NES entry counts as empty');
	if (shots) await page.screenshot({ path: path.join(shots, 'owner-arcade-nes-setup-phone.png') });
	const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'nes-'));
	const sfc = path.join(tmp, 'other.sfc'); fs.writeFileSync(sfc, Buffer.from('not a game'));
	await page.setInputFiles('#file', sfc);
	await page.click('#upload');
	check(/doesn't fit this cabinet/.test(await page.textContent('#msg')) && puts.length === 0, 'a Super NES file is refused, nothing uploaded');
	const nes = path.join(tmp, 'my_game.nes'); fs.writeFileSync(nes, Buffer.concat([Buffer.from('NES\x1a'), Buffer.alloc(16)]));
	await page.setInputFiles('#file', nes);
	await page.click('#upload');
	await page.waitForFunction(() => /Done|Not uploaded/.test(document.getElementById('msg').textContent), null, { timeout: 15000 });
	check(/Done/.test(await page.textContent('#msg')), 'an .nes file uploads (' + (await page.textContent('#msg')) + ')');
	const romPut = puts.find((p) => p.path.endsWith('/play/roms/my_game.nes'));
	const listPut = puts.find((p) => p.path.endsWith('/play/roms.json'));
	check(!!romPut, 'the file goes to play/roms/');
	const L = listPut ? JSON.parse(Buffer.from(listPut.body.content, 'base64').toString()) : { cabinets: {} };
	check(L.cabinets['pc.video.62'] && L.cabinets['pc.video.62'].core === 'nes' && L.cabinets['pc.video.62'].system === 'nes', 'the cabinet gets an NES entry');
	check(!L.cabinets['pc.video.03'] && L.cabinets['pc.video.37'], 'the list drops the old Genesis entry and keeps the NES one (' + Object.keys(L.cabinets).join(', ') + ')');
	if (shots) await page.screenshot({ path: path.join(shots, 'owner-arcade-nes-setup-done-phone.png') });
	// playing: an old Genesis entry has no game; an NES one starts the NES core
	await page.goto(base + 'emu.html?id=pc.video.03');
	await page.waitForFunction(() => document.getElementById('title').textContent !== '', null, { timeout: 10000 });
	check(/No game on this cabinet/.test(await page.textContent('#title')) && cdn === 0, 'a cabinet with an old non-NES entry has no game');
	await page.goto(base + 'emu.html?id=pc.video.37');
	await page.waitForFunction(() => window.EJS_core, null, { timeout: 10000 });
	check(await page.evaluate(() => window.EJS_core) === 'nes', 'an NES cabinet starts EmulatorJS with the nes core');
	fs.rmSync(tmp, { recursive: true });
	await browser.close();
	server.close();
	if (errors.length) { console.log('ARCADE NES WEBTEST FAILED: ' + JSON.stringify(errors)); process.exit(1); }
	console.log('ARCADE NES WEBTEST OK (' + oks + ' checks)');
})().catch((e) => { console.log('ARCADE NES WEBTEST FAILED: ' + e); process.exit(1); });
