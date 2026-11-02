"""Evidence sheets (production/qa/evidence/wsB1-*.jpg): writes turntable specs and renders them.
  python3 sheets.py bodies|hair|outfits ...   (renders with the bpy python)"""
import json, os, subprocess, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import sliders
HERE = os.path.dirname(os.path.abspath(__file__)); PROJ = os.path.abspath(os.path.join(HERE, "..", "..", ".."))
EV = os.path.abspath(os.path.join(PROJ, "..", "..", "..", "production", "qa", "evidence"))
BPY = os.environ.get("BPY", "/home/claude/bvenv/bin/python")
TONE = {"female": "#cf9a76", "male": "#83553a"}
HAIRC = {"black": "#1b1714", "dark brown": "#3b2a1f", "brown": "#5e4330", "light brown": "#8a6a4c", "auburn": "#7a3a22", "dark blonde": "#a88a5e", "grey": "#9a9690", "white": "#e8e6e2"}

BASE_BODY = {"female": ["base_briefs"], "male": ["base_boxerbriefs"]}   # the compulsory minimum: a base bottom, no top


def item(sex, values, label, extra=(), **kw):
    d = {"glbs": ["models/characters/body_%s.glb" % sex] + list(extra), "shapes": sliders.shape_weights(values, sex),
         "turns": sliders.bone_turns(values), "pose": "apose", "label": label}
    d.update(kw); return d

def render(name, spec, jpg=True):
    os.makedirs(os.path.join(PROJ, ".scratch", "chars"), exist_ok=True)
    sp = os.path.join(PROJ, ".scratch", "chars", name + ".json"); json.dump(spec, open(sp, "w"))
    png = os.path.join(PROJ, ".scratch", "chars", name + ".png")
    subprocess.run([BPY, os.path.join(HERE, "turntable.py"), png, sp], check=True, stdout=subprocess.DEVNULL)
    if jpg:
        from PIL import Image
        im = Image.open(png).convert("RGB"); im.thumbnail((1600, 1600)); out = os.path.join(EV, "wsB1-%s.jpg" % name)
        im.save(out, quality=86); print("evidence", out)
    return png

def bodies(sex):
    ex = sliders.PRESETS["extremes"]
    base = ["models/characters/%s_%s.glb" % (b, sex) for b in BASE_BODY[sex]]
    its = [item(sex, {}, "%s neutral" % sex, extra=base)] + [item(sex, v, k, extra=base) for k, v in ex.items()]
    return {"items": its, "angles": [0, 90, 180], "tile": 200, "cols": 3, "colors": {"skin": TONE[sex]},
            "title": "B1 %s body (game mesh, 14.8k tris) in its base layer: neutral and the five cast-sheet extremes, A-pose, front / side / back" % sex}

def presets(sex):
    base = ["models/characters/%s_%s.glb" % (b, sex) for b in BASE_BODY[sex]]
    its = [item(sex, v, k, extra=base) for k, v in sliders.PRESETS[sex].items()]
    return {"items": its, "angles": [0, 90], "tile": 200, "cols": 3, "colors": {"skin": TONE[sex]}, "title": "B1 %s presets" % sex}

def hair(sex):
    import hair as H
    its = []
    for n, S in H.STYLES.items():
        it = item(sex, {}, S["label"], extra=["models/characters/hair_%s_%s.glb" % (n, sex)], zoom=0.62, focus_z=1.35 if sex == "female" else 1.47)
        it["colors"] = {"hair": HAIRC[S["color"]]}
        its.append(it)
    return {"items": its, "angles": [0, 70, 180], "tile": 170, "aspect": 1.2, "cols": 4, "colors": {"skin": TONE[sex], "lashes": "#1b1714"},
            "title": "B1 hair library on the %s body (default colours; every style tints)" % sex}

BASE = {"female": ["base_sportsbra", "base_briefs"], "male": ["base_boxerbriefs"]}
OUTFIT_EXTREMES = {"female": ["curvy larger", "skinny 74"], "male": ["heavy-set 52", "muscular 20"]}


def pieces_sheet(sex, ids, title, name, base=True, extremes=None):
    import glob
    ex = sliders.PRESETS["extremes"]
    its = []
    for pid in ids:
        for e in (extremes or OUTFIT_EXTREMES[sex]):
            under = [b for b in BASE[sex] if base and not pid.startswith("base_") and not pid.startswith("full_") or (base and pid.startswith("full_") and b.endswith(("briefs", "boxerbriefs")))]
            glbs = ["models/characters/%s_%s.glb" % (u, sex) for u in under] + ["models/characters/%s_%s.glb" % (pid, sex)]
            if pid.startswith("top_flannel"):
                glbs.insert(-1, "models/characters/top_tee_%s.glb" % sex)
            if pid.startswith("top_cardigan"):
                glbs.insert(-1, "models/characters/top_buttondown_%s.glb" % sex)
            it = item(sex, ex[e], "%s / %s" % (pid, e), extra=glbs)
            its.append(it)
    spec = {"items": its, "angles": [0, 150], "tile": 150, "aspect": 1.7, "cols": 6, "colors": {"skin": TONE[sex]},
            "title": title}
    return render(name, spec)


def catalogue_ids(sex):
    import garments as G
    import fields
    return [c[0] for c in G.catalogue(type("L", (), {"chest": 0, "waist": 0, "crotch": 0, "neck_base": 0, "hips_joint": 0, "rise": lambda s, f: 0})(), sex) if sex in c[4]]


if __name__ == "__main__":
    for a in sys.argv[1:]:
        if a == "bodies":
            for s in ("female", "male"):
                render("body-%s-extremes" % s, bodies(s))
        if a == "hair":
            for s in ("female", "male"):
                render("hair-%s" % s, hair(s))
        if a in ("base", "tops", "bottoms", "full", "shoes", "extras"):
            pre = {"base": "base_", "tops": "top_", "bottoms": "bot_", "full": "full_", "shoes": "shoe_", "extras": "x_"}[a]
            for s in ("female", "male"):
                ids = [i for i in catalogue_ids(s) if i.startswith(pre)]
                pieces_sheet(s, ids, "B1 %s on the %s body at two extremes (%s); front / back; unhidden body (strict: any poke-through shows)" % (a, s, " and ".join(OUTFIT_EXTREMES[s])),
                             "outfit-%s-%s" % (a, s), base=(a != "base"))
        if a == "presets":
            for s in ("female", "male"):
                render("body-%s-presets" % s, presets(s))
