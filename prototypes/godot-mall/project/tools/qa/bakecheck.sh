#!/bin/bash
# usage: bakecheck.sh <prefix> <night|day> ['{"name":"x,z,yaw,pitch",...}']
# After a bake on the Mac: copy main_<mode>.exr, .lmbake AND .exr.import to
# ~/GodotProjects/<prefix>_main_<mode>.* there, stage them with device_stage_files
# (they land in /mnt/user-data/uploads/GodotProjects/), then run this. It puts them in
# the project, re-imports, exports the web build to .scratch/builds/<prefix>, shoots the
# cameras with ?time=<mode> through movetest.py (0 errors + MOVED expected) and writes
# .scratch/shots/<prefix>-<mode>-sheet.jpg. Default cameras: Pocket Change.
# The export is split (tools/export_web.sh): index.desktop.pck and index.mobile.pck.
# The .exr.import matters: its slices/vertical follows the lightmap atlas layer count.
# Needs godot 4.7.2 at /home/claude/godot. Run in the background or split cameras if the
# 10-minute tool limit is near (SwiftShader takes ~40-60 s per camera).
set -e
PX=$1; M=$2; R=/home/claude/houma-mall-rewind; P=$R/prototypes/godot-mall/project; U=/mnt/user-data/uploads/GodotProjects
sleep 2
for f in exr lmbake exr.import; do cp $U/${PX}_main_$M.$f $P/main_$M.$f; done
md5sum $P/main_$M.exr | cut -c1-12
cd $P; export PATH=/home/claude:$PATH
(timeout 900 godot --headless --path . --import > /dev/null 2>&1 || true)
mkdir -p $R/.scratch/builds/$PX
tools/export_web.sh $R/.scratch/builds/$PX > $R/.scratch/builds/$PX.log 2>&1 || true
cat $R/.scratch/builds/$PX.log | tail -1 | sed 's/^/pck /'
cd $R
curl -s -o /dev/null http://127.0.0.1:8765/ || (python3 -m http.server 8765 > /dev/null 2>&1 &); sleep 1
C=${3:-'{"front":"-101.6,57.2,128,3","hall":"-106,52,180,6","door":"-106,63,180,-4","rede":"-104.6,70.5,180,-4","mid":"-106,74,180,-4","back":"-106,88,180,-4"}'}
C=$(echo "$C" | python3 -c "import sys,json; d=json.load(sys.stdin); print(json.dumps({k:v+'&time=$M' for k,v in d.items()}))")
CAMS="$C" timeout 900 python3 $P/tools/qa/movetest.py .scratch/builds/$PX/index.html .scratch/shots/$PX-$M 2>&1 | grep -E 'errors|MOVED|Error'
python3 - "$PX-$M" "$C" <<'PY'
import sys, json
from PIL import Image
n=sys.argv[1]; cs=list(json.loads(sys.argv[2]).keys())
W,H=640,360; cols=3; rows=(len(cs)+2)//3
sh=Image.new('RGB',(W*cols,H*rows))
for i,c in enumerate(cs):
    sh.paste(Image.open('.scratch/shots/%s-%s.png'%(n,c)).convert('RGB').resize((W,H)),((i%cols)*W,(i//cols)*H))
sh.save('.scratch/shots/%s-sheet.jpg'%n,quality=85)
print('sheet .scratch/shots/%s-sheet.jpg'%n)
PY
