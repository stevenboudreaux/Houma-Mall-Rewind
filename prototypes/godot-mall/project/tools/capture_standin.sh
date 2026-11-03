#!/bin/bash
# usage: tools/capture_standin.sh <wing> [2026]   (from the project folder; godot 4.7.2 on PATH, xvfb-run)
# <wing> 4 / 5 = the anchors' own wings (workstream S): the picture in the mall wing's opening.
# <wing> 3 = the outside: the pictures past the inside wings' exit doors (design/godot-exterior.md).
# Captures wing <wing>'s storefronts, night and day, from its baked build into
# tex/standin/from_w<wing>_{night,day}.png for the other wing's stand-in, and stamps them with
# tools/wing_hash.sh (design/godot-wings.md). The wing's lightmaps must be in the project and
# imported (godot --headless --path . --import). Takes a few minutes per mode in software GL.
set -e
W=$1; Y=${2:-1995}
# scripts/lighting.json "day_only" (Steven, Oct 16 2026): the game never shows the night lighting, so
# the night pictures are never seen. Nov 1 2026 (integration, Demo 47): with day_only the night
# picture is a 256 px thumbnail of the day one (the packs were at GitHub's 100 MB limit; each full
# night picture cost 5.6 MB per wing). Set day_only false and re-run to get real night pictures.
DAY_ONLY=$(python3 -c "import json;print(1 if json.load(open('scripts/lighting.json')).get('day_only') else 0)")
tiny_night() { python3 -c "from PIL import Image;im=Image.open('$1');im.thumbnail((256,256));im.save('$2')"; }
if [ "$W" = "4" ] || [ "$W" = "5" ]; then
  # Workstream S (Nov 2 2026): wings 4 / 5 are the anchors' own wings (Sears / Lynn's, Dillard's level 1).
  # Their picture is the one in the mall wing's opening (build_mall.gd anchor_standin), taken from the
  # mall through the opening by tools/capture_anchor.gd: tex/standin/[y26_]from_w<4|5>_day.png. Then
  # recapture the mall wing it shows in (1 for 4, 2 for 5): the other mall wing's stand-in shows it.
  timeout 900 xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 640x360 \
    --script res://tools/capture_anchor.gd -- --wing=$W --mode=day --year=$Y 2>&1 | grep -E "capturing|wrote|ERROR|error|unbaked" | grep -v "RID alloc\|resources still\|Pages in use" | head -20
  P=from_w; [ "$Y" = "2026" ] && P=y26_from_w
  [ -s tex/standin/${P}${W}_day.png ] || { echo "capture failed: wing $W $Y"; exit 1; }
  tiny_night tex/standin/${P}${W}_day.png tex/standin/${P}${W}_night.png
  if [ "$Y" = "2026" ]; then tools/wing_hash.sh $W 2026 > tex/standin/${P}$W.stamp; else tools/wing_hash.sh $W > tex/standin/${P}$W.stamp; fi
  echo "stamped wing $W ($Y) opening picture: $(cat tex/standin/${P}$W.stamp); now recapture wing $((W - 3)) ($Y)"
  exit 0
fi
if [ "$W" = "6" ]; then
  echo "wing 6 (the cinema lobby placeholder) has no stand-in picture: its doors are behind the roll gate"
  exit 0
fi
if [ "$W" = "3" ]; then
  # Workstream F (Nov 1 2026): wing 3 is the outside; its pictures are the lot seen out of the inside
  # wings' exit doors (tools/exterior/door_view.gd, capture_doors.gd): tex/standin/door_w<1|2>_<mode>.png,
  # 2026 y26_door_w<1|2>_day.png (the night a copy). Run after the outside's bake, like the stand-in.
  MODES="night day"; { [ "$Y" = "2026" ] || [ "$DAY_ONLY" = "1" ]; } && MODES="day"
  for IW in 1 2; do for M in $MODES; do
    timeout 900 xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 640x360 \
      --script res://tools/exterior/capture_doors.gd -- --wing=$IW --mode=$M --year=$Y 2>&1 | grep -E "capturing|wrote|ERROR|error|unbaked" | grep -v "RID alloc\|resources still\|Pages in use" | head -20
  done; done
  P=door_w; [ "$Y" = "2026" ] && P=y26_door_w
  if [ "$DAY_ONLY" = "1" ] && [ "$Y" != "2026" ]; then for IW in 1 2; do tiny_night tex/standin/door_w${IW}_day.png tex/standin/door_w${IW}_night.png; done; fi
  for IW in 1 2; do [ -s tex/standin/${P}${IW}_day.png ] || { echo "capture failed: doors of wing $IW"; exit 1; }; done
  tools/wing_hash.sh 3 $Y > tex/standin/${P}3.stamp
  echo "stamped the door pictures from the outside ($Y): $(cat tex/standin/${P}3.stamp)"
  exit 0
fi
if [ "$Y" = "2026" ]; then
  # 2026 (tools/make_layout_2026.py): day only (the game is day-only); the night picture is a copy
  timeout 1500 xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 640x360 \
    --script res://tools/capture_standin.gd -- --wing=$W --mode=day --year=2026 2>&1 | grep -E "capturing|wrote|ERROR|error" | grep -v "RID alloc\|resources still\|Pages in use" | head -20
  [ -s tex/standin/y26_from_w${W}_day.png ] || { echo "capture failed: wing $W 2026"; exit 1; }
  if [ "$DAY_ONLY" = "1" ]; then tiny_night tex/standin/y26_from_w${W}_day.png tex/standin/y26_from_w${W}_night.png; else cp tex/standin/y26_from_w${W}_day.png tex/standin/y26_from_w${W}_night.png; fi
  tools/wing_hash.sh $W 2026 > tex/standin/y26_from_w$W.stamp
  echo "stamped wing $W 2026 stand-in: $(cat tex/standin/y26_from_w$W.stamp)"
  exit 0
fi
MODES="night day"; [ "$DAY_ONLY" = "1" ] && MODES="day"
for M in $MODES; do
  timeout 1500 xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --resolution 640x360 \
    --script res://tools/capture_standin.gd -- --wing=$W --mode=$M 2>&1 | grep -E "capturing|wrote|ERROR|error" | grep -v "RID alloc\|resources still\|Pages in use" | head -20
  [ -s tex/standin/from_w${W}_$M.png ] || { echo "capture failed: wing $W $M"; exit 1; }
done
[ "$DAY_ONLY" = "1" ] && tiny_night tex/standin/from_w${W}_day.png tex/standin/from_w${W}_night.png
tools/wing_hash.sh $W > tex/standin/from_w$W.stamp
echo "stamped wing $W stand-in: $(cat tex/standin/from_w$W.stamp)"
