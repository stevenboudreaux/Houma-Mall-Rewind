# Session handoff, Nov 16 2026: workstream SECRET-SCAN

Branch `ws/secret-scan` (from `ws/seamless-upfront` @ `74cef19`). Goal (Steven): "I want to ensure my secrets for
git and R2 aren't visible publicly in code." Nothing was uploaded, published, merged, force-pushed or rewritten.
No value was printed anywhere: findings below give the first 4 characters only.

## Result

**No secret found** in the repository's history, on the live site, or on the bucket's public side.

## What was scanned

- **Every branch on origin: 124** (`main`, `godot-build`, `refs`, `integration`, all `ws/*`, `claude/*`, `tmp/*`,
  `int-*`, demo branches …). **No tags exist.** Full history: a `--mirror` clone, then every large object fetched
  too (25 blobs over 10 MB: lightmaps, `play/*.desktop.pck`, `play/index.wasm`, two `.glb`, two `.mp4`), so
  nothing was skipped. **700 commits, 27,263 objects, 3.78 GB.**
- **Pass 1, own scanner** (every blob, commit message and tag object; raw bytes, binaries included):
  - exact match of the live `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY` from this environment, and of their
    first 16 characters (in case a value was cut or wrapped): **0 matches**;
  - patterns: `ghp_/gho_/ghs_/ghu_/ghr_`, `github_pat_`, AWS-style `AKIA…`, private key blocks,
    `secret_access_key` / `access_key_id` assignments, passwords in URLs, Google `AIza…` keys, Slack tokens,
    `ADMIN_KEY` assignments, quoted `token/secret/password/api_key` values, rclone `[remote] type = s3` sections.
- **Pass 2, standard scanners:** gitleaks 8.21.2 (`git log -p --all`: 583 commits with changes) → **no leaks**;
  trufflehog 3.88.0 (`--bare`, all refs, no verification: 473,377 chunks, 11.2 GB decoded) → 459 unverified hits,
  **all the "Box" detector** (see below).
- **File names** in all 15,106 paths ever committed: no `rclone*.conf`, `.env*`, `*.pem`, `*.key`, `id_rsa*`,
  `.netrc`, `credentials*`, `secrets*`, keystores. No Godot `script_encryption_key` or keystore password in any
  `export_presets.cfg` on any branch.

## Findings (all false positives)

| Where | Kind | First 4 | Verdict |
|---|---|---|---|
| `play/index.wasm` (blob `8f900d0`, godot-build history) | private-key-block ×7 | `----` | mbedTLS's PEM header strings compiled into the Godot engine; no key material |
| `apps-script/Code.gs`, all 3 versions (blobs `300ffa8`, `cc04794`, `ed95244`) | `ADMIN_KEY:"…"` | `PICK` | the placeholder (upper-case words only); the real passphrase lives only in the deployed script |
| `apps-script/Code.gs`, all 3 versions | `GITHUB_TOKEN:"…"` | `PAST` | the placeholder `PASTE_…` (no `ghp_` value anywhere in history) |
| 36 `prizes/box_*.png.import` and 166 hits in `play/w*.desktop.pck` | trufflehog "Box" | various | Godot's import cache names (`box_rc.png-<md5>.ctex`): the word "box" next to a 32-hex hash |

Public on purpose, not keys: the Cloudflare account id and the `pub-848b….r2.dev` host in
`design/godot-build-hosting.md` and `tools/publish_build.sh` (an account id alone grants nothing).

## What the public site and the bucket expose

`curl -I` (HEAD) for `rclone.conf`, `.rclone.conf`, `.env`, `.env.local`, `credentials.json`, `secrets.json`,
`id_rsa`, `.git/config`, `.git/HEAD`, `r2.key`, `key.pem`, `.netrc`, `.npmrc`, `config.json`,
`apps-script/Code.gs`, `.github/workflows/pages.yml` under the site root, `play/`, the old
`prototypes/godot-mall/play/`, the bucket root, `builds/` and the current build folder
(`builds/20261113-1915-df378f57/`, from the site's `r2-build.txt`): **96 of 96 answer 404.** The bucket root does
not list. The Pages workflow copies only the play build, `classic.html`, `review.html`, `photos*`, `pending*` and
`.nojekyll` to the site; source, tools and design notes are not deployed (the repo itself is public anyway).

`tools/publish_build.sh` was read, not changed: it reads `R2_*` by name into `RCLONE_CONFIG_R2_*` for rclone; no
`set -x`, no `env`/`printenv`, no `rclone config show`; nothing in it can echo a key.

## GitHub settings (read through the API)

Repository is **public**. **Secret scanning: on. Push protection: on.** Off: non-provider patterns, validity
checks, Dependabot security updates. GitHub's push protection knows provider formats (GitHub tokens, Cloudflare
API tokens …) but not R2's S3-style keys, which are bare hex; the new check covers those by the words around them.

## Guards added (commits on `ws/secret-scan`)

1. `2b2b622` **chore:** `.gitignore` (root) adds `rclone.conf`, `rclone*.conf`, `*.p12`, `*.pfx`, `*.keystore`,
   `*.jks`, `id_rsa*`, `id_ed25519*`, `id_ecdsa*`, `.netrc`, `.git-credentials`, `export_credentials.cfg` (it
   already had `.env`, `.env.*`, `*.pem`, `*.key`, `credentials.json`, `secrets.json`).
   `prototypes/godot-mall/project/.gitignore` repeats `rclone*.conf`, `.env*`, `*.pem`, `*.key`. No tracked file
   becomes ignored. No `*.conf` exists under `tools/`.
2. `a8484cc` **feat:** `.githooks/secret_check.py` + `.githooks/pre-commit` + `.github/workflows/secret-scan.yml`.
   - **Chosen: both a pre-commit hook and CI, one script.** The hook stops a key before it leaves the machine but
     is opt-in per clone (`git config core.hooksPath .githooks`; now in CLAUDE-CLOUD.md's setup); CI cannot be
     skipped and runs on every push to any branch and every pull request.
   - **Why it is cheap:** standard-library Python, nothing to install; it reads only the *added* lines of the new
     commits (and added file names). CI does a blob-less, sparse checkout (commits and trees only, plus
     `.githooks/`), so `main`'s 440 MB is never downloaded: a push takes ~5 s end to end, the check itself 0.3 s.
     The whole history of all 124 branches takes 47 s locally.
   - It never prints a value (first 4 characters and length only). A false positive passes with
     `secret-check: allow` on the line. It also refuses the live `$R2_*` / `$GITHUB_TOKEN` values when the
     environment holds them.
   - Gitleaks / trufflehog were not put in CI: they need a download per run, and on this repo they mostly add
     noise (trufflehog's 459 "Box" hits); GitHub's own scanning already covers provider formats.
3. `9876d64` **docs:** CLAUDE-CLOUD.md "Secrets" (where keys live, the names, never print, what to do on a
   finding) and `git config core.hooksPath .githooks` as step 0 of the fresh-workspace setup.
4. `42c3688` **fix:** the first CI run said "commits checked: 0" (an `--exclude` before `--remotes` must not carry
   `refs/remotes/`, so a new branch excluded itself). Reproduced locally (0 → 3), fixed; the second run checked 1
   commit. The new-branch path is verified locally only: the next new `ws/*` branch is its first live run.

## Tests

- **Clean:** current tree (`--tree HEAD`): none. All history, all branches (`--range --all`): none (0 false
  positives, so nothing needed an allow marker). This branch's commits: none (hook on each commit, and CI).
- **Planted (scratch repo in the session scratchpad, no remote, never pushed; random fake values):** a `ghp_`
  token, an R2-style 64-hex secret, an `AKIA` key, a password in a URL, an OpenSSH private key header, a 32-hex
  "r2 key id", and an `rclone.conf` → the pre-commit hook refused the commit (exit 1, 8 findings, all masked);
  the CI mode on a `--no-verify` commit failed the same way; a fake value placed in `$R2_SECRET_ACCESS_KEY` was
  caught as "the live value". A plain 64-hex hash with no credential word, a `"${R2_SECRET_ACCESS_KEY:?}"`
  reference and a line marked `secret-check: allow` passed. The "r2 key id" plant was missed on the first try;
  the credential-word list was widened and history re-checked clean.
- **The 8 headless suites** (Godot 4.7.2, fresh import of this branch): SHOP 200, CUCOS 89, FLAGS 31,
  INVENTORY 45, REDEMPTION 32, ECON 52, MENU UNIT 64, INT D49: **all OK**. (INT D49's log shows "Failed loading
  resource: tex/standin/…" because this session did not fetch the stand-in pictures from godot-build; the test
  still passes, as before.)

## What Steven must do himself

1. **Nothing urgent:** no key is exposed, so no rotation is needed because of this scan.
2. Optional, in the repo's Settings → Code security: turn on **"Non-provider patterns"** (catches generic
   passwords and private keys) and **"Validity checks"**; check the Security tab → Secret scanning for any alerts
   (the API here can read the settings but not the alert list).
3. On the Mac, once per clone: `git config core.hooksPath .githooks` (the hook is not automatic).
4. Keep the R2 token scoped to the one bucket, Object Read & Write; if it was made with "Admin" permissions,
   replacing it with a bucket-scoped one limits the damage of any future leak (not checked here: that needs the
   Cloudflare dashboard).
5. Merge: `.gitignore` and `CLAUDE-CLOUD.md` are shared files; this branch only adds clearly separated hunks.
   No game code, scenes, data, tests or export presets were touched; no wing needs a rebake.

## Scratch (not committed)

`.scratch/secret-scan/` holds the mirror (2.4 GB; delete it when done), the scanner logs (masked) and the gitleaks
/ trufflehog summaries. The one-off history scanner is in the session scratchpad, not the repo.
