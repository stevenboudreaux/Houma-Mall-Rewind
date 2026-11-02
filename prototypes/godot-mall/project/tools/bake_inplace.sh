#!/bin/bash
# usage: tools/bake_inplace.sh <wing> [mode] [--year=2026] [--dry-run] [--make-swap] [--no-build]
#   (from the project folder; godot 4.7.2 on PATH)
#   <wing>  1, 2 or 3 (3 = the outside, 1995 only)      [mode]  day (default) | night | fastday | fastnight
#           4 or 5 (workstream S, Nov 2 2026: Sears / Lynn's, Dillard's level 1; their own wings, both
#           years, day only); 6 (the cinema lobby) is an unlit placeholder and is never baked
#           ("fast" = Medium quality, the cloud's quick bake; the shipped Ultra bake is done on Steven's Mac)
#
# Bakes one wing's lightmap on a Linux box, the way Demo 45/46 did by hand (workstream H, Nov 1 2026;
# design/godot-performance.md "Baking on Linux"), and leaves the work tree exactly as it was except for
# the new lightmap files:
#   0. checks:   godot, xvfb-run, a software Vulkan driver (lavapipe, mesa-vulkan-drivers), >= 12 GB
#                swap (Ultra/High bakes of a wing are killed by the OOM killer without it; --make-swap
#                creates /swapfile, needs root), the stand-in pictures and the other lightmaps from
#                godot-build (CLAUDE-CLOUD.md setup step 3), a finished import, and no uncommitted
#                changes to tracked files under the project (they could not be told apart from the
#                editor's side effects)
#   1. build:    tools/build_mall.gd for the wing, so the bake sees the scene in build form (--no-build skips)
#   2. bake:     the editor under xvfb (OpenGL, the project is GL Compatibility) with addons/autobake
#                (AUTOBAKE="<scene>:<mode>"); the lightmapper makes its own Vulkan device: lavapipe
#   3. revert:   the editor's side effects, with `git checkout`: the .import files it flips
#                (detect_3d turns textures to VRAM compression: ~206 on the Mac for Demo 45/46, 449 on
#                a fresh Linux box on Nov 1), project.godot, gen/env_day.tres and env_night.tres, the
#                gen/ meshes and the scene it re-saved with its own resource ids (design/godot-wings.md:
#                a scene saved by the editor makes the web export leave out meshes). Untracked files it
#                created are listed and removed.
#   4. import:   drop the stale .godot/imported copy of the new .exr, then `godot --headless --import`
#   5. rebuild:  the wing again, so the scene is in build form and points at the new .lmbake
#   6. keep:     only <scene>_<m>.exr, .exr.import, .lmbake are new; every other lightmap file is
#                put back from the copy taken before the bake
# --dry-run runs every step except the bake itself (and step 6 then has nothing new to keep).
# Tested Nov 1 2026 on the 4-CPU, 15 GB cloud box: wing 3 fastday (Medium), 12 GB swap, editor 434 s,
# everything reverted, only wing3_day.exr/.lmbake new (production/qa/evidence/wsH-bake-inplace-*).
# Never commit the lightmaps: they go to godot-build with tools/publish_build.sh (integration session).
set -e
W=""; MODE=day; YEAR=""; DRY=0; MKSWAP=0; BUILD=1
for a in "$@"; do
  case "$a" in
    --dry-run) DRY=1 ;; --make-swap) MKSWAP=1 ;; --no-build) BUILD=0 ;;
    --year=2026) YEAR=2026 ;;
    [123]) W=$a ;;
    day|night|fastday|fastnight) MODE=$a ;;
    *) echo "unknown argument: $a"; exit 2 ;;
  esac
done
[ -n "$W" ] || { sed -n 2,6p "$0"; exit 2; }
[ -f project.godot ] || { echo "run from the project folder"; exit 2; }
SCENE=wing$W; [ "$YEAR" = 2026 ] && SCENE=wing${W}_2026
[ "$YEAR" = 2026 ] && [ "$W" = 3 ] && { echo "the outside has no 2026 scene"; exit 2; }
[ "$W" = 6 ] && { echo "wing 6 (the cinema lobby placeholder) is never baked: its lights are real-time"; exit 2; }
M=${MODE#fast}
LM="${SCENE}_$M"
P=$(pwd); REL=$(git rev-parse --show-prefix); REL=${REL%/}
LOG=${BAKE_LOG:-/tmp/bake_inplace_$SCENE}
mkdir -p "$LOG"
# tracked files changed under the project / untracked files, as paths relative to the project
changed() { git status --porcelain --untracked-files=no -- . | cut -c4- | sed "s|^$REL/||" | sort; }
untracked() { git status --porcelain --untracked-files=all -- . | grep '^??' | cut -c4- | sed "s|^$REL/||" | sort; }
say() { echo "[bake_inplace $(date +%H:%M:%S)] $*"; }

# ---- 0. checks
command -v godot >/dev/null || { echo "godot is not on PATH (CLAUDE-CLOUD.md setup step 1)"; exit 1; }
godot --version | grep -q '^4\.7\.2' || echo "warning: not Godot 4.7.2 ($(godot --version))"
command -v xvfb-run >/dev/null || { echo "xvfb-run missing: apt-get install -y xvfb"; exit 1; }
if ! ls /usr/share/vulkan/icd.d/lvp_icd*.json >/dev/null 2>&1 && ! ls /usr/share/vulkan/icd.d/*.json >/dev/null 2>&1; then
  echo "no Vulkan driver: apt-get install -y mesa-vulkan-drivers (lavapipe; the lightmapper runs on Vulkan compute)"
  [ $DRY = 1 ] || exit 1
fi
SWAP_KB=$(awk 'NR>1 {s+=$3} END {print s+0}' /proc/swaps)
if [ "$SWAP_KB" -lt 12000000 ]; then
  if [ $MKSWAP = 1 ]; then
    say "making a 12 GB swap file (/swapfile)"
    fallocate -l 12G /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null && swapon /swapfile \
      || { echo "could not enable swap (a container may not allow swapon); bakes above Medium may be OOM-killed"; [ $DRY = 1 ] || [ "${MODE#fast}" != "$MODE" ] || exit 1; }
  else
    echo "only $((SWAP_KB / 1024)) MB swap: wing bakes OOM without ~12 GB (sudo fallocate -l 12G /swapfile; chmod 600; mkswap; swapon; or --make-swap)"
    [ $DRY = 1 ] || [ "${MODE#fast}" != "$MODE" ] || exit 1
    echo "  continuing: a fast (Medium) bake usually fits in RAM"
  fi
fi
if [ "$W" != 3 ]; then
  O=$((3 - W)); PRE=from_w$O; [ "$YEAR" = 2026 ] && PRE=y26_from_w$O
  ls tex/standin/${PRE}_*.png >/dev/null 2>&1 || { echo "no stand-in pictures tex/standin/${PRE}_*.png: CLAUDE-CLOUD.md setup step 3 (git archive origin/godot-build lightmaps standin)"; exit 1; }
fi
for f in wing1_day wing2_day wing3_day; do
  [ -s $f.lmbake ] || echo "warning: $f.lmbake missing (setup step 3); the other wings' exports will lack lighting"
done
[ -d .godot/imported ] && [ "$(ls .godot/imported | wc -l)" -gt 500 ] || { echo "the project is not imported: godot --headless --path . --import (CLAUDE-CLOUD.md setup step 4)"; exit 1; }
DIRTY=$(changed | wc -l)
if [ "$DIRTY" -gt 0 ]; then
  echo "tracked files under $REL have uncommitted changes; commit or stash them first:"; git status --short --untracked-files=no -- . | head; exit 1
fi

# ---- 1. build
if [ $BUILD = 1 ]; then
  say "1. build $SCENE"
  ARGS="--wing=$W"; [ "$YEAR" = 2026 ] && ARGS="$ARGS --year=2026"
  timeout 1200 godot --headless --path . --script res://tools/build_mall.gd -- $ARGS > "$LOG/build1.log" 2>&1 || true
  grep -q "BUILD OK" "$LOG/build1.log" || { echo "build failed: $LOG/build1.log"; exit 1; }
  # building rewrites tracked generated files (gen/, the scene); those are the wing's real state, keep them
  changed > "$LOG/built.files"
  say "   build changed $(wc -l < "$LOG/built.files") tracked files (kept)"
else
  : > "$LOG/built.files"
fi
untracked > "$LOG/untracked.before"
# what the editor must not be allowed to change after the build: the snapshot to return to
SNAP=$(mktemp -d); tar -cf "$SNAP/built.tar" -T "$LOG/built.files" 2>/dev/null || true

# ---- lightmaps before: every lightmap file, to put back all but the new one
mkdir -p "$SNAP/lm"
for f in wing*_day.* wing*_night.* main_*.exr main_*.lmbake main_*.exr.import; do [ -e "$f" ] && cp -p "$f" "$SNAP/lm/"; done
md5sum wing*_day.* wing*_night.* 2>/dev/null | sort -k2 > "$LOG/lightmaps.before" || true

# ---- 2. bake
if [ $DRY = 1 ]; then
  say "2. DRY RUN: would bake $SCENE:$MODE  (AUTOBAKE=\"$SCENE:$MODE\" xvfb-run -a godot --editor --path . --rendering-driver opengl3)"
else
  say "2. bake $SCENE:$MODE (software Vulkan: ~10 min for a wing at Medium, much longer at Ultra)"
  rm -f .autobake_done
  T0=$(date +%s)
  AUTOBAKE="$SCENE:$MODE" timeout ${BAKE_TIMEOUT:-14400} xvfb-run -a -s "-screen 0 1280x720x24" \
    godot --editor --path . --rendering-driver opengl3 > "$LOG/bake.log" 2>&1 || true
  say "   editor exited after $(( $(date +%s) - T0 )) s: $(cat .autobake_done 2>/dev/null || echo 'no .autobake_done')"
  grep -q "^$SCENE:$MODE ok" .autobake_done 2>/dev/null || { echo "bake failed: $LOG/bake.log (OOM? dmesg | grep -i kill)"; BAKE_FAILED=1; }
  rm -f .autobake_done
fi

# ---- 3. revert the editor's side effects
say "3. revert the editor's side effects"
changed > "$LOG/after_bake.files"
comm -23 "$LOG/after_bake.files" "$LOG/built.files" > "$LOG/editor_changed.files"
N_IMP=$(grep -c '\.import$' "$LOG/editor_changed.files" || true)
say "   the editor changed $(wc -l < "$LOG/editor_changed.files") tracked files ($N_IMP .import flips): $LOG/editor_changed.files"
if [ -s "$LOG/editor_changed.files" ]; then
  (cd "$(git rev-parse --show-toplevel)" && sed "s|^|$REL/|" "$LOG/editor_changed.files" | xargs -r git checkout --)
fi
# files that were changed by the build and then re-saved by the editor (the scene): back to the build's copy
[ -s "$SNAP/built.tar" ] && tar -xf "$SNAP/built.tar"
untracked > "$LOG/untracked.after" || true
comm -13 "$LOG/untracked.before" "$LOG/untracked.after" | grep -v -E "^${SCENE}_$M\.(exr|exr\.import|lmbake)$" > "$LOG/editor_new.files" || true
if [ -s "$LOG/editor_new.files" ]; then
  say "   removing $(wc -l < "$LOG/editor_new.files") files the editor created: $LOG/editor_new.files"
  xargs -r rm -f < "$LOG/editor_new.files"
fi

# ---- 4. import
say "4. import"
rm -f .godot/imported/${LM}.exr-*
timeout 3600 godot --headless --path . --import > "$LOG/import.log" 2>&1 || true

# ---- 5. rebuild
if [ $BUILD = 1 ]; then
  say "5. rebuild $SCENE in build form"
  timeout 1200 godot --headless --path . --script res://tools/build_mall.gd -- $ARGS > "$LOG/build2.log" 2>&1 || true
  grep -q "BUILD OK" "$LOG/build2.log" || { echo "rebuild failed: $LOG/build2.log"; exit 1; }
fi
# the import can flip .import files too (none expected headless): revert anything not from the build
changed | comm -23 - "$LOG/built.files" > "$LOG/import_changed.files"
if [ -s "$LOG/import_changed.files" ]; then
  say "   reverting $(wc -l < "$LOG/import_changed.files") files changed by the import/rebuild beyond the first build"
  (cd "$(git rev-parse --show-toplevel)" && sed "s|^|$REL/|" "$LOG/import_changed.files" | xargs -r git checkout --)
fi

# ---- 6. keep only the new lightmap
say "6. keep only ${LM}.{exr,exr.import,lmbake}"
for f in "$SNAP"/lm/*; do
  b=$(basename "$f")
  case "$b" in ${LM}.exr|${LM}.exr.import|${LM}.lmbake) [ $DRY = 1 ] && cp -p "$f" "$b" ;; *) cp -p "$f" "$b" ;; esac
done
md5sum wing*_day.* wing*_night.* 2>/dev/null | sort -k2 > "$LOG/lightmaps.after" || true
diff "$LOG/lightmaps.before" "$LOG/lightmaps.after" | grep '^>' | sed 's/^> /   new: /' || say "   no lightmap changed"
rm -rf "$SNAP"
LEFT=$(changed | comm -23 - "$LOG/built.files" | wc -l)
say "done. tracked changes beyond the build: $LEFT (expect 0). Next: capture_standin.sh for wings that see this one, export, check."
# every build gives the scene's nodes new random unique_ids: if the wing itself did not change, the
# rebuilt scene is noise; keep the committed one
if git diff --quiet -- "$SCENE.tscn"; then :; elif [ -z "$(git diff -U0 -- "$SCENE.tscn" | grep '^[-+][^-+]' | grep -v 'unique_id=')" ]; then
  say "   $SCENE.tscn differs only in node unique_ids (every build makes new ones): git checkout -- $SCENE.tscn unless you are committing this wing"
fi
[ -z "$BAKE_FAILED" ] || exit 1
