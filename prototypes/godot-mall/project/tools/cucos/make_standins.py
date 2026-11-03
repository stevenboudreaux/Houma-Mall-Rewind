"""Stand-in items for workstream CUCOS (design/godot-cucos.md), until workstream FOOD's cu_* land.

Writes scripts/items/cucos/cu_*.tscn (plain primitive meshes, no textures) and tex/items/cu_*.png
(256 px icons, marked STAND-IN). FOOD's models and icons replace them under the same ids: delete
data/items/cucos_standin.json, scripts/items/cucos/ and tex/items/cu_*.png when they land.

    python3 tools/cucos/make_standins.py
"""
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(__file__), "..", "..")
SCN = os.path.join(ROOT, "scripts", "items", "cucos")
ICO = os.path.join(ROOT, "tex", "items")


def mat(i, rgba, rough=0.4, metal=0.0, alpha=False):
    s = f'[sub_resource type="StandardMaterial3D" id="m{i}"]\nalbedo_color = Color({rgba[0]}, {rgba[1]}, {rgba[2]}, {rgba[3]})\nroughness = {rough}\nmetallic = {metal}\n'
    if alpha:
        s += "transparency = 1\n"
    return s + "\n"


def cyl(i, m, top, bot, h, seg=16):
    return f'[sub_resource type="CylinderMesh" id="c{i}"]\nmaterial = SubResource("m{m}")\ntop_radius = {top}\nbottom_radius = {bot}\nheight = {h}\nradial_segments = {seg}\nrings = 1\n\n'


def box(i, m, x, y, z):
    return f'[sub_resource type="BoxMesh" id="c{i}"]\nmaterial = SubResource("m{m}")\nsize = Vector3({x}, {y}, {z})\n\n'


def node(name, mesh, y, root):
    return f'[node name="{name}" type="MeshInstance3D" parent="."]\ntransform = Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, {y}, 0)\nmesh = SubResource("c{mesh}")\n\n'


def scene(name, mats, meshes, nodes):
    out = "[gd_scene format=3]\n\n" + "".join(mats) + "".join(meshes)
    out += f'[node name="{name}" type="Node3D"]\n\n' + "".join(nodes)
    with open(os.path.join(SCN, name + ".tscn"), "w") as f:
        f.write(out)


def glass_margarita(name, drink, rim):
    # a stemmed glass: foot, stem, a wide shallow bowl, the drink in it, a salt rim
    scene(name,
          [mat(0, (0.85, 0.9, 0.92, 0.35), 0.05, 0, True), mat(1, drink, 0.2, 0, True), mat(2, rim, 0.9)],
          [cyl(0, 0, 0.035, 0.035, 0.004), cyl(1, 0, 0.004, 0.004, 0.07), cyl(2, 0, 0.06, 0.012, 0.055),
           cyl(3, 1, 0.054, 0.014, 0.045), cyl(4, 2, 0.061, 0.061, 0.004)],
          [node("Foot", 0, 0.002, name), node("Stem", 1, 0.039, name), node("Bowl", 2, 0.1, name),
           node("Drink", 3, 0.096, name), node("Salt", 4, 0.126, name)])


def main():
    os.makedirs(SCN, exist_ok=True)
    # beer: a pint glass of amber with a head
    scene("cu_beer",
          [mat(0, (0.85, 0.9, 0.92, 0.35), 0.05, 0, True), mat(1, (0.85, 0.55, 0.12, 0.85), 0.2, 0, True), mat(2, (0.97, 0.95, 0.88, 1), 0.9)],
          [cyl(0, 0, 0.042, 0.032, 0.15), cyl(1, 1, 0.039, 0.03, 0.12), cyl(2, 2, 0.04, 0.04, 0.02)],
          [node("Glass", 0, 0.075, "cu_beer"), node("Beer", 1, 0.062, "cu_beer"), node("Head", 2, 0.132, "cu_beer")])
    glass_margarita("cu_margarita", (0.75, 0.9, 0.45, 0.8), (0.97, 0.97, 0.95, 1))
    glass_margarita("cu_topshelf", (0.92, 0.88, 0.5, 0.8), (0.97, 0.97, 0.95, 1))
    # the coupon: a paper slip
    scene("cu_coupon", [mat(0, (0.98, 0.94, 0.82, 1), 0.95), mat(1, (0.78, 0.13, 0.17, 1), 0.9)],
          [box(0, 0, 0.15, 0.002, 0.07), box(1, 1, 0.13, 0.0025, 0.012)],
          [node("Slip", 0, 0.001, "cu_coupon"), node("Band", 1, 0.0012, "cu_coupon")])
    # the doubloon: a thin gold coin
    scene("cu_doubloon", [mat(0, (0.95, 0.75, 0.25, 1), 0.3, 0.9)],
          [cyl(0, 0, 0.022, 0.022, 0.003, 24)],
          [node("Coin", 0, 0.0015, "cu_doubloon")])

    icons = {
        "cu_beer": ((0.85, 0.55, 0.12), "BEER"),
        "cu_margarita": ((0.6, 0.85, 0.4), "MARG."),
        "cu_topshelf": ((0.92, 0.82, 0.4), "TOP\nSHELF"),
        "cu_coupon": ((0.98, 0.94, 0.82), "COUPON"),
        "cu_doubloon": ((0.95, 0.75, 0.25), "DOUB-\nLOON"),
    }
    try:
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", 40)
        small = ImageFont.truetype("DejaVuSans-Bold.ttf", 22)
    except OSError:
        font = small = ImageFont.load_default()
    for k, (c, label) in icons.items():
        im = Image.new("RGBA", (256, 256), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        col = tuple(int(v * 255) for v in c) + (255,)
        if k == "cu_doubloon":
            d.ellipse((28, 28, 228, 228), fill=col, outline=(120, 80, 20, 255), width=8)
        elif k == "cu_coupon":
            d.rectangle((16, 64, 240, 192), fill=col, outline=(200, 32, 44, 255), width=8)
        else:
            d.rounded_rectangle((40, 24, 216, 232), 24, fill=col, outline=(40, 40, 40, 255), width=6)
        d.multiline_text((128, 120), label, font=font, fill=(30, 30, 30, 255), anchor="mm", align="center")
        d.text((128, 214 if k != "cu_coupon" else 176), "STAND-IN", font=small, fill=(200, 0, 0, 255), anchor="mm")
        im.save(os.path.join(ICO, k + ".png"))


if __name__ == "__main__":
    main()
