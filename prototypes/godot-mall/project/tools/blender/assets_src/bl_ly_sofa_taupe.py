"""SOFA-A variant 3, "taupe slipcover": a putty-taupe slipcovered sofa with rolled arms, a dressmaker
skirt to the floor, two loose back cushions over two long seat cushions; two cream pillows with a mustard
medallion (refs/new/sears IMG_4413_t000_051-053, the round X-base cocktail table in front). ~2.2 m.
Guessed: the back height, the skirt's pleats (kick pleats at the corners not modelled).
Generator and sources: _lynns_sofa.py, design/lynns/inventory.md ("SOFA-A")."""
import _lynns_sofa

META = {
    "id": "bl_ly_sofa_taupe", "class": "large_fixture", "tex": 2048, "ao": 0.55, "out": "lynns", "ao_samples": 16,
    "refs": [["refs/new/sears/IMG_4413_t000_052.jpg", [0.0, 0.33, 1.0, 0.66], "IMG_4413 t052"],
             ["refs/new/sears/IMG_4413_t000_053.jpg", [0.0, 0.35, 1.0, 0.75], "IMG_4413 t053"]],
}


def build():
    _lynns_sofa.build(W=2.20, D=1.0, seat_h=0.47, back_h=0.92, arm="rolled", arm_w=0.20, arm_h=0.64, back="loose", n_back=2, n_seat=2, base="skirt", welt=True, fabric=("linen", "#a39b8d"), pillows=[("medallion", "#f2ede2", "#c99a2e", "linen", 0.52), ("medallion", "#f2ede2", "#c99a2e", "linen", 0.52)])
