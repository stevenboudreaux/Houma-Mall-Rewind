#!/bin/bash
# Fetch the MakeHuman CC0 assets the character bodies are built from (base mesh hm08, targets,
# the Mixamo rig + weights, region masks) from MPFB2's repository, pinned to one commit, into
# .scratch/mh/ (git-ignored). The code in that repository is GPL and is NOT used or copied: only
# files under src/mpfb/data (LICENSE.ASSETS.md: CC0 1.0). See design/godot-characters.md.
set -e
SHA=6ff1eb358f6c1959ced77e79e6dd2406d9a71f49
HERE=$(cd "$(dirname "$0")" && pwd); P=$(cd "$HERE/../../.." && pwd)
D=$P/.scratch/mh/mpfb2
if [ -f "$D/.ok-$SHA" ]; then echo "mh assets ok ($D)"; exit 0; fi
rm -rf "$D"; mkdir -p "$P/.scratch/mh"
git clone -q --filter=blob:none --sparse --no-checkout https://github.com/makehumancommunity/mpfb2 "$D"
cd "$D"
git sparse-checkout set --no-cone 'LICENSE*' 'src/mpfb/data/3dobjs' 'src/mpfb/data/rigs/standard/*mixamo.json' \
  'src/mpfb/data/mesh_metadata' 'src/mpfb/data/targets/**/*.gz' 'src/mpfb/data/textures'
git checkout -q $SHA
touch "$D/.ok-$SHA"
echo "mh assets fetched at $SHA"
