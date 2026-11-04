"""BED-A suite "oak" (French limed-oak suite with a cream linen headboard): the nightstand. Generator, sizes and sources: _lynns_bedroom.py,
design/lynns/inventory.md ("BED-A"). Guessed: the case goods (one oak chest in the background of t090; dresser and nightstand follow it), the pulls."""
import _lynns_bedroom

META = {
    "id": "bl_ly_night_oak", "class": "small_fixture", "tex": 1024, "ao": 0.5, "out": "lynns", "ao_samples": 16,
    "refs": [["refs/new/sears/IMG_4413_t000_090.jpg", [0, 0.3, 1, 0.85], "IMG_4413 t090"],
             ["refs/new/sears/IMG_4413_t000_089.jpg", [0, 0.15, 1, 0.85], "IMG_4413 t089"]],
}


def build():
    _lynns_bedroom.nightstand("oak")
