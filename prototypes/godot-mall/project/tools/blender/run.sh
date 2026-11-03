#!/bin/bash
# usage: tools/blender/run.sh <asset> [--fast] [--no-sheet] [--evidence]
# Builds tools/blender/assets_src/<asset>.py with Blender-as-a-Python-module (bpy):
#   res://models/<id>/<id>.glb + <id>_albedo/_orm/_normal.png (+ <id>_icon.png for items)
#   .scratch/blender/<id>-sheet.png (turntable beside the reference), <id>-report.json
# Fails with "OVER BUDGET: ..." when the mesh is over its class budget (tools/blender/budgets.json).
# --evidence also writes production/qa/evidence/wsT-<asset>-sheet.jpg (<= 1600 px; EV_PREFIX=wsT2 changes the prefix).
# Needs: python3 -m venv /home/claude/bvenv && /home/claude/bvenv/bin/pip install bpy pillow numpy
set -e
A=$1; shift || true
[ -z "$A" ] && { echo "usage: run.sh <asset> [--fast] [--no-sheet] [--evidence]"; exit 2; }
HERE=$(cd "$(dirname "$0")" && pwd)
P=$(cd "$HERE/../.." && pwd)
PY=${BPY:-/home/claude/bvenv/bin/python}
[ -x "$PY" ] || { echo "no bpy python at $PY (see the header of this script)"; exit 2; }
"$PY" -c "import PIL, numpy" 2>/dev/null || "$PY" -m pip install -q pillow numpy
cd "$P"
LOG=.scratch/blender/$A.log; mkdir -p .scratch/blender
set +e
"$PY" "$HERE/build.py" -- "$A" "$@" 2>&1 | tee "$LOG" | grep -E "^(BUILD OK|NORMAL CLAMP|OVER BUDGET|BUDGET NOT ASSESSED|HIPOLY|EXPORT CHECK|DECIMATED|SHEET|REF MISSING|Traceback|  File|[A-Za-z]*Error)"
RC=${PIPESTATUS[0]}
set -e
grep -q "^BUILD OK" "$LOG" || { echo "BUILD FAILED ($A), see $P/$LOG"; tail -5 "$LOG"; exit 1; }
if [[ " $* " == *" --evidence "* ]]; then
  ID=$A   # asset source files are named by their id
  python3 - "$P/.scratch/blender/$ID-sheet.png" "$P/../../../production/qa/evidence/${EV_PREFIX:-wsT}-$A-sheet.jpg" <<'EOF'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB"); im.thumbnail((1600, 1600)); im.save(sys.argv[2], quality=88)
print("evidence", sys.argv[2])
EOF
fi
exit $RC
