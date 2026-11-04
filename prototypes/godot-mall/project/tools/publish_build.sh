#!/bin/bash
# usage: tools/publish_build.sh <builddir> "<commit message>"   (run from the project folder)
# Replaces the godot-build branch with this build and the project's current lightmaps, as one
# commit, and force-pushes it. Its workflow then asks main's Pages workflow to redeploy.
# <builddir> is an export from tools/export_web.sh (w1/w2/w3 .desktop.pck and .mobile.pck, ...;
# w3 is the outside, design/godot-exterior.md: its own day lightmap, no stand-in pictures).
# Old builds never pile up: see design/godot-build-hosting.md.
# Refuses to publish when either wing's stand-in pictures (tex/standin/from_w<n>_*.png) were not
# captured from that wing as it is now (tools/wing_hash.sh; design/godot-wings.md): run
# tools/capture_standin.sh <n> and export again.
# Workstream S (Nov 2 2026): the room wings 4-6 (4 Sears / Lynn's, 5 Dillard's level 1, 6 the cinema
# lobby; design/godot-wings.md "Wings 4-6"): expected in the export; 4 and 5 are checked like the other
# wings (their picture in the mall wing's opening, tools/capture_standin.sh 4 / 5) and may ship without
# a lightmap until their first bake on the Mac (a warning, not a refusal); 6 is never baked.
# DRY_RUN=1 tools/publish_build.sh <builddir> "msg": every check, then stop before anything is pushed.
set -e
SRC=$(realpath "$1"); MSG=$2
for w in 1 2; do for k in desktop mobile; do [ -s "$SRC/w$w.$k.pck" ] || { echo "not a wing export: $SRC (no w$w.$k.pck)"; exit 1; }; done; done
grep -q '"w1": {"desktop": [1-9]' "$SRC/index.html" || { echo "index.html has no pack sizes (export with tools/export_web.sh)"; exit 1; }
for w in 1 2; do for f in exr exr.import lmbake; do for m in night day; do [ -s wing${w}_$m.$f ] || { echo "missing wing${w}_$m.$f"; exit 1; }; done; done; done
for w in 1 2; do
  for m in night day; do [ -s tex/standin/from_w${w}_$m.png ] || { echo "no stand-in pictures of wing $w ($m): run tools/capture_standin.sh $w"; exit 1; }; done
  H=$(tools/wing_hash.sh $w); S=$(cat tex/standin/from_w$w.stamp 2>/dev/null || echo none)
  [ "$H" = "$S" ] || { echo "wing $w changed since its stand-in pictures were taken (stamp $S, now $H): run tools/capture_standin.sh $w, export, publish"; exit 1; }
  for k in desktop mobile; do [ "$SRC/w$((3-w)).$k.pck" -nt tex/standin/from_w${w}_night.png ] || { echo "the export is older than wing $w's stand-in pictures: export again"; exit 1; }; done
done
# the 2026 wings (tools/make_layout_2026.py), when the export has them: the same stand-in checks
if [ -s "$SRC/w1y26.desktop.pck" ]; then
  for w in 1 2; do
    for k in desktop mobile; do [ -s "$SRC/w${w}y26.$k.pck" ] || { echo "2026 export incomplete: no w${w}y26.$k.pck"; exit 1; }; done
    [ -s wing${w}_2026_day.lmbake ] || { echo "missing wing${w}_2026_day.lmbake"; exit 1; }
    [ -s tex/standin/y26_from_w${w}_day.png ] || { echo "no 2026 stand-in pictures of wing $w: run tools/capture_standin.sh $w 2026"; exit 1; }
    H=$(tools/wing_hash.sh $w 2026); S=$(cat tex/standin/y26_from_w$w.stamp 2>/dev/null || echo none)
    [ "$H" = "$S" ] || { echo "2026 wing $w changed since its stand-in pictures were taken (stamp $S, now $H): run tools/capture_standin.sh $w 2026, export, publish"; exit 1; }
    for k in desktop mobile; do [ "$SRC/w$((3-w))y26.$k.pck" -nt tex/standin/y26_from_w${w}_day.png ] || { echo "the export is older than 2026 wing $w's stand-in pictures: export again"; exit 1; }; done
  done
fi
# the room wings (S)
ROOMS=""
for w in 4 5 6; do
  if [ ! -s "$SRC/w$w.desktop.pck" ]; then echo "warning: the export has no wing $w (w$w.desktop.pck): export all wings (tools/export_web.sh) to ship it"; continue; fi
  ROOMS="$ROOMS $w"
  for k in desktop mobile; do [ -s "$SRC/w$w.$k.pck" ] || { echo "wing $w export incomplete: no w$w.$k.pck"; exit 1; }; done
  if [ -s "$SRC/w1y26.desktop.pck" ]; then for k in desktop mobile; do [ -s "$SRC/w${w}y26.$k.pck" ] || { echo "2026 export incomplete: no w${w}y26.$k.pck"; exit 1; }; done; fi
  [ "$w" = "6" ] && continue
  for lm in wing${w}_day wing${w}_2026_day; do
    for f in exr exr.import lmbake; do
      [ -s $lm.$f ] || { echo "warning: no $lm.$f: wing $w is not baked yet and ships unlit (allowed until its first bake: add \"wing$w:day wing${w}_2026:day\" to the Mac's .autobake jobs)"; break; }
    done
  done
  mw=$((w - 3))
  for y in 1995 2026; do
    P=from_w; H=$(tools/wing_hash.sh $w); [ "$y" = "2026" ] && { P=y26_from_w; H=$(tools/wing_hash.sh $w 2026); }
    [ -s tex/standin/${P}${w}_day.png ] || { echo "no picture of wing $w ($y) for wing $mw's opening: run tools/capture_standin.sh $w $( [ $y = 2026 ] && echo 2026)"; exit 1; }
    S=$(cat tex/standin/${P}$w.stamp 2>/dev/null || echo none)
    [ "$H" = "$S" ] || { echo "wing $w ($y) changed since its picture was taken (stamp $S, now $H): run tools/capture_standin.sh $w $( [ $y = 2026 ] && echo 2026), then tools/capture_standin.sh $mw $( [ $y = 2026 ] && echo 2026), export, publish"; exit 1; }
    Y=""; [ "$y" = "2026" ] && Y=y26
    for k in desktop mobile; do [ "$SRC/w$mw$Y.$k.pck" -nt tex/standin/${P}${w}_day.png ] || { echo "the export is older than wing $w's ($y) picture: export again"; exit 1; }; done
  done
done
# Two sites (Nov 3 2026, design/godot-build-hosting.md "Two sites"): a Pages site may hold 1 GB. The main
# site carries the phone packs and the rest of play/, the second site the computer packs; each must fit
# (0.95 GB here, for main's own files and headroom).
# CHARS (Nov 3 2026, "Shared packs"): the shared packs (items, chars, chars_<map>) count too, and every pack
# must stay under GitHub's 100 MiB file limit; the shared packs listed in index.html must be in the export.
SHARED=$(python3 -c "import re,sys,json; s=open(sys.argv[1]).read(); m=re.search(r'const SHARED_PACKS = (.*); // SHARED_PACKS', s); d=json.loads(m.group(1)) if m else {}; print(' '.join(n for n,e in d.items() if e.get('desktop')))" "$SRC/index.html")
for n in $SHARED; do for k in desktop mobile; do [ -s "$SRC/$n.$k.pck" ] || { echo "index.html lists the shared pack $n, the export has no $n.$k.pck"; exit 1; }; done; done
# Packs on R2 (Nov 4 2026, design/godot-build-hosting.md "Packs on R2"), the default: every pack (both kinds)
# and the page go to the Cloudflare R2 bucket under builds/<id>/; godot-build keeps the page (with that id
# written in), the lightmaps and the stand-ins, no packs. No Pages size limit applies to the packs any more.
# R2=0: the old two sites (the computer packs on the desktop repo's site), for a rollback.
# R2 needs rclone and either an "r2" remote (rclone config, as on the Air) or R2_ACCESS_KEY_ID,
# R2_SECRET_ACCESS_KEY and R2_ENDPOINT in the environment (a cloud session's secrets), and the network must
# reach *.r2.cloudflarestorage.com and *.r2.dev.
# UPLOAD_ONLY=1: upload and check this build, print where to play it, and stop: nothing on GitHub changes.
# BUILD_ID=<id> names the folder (default <UTC date-time>-<short commit>); KEEP=<n> builds are kept (3).
R2=${R2:-1}; R2_BUCKET=${R2_BUCKET:-houma-mall-rewind}
R2_PUBLIC=${R2_PUBLIC_TEST:-https://pub-848b5102ea0e4d78999797a799545451.r2.dev}   # must match web/shell.html MALL_R2 (R2_PUBLIC_TEST: tests only)
PAGE_ORIGIN=${PAGE_ORIGIN_TEST:-https://stevenboudreaux.github.io}
REST=$(find "$SRC" -maxdepth 1 -type f ! -name '*.pck' -exec cat {} + | wc -c)
if [ "$R2" = "1" ]; then
  echo "R2: packs $(( $(cat "$SRC"/*.pck | wc -c) / 1000000 )) MB to the bucket; the site keeps $(( REST / 1000000 )) MB of page"
  [ "$REST" -lt 950000000 ] || { echo "the page files alone would be over GitHub Pages' 1 GB"; exit 1; }
  grep -q "const set = ''; // MALL_R2_BUILD" "$SRC/index.html" || { echo "index.html has no MALL_R2_BUILD line (export again from a web/shell.html with Packs on R2)"; exit 1; }
  command -v rclone >/dev/null || { echo "R2: rclone is not installed (curl https://rclone.org/install.sh | sudo bash)"; exit 1; }
  if [ -n "${R2_ACCESS_KEY_ID:-}" ]; then
    export RCLONE_CONFIG_R2_TYPE=s3 RCLONE_CONFIG_R2_PROVIDER=Cloudflare RCLONE_CONFIG_R2_ACL=private RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true \
      RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID" RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="${R2_SECRET_ACCESS_KEY:?}" RCLONE_CONFIG_R2_ENDPOINT="${R2_ENDPOINT:?}"
  fi
  rclone lsf "r2:$R2_BUCKET/" --max-depth 1 >/dev/null 2>&1 || { echo "R2: cannot reach r2:$R2_BUCKET (no 'r2' rclone remote, no R2_* secrets, or the network blocks *.r2.cloudflarestorage.com)"; exit 1; }
  CODE=$(curl -sS -m 30 -o /dev/null -w '%{http_code}' "$R2_PUBLIC/" 2>/dev/null || true)
  [ "$CODE" = "404" ] || [ "$CODE" = "200" ] || { echo "R2: the public URL $R2_PUBLIC does not answer (got '${CODE:-nothing}'; the network may block *.r2.dev)"; exit 1; }
else
  # Two sites (Nov 3 2026, design/godot-build-hosting.md "Two sites"): a Pages site may hold 1 GB. The main
  # site carries the phone packs and the rest of play/, the second site the computer packs; each must fit
  # (0.95 GB here, for main's own files and headroom). Every pack must stay under GitHub's 100 MiB file limit.
  for f in "$SRC"/*.pck; do [ "$(stat -c %s "$f")" -lt 104857600 ] || { echo "$(basename "$f") is over GitHub's 100 MiB file limit: it cannot be pushed"; exit 1; }; done
  DESK=$(cat "$SRC"/*.desktop.pck | wc -c); MOB=$(cat "$SRC"/*.mobile.pck | wc -c)
  echo "sites: main $(( (MOB + REST) / 1000000 )) MB (phone packs + page), desktop $(( DESK / 1000000 )) MB (computer packs); each must stay under 950"
  [ $((MOB + REST)) -lt 950000000 ] || { echo "the main site would be over GitHub Pages' 1 GB: make the phone packs smaller first"; exit 1; }
  [ "$DESK" -lt 950000000 ] || { echo "the desktop site would be over GitHub Pages' 1 GB: make the computer packs smaller first"; exit 1; }
fi
if [ "${DRY_RUN:-0}" = "1" ]; then echo "dry run: all checks passed; nothing published (room wings in the export:${ROOMS:- none})"; exit 0; fi
REPO=$(git rev-parse --show-toplevel)
if [ "$R2" = "1" ]; then
  ID=${BUILD_ID:-$(date -u +%Y%m%d-%H%M)-$(git -C "$REPO" rev-parse --short HEAD)}
  echo "$ID" | grep -Eq '^[a-z0-9][a-z0-9._-]{0,63}$' || { echo "R2: build id '$ID' is not [a-z0-9._-] (web/shell.html refuses others)"; exit 1; }
  # the packs, then the page files (so the folder plays on its own: $R2_PUBLIC/builds/<id>/index.html)
  rclone copy "$SRC" "r2:$R2_BUCKET/builds/$ID/" --include "*.pck" --include "index.*" --transfers 4 --stats 60s --stats-one-line -v 2>&1 \
    | grep -E "ERROR|Transferred:.*%|Failed" || true
  # every file is there at its size (a failed or cut-off upload stops the publish here)
  rclone lsjson "r2:$R2_BUCKET/builds/$ID/" > "$SRC/.r2-listing.json" || { echo "R2: cannot list builds/$ID"; exit 1; }
  python3 - "$SRC" "$SRC/.r2-listing.json" <<'PY' || { echo "R2: the bucket does not hold this build whole: not published"; exit 1; }
import json, os, sys
src, listing = sys.argv[1], sys.argv[2]
remote = {e["Name"]: e["Size"] for e in json.load(open(listing))}
bad = [f for f in sorted(os.listdir(src)) if (f.endswith(".pck") or f.startswith("index.")) and os.path.isfile(os.path.join(src, f))
       and remote.get(f) != os.path.getsize(os.path.join(src, f))]
for f in bad: print("  ", f, "local", os.path.getsize(os.path.join(src, f)), "bucket", remote.get(f))
sys.exit(1 if bad else 0)
PY
  rm -f "$SRC/.r2-listing.json"
  # the public URL serves it to the game's page (CORS), byte 0 of the first wing's phone pack
  H=$(curl -sS -m 60 -D - -o /dev/null -r 0-0 -H "Origin: $PAGE_ORIGIN" "$R2_PUBLIC/builds/$ID/w1.mobile.pck" 2>&1 | tr -d '\r')
  echo "$H" | grep -Eq '^HTTP/[0-9.]+ 20[06]' || { echo "R2: $R2_PUBLIC/builds/$ID/w1.mobile.pck is not served:"; echo "$H" | head -3; exit 1; }
  echo "$H" | grep -iq "^access-control-allow-origin: \(\*\|$PAGE_ORIGIN\)" || { echo "R2: no CORS for $PAGE_ORIGIN (the bucket's CORS policy, design/godot-build-hosting.md \"Packs on R2\")"; exit 1; }
  echo "R2: builds/$ID uploaded and served"
  if [ "${UPLOAD_ONLY:-0}" = "1" ]; then
    echo "upload only: play it at $R2_PUBLIC/builds/$ID/index.html, or with the live page at $PAGE_ORIGIN/Houma-Mall-Rewind/?packs=$ID (the live page's own code). Nothing on GitHub changed."
    exit 0
  fi
fi
W=$(mktemp -d)
git -C "$REPO" fetch -q origin godot-build
git -C "$REPO" archive origin/godot-build README.md .github | tar -x -C "$W"
mkdir -p "$W/play" "$W/lightmaps" "$W/standin"
cp "$SRC"/index.* "$SRC"/w1.*.pck "$SRC"/w2.*.pck "$W/play/"
cp "$SRC"/w1y26.*.pck "$SRC"/w2y26.*.pck "$W/play/" 2>/dev/null || true
if [ -s "$SRC/w3.desktop.pck" ]; then
  [ -s "$SRC/w3.mobile.pck" ] || { echo "outside export incomplete: no w3.mobile.pck"; exit 1; }
  [ -s wing3_day.lmbake ] || { echo "missing wing3_day.lmbake (bake the outside)"; exit 1; }
  cp "$SRC"/w3.*.pck "$W/play/"
  cp wing3_day.* "$W/lightmaps/"
  # the 2026 outside (Workstream F, Nov 1 2026) when it was exported and baked
  if [ -s "$SRC/w3y26.desktop.pck" ]; then
    [ -s "$SRC/w3y26.mobile.pck" ] || { echo "2026 outside export incomplete: no w3y26.mobile.pck"; exit 1; }
    [ -s wing3_2026_day.lmbake ] || { echo "missing wing3_2026_day.lmbake (bake the 2026 outside)"; exit 1; }
    cp "$SRC"/w3y26.*.pck "$W/play/"
    cp wing3_2026_day.* "$W/lightmaps/"
  fi
fi
cp wing1_night.* wing1_day.* wing2_night.* wing2_day.* "$W/lightmaps/"
cp wing1_2026_day.* wing2_2026_day.* "$W/lightmaps/" 2>/dev/null || true
# CHARS: the shared packs (the desktop site's workflow copies every *.desktop.pck, main's drops them)
for n in $SHARED; do cp "$SRC"/$n.*.pck "$W/play/"; done
# the room wings (S): their packs, and wings 4 / 5's lightmaps once baked
for w in $ROOMS; do
  cp "$SRC"/w$w.*.pck "$W/play/"; cp "$SRC"/w${w}y26.*.pck "$W/play/" 2>/dev/null || true
  cp wing${w}_day.* wing${w}_2026_day.* "$W/lightmaps/" 2>/dev/null || true
done
cp tex/standin/*.png tex/standin/*.stamp "$W/standin/"
if [ "$R2" = "1" ]; then
  # Packs on R2: the packs are in the bucket, not here; the page names their folder
  rm -f "$W"/play/*.pck
  sed -i "s#const set = ''; // MALL_R2_BUILD#const set = '$ID'; // MALL_R2_BUILD#" "$W/play/index.html"
  [ "$(grep -c "const set = '$ID'; // MALL_R2_BUILD" "$W/play/index.html")" = "1" ] || { echo "R2: could not write the build id into play/index.html"; exit 1; }
  echo "$ID" > "$W/play/r2-build.txt"
fi
cd "$W"
git init -q -b godot-build
git add -A
export GIT_AUTHOR_NAME="Steven Boudreaux" GIT_AUTHOR_EMAIL="steven_boudreaux@outlook.com" GIT_COMMITTER_NAME="Steven Boudreaux" GIT_COMMITTER_EMAIL="steven_boudreaux@outlook.com"
git commit -q -m "$MSG"
B=$(git rev-parse HEAD)
# Demo 49b (Nov 3 2026): a 1 GB push fails with a 502, and the old `| grep ... || true` hid that and
# printed "published" anyway. Now the build goes up in pieces of about PIECE_MB (120) through one
# temporary branch, tmp/publish (each push carries only the new files), then godot-build is forced, which
# sends only the commit, and the remote ref is read back before anything is called published.
# GitHub redirects the old mixed-case URL ("moved"): the lowercase one is used.
ORIGIN=${PUBLISH_ORIGIN_TEST:-$(git -C "$REPO" remote get-url origin | tr 'A-Z' 'a-z' | sed 's/\.git$//')}   # PUBLISH_ORIGIN_TEST: tests only
PIECE=$(( ${PIECE_MB:-120} * 1000000 ))
push_ref() { # <commit> <branch>: force-push, then confirm the remote has it
  local out; out=$(git push -q --force "$ORIGIN" "$1:refs/heads/$2" 2>&1) || { echo "$out" | grep -iv "moved\|new location\|^remote: *$\|GH001\|gh.io\|lfs\|recommended maximum"; echo "push of $2 failed"; return 1; }
  local r; r=$(git ls-remote "$ORIGIN" "refs/heads/$2" | cut -f1)
  [ "$r" = "$1" ] || { echo "after the push, $2 on GitHub is ${r:-missing}, not $1"; return 1; }
}
export GIT_INDEX_FILE="$W/.git/piece-index"
rm -f "$GIT_INDEX_FILE"; SUM=0; N=0
while IFS= read -r -d '' f; do
  git update-index --add "$f"
  SUM=$(( SUM + $(stat -c %s "$f") ))
  if [ $SUM -ge $PIECE ]; then
    N=$((N + 1)); C=$(git commit-tree "$(git write-tree)" -m "piece $N of $MSG")
    echo "piece $N: $(( SUM / 1000000 )) MB"; push_ref "$C" tmp/publish || exit 1; SUM=0
  fi
done < <(find . -path ./.git -prune -o -type f -print0 | sort -z)
unset GIT_INDEX_FILE
push_ref "$B" godot-build || exit 1
git push -q "$ORIGIN" --delete tmp/publish 2>/dev/null || echo "note: could not delete tmp/publish on GitHub (Steven can)"
echo "published $(git rev-parse --short HEAD)"
cd / && rm -rf "$W"
if [ "$R2" = "1" ]; then
  echo "packs: $R2_PUBLIC/builds/$ID/ (main's Pages workflow deploys the page; the desktop repo is no longer used)"
  # keep the newest KEEP builds (the folders sort by date), never the one just published
  OLD=$(rclone lsf --dirs-only "r2:$R2_BUCKET/builds/" | sed 's#/$##' | sort | head -n -"${KEEP:-3}")
  for d in $OLD; do [ "$d" = "$ID" ] || { rclone purge "r2:$R2_BUCKET/builds/$d" && echo "R2: removed the old build $d"; }; done
  exit 0
fi
# the second site: one commit (its workflow and the build's name) replaces the desktop repo's main; the push
# starts its Pages workflow, which copies the computer packs from godot-build ("Two sites")
D=$(echo "${DESKTOP_REPO:-https://github.com/stevenboudreaux/houma-mall-rewind-desktop}" | tr 'A-Z' 'a-z')
W=$(mktemp -d); mkdir -p "$W/.github/workflows"
cp "$REPO/prototypes/godot-mall/project/tools/desktop_site/pages.yml" "$W/.github/workflows/pages.yml"
cp "$REPO/prototypes/godot-mall/project/tools/desktop_site/README.md" "$W/README.md"
echo "$B" > "$W/build.txt"
cd "$W"
git init -q -b main
git add -A
git commit -q -m "computer packs of $MSG"
ORIGIN=$D; push_ref "$(git rev-parse HEAD)" main || { echo "the desktop repo was NOT updated: godot-build is $B, push build.txt there by hand"; exit 1; }
echo "desktop site: asked to deploy the computer packs of $(echo $B | cut -c1-7)"
cd / && rm -rf "$W"
