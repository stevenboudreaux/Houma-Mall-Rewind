// OWNER (design/godot-owner-mode.md "Pictures"): the page's picture chooser (web/shell.html
// window.mallPictures.pick) in Chromium, without the game: a big picture chosen through the real file
// input comes back as a JPEG data URL at most 1024 px on its longer side, with its size; Cancel and
// "Original picture" answer as they should. No network.
//   node tools/qa/pictures_pick_webtest.js [shot.png]   -> PICTURES PICK WEBTEST OK (n checks)
'use strict';
const fs = require('fs');
const path = require('path');
const os = require('os');
const { chromium } = require('playwright');

const shell = fs.readFileSync(path.join(__dirname, '../../web/shell.html'), 'utf8');
const pubStart = shell.indexOf('function mallPublisher(');
const pubEnd = shell.indexOf('window.mallSigns = mallPublisher(', pubStart);
const code = shell.slice(pubStart, pubEnd) + '\n' + shell.slice(shell.indexOf('// PICTURES-BEGIN'), shell.indexOf('// PICTURES-END'));
const shot = process.argv[2] || '';

let oks = 0; const errors = [];
function check(ok, what) { console.error((ok ? 'ok   ' : 'FAIL ') + what); if (ok) oks++; else errors.push(what); }

(async () => {
	const browser = await chromium.launch();
	const page = await browser.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
	await page.setContent('<!doctype html><html><body style="margin:0;background:#333"><canvas id="canvas" width="390" height="844"></canvas><script>' + code + '</script></body></html>');
	// a 3000 x 2000 PNG made in the page
	const png = await page.evaluate(() => {
		const c = document.createElement('canvas'); c.width = 3000; c.height = 2000;
		const g = c.getContext('2d'); g.fillStyle = '#c03040'; g.fillRect(0, 0, 3000, 2000);
		g.fillStyle = '#ffd23c'; g.beginPath(); g.arc(1500, 1000, 600, 0, 7); g.fill();
		return c.toDataURL('image/png').split(',')[1];
	});
	const file = path.join(os.tmpdir(), 'pic-pick-test.png');
	fs.writeFileSync(file, Buffer.from(png, 'base64'));
	await page.evaluate(() => window.mallPictures.pick(JSON.stringify({ id: 'ad.gryders', title: 'Gryders ad', custom: true, max: 1024 })));
	check(await page.isVisible('#pic-pick'), 'the dialog opens over the game');
	check(await page.isDisabled('#pic-use'), '"Use this picture" waits for a picture');
	await page.setInputFiles('#pic-file', file);
	await page.waitForFunction(() => !document.getElementById('pic-use').disabled, null, { timeout: 15000 });
	if (shot) await page.screenshot({ path: shot });
	await page.click('#pic-use');
	const r = JSON.parse(await page.evaluate(() => window.mallPictures.take()));
	check(r.w === 1024 && r.h === 683, 'the picture is shrunk to 1024 px on its longer side (' + r.w + ' x ' + r.h + ')');
	check(/^data:image\/jpeg;base64,/.test(r.data), 'as a JPEG data URL');
	check(r.data.length < 1200000, 'under the size cap (' + Math.round(r.data.length / 1024) + ' KB of base64)');
	check(!(await page.isVisible('#pic-pick')), 'the dialog closes');
	// a small picture is not enlarged; Cancel and Original picture
	await page.evaluate(() => window.mallPictures.pick(JSON.stringify({ id: 'x', title: 'x', custom: false, max: 1024 })));
	check((await page.$$('#pic-pick button')).length === 2, 'no "Original picture" when the slot shows its original');
	await page.click('text=Cancel');
	check(await page.evaluate(() => window.mallPictures.take()) === '{"cancel":1}', 'Cancel answers cancel');
	await page.evaluate(() => window.mallPictures.pick(JSON.stringify({ id: 'x', title: 'x', custom: true, max: 1024 })));
	await page.click('text=Original picture');
	check(await page.evaluate(() => window.mallPictures.take()) === '{"reset":1}', '"Original picture" answers reset');
	await browser.close();
	fs.unlinkSync(file);
	if (errors.length) { console.log('PICTURES PICK WEBTEST FAILED: ' + JSON.stringify(errors)); process.exit(1); }
	console.log('PICTURES PICK WEBTEST OK (' + oks + ' checks)');
})().catch((e) => { console.log('PICTURES PICK WEBTEST FAILED: ' + e); process.exit(1); });
