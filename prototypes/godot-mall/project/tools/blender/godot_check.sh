#!/bin/bash
# usage: tools/blender/godot_check.sh <glb|store:NAME> <out-prefix> "<x,y,z,yaw,pitch;...>" '<opts-json>' [lit|dark]
# Imports new models (godot --headless --import), then renders them with tools/qa/preview.sh's scene
# through tools/blender/godot_check.gd. Example (a hand item on a counter-height block):
#   tools/blender/godot_check.sh glb .scratch/blender/scan-godot "0,1.2,0.45,0,-35" \
#     '{"stand":[0.6,0.9,0.4],"glb":[{"path":"res://models/bl_rs_scanner/bl_rs_scanner.glb","at":[0,0.9,0]}]}'
set -e
P=$(cd "$(dirname "$0")/../.." && pwd)
G=$(command -v godot || echo /home/claude/godot)
cd "$P"
if [ -z "$NO_IMPORT" ]; then
  timeout 900 "$G" --headless --path . --import > .scratch/blender/import.log 2>&1 || true
  grep -E "ERROR.*models/" .scratch/blender/import.log | head -5 || true
fi
PREVIEW_SCRIPT=res://tools/blender/godot_check.gd exec tools/qa/preview.sh "$@"
