"""Compose a cast member's evidence images (CHAR-BUILD, design/godot-cast.md):

  python3 tools/qa/cast_evidence.py sheet  <id> <turntable prefix> "<caption>"   -> production/qa/evidence/wsCAST-<id>-sheet.jpg
  python3 tools/qa/cast_evidence.py ingame <id> <shot prefix> "<caption>"         -> production/qa/evidence/wsCAST-<id>-ingame.jpg

sheet: the six turntable frames of tools/qa/cast_turntable.gd (Godot, idle clip), then the research render
(CHAR-RESEARCH, pipeline B, Cycles) beside the five face frames (neutral, talk, smile, blink, eye bones).
ingame: tools/qa/cast_shot.gd's far / talk / face frames.
"""
import json
import os
import sys

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.abspath(os.path.join(HERE, "..", ".."))
EVID = os.path.abspath(os.path.join(PROJ, "..", "..", "..", "production", "qa", "evidence"))
REF = os.path.abspath(os.path.join(PROJ, "..", "..", "..", ".scratch", "ref.jpg"))   # wsCHAR-radioshack-before-after.jpg
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"


def F(n):
    return ImageFont.truetype(FONT, n)


def sheet(pid, pre, caption):
    m = json.load(open(os.path.join(PROJ, "cast", pid + ".json")))
    W, tw, th = 1600, 266, 400
    s = Image.new("RGB", (W, th + 30 + 420 + 60), (24, 21, 18)); d = ImageDraw.Draw(s)
    for i, a in enumerate([0, 45, 90, 135, 180, 270]):
        s.paste(Image.open("%s-turn%03d.png" % (pre, a)).convert("RGB").resize((tw, th)), (i * tw, 0))
    d.text((8, th + 4), caption, fill=(235, 225, 200), font=F(15))
    y = th + 30; x = 0
    if os.path.exists(REF):
        r = Image.open(REF).convert("RGB"); rw, rh = r.size
        c = r.crop((int(rw * 0.385), 0, int(rw * 0.69), int(rh * 0.93)))
        c = c.resize((int(420 * c.size[0] / c.size[1]), 420)); s.paste(c, (0, y)); x = c.size[0] + 6
        d.text((4, y + 422), "research render (Cycles)", fill=(200, 190, 170), font=F(13))
    fw = (W - x) // 5 - 4
    labels = {"talk": "jaw_open .35 + smile .5 + aa", "smile": "smile .9", "blink": "blink_L/R 1", "look-left": "eye bones 18 deg"}
    for f in ["neutral", "talk", "smile", "blink", "look-left"]:
        im = Image.open("%s-face-%s.png" % (pre, f)).convert("RGB").crop((60, 90, 420, 630)).resize((fw, int(fw * 1.5)))
        s.paste(im.crop((0, 0, fw, 420)), (x, y))
        d.text((x + 3, y + 422), labels.get(f, f), fill=(230, 220, 200), font=F(13)); x += fw + 4
    d.text((8, y + 442), "LOD0 %d tris, %d draw calls · LOD1 %d tris · %d morphs (20 cast names + 15 visemes) · eye.L/eye.R/jaw · height %.2f m" % (
        m["lod0"]["tris"], m["lod0"]["surfaces"], m["lod1"]["tris"], len(m["morphs"]), m["height_m"]), fill=(235, 225, 200), font=F(14))
    out = os.path.join(EVID, "wsCAST-%s-sheet.jpg" % pid); s.save(out, quality=88); print(out)


def ingame(pid, pre, caption):
    ims = [Image.open("%s-%s.png" % (pre, n)).convert("RGB") for n in ("far", "talk", "face")]
    W = 1600; h = int(800 * (W / 2) / 1280)
    s = Image.new("RGB", (W, h * 2 + 30), (24, 21, 18))
    s.paste(ims[0].resize((W // 2, h)), (0, 0)); s.paste(ims[1].resize((W // 2, h)), (W // 2, 0))
    s.paste(ims[2].resize((W // 2, h)), (W // 4, h))
    ImageDraw.Draw(s).text((10, h * 2 + 5), caption, fill=(230, 220, 200), font=F(17))
    out = os.path.join(EVID, "wsCAST-%s-ingame.jpg" % pid); s.save(out, quality=88); print(out)


if __name__ == "__main__":
    {"sheet": sheet, "ingame": ingame}[sys.argv[1]](sys.argv[2], sys.argv[3], sys.argv[4])
