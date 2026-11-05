"""Side-by-side sheets for the generator-vs-pack decision (design/lynns/asset-manifest.md "Which source won"):
footage frames | generator props (front 3/4 from their turntable sheets) | pack conversions (from the
import_quaternius.py contact sheet). Writes production/qa/evidence/lynns-compare-<family>.jpg.
Run after: import_quaternius.py --sheet-only --sheet .scratch/lyq/all.png  (refs/ unpacked at the repo root)."""
import json, os, sys
from PIL import Image, ImageDraw
P = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
R = os.path.abspath(os.path.join(P, "..", "..", ".."))
EV = os.path.join(R, "production", "qa", "evidence")
ALL = os.path.join(P, ".scratch", "lyq", "all.png")
ORDER = json.load(open(os.path.join(P, ".scratch", "lyq", "all_order.json")))
S = 300

def ref(name):
    im = Image.open(os.path.join(R, "refs", "new", "sears", name + ".jpg")).convert("RGB")
    w, h = im.size
    im = im.crop((0, (h - w) // 2, w, (h + w) // 2))
    return im.resize((S, S)), "REF " + name.replace("_t000_", " f")

def gen(id_):
    im = Image.open(os.path.join(EV, "lynns-bl_ly_%s-sheet.jpg" % id_)).convert("RGB")
    return im.crop((1200, 22, 1600, 400)).resize((S, S)), "GENERATOR bl_ly_" + id_

_all = None
def pack(id_):
    global _all
    _all = _all or Image.open(ALL).convert("RGB")
    n = ORDER.index(id_)
    x, y = (n % 6) * 320, (n // 6) * 342 + 22
    return _all.crop((x, y, x + 320, y + 320)).resize((S, S)), "PACK " + id_

SHEETS = {
    "sofa": ([ref("IMG_4413_t000_078"), ref("IMG_4411_t000_041"), ref("IMG_4409_t000_005")],
             [gen("sofa_sage"), gen("sofa_leather"), gen("sofa_cream")],
             [pack("pk_motion_grey"), pack("pk_sect_grey"), pack("pk_love_cognac")]),
    "bedroom": ([ref("IMG_4413_t000_029"), ref("IMG_4413_t000_120"), ref("IMG_4412_t000_045")],
                [gen("bed_espresso"), gen("dresser_glam"), gen("chest_oak")],
                [pack("pk_bediron_black"), pack("pk_sideboard_greywash"), pack("pk_end_oak")]),
    "chairs": ([ref("IMG_4412_t000_007"), ref("IMG_4412_t000_003"), ref("IMG_4413_t000_105")],
               [],
               [pack("pk_reclc_brown"), pack("pk_recl_cognac"), pack("pk_accent_black")]),
    "mattress": ([ref("IMG_4412_t000_031"), ref("IMG_4412_t000_043"), ref("IMG_4412_t000_027")],
                 [],
                 [pack("pk_mat_navy"), pack("pk_mat_adjustable"), pack("pk_bediron_bronze")]),
    "dining": ([ref("IMG_4412_t000_061"), ref("IMG_4412_t000_067"), ref("IMG_4412_t000_017")],
               [],
               [pack("pk_trect_oak"), pack("pk_chair_cush_white"), pack("pk_stool_oak")]),
    "occasional": ([ref("IMG_4413_t000_051"), ref("IMG_4413_t000_107"), ref("IMG_4411_t000_013")],
                   [],
                   [pack("pk_cocktail_burl"), pack("pk_lamp_gourd"), pack("pk_rug_vintage")]),
}
for fam, rows in SHEETS.items():
    rows = [r for r in rows if r]
    im = Image.new("RGB", (3 * S, len(rows) * (S + 24)), (22, 22, 26))
    d = ImageDraw.Draw(im)
    for ri, row in enumerate(rows):
        for ci, (tile, label) in enumerate(row):
            im.paste(tile, (ci * S, ri * (S + 24) + 24))
            d.text((ci * S + 6, ri * (S + 24) + 6), label, fill=(240, 210, 110))
    out = os.path.join(EV, "lynns-compare-%s.jpg" % fam)
    im.save(out, quality=84)
    print("wrote", out)
