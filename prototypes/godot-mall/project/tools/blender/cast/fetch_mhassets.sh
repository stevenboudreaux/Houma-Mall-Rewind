#!/bin/bash
# Fetch MakeHuman's system asset library (skins, eyebrows, eyelashes, eyes, hair, clothes, teeth) for the
# cast build, into .scratch/mh/mh11/ (git-ignored; never committed).
#
# Source: Ubuntu's makehuman-data 1.1.1 package (the asset server and GitHub's makehuman-assets repository
# are not reachable from the cloud sessions). Unpacked with dpkg-deb -x: no package scripts run.
# Licence: MakeHuman's upstream LICENSE.md, section C "The license for the bundled assets" (repository
# makehumancommunity/makehuman): base mesh, proxies, targets, textures and MHCLO clothes are released
# under CC0 1.0. The 1.1.1 files' own headers predate that statement and say AGPLv3; see
# design/godot-cast.md "Licences" (a point for Steven to confirm).
set -e
HERE=$(cd "$(dirname "$0")" && pwd); P=$(cd "$HERE/../../.." && pwd)
D=$P/.scratch/mh/mh11
SHA=881a79c3a6640e2ecc579093f6895d161fd902856504b123ef750e843f4304a7
URL=http://archive.ubuntu.com/ubuntu/pool/universe/m/makehuman/makehuman-data_1.1.1-1_all.deb
if [ -f "$D/.ok-$SHA" ]; then echo "mh 1.1.1 assets ok ($D)"; exit 0; fi
mkdir -p "$D/deb"
curl -sS -o "$D/deb/makehuman-data.deb" "$URL"
echo "$SHA  $D/deb/makehuman-data.deb" | sha256sum -c -
rm -rf "$D/x"; dpkg-deb -x "$D/deb/makehuman-data.deb" "$D/x"
touch "$D/.ok-$SHA"
echo "mh 1.1.1 assets in $D/x/usr/share/makehuman/data"
