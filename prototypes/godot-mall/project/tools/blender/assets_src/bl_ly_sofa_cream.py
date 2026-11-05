"""SOFA-A variant 2, "cream English arm": an ivory three-seat sofa with low set-back rolled (English) arms,
three loose back cushions, three welted seat cushions and turned dark legs; ivory solids and two grey
woven-stripe throw pillows (refs/new/sears IMG_4413_t000_115-119). ~2.3 m against the 0.7 m column at t117.
Guessed: the leg turning, the back from behind.
Generator and sources: _lynns_sofa.py, design/lynns/inventory.md ("SOFA-A")."""
import _lynns_sofa

META = {
    "id": "bl_ly_sofa_cream", "class": "large_fixture", "tex": 2048, "ao": 0.55, "out": "lynns", "ao_samples": 16,
    "refs": [["refs/new/sears/IMG_4413_t000_117.jpg", [0.0, 0.38, 1.0, 0.8], "IMG_4413 t117"],
             ["refs/new/sears/IMG_4413_t000_116.jpg", [0.0, 0.35, 1.0, 0.85], "IMG_4413 t116"]],
}


def build():
    _lynns_sofa.build(W=2.34, D=1.0, seat_h=0.48, back_h=0.92, arm="english", arm_w=0.19, arm_h=0.60, back="loose", n_back=3, n_seat=3, leg="turned", leg_h=0.13, welt=True, fabric=("boucle", "#e4dccb"), leg_wood=("#4a3324", "#24170f"), pillows=[("solid", "#efe9dc", "#efe9dc", "linen", 0.55), ("solid", "#efe9dc", "#efe9dc", "linen", 0.55), ("stripe", "#efe9dc", "#5f5c57", "linen", 0.48), ("stripe", "#efe9dc", "#5f5c57", "linen", 0.48)])
