"""Paint flat artwork (labels, screens, printed boxes) with PIL for decals. Every brand, logo and model
name on a product is invented (CLAUDE-CLOUD.md IP rule); only period-plausible generic words otherwise.
Images go to .scratch/blender/src/ (build inputs, not shipped: they end up baked into the atlas)."""
import os
from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJ = os.path.abspath(os.path.join(HERE, "..", ".."))
SRC = os.path.join(PROJ, ".scratch", "blender", "src")
FONTS = {"sans": "sans.otf", "italic": "sans_italic.otf", "bold": "forza.ttf", "serif": "serif.ttf", "script": "script.ttf"}


def font(kind, px):
    return ImageFont.truetype(os.path.join(PROJ, "fonts", FONTS[kind]), int(px))


def canvas(w, h, bg=(0, 0, 0, 0)):
    im = Image.new("RGBA", (int(w), int(h)), bg)
    return im, ImageDraw.Draw(im)


def text(d, xy, s, kind="sans", px=20, fill=(255, 255, 255, 255), anchor="mm"):
    d.text(xy, s, font=font(kind, px), fill=fill, anchor=anchor)


def save(im, name):
    os.makedirs(SRC, exist_ok=True)
    p = os.path.join(SRC, name + ".png")
    im.save(p)
    return p
