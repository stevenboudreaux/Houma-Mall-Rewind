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
# [wings]: "1 2 3" (default; 3 is the outside, design/godot-exterior.md, 1995 only). Exporting one
# wing keeps the other wings' files already in <outdir>.
set -e
OUT=$(realpath -m "$1"); T=$OUT.tmp; WINGS=${2:-"1 2 3"}
rm -rf "$T"; mkdir -p "$OUT" "$T"
# YEARS: "1995 2026" (default when the 2026 wings are built: wing1_2026.tscn), or "1995".
# 2026 (tools/make_layout_2026.py) writes w1y26.* / w2y26.* from the "Wing <n> <Kind> 2026" presets.
YEARS=${YEARS:-$( [ -f wing1_2026.tscn ] && echo "1995 2026" || echo "1995")}
for y in $YEARS; do
for w in $WINGS; do
  # the 2026 outside (Workstream F, Nov 1 2026) exports once wing3_2026.tscn is built
  if [ "$y" = "2026" ] && [ "$w" = "3" ] && [ ! -f wing3_2026.tscn ]; then continue; fi
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
sed -i "s|const PACK_SIZES = {\"w1\": {\"desktop\": 0, \"mobile\": 0}, \"w2\": {\"desktop\": 0, \"mobile\": 0}, \"w3\": {\"desktop\": 0, \"mobile\": 0}, \"w1y26\": {\"desktop\": 0, \"mobile\": 0}, \"w2y26\": {\"desktop\": 0, \"mobile\": 0}, \"w3y26\": {\"desktop\": 0, \"mobile\": 0}};|const PACK_SIZES = {\"w1\": {\"desktop\": $S1D, \"mobile\": $S1M}, \"w2\": {\"desktop\": $S2D, \"mobile\": $S2M}, \"w3\": {\"desktop\": $S3D, \"mobile\": $S3M}, \"w1y26\": {\"desktop\": $Y1D, \"mobile\": $Y1M}, \"w2y26\": {\"desktop\": $Y2D, \"mobile\": $Y2M}, \"w3y26\": {\"desktop\": $Y3D, \"mobile\": $Y3M}};|" "$OUT/index.html"
grep -q "\"desktop\": $S1D" "$OUT/index.html" || { echo "could not write pack sizes into index.html"; exit 1; }
rm -rf "$T"
echo "wing1 desktop $S1D mobile $S1M  wing2 desktop $S2D mobile $S2M  outside $S3D/$S3M  2026: wing1 $Y1D/$Y1M wing2 $Y2D/$Y2M outside $Y3D/$Y3M"
