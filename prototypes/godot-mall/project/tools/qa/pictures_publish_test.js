// OWNER (design/godot-owner-mode.md "Pictures"): window.mallPictures.publish() from web/shell.html
// against a mocked GitHub contents API (no network, never the live repo). Checks: each new picture is
// PUT as a JPEG under prototypes/godot-mall/play/posters/ with a content-hash name; posters.json is read
// live and merged (others' entries kept, "reset" ids removed) and written against the live sha; the
// same picture twice is not uploaded again; a refused token, a read-only token and a conflict end in
// an error status and leave the list alone.
//   node tools/qa/pictures_publish_test.js        -> PICTURES PUBLISH TEST OK (n checks)
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const shell = fs.readFileSync(path.join(__dirname, '../../web/shell.html'), 'utf8');
const pubStart = shell.indexOf('function mallPublisher(');
const pubEnd = shell.indexOf('window.mallSigns = mallPublisher(', pubStart);
const picStart = shell.indexOf('// PICTURES-BEGIN');
const picEnd = shell.indexOf('// PICTURES-END');
if (pubStart < 0 || picStart < 0 || picEnd < 0) { console.log('PICTURES PUBLISH TEST FAILED: blocks not found in shell.html'); process.exit(1); }
const code = shell.slice(pubStart, pubEnd) + '\n' + shell.slice(picStart, picEnd);

let oks = 0; const errors = [];
function check(ok, what) { console.error((ok ? 'ok   ' : 'FAIL ') + what); if (ok) oks++; else errors.push(what); }

// a tiny GitHub: files[path] = {content (base64), sha}
function makeGitHub(opts) {
	opts = opts || {};
	const files = {}; const calls = []; let n = 0;
	const json = (status, body) => Promise.resolve({ status, ok: status >= 200 && status < 300, json: () => Promise.resolve(body) });
	function fetch(url, init) {
		init = init || {};
		const u = new URL(url);
		const m = /^\/repos\/([^/]+\/[^/]+)\/contents\/(.+)$/.exec(u.pathname);
		const p = decodeURIComponent(m[2]).split('/').map(decodeURIComponent).join('/');
		const method = init.method || 'GET';
		calls.push({ method, repo: m[1], path: p, body: init.body ? JSON.parse(init.body) : null, auth: (init.headers || {}).Authorization });
		if ((init.headers || {}).Authorization !== 'Bearer ' + (opts.token || 'tok-good')) return json(401, {});
		if (method === 'GET') return files[p] ? json(200, { content: files[p].content, sha: files[p].sha }) : json(404, {});
		if (opts.readOnly) return json(403, {});
		const b = JSON.parse(init.body);
		if (opts.conflictOn === p) return json(409, {});
		if (files[p] && b.sha !== files[p].sha) return json(409, {});
		if (!files[p] && b.sha) return json(409, {});
		files[p] = { content: b.content, sha: 'sha' + (++n) };
		return json(files[p] ? 201 : 200, { content: { sha: files[p].sha } });
	}
	return { files, calls, fetch };
}

function sandbox(gh, store) {
	const ctx = {
		console, Promise, JSON, Math, Object, String, Uint8Array, TextEncoder, TextDecoder, URL, encodeURIComponent,
		atob: (s) => Buffer.from(s, 'base64').toString('binary'),
		btoa: (s) => Buffer.from(s, 'binary').toString('base64'),
		location: { hostname: 'stevenboudreaux.github.io', pathname: '/Houma-Mall-Rewind/' },
		localStorage: { getItem: (k) => (k in store ? store[k] : null), setItem: (k, v) => { store[k] = String(v); }, removeItem: (k) => { delete store[k]; } },
		prompt: () => null,
		fetch: gh.fetch,
		document: {},
	};
	ctx.window = ctx;
	vm.createContext(ctx);
	vm.runInContext(code, ctx);
	return ctx;
}
const dec = (b64) => Buffer.from(b64, 'base64');
const LIST = 'prototypes/godot-mall/play/posters.json';
// a real 1x1 JPEG
const JPEG = '/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/yQALCAABAAEBAREA/8wABgAQEAX/2gAIAQEAAD8A0s8g/9k=';

(async () => {
	// ---- 1. two new pictures and a reset, merged into a live list that has someone else's entry
	{
		const gh = makeGitHub();
		gh.files[LIST] = { content: Buffer.from(JSON.stringify({ pictures: { 'ad.tgmc': { file: 'posters/old.jpg', w: 10, h: 20 }, 'ad.saadis': { file: 'posters/s.jpg', w: 5, h: 5 } } })).toString('base64'), sha: 'live1' };
		const W = sandbox(gh, { 'southland-gh': JSON.stringify({ token: 'tok-good' }) });
		const draft = {
			'ad.gryders': { data: 'data:image/jpeg;base64,' + JPEG, w: 800, h: 1024 },
			'2026:f26_posters_lit@4.6,1.3,-87.1': { data: 'data:image/jpeg;base64,' + JPEG + 'AA', w: 1024, h: 600 },
			'ad.saadis': { reset: true },
		};
		await W.mallPictures.publish(JSON.stringify(draft));
		check(W.mallPictures.status === 'ok', 'publish: status ok (' + W.mallPictures.status + ')');
		const puts = gh.calls.filter((c) => c.method === 'PUT');
		const pics = puts.filter((c) => c.path.startsWith('prototypes/godot-mall/play/posters/'));
		check(pics.length === 2 && pics.every((c) => /\.jpg$/.test(c.path)), 'two pictures PUT as .jpg under play/posters/ (' + pics.map((c) => c.path).join(', ') + ')');
		check(pics.every((c) => c.repo === 'stevenboudreaux/Houma-Mall-Rewind' && c.body.branch === 'main'), 'to this repo\'s main branch');
		check(dec(pics[0].body.content).slice(0, 2).equals(Buffer.from([0xff, 0xd8])), 'the uploaded bytes are the JPEG itself (not a data URL)');
		check(pics.every((c) => /^[A-Za-z0-9._-]+-[0-9a-f]{8}\.jpg$/.test(path.basename(c.path))), 'file names are safe ids plus a content hash');
		const last = puts[puts.length - 1];
		check(last.path === LIST && last.body.sha === 'live1', 'posters.json is written last, against the live sha');
		const L = JSON.parse(dec(last.body.content).toString());
		check(L.pictures['ad.tgmc'] && L.pictures['ad.tgmc'].file === 'posters/old.jpg', 'someone else\'s entry is kept');
		check(!('ad.saadis' in L.pictures), 'a reset removes its entry');
		check(L.pictures['ad.gryders'] && L.pictures['ad.gryders'].w === 800 && L.pictures['ad.gryders'].h === 1024 && L.pictures['ad.gryders'].file === 'posters/' + path.basename(pics[0].path), 'a new picture is listed with its file and size');
		check(JSON.parse(W.mallPictures.published)['ad.gryders'] !== undefined, 'published carries the merged list for the game');
		check(gh.calls.every((c) => c.auth === 'Bearer tok-good'), 'every call uses the editor\'s saved token');
		// the same picture again: not uploaded twice
		const before = gh.calls.length;
		await W.mallPictures.publish(JSON.stringify({ 'ad.gryders': draft['ad.gryders'] }));
		const again = gh.calls.slice(before).filter((c) => c.method === 'PUT');
		check(W.mallPictures.status === 'ok' && again.length === 1 && again[0].path === LIST, 'the same picture again: only the list is written');
	}
	// ---- 2. no list yet: it is created
	{
		const gh = makeGitHub();
		const W = sandbox(gh, { 'southland-gh': JSON.stringify({ token: 'tok-good' }) });
		await W.mallPictures.publish(JSON.stringify({ 'ad.tgmc': { data: 'data:image/jpeg;base64,' + JPEG, w: 2, h: 3 } }));
		const L = gh.files[LIST] ? JSON.parse(dec(gh.files[LIST].content).toString()) : null;
		check(W.mallPictures.status === 'ok' && L && L.pictures['ad.tgmc'], 'no posters.json yet: it is created');
	}
	// ---- 3. errors
	{
		const gh = makeGitHub({ token: 'other' });
		const W = sandbox(gh, { 'southland-gh': JSON.stringify({ token: 'tok-good' }) });
		await W.mallPictures.publish(JSON.stringify({ 'ad.tgmc': { data: 'data:image/jpeg;base64,' + JPEG, w: 2, h: 3 } }));
		check(/token was refused/.test(W.mallPictures.status) && !gh.files[LIST], 'a refused token: error, nothing written (' + W.mallPictures.status + ')');
	}
	{
		const gh = makeGitHub({ readOnly: true });
		const W = sandbox(gh, { 'southland-gh': JSON.stringify({ token: 'tok-good' }) });
		await W.mallPictures.publish(JSON.stringify({ 'ad.tgmc': { data: 'data:image/jpeg;base64,' + JPEG, w: 2, h: 3 } }));
		check(/cannot write/.test(W.mallPictures.status), 'a read-only token: error (' + W.mallPictures.status + ')');
	}
	{
		const gh = makeGitHub({ conflictOn: LIST });
		const W = sandbox(gh, { 'southland-gh': JSON.stringify({ token: 'tok-good' }) });
		await W.mallPictures.publish(JSON.stringify({ 'ad.tgmc': { data: 'data:image/jpeg;base64,' + JPEG, w: 2, h: 3 } }));
		check(/someone else changed/.test(W.mallPictures.status) && !gh.files[LIST], 'a conflict on the list: error, list untouched (' + W.mallPictures.status + ')');
	}
	{
		const gh = makeGitHub();
		const W = sandbox(gh, {});
		await W.mallPictures.publish(JSON.stringify({ 'ad.tgmc': { data: 'data:image/jpeg;base64,' + JPEG, w: 2, h: 3 } }));
		check(W.mallPictures.status === 'error: no GitHub token' && gh.calls.length === 0, 'no saved token and none typed: nothing is sent');
	}
	// ---- 4. take() hands a dialog's answer over once
	{
		const W = sandbox(makeGitHub(), {});
		W.mallPictures.result = '{"cancel":1}';
		check(W.mallPictures.take() === '{"cancel":1}' && W.mallPictures.take() === '', 'take() hands the answer over once');
	}
	if (errors.length) { console.log('PICTURES PUBLISH TEST FAILED: ' + JSON.stringify(errors)); process.exit(1); }
	console.log('PICTURES PUBLISH TEST OK (' + oks + ' checks)');
})();
