// Packs on R2 (design/godot-build-hosting.md "Packs on R2"): where web/shell.html sends pack requests.
// Usage: node tests/unit/hosting/pack_base_test.js   (from the repo root; prints PACK BASE OK)
// The ?packs= checks matter for safety: a pack runs as code on the page, so only a build id is accepted.
const fs = require('fs');
const path = require('path');
const shell = fs.readFileSync(path.join(__dirname, '../../../prototypes/godot-mall/project/web/shell.html'), 'utf8');
const m = /const MALL_DESKTOP_SITE[\s\S]*?: ''\);\n/.exec(shell);
if (!m) { console.log('FAIL: no MALL_PACK_BASE block in web/shell.html'); process.exit(1); }
const R = (/const MALL_R2 = '([^']+)'/.exec(m[0]) || [])[1];
function base(search, host, pack, id) {
	const code = (id ? m[0].replace("const set = '';", "const set = '" + id + "';") : m[0]) + '\nMALL_PACK_BASE();';
	const location = { search: search, hostname: host };   // eslint-disable-line no-unused-vars
	const window = { __mallPack: pack };                    // eslint-disable-line no-unused-vars
	return eval(code);
}
let fails = 0;
function t(name, got, want) { if (got !== want) { fails++; console.log('FAIL ' + name + ': ' + JSON.stringify(got) + ', want ' + JSON.stringify(want)); } }
t('the bucket address is https', /^https:\/\/[a-z0-9-]+\.r2\.dev\/builds\/$/.test(R || ''), true);
t('local export: next to the page', base('', '127.0.0.1', 'desktop'), '');
t('github.io, no id, computer: the old second site', base('', 'stevenboudreaux.github.io', 'desktop'), '/Houma-Mall-Rewind-desktop/');
t('github.io, no id, phone: next to the page', base('', 'stevenboudreaux.github.io', 'mobile'), '');
t('a published id: the bucket', base('', 'stevenboudreaux.github.io', 'mobile', '20261104-0700-abc1234'), R + '20261104-0700-abc1234/');
t('?packs= picks another build', base('?packs=test-1', 'stevenboudreaux.github.io', 'desktop', 'pub'), R + 'test-1/');
t('?packs= works locally too', base('?packs=test-1', '127.0.0.1', 'desktop'), R + 'test-1/');
for (const bad of ['https://evil.example/x', '//evil.example', '../x', 'a/b', 'a b', '-x', 'a'.repeat(65), 'x%2F..']) {
	t('?packs=' + bad + ' refused', base('?packs=' + encodeURIComponent(bad), 'stevenboudreaux.github.io', 'mobile', 'pub'), R + 'pub/');
}
console.log(fails ? fails + ' FAILED' : 'PACK BASE OK');
process.exit(fails ? 1 : 0);
