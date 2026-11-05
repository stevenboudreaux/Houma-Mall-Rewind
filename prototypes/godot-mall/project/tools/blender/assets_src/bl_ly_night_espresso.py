"""BED-A suite "espresso" (Louis Philippe panel suite in espresso): the nightstand. Generator, sizes and sources: _lynns_bedroom.py,
design/lynns/inventory.md ("BED-A"). Guessed: the bed's footboard height and the panel profile (seen at an angle, t120-125)."""
import _lynns_bedroom

META = {
    "id": "bl_ly_night_espresso", "class": "small_fixture", "tex": 1024, "ao": 0.5, "out": "lynns", "ao_samples": 16,
    "refs": [["refs/new/sears/IMG_4413_t000_029.jpg", [0, 0.2, 1, 0.7], "IMG_4413 t029"],
             ["refs/new/sears/IMG_4413_t000_120.jpg", [0, 0.3, 1, 0.65], "IMG_4413 t120"]],
}


def build():
    _lynns_bedroom.nightstand("espresso")
