"""BED-A suite "sage" (grey-wash farmhouse suite in sage grey): the bed (queen, dressed for display). Generator, sizes and sources: _lynns_bedroom.py,
design/lynns/inventory.md ("BED-A"). Guessed: the bed and the dresser/mirror (only the chest and a nightstand were filmed: the lp panel bed and the espresso suite's carcass in this finish)."""
import _lynns_bedroom

META = {
    "id": "bl_ly_bed_sage", "class": "large_fixture", "tex": 2048, "ao": 0.5, "out": "lynns", "ao_samples": 16,
    "refs": [["refs/new/sears/IMG_4413_t000_046.jpg", [0, 0.18, 0.62, 0.55], "IMG_4413 t046"],
             ["refs/new/sears/IMG_4413_t000_048.jpg", [0, 0.1, 1, 0.7], "IMG_4413 t048"]],
}


def build():
    _lynns_bedroom.bed("sage")
