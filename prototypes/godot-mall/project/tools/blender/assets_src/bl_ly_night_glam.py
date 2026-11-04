"""BED-A suite "glam" (white lacquer glam suite with brass): the nightstand. Generator, sizes and sources: _lynns_bedroom.py,
design/lynns/inventory.md ("BED-A"). Guessed: the bed pairing (the light-grey upholstered panel bed from the mattress gallery, 4412 t045), the chest and nightstand (from the six-drawer dresser, t086)."""
import _lynns_bedroom

META = {
    "id": "bl_ly_night_glam", "class": "small_fixture", "tex": 1024, "ao": 0.5, "out": "lynns", "ao_samples": 16,
    "refs": [["refs/new/sears/IMG_4413_t000_086.jpg", [0, 0.25, 1, 0.75], "IMG_4413 t086"],
             ["refs/new/sears/IMG_4413_t000_087.jpg", [0, 0.2, 1, 0.95], "IMG_4413 t087"]],
}


def build():
    _lynns_bedroom.nightstand("glam")
