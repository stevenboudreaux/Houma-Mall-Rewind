"""A 1995 alphanumeric pager (RadioShack, 1995 map). Pocket item.

Reference: refs/era_1995/ads/ad_3.jpg (Radiofone, Houma, holiday 1990s: the row of landscape pagers, a
wide LCD over three buttons in a rounded black or clear case). Shape from that ad; brand invented
("BAYOU COM", the invented label used on all bl_rs_* goods), no Radiofone or Motorola marks.
Origin: bottom centre, standing on its bottom edge, screen facing Godot +Z.
"""
from lib import core, parts, mats, labels

W, D, H = 0.062, 0.019, 0.046      # body
R = 0.008                          # corner radius (front view)
LCD = (0.046, 0.013)               # screen window
LCD_Z = 0.031
BODY = "#1b1b1e"

META = {
    "id": "bl_rs_pager",
    "class": "pocket",
    "tex": 1024,
    "ao": 0.35,
    "refs": [["refs/era_1995/ads/ad_3.jpg", [0.15, 0.15, 0.85, 0.48], "era_1995 ad_3 (Radiofone, Houma)"]],
    "item": {"name": "Pager", "year": 1995, "store": "RADIO SHACK"},
}


def art():
    im, d = labels.canvas(920, 260, (128, 140, 110, 255))          # LCD: grey-green
    labels.text(d, (30, 70), "12:45P", "sans", 92, (35, 42, 30, 255), "lm")
    labels.text(d, (890, 70), "▲ 3", "sans", 70, (35, 42, 30, 255), "rm")
    labels.text(d, (30, 190), "CALL MOM 555-0137", "sans", 84, (35, 42, 30, 255), "lm")
    lcd = labels.save(im, "rs_pager_lcd")
    im, d = labels.canvas(1240, 300)
    labels.text(d, (620, 150), "BAYOU COM", "bold", 150, (205, 205, 205, 255))
    brand = labels.save(im, "rs_pager_brand")
    return lcd, brand


def build():
    lcd, brand = art()
    mb = mats.M("body", BODY, 0.5)
    n = mb.noise(900.0, 2.0)
    mb.bump(n.outputs["Fac"], 0.05, 0.0003)
    mats.decal(mb, brand, (0, -D / 2, 0.009), (0.030, 0.0073), "XZ", facing="-Y")
    parts.rounded_panel("body", W, H, D, R, 5, loc=(0, 0, H / 2), mat=mb.mat, bev=0.0015)
    # the screen sits in a shallow dark bezel
    parts.rounded_panel("bezel", LCD[0] + 0.006, LCD[1] + 0.005, 0.0012, 0.002, 2, loc=(0, -D / 2 - 0.0003, LCD_Z),
                        mat=mats.flat("bezel", "#0c0c0d", 0.25), bev=0.0004)
    ml = mats.M("lcd", "#808c6e", 0.15)
    mats.decal(ml, lcd, (0, 0, LCD_Z), LCD, "XZ")
    parts.box("lcd", (LCD[0], 0.0006, LCD[1]), loc=(0, -D / 2 - 0.0009, LCD_Z), mat=ml.mat, bev=0)
    # three buttons under the screen
    mk = mats.flat("keys", "#3a3a3e", 0.4)
    for i, x in enumerate((-0.015, 0.0, 0.015)):
        b = parts.button("key%d" % i, 0.0042, 0.0018, loc=(x, -D / 2, 0.0175), rot=(90, 0, 0), mat=mk)
        b.scale = (1.35, 1.0, 1.0)
    # belt clip on the back
    parts.box("clip", (0.030, 0.0028, 0.036), loc=(0, D / 2 + 0.0024, 0.026), mat=mats.flat("clip", "#151517", 0.45), bev=0.0008)
    parts.box("clipfoot", (0.030, 0.0050, 0.004), loc=(0, D / 2 + 0.0012, 0.044), mat=mats.flat("clip2", "#151517", 0.45), bev=0.0008)
    # a red message LED on the top edge
    parts.cylinder("led", 0.0016, 0.002, 10, loc=(0.022, -0.004, H + 0.0006), mat=mats.flat("led", "#b01818", 0.2), bev=0.0003)
