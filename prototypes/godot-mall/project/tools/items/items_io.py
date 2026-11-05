#!/usr/bin/env python3
"""The item files from Python (ws/items, Nov 4 2026; design/godot-items.md): data/items/<store>.json, one schema.

Every tool that writes item entries goes through here (tools/blender/build.py, tools/prizes/make_items.py,
tools/shops/make_standins.py), so an entry lands in its store's file with its category, and an existing id is
updated where it already is (never moved, never renamed, its category kept).

    import items_io                      # sys.path: tools/items
    items_io.load()                      -> {id: entry}, in file order
    items_io.upsert([entry, ...])        # replace by id where it is, else add to the store's file
    items_io.set_field(ids, "year", "both")

The game reads the same files with scripts/items/item_db.gd (the one loader); tools/qa/items_test.gd checks them.
"""
import collections
import glob
import json
import os

O = collections.OrderedDict
HERE = os.path.dirname(os.path.abspath(__file__))
DIR = os.path.normpath(os.path.join(HERE, "..", "..", "data", "items"))

# scripts/items/item_db.gd CATEGORIES (keep the two the same)
CATEGORIES = ["food", "drink", "book", "toy", "electronics", "home", "clothing", "stationery", "token", "story"]
# a store's file (the layout's store name -> data/items/<file>.json); an entry with no store goes to "misc"
FILES = {"POCKET CHANGE": "pocket_change", "GAMES, INC.": "games_inc", "B. DALTON BOOKSELLER": "b_dalton",
         "WOOLWORTH": "woolworth", "CORN DOG 7": "corn_dog_7", "CUCOS": "cucos", "RADIO SHACK": "radio_shack",
         "GUMBALLS": "gumballs", "GREAT AMERICAN COOKIE CO": "great_american_cookie", "KARMELKORN": "karmelkorn",
         "ORANGE JULIUS": "orange_julius", "TEE TAI'S": "tee_tais"}
ORDER = ["id", "name", "category", "subcategory", "class", "scene", "icon", "year", "store"]
NOTE = (" One item schema for every file here: design/godot-items.md (id, name, category, subcategory, class, scene, "
        "icon, year, store, and the optional fields it lists). Read by scripts/items/item_db.gd; written by hand or by "
        "tools/items/items_io.py (tools/blender/build.py, tools/prizes/make_items.py, tools/shops/make_standins.py). "
        "Never change an id.")


def _files():
    return sorted(glob.glob(os.path.join(DIR, "*.json")))


def _read(path):
    with open(path) as f:
        d = json.load(f, object_pairs_hook=O)
    return d if isinstance(d, dict) else O([("_", ""), ("items", d)])


def _write(path, d):
    with open(path, "w") as f:
        f.write(json.dumps(d, indent=1, ensure_ascii=False) + "\n")


def _ordered(e):
    n = O((k, e[k]) for k in ORDER if k in e)
    for k in e:
        if k not in n:
            n[k] = e[k]
    return n


def load():
    """{id: entry} for every item, in file order (files sorted by name)."""
    out = O()
    for p in _files():
        for e in _read(p)["items"]:
            out[e["id"]] = e
    return out


def file_for(entry):
    return os.path.join(DIR, FILES.get(entry.get("store", ""), "misc") + ".json")


def upsert(entries, head=None):
    """Write entries: an id already in a file is replaced there (keeping its category and subcategory unless the
    new entry gives them); a new id goes to its store's file and must carry category and subcategory."""
    docs = {p: _read(p) for p in _files()}
    where = {}
    for p, d in docs.items():
        for i, e in enumerate(d["items"]):
            where[e["id"]] = (p, i)
    for e in entries:
        e = O(e)
        if e["id"] in where:
            p, i = where[e["id"]]
            old = docs[p]["items"][i]
            for k in ("category", "subcategory"):
                if k not in e and k in old:
                    e[k] = old[k]
            docs[p]["items"][i] = _ordered(e)
            continue
        if e.get("category") not in CATEGORIES or not e.get("subcategory"):
            raise SystemExit("items_io: new item %s needs a category (%s) and a subcategory" % (e["id"], ", ".join(CATEGORIES)))
        p = file_for(e)
        if p not in docs:
            docs[p] = O([("_", (head or e.get("store", "Items")) + "." + NOTE), ("items", [])])
        docs[p]["items"].append(_ordered(e))
        where[e["id"]] = (p, len(docs[p]["items"]) - 1)
    for p, d in docs.items():
        _write(p, d)


def set_field(ids, key, value):
    """Set one field on existing items (e.g. year 'both')."""
    ids = set(ids)
    for p in _files():
        d = _read(p)
        hit = False
        for e in d["items"]:
            if e["id"] in ids:
                e[key] = value
                hit = True
        if hit:
            _write(p, d)
