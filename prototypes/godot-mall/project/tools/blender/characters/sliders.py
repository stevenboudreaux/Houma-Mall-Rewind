"""Slider values -> blend shape weights, the rule the editor (B2) implements from the manifest:

  slider x > 0  ->  '<name>+' = x          slider x < 0  ->  '<name>-' = -x
  corrective 'c_a_b[_c]' = product of the named side weights (e.g. weight+ * muscle-)
  skeleton sliders (posture) give bone rest rotations instead (manifest 'bone_sliders').
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
KEYS = json.load(open(os.path.join(HERE, "keys.json")))
PRESETS = json.load(open(os.path.join(HERE, "presets.json")))


def shape_weights(values, sex):
    w = {}
    for s in KEYS["sliders"]:
        if "bones" in s or (s.get("sex") and s["sex"] != sex):
            continue
        x = float(values.get(s["name"], 0.0))
        lo, hi = s["range"]
        x = max(lo, min(hi, x))
        if x > 0 and "+" in s:
            w[s["name"] + "+"] = x
        elif x < 0 and "-" in s:
            w[s["name"] + "-"] = -x
    for combo in KEYS["correct"]:
        p = 1.0
        for c in combo:
            p *= w.get(c, 0.0)
        if p:
            w["c_" + "_".join(combo)] = p
    return w


def bone_turns(values):
    """{bone: degrees about the body's X axis (forward bend +)} from skeleton sliders."""
    out = {}
    for s in KEYS["sliders"]:
        if "bones" in s:
            x = float(values.get(s["name"], 0.0))
            for b, deg in s["bones"].items():
                if deg:
                    out[b] = out.get(b, 0.0) + deg * x
    return out
