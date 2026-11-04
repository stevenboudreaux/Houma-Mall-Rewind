#!/bin/bash
# usage: tools/export_web.sh <outdir> [wings]   (run from the project folder, godot on PATH)
# Exports the web build: the mall in two wings (design/godot-wings.md), each as two game files
# that differ only in texture formats, so each device downloads one wing in one format:
#   w1.desktop.pck / w2.desktop.pck  S3TC and BPTC  (computer GPUs)
#   w1.mobile.pck  / w2.mobile.pck   ETC2 and ASTC  (phones, tablets, VR headsets)
# plus the shared index.html / .js / .wasm. web/shell.html picks the wing (?wing=) and the
# format at load time; scripts/mall_runtime.gd switches format once if it guessed wrong. Writes
# the pack sizes into index.html for the loading bar and the cache name. Presets "Wing 1 Desktop",
# "Wing 1 Mobile", "Wing 2 Desktop", "Wing 2 Mobile" in export_presets.cfg.
# [wings]: "1 2 3 4 5 6" (default; 3 is the outside, design/godot-exterior.md; 4-6 the room wings,
# workstream S, Nov 2 2026: 4 Sears / Lynn's, 5 Dillard's level 1, 6 the Southland Cinema lobby,
# design/godot-wings.md "Wings 4-6", presets from tools/make_presets.py; a room wing whose scene is not
# built is skipped). Exporting one wing keeps the other wings' files already in <outdir>.
set -e
OUT=$(realpath -m "$1"); T=$OUT.tmp; WINGS=${2:-"1 2 3 4 5 6"}
rm -rf "$T"; mkdir -p "$OUT" "$T"
# YEARS: "1995 2026" (default when the 2026 wings are built: wing1_2026.tscn), or "1995".
# 2026 (tools/make_layout_2026.py) writes w1y26.* / w2y26.* from the "Wing <n> <Kind> 2026" presets.
YEARS=${YEARS:-$( [ -f wing1_2026.tscn ] && echo "1995 2026" || echo "1995")}
for y in $YEARS; do
for w in $WINGS; do
  # the 2026 outside (Workstream F, Nov 1 2026) exports once wing3_2026.tscn is built
  if [ "$y" = "2026" ] && [ "$w" = "3" ] && [ ! -f wing3_2026.tscn ]; then continue; fi
  # the room wings (S) once built
  if [ "$w" -ge 4 ]; then if [ "$y" = "2026" ]; then [ -f wing${w}_2026.tscn ] || continue; else [ -f wing$w.tscn ] || continue; fi; fi
  for k in desktop mobile; do
    K=$(echo $k | sed 's/./\U&/')
    PRE="Wing $w $K"; NAME="w$w"
    if [ "$y" = "2026" ]; then PRE="Wing $w $K 2026"; NAME="w${w}y26"; fi
    mkdir -p "$T/$NAME$k"
    timeout 600 godot --headless --path . --export-release "$PRE" "$T/$NAME$k/index.html" > "$T/$NAME-$k.log" 2>&1 || true
    [ -s "$T/$NAME$k/index.pck" ] || { echo "export failed ($PRE), see $T/$NAME-$k.log"; exit 1; }
    cp "$T/$NAME$k/index.pck" "$OUT/$NAME.$k.pck"
  done
done
done
F=w$(echo $WINGS | cut -d' ' -f1)
for f in "$T/${F}desktop/"index.*; do
  b=$(basename "$f"); [ "$b" = "index.pck" ] || cp "$f" "$OUT/$b"
done
rm -f "$OUT/index.pck" "$OUT/index.desktop.pck" "$OUT/index.mobile.pck"
for w in 1 2; do for k in desktop mobile; do [ -s "$OUT/w$w.$k.pck" ] || { echo "missing $OUT/w$w.$k.pck"; exit 1; }; done; done
S1D=$(stat -c %s "$OUT/w1.desktop.pck"); S1M=$(stat -c %s "$OUT/w1.mobile.pck")
S2D=$(stat -c %s "$OUT/w2.desktop.pck"); S2M=$(stat -c %s "$OUT/w2.mobile.pck")
sz() { [ -s "$OUT/$1.$2.pck" ] && stat -c %s "$OUT/$1.$2.pck" || echo 0; }
S3D=$(sz w3 desktop); S3M=$(sz w3 mobile)
Y1D=$(sz w1y26 desktop); Y1M=$(sz w1y26 mobile); Y2D=$(sz w2y26 desktop); Y2M=$(sz w2y26 mobile)
Y3D=$(sz w3y26 desktop); Y3M=$(sz w3y26 mobile)
# every pack's size (0 when not exported) into web/shell.html's PACK_SIZES line, the 12 names in its order
PS=""
for nm in w1 w2 w3 w1y26 w2y26 w3y26 w4 w5 w6 w4y26 w5y26 w6y26; do
  PS="$PS${PS:+, }\"$nm\": {\"desktop\": $(sz $nm desktop), \"mobile\": $(sz $nm mobile)}"
done
sed -i "s|^const PACK_SIZES = {.*}; // PACK_SIZES|const PACK_SIZES = {$PS}; // PACK_SIZES|" "$OUT/index.html"
grep -q "\"desktop\": $S1D" "$OUT/index.html" || { echo "could not write pack sizes into index.html"; exit 1; }
# CHARS (Nov 3 2026, design/godot-build-hosting.md "Shared packs"): the packs every wing shares instead of
# carrying its own copy (tools/shared_packs.py: "items", the Blender items; "chars" / "chars_<map>", the
# characters), each <name>.desktop.pck / .mobile.pck, through the presets "Shared Desktop" / "Shared Mobile";
# their sizes go into index.html's SHARED_PACKS line. SHARED=0 skips them (a quick wing-only export keeps
# the shared packs already in <outdir>).
if [ "${SHARED:-1}" = "1" ]; then
  cp export_presets.cfg "$T/export_presets.keep"
  for n in $(python3 tools/shared_packs.py --names); do
    python3 tools/shared_packs.py --write=$n > /dev/null
    for k in desktop mobile; do
      K=$(echo $k | sed 's/./\U&/')
      timeout 600 godot --headless --path . --export-pack "Shared $K" "$OUT/$n.$k.pck" > "$T/shared-$n-$k.log" 2>&1 || true
      [ -s "$OUT/$n.$k.pck" ] || { cp "$T/export_presets.keep" export_presets.cfg; echo "shared pack export failed ($n $k), see $T/shared-$n-$k.log"; exit 1; }
    done
    echo "shared $n: desktop $(stat -c %s "$OUT/$n.desktop.pck") mobile $(stat -c %s "$OUT/$n.mobile.pck")"
  done
  cp "$T/export_presets.keep" export_presets.cfg
fi
SP=$(python3 tools/shared_packs.py --shell="$OUT")
python3 - "$OUT/index.html" "$SP" <<'PY'
import sys
p, line = sys.argv[1], sys.argv[2]
s = open(p).read()
i = s.index("const SHARED_PACKS = "); j = s.index("// SHARED_PACKS", i) + len("// SHARED_PACKS")
open(p, "w").write(s[:i] + line + s[j:])
PY
# GitHub refuses a file over 100 MiB (design/godot-build-hosting.md): warn from 95 MB, tools/publish_build.sh refuses
for f in "$OUT"/*.pck; do [ "$(stat -c %s "$f")" -lt 95000000 ] || echo "WARNING: $(basename "$f") is $(stat -c %s "$f") bytes, near GitHub's 100 MiB file limit"; done
rm -rf "$T"
echo "wing1 desktop $S1D mobile $S1M  wing2 desktop $S2D mobile $S2M  outside $S3D/$S3M  2026: wing1 $Y1D/$Y1M wing2 $Y2D/$Y2M outside $Y3D/$Y3M"
echo "room wings (desktop/mobile): sears $(sz w4 desktop)/$(sz w4 mobile) dillards $(sz w5 desktop)/$(sz w5 mobile) cinema $(sz w6 desktop)/$(sz w6 mobile)  2026: $(sz w4y26 desktop)/$(sz w4y26 mobile) $(sz w5y26 desktop)/$(sz w5y26 mobile) $(sz w6y26 desktop)/$(sz w6y26 mobile)"
