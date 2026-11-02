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
      [ -s $lm.$f ] || { echo "warning: no $lm.$f: wing $w is not baked yet and ships unlit (allowed until its first bake; on the Mac: echo \"wing$w:day wing${w}_2026:day\" > .autobake)"; break; }
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
if [ "${DRY_RUN:-0}" = "1" ]; then echo "dry run: all checks passed; nothing published (room wings in the export:${ROOMS:- none})"; exit 0; fi
REPO=$(git rev-parse --show-toplevel)
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
# the room wings (S): their packs, and wings 4 / 5's lightmaps once baked
for w in $ROOMS; do
  cp "$SRC"/w$w.*.pck "$W/play/"; cp "$SRC"/w${w}y26.*.pck "$W/play/" 2>/dev/null || true
  cp wing${w}_day.* wing${w}_2026_day.* "$W/lightmaps/" 2>/dev/null || true
done
cp tex/standin/*.png tex/standin/*.stamp "$W/standin/"
cd "$W"
git init -q -b godot-build
git add -A
git -c user.name="Steven Boudreaux" -c user.email="steven_boudreaux@outlook.com" commit -q -m "$MSG"
git push -q --force "$(git -C "$REPO" remote get-url origin)" godot-build 2>&1 | grep -iv "moved\|new location\|github.com/stevenboudreaux\|^remote: *$\|GH001\|gh.io\|lfs\|recommended maximum" || true
echo "published $(git rev-parse --short HEAD)"
cd / && rm -rf "$W"
