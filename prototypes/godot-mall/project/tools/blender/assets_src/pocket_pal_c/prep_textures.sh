#!/bin/bash
# Route C textures (design/godot-device-bakeoff.md): surface patches cut from the reference video stills and
# enlarged 4x with Real-ESRGAN (BSD-3; weights RealESRGAN_x4plus.pth from the project's GitHub releases), on
# CPU. Needs a Python with torch + opencv (not the bpy venv):  PY=/path/to/python W=/path/to/RealESRGAN_x4plus.pth
# Then tile.py makes each patch a seamless 512 px tile (mirror tiling) for device.py's "ai" style.
set -e
H=$(cd "$(dirname "$0")" && pwd); R=$(cd "$H/../../../../../../.." && pwd); E=$R/production/qa/evidence
PY=${PY:-/home/claude/routeB/venv/bin/python}; W=${W:-/home/claude/routeB/dl/esrgan/RealESRGAN_x4plus.pth}
$PY $H/esrgan_cpu.py x4plus $W $E/wsDEV-ref-380.jpg $H/ai/plastic_x4.png 330,212,450,276     # the plain underside
$PY $H/esrgan_cpu.py x4plus $W $E/wsDEV-ref-247.jpg $H/ai/rubber_x4.png 264,270,282,283      # the blank end of a key top
$PY $H/esrgan_cpu.py x4plus $W $E/wsDEV-ref-193.jpg $H/ai/bezel_x4.png 115,141,300,147        # the LCD's light bezel
$PY - "$H/ai" <<'P'
import sys, cv2, numpy as np
d = sys.argv[1]
for n in ("plastic", "rubber", "bezel"):
    im = cv2.imread("%s/%s_x4.png" % (d, n)).astype(np.float32)
    im = im - cv2.GaussianBlur(im, (0, 0), 24) + im.mean((0, 1))          # flatten the lighting gradient
    t = np.vstack([np.hstack([im, im[:, ::-1]]), np.hstack([im[::-1], im[::-1, ::-1]])])   # mirror tile: seamless
    cv2.imwrite("%s/%s_tile.png" % (d, n), cv2.resize(np.clip(t, 0, 255), (512, 512), interpolation=cv2.INTER_AREA).astype(np.uint8))
P
