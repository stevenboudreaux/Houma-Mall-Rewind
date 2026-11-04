"""SOFA-A variant 1, "sage": a pale sage-grey three-seat sofa with three loose back cushions,
slim track arms, three welted seat cushions and slim tapered dark legs; two grey velvet throw pillows. The
"coastal/glam" group by the burl tables (refs/new/sears IMG_4413_t000_071-081). Sizes: ~2.25 m long
against the 0.7 m column behind it (t079). Generator and sources: _lynns_sofa.py, design/lynns/inventory.md.
Guessed: the back's exact depth (never seen from behind), the leg wood."""
import _lynns_sofa

META = {
    "id": "bl_ly_sofa_sage", "class": "large_fixture", "tex": 2048, "ao": 0.55, "out": "lynns", "ao_samples": 16,
    "refs": [["refs/new/sears/IMG_4413_t000_078.jpg", [0.0, 0.40, 1.0, 0.78], "IMG_4413 t078"],
             ["refs/new/sears/IMG_4413_t000_080.jpg", [0.0, 0.40, 1.0, 0.85], "IMG_4413 t080"]],
}


def build():
    _lynns_sofa.build(W=2.24, D=0.96, seat_h=0.47, back_h=0.88, arm="track", arm_w=0.14, arm_h=0.64,
                      back="loose", n_back=3, n_seat=3, leg="tapered", leg_h=0.14, welt=True,
                      fabric=("linen", "#b9bcae"), leg_wood=("#5c4433", "#2e2018"),
                      pillows=[("solid", "#6d6c68", "#6d6c68", "velvet", 0.55), ("solid", "#6d6c68", "#6d6c68", "velvet", 0.55)])
