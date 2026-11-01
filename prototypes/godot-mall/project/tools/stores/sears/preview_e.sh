#!/bin/bash
# usage: preview.sh <target> <out-prefix> "<x,y,z,yaw,pitch;...>" [opts-json] [lit|dark]
# Renders a prop module (tools/stores/pocket_change/<target>.gd) or "store:<NAME>"
# with tools/qa/preview.gd and writes <out-prefix>-<i>.png, one per camera, plus
# <out-prefix>-sheet.png with all of them side by side. Needs godot 4.7 at
# /home/claude/godot (or on PATH) and xvfb-run. Takes ~10-60 s.
set -e
T=$1; OUT=$2; CAMS=${3:-"0,1.6,3.5,0,-10"}; OPTS=${4:-"{}"}; LIGHT=${5:-lit}
P=$(cd "$(dirname "$0")/../../.." && pwd)
G=$(command -v godot || echo /home/claude/godot)
TMP=$(mktemp -d)
mkdir -p "$(dirname "$OUT")"
cd "$P"
timeout 300 xvfb-run -a -s "-screen 0 1280x720x24" "$G" --path . --rendering-driver opengl3 --resolution 1280x720 \
  --write-movie "$TMP/f.png" --fixed-fps 1 --script res://tools/stores/sears/preview_e.gd -- "$T" "$CAMS" "$OPTS" "$LIGHT" > "$TMP/log.txt" 2>&1 || true
grep -E "ERROR|SCRIPT ERROR|Parse Error|error\(" "$TMP/log.txt" | grep -v "Condition \"!windows.has" | head -20 || true
python3 - "$TMP" "$OUT" <<'EOF'
import sys, os, glob
from PIL import Image
tmp, out = sys.argv[1], sys.argv[2]
frames = sorted(glob.glob(os.path.join(tmp, "f*.png")))
# two frames per camera; keep the second of each pair (frame i*2+1)
shots = frames[1::2]
ims = []
for i, f in enumerate(shots):
    im = Image.open(f).convert("RGB")
    im.save("%s-%d.png" % (out, i))
    ims.append(im)
if ims:
    w = 640; h = 360
    sheet = Image.new("RGB", (w * min(3, len(ims)), h * ((len(ims) + 2) // 3)))
    for i, im in enumerate(ims):
        sheet.paste(im.resize((w, h)), ((i % 3) * w, (i // 3) * h))
    sheet.save("%s-sheet.png" % out)
print("wrote", len(ims), "shots to", out + "-*.png")
for f in glob.glob(os.path.join(tmp, "*")):
    os.remove(f)
os.rmdir(tmp)
EOF
