#!/bin/bash
# B2 (design/godot-character-editor.md): the character packs, one per map and texture kind:
#   chars_w1.desktop.pck / chars_w1.mobile.pck, chars_w2.*, chars_w3.*, chars_w1y26.* ...
# Each holds only that map's presets' bodies / hair / pieces and the player's wardrobe
# (tools/chars/pack_list.py). scripts/chars/char_pack.gd fetches and mounts it at start.
# usage (project folder, godot on PATH): tools/chars/export_chars.sh <outdir> [maps]
#   maps: "wing1 wing2 wing3 w1y26 w2y26 w3y26" (default)
set -e
OUT=$(realpath -m "$1"); MAPS=${2:-"wing1 wing2 wing3 w1y26 w2y26 w3y26"}
mkdir -p "$OUT"
cp export_presets.cfg "$OUT/.export_presets.keep"
trap 'cp "$OUT/.export_presets.keep" export_presets.cfg; rm -f "$OUT/.export_presets.keep"' EXIT
for m in $MAPS; do
  n=$(echo $m | sed 's/^wing/w/')
  python3 tools/chars/pack_list.py --preset=$m > /dev/null
  for k in desktop mobile; do
    K=$(echo $k | sed 's/./\U&/')
    timeout 600 godot --headless --path . --export-pack "Characters $K" "$OUT/chars_$n.$k.pck" > "$OUT/.chars_$n-$k.log" 2>&1 || true
    [ -s "$OUT/chars_$n.$k.pck" ] || { echo "character pack export failed ($m $k), see $OUT/.chars_$n-$k.log"; exit 1; }
  done
  echo "chars_$n: desktop $(stat -c %s "$OUT/chars_$n.desktop.pck") mobile $(stat -c %s "$OUT/chars_$n.mobile.pck")"
done
