#!/bin/bash
# CHARS-UBC: Godot doesn't notice a glTF whose .bin changed but whose .gltf text didn't (it hashes the
# .gltf only), so every UBC glTF is forced to reimport, then the manifest is rewritten.
# Run from the Godot project folder.
set -e
for f in models/ubc/*.gltf; do
  b=$(basename "$f")
  rm -f .godot/imported/"$b"-*
done
"${GODOT:-godot}" --headless --path . --import > /dev/null 2>&1 || true
"${GODOT:-godot}" --headless --path . --script res://tools/chars/ubc_manifest.gd 2>&1 | grep -E "UBC MANIFEST|SCRIPT ERROR"
