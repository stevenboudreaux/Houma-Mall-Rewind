#!/bin/bash
# usage: tools/wing_hash.sh <wing> [2026]   (from the project folder)
# One fingerprint of everything that decides how a wing looks: its generated meshes and data
# (gen/w<wing>/), its lightmaps (wing<wing>_night/day.exr), the scene, and every texture outside
# tex/standin. tools/capture_standin.sh stamps the stand-in pictures with it; tools/publish_build.sh
# compares (design/godot-wings.md).
# Workstream S (Nov 2 2026): wings 4-6 are the room wings (4 Sears / Lynn's, 5 Dillard's level 1,
# 6 the cinema lobby), hashed like the inside wings. Wing 1 also counts the Sears picture in its
# opening (tex/standin/from_w4_day.png) and wing 2 the Dillard's one (from_w5): the other mall wing's
# stand-in of wing 1 / 2 shows them, so a new anchor picture means a new capture of 1 / 2 too.
W=$1
if [ "$W" = "3" ]; then
  # the outside (Workstream F): its meshes, its lightmap and its own textures (tex/ex)
  G=gen/w3; L="wing3_day.exr"; [ "$2" = "2026" ] && { G=gen/w3y26; L="wing3_2026_day.exr"; }
  { ls $G/* $L 2>/dev/null; find tex/ex -type f -name "*.png"; } | sort | xargs md5sum 2>/dev/null | md5sum | cut -c1-32
  exit 0
fi
P=""
if [ "$2" = "2026" ]; then
  [ "$W" = "1" ] && P=tex/standin/y26_from_w4_day.png
  [ "$W" = "2" ] && P=tex/standin/y26_from_w5_day.png
  { ls gen/w${W}y26/* wing${W}_2026_day.exr $P 2>/dev/null; find tex -type f -name "*.png" -not -path "tex/standin/*" -not -path "tex/ex/*"; } | sort | xargs md5sum 2>/dev/null | md5sum | cut -c1-32
  exit 0
fi
[ "$W" = "1" ] && P=tex/standin/from_w4_day.png
[ "$W" = "2" ] && P=tex/standin/from_w5_day.png
# (the 2026 signs' textures, tex/sg/y26, and the 2026 stores' own, tex/gi (games inc), are not in any
# 1995 wing; the outside's, tex/ex, in no inside wing)
{ ls gen/w$W/* wing${W}_night.exr wing${W}_day.exr $P 2>/dev/null; find tex -type f -name "*.png" -not -path "tex/standin/*" -not -path "tex/sg/y26/*" -not -path "tex/gi/*" -not -path "tex/ex/*"; } | sort | xargs md5sum 2>/dev/null | md5sum | cut -c1-32
