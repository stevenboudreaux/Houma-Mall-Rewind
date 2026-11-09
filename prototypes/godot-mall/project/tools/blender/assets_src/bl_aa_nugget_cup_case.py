"""Auntie Anne's cup of pretzel nuggets as it stands in the warmer (workstream FOOD3D, Nov 8 2026): the hand cup
(bl_aa_nugget_cup) with a few nuggets spilled round it (two on the tier in front, one by its foot, one caught on
the rim). Instanced eight times on the warmer's front tier by tools/stores/auntie_annes/store.gd (the warmer's own
closed cups are gone: bl_aa_warmer CUPS = False). Not an item. See bl_aa_nugget_cup for sources and guesses.
"""
import bl_aa_nugget_cup as C

META = dict(C.META, id="bl_aa_nugget_cup_case", icon=False)


def build():
    C.SPILL = True
    C.build()
