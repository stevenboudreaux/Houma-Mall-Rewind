"""Pull the hand-built storefront notes out of the current game (index.html).

The current game draws ~50 storefronts by hand, each introduced by a comment
like "/* ---- Corn Dog 7, from a photograph of the Southland Mall shop: ... */".
This collects those notes, matches them to map stores, and records what the
note says it was built from (photos, one photo, memory, descriptions), which
seeds the storefront accuracy meter.
Run: python3 tools/extract_facades.py ../Houma-Mall-Rewind/index.html
Writes facade_notes.json next to layout_mall.json.
"""
import json, os, re, sys

HERE = os.path.dirname(__file__)


def norm(s):
    return re.sub(r"[^a-z0-9]", "", s.lower())


def main(src):
    s = open(src, encoding="utf-8").read()
    d = json.loads(re.search(r'<script[^>]*id="mall-data"[^>]*>(.*?)</script>', s, re.S).group(1))
    stores = {norm(st["name"]): st["name"] for st in d["stores"] if st["name"]}
    alias = {"fwwoolworth": "WOOLWORTH", "woolworthredpanelfascia": "WOOLWORTH", "paylessshoesource": "PAYLESS SHOES",
             "theshoedept": "THE SHOE DEPT", "gnc": "GENERAL NUTRITION CENTER", "regis": "REGIS HAIRSTYLISTS",
             "gryder": "GRYDER'S", "gryder'sshoes": "GRYDER'S", "bdalton": "B. DALTON BOOKSELLER",
             "fatherson": "FATHER & SON", "claires": "CLAIRE'S BOUTIQUES", "jw": "JW", "cucosmexicancafe": "CUCOS BORDER CAFE"}
    notes = {}
    for m in re.finditer(r"/\* ---- (.*?)---- \*/", s, re.S):
        body = re.sub(r"\s+", " ", m.group(1)).strip()
        head = re.split(r"[,:(]", body, maxsplit=1)[0].strip()
        key = norm(head)
        name = stores.get(key) or alias.get(key)
        if not name:
            for k, v in stores.items():
                if key and (key.startswith(k) or k.startswith(key)) and len(k) > 3:
                    name = v
                    break
        if not name:
            continue
        low = body.lower()
        if "from the photos" in low or "photographs" in low:
            src_kind = "photos"
        elif "from the photo" in low or "from a photograph" in low or "from the photograph" in low:
            src_kind = "photo"
        elif "memory" in low:
            src_kind = "memory"
        elif "descriptions only" in low:
            src_kind = "description"
        else:
            src_kind = "unstated"
        prev = notes.get(name)
        entry = {"note": body, "source": src_kind}
        if prev:
            prev["note"] += " || " + body
            if prev["source"] in ("unstated", "description") and src_kind not in ("unstated", "description"):
                prev["source"] = src_kind
        else:
            notes[name] = entry
    out = os.path.join(HERE, "..", "facade_notes.json")
    json.dump(notes, open(out, "w"), indent=1)
    counts = {}
    for v in notes.values():
        counts[v["source"]] = counts.get(v["source"], 0) + 1
    missing = sorted(v for v in stores.values() if v not in notes)
    print(len(notes), "stores with hand-built fronts", counts)
    print("no hand-built front:", len(missing), missing)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "..", "..", "Houma-Mall-Rewind", "index.html"))
