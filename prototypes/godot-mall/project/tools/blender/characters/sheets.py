"""Piece sheets (B1; B-FIX, Steven, Nov 2, final: every character is clothed at all times).
Renders turntable sheets of FULLY CLOTHED ADULT bodies only, into .scratch/chars/ (never committed,
never production/qa/evidence: in-game shots of clothed adults are the only character evidence).
There are no body, preset or base-layer sheets: every item wears a closed top and a bottom (or a full
outfit), and child extremes (youth > 0) are refused.
  python3 sheets.py hair|tops|bottoms|full|shoes|extras ...   (renders with the bpy python)"""
import json, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sliders
HERE = os.path.dirname(os.path.abspath(__file__)); PROJ = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
OUT = os.path.join(PROJ, ".scratch", "chars")
BPY = os.environ.get("BPY", "/home/claude/bvenv/bin/python")
TONE = {"female": "#cf9a76", "male": "#83553a"}
HAIRC = {"black": "#1b1714", "dark brown": "#3b2a1f", "brown": "#5e4330", "light brown": "#8a6a4c", "auburn": "#7a3a22", "dark blonde": "#a88a5e", "grey": "#9a9690", "white": "#e8e6e2"}
# the clothed rule (scripts/char_body.gd)
CLOSED_TOPS = ("top_tee", "top_polo", "top_buttondown", "top_sweatshirt", "top_tank", "top_babytee")
BOTTOMS = ("bot_",)
FULL = ("full_football", "full_cheer", "full_waitress", "full_coveralls")
DRESS = {"top": "top_tee", "bottom": "bot_jeans"}


def dressed(sex, ids):
    """ids plus a tee / jeans where they leave the chest or the groin bare; refuses base pieces"""
    ids = list(ids)
    if any(i.startswith("base_") for i in ids):
        raise SystemExit("sheets.py: base-layer pieces are not rendered (B-FIX)")
    if not any(i in FULL for i in ids):
        if not any(i in CLOSED_TOPS for i in ids): ids.insert(0, DRESS["top"])
        if not any(i.startswith(BOTTOMS) for i in ids): ids.insert(0, DRESS["bottom"])
    return ["models/characters/%s_%s.glb" % (i, sex) for i in ids]


def adult(values):
    if float(values.get("youth", 0)) > 0 or float(values.get("youth_small", 0)) > 0:
        raise SystemExit("sheets.py: no sheets of child figures (B-FIX)")
    return values


def item(sex, values, label, ids=(), **kw):
    adult(values)
    d = {"glbs": ["models/characters/body_%s.glb" % sex] + dressed(sex, ids), "shapes": sliders.shape_weights(values, sex),
         "turns": sliders.bone_turns(values), "pose": "apose", "label": label}
    d.update(kw); return d

def render(name, spec, jpg=True):
    os.makedirs(OUT, exist_ok=True)
    sp = os.path.join(OUT, name + ".json"); json.dump(spec, open(sp, "w"))
    png = os.path.join(OUT, name + ".png")
    subprocess.run([BPY, os.path.join(HERE, "turntable.py"), png, sp], check=True, stdout=subprocess.DEVNULL)
    if jpg:
        from PIL import Image
        im = Image.open(png).convert("RGB"); im.thumbnail((1600, 1600)); out = os.path.join(OUT, "sheet-%s.jpg" % name)
        im.save(out, quality=86); print("sheet (scratch, not evidence)", out)
    return png

def hair(sex):
    import hair as H
    its = []
    for n, S in H.STYLES.items():
        it = item(sex, {}, S["label"], ids=["hair_%s" % n], zoom=0.62, focus_z=1.35 if sex == "female" else 1.47)
        it["colors"] = {"hair": HAIRC[S["color"]]}
        its.append(it)
    return {"items": its, "angles": [0, 70, 180], "tile": 170, "aspect": 1.2, "cols": 4, "colors": {"skin": TONE[sex], "lashes": "#1b1714"},
            "title": "B1 hair library on the %s body (default colours; every style tints)" % sex}

OUTFIT_EXTREMES = {"female": ["curvy larger", "skinny 74"], "male": ["heavy-set 52", "muscular 20"]}


def pieces_sheet(sex, ids, title, name, extremes=None):
    ex = sliders.PRESETS["extremes"]
    its = []
    for pid in ids:
        for e in (extremes or OUTFIT_EXTREMES[sex]):
            wear = [pid]
            if pid.startswith("top_flannel"): wear.insert(0, "top_tee")
            if pid.startswith("top_cardigan"): wear.insert(0, "top_buttondown")
            its.append(item(sex, ex[e], "%s / %s" % (pid, e), ids=wear))
    spec = {"items": its, "angles": [0, 150], "tile": 150, "aspect": 1.7, "cols": 6, "colors": {"skin": TONE[sex]},
            "title": title}
    return render(name, spec)


def catalogue_ids(sex):
    import garments as G
    import fields
    return [c[0] for c in G.catalogue(type("L", (), {"chest": 0, "waist": 0, "crotch": 0, "neck_base": 0, "hips_joint": 0, "rise": lambda s, f: 0})(), sex) if sex in c[4]]


if __name__ == "__main__":
    for a in sys.argv[1:]:
        if a in ("bodies", "presets", "base"):
            raise SystemExit("sheets.py: '%s' sheets are gone (B-FIX: no undressed or base-layer sheets)" % a)
        if a == "hair":
            for s in ("female", "male"):
                render("hair-%s" % s, hair(s))
        if a in ("tops", "bottoms", "full", "shoes", "extras"):
            pre = {"tops": "top_", "bottoms": "bot_", "full": "full_", "shoes": "shoe_", "extras": "x_"}[a]
            for s in ("female", "male"):
                ids = [i for i in catalogue_ids(s) if i.startswith(pre)]
                pieces_sheet(s, ids, "B1 %s on the %s body at two adult extremes (%s), dressed (tee / jeans where the piece leaves the chest or groin bare)" % (a, s, " and ".join(OUTFIT_EXTREMES[s])),
                             "outfit-%s-%s" % (a, s))
