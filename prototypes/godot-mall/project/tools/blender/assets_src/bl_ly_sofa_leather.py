"""SOFA-A variant 4, "brown leather": a dark brown leather three-seat sofa with padded track arms
(welted), three loose back cushions, three welted seat cushions and block legs; two cream-and-black
striped pillows (refs/new/sears IMG_4413_t000_095-101). ~2.3 m. Guessed: the legs (hidden at t097-101),
the leather grain scale.
Generator and sources: _lynns_sofa.py, design/lynns/inventory.md ("SOFA-A")."""
import _lynns_sofa

META = {
    "id": "bl_ly_sofa_leather", "class": "large_fixture", "tex": 2048, "ao": 0.55, "out": "lynns", "ao_samples": 16,
    "refs": [["refs/new/sears/IMG_4413_t000_100.jpg", [0.0, 0.65, 1.0, 1.0], "IMG_4413 t100"],
             ["refs/new/sears/IMG_4413_t000_097.jpg", [0.0, 0.45, 1.0, 0.95], "IMG_4413 t097"]],
}


def build():
    _lynns_sofa.build(W=2.30, D=1.0, seat_h=0.48, back_h=0.94, arm="track", arm_w=0.22, arm_h=0.64, back="loose", n_back=3, n_seat=3, leg="block", leg_h=0.10, welt=True, fabric=("leather", "#55433a"), leg_wood=("#2c1f17", "#140c08"), pillows=[("stripe", "#e9e3d6", "#26231f", "linen", 0.52), ("stripe", "#e9e3d6", "#26231f", "linen", 0.52)])
