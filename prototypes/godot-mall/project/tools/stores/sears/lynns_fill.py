"""Lynn's Interiors (2026), pass 2: fill the floor with the pack furniture (and reuse the generator sofas and
suites) — workstream LYNNS (Nov 4 2026). design/lynns/layout.md "Pass 2", design/lynns/asset-manifest.md.

Writes the pass-2 groups into data/lynns/placements.json (groups with "pass": 2 are replaced; the phase-1
groups are kept), adds the pack models to its "models" table from models/lynns/pack/manifest.json, and checks
every footprint against the columns, partitions, doorways, the main aisle and the other pieces.

The JSON is the source of truth once written: Steven nudges pieces there. Re-running this script rewrites
only the "pass": 2 groups (so a nudge to one of those is lost on a re-run; move the group to "pass": 3 to keep it).

Item: [model, x, z, yaw_deg] or [model, x, z, yaw_deg, y] (y = on top of another piece: lamps on tables).
Run: python3 tools/stores/sears/lynns_fill.py [--check-only]
"""
import json, math, os, re, sys

P = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
PL = os.path.join(P, "data", "lynns", "placements.json")
MAN = os.path.join(P, "models", "lynns", "pack", "manifest.json")

COLS_X = [-35.5, -26.5, -17.5, -8.5, 0.5, 9.5, 18.5, 27.5]
COLS_Z = [-101.0, -110.0, -119.0, -128.0, -137.0]
PIPES = [[14.0, -133.0], [19.5, -133.0], [25.0, -133.0], [14.0, -140.0], [19.5, -140.0], [25.0, -140.0]]
X0, X1, ZB, ZF = -40.0, 30.0, -146.0, -96.3
PARTS = [
    [-40.0, -128.0, -17.5, -128.0, [[-31.0, -24.0]]],
    [-17.5, -146.0, -17.5, -128.0, [[-136.0, -131.0]]],
    [-26.5, -128.0, -26.5, -110.0, [[-122.0, -116.0]]],
    [-40.0, -110.0, -26.5, -110.0, []],
    [-17.5, -137.0, -8.5, -137.0, []],
    [-8.5, -146.0, -8.5, -137.0, [[-142.4, -140.6]]],
    [0.5, -146.0, 0.5, -137.0, []],
    [0.5, -137.0, 9.5, -137.0, []],
    [9.5, -146.0, 9.5, -128.0, [[-137.0, -131.0]]],
    [9.5, -128.0, 30.0, -128.0, [[13.0, 21.0]]],
]
AISLE = [-6.0, -2.0]
KEEP_CLEAR = [  # [x0, z0, x1, z1, why]
    [-6.0, -146.0, -2.0, -96.3, "main aisle"],
    [-16.0, -98.8, 8.0, -96.3, "mall mouth threshold"],
    [27.0, -121.3, 30.0, -114.7, "east storefront doors"],
    [-6.6, -146.0, -1.4, -143.5, "side exit"],
]


def rot(lx, lz, yaw):
    a = math.radians(yaw)
    return lx * math.cos(a) + lz * math.sin(a), -lx * math.sin(a) + lz * math.cos(a)


class G:
    def __init__(self, zone, name, ox, oz, yaw=0.0):
        self.zone, self.name, self.ox, self.oz, self.yaw = zone, name, ox, oz, yaw
        self.items = []

    def add(self, m, lx, lz, lyaw=0.0, y=None):
        dx, dz = rot(lx, lz, self.yaw)
        it = [m, round(self.ox + dx, 3), round(self.oz + dz, 3), round((self.yaw + lyaw + 180) % 360 - 180, 1)]
        if y is not None:
            it.append(y)
        self.items.append(it)
        return self


GROUPS = []


def group(zone, name, ox, oz, yaw=0.0):
    g = G(zone, name, ox, oz, yaw)
    GROUPS.append(g)
    return g


# ------------------------------------------------------------------ templates (local: front = +z)
LAMP_ON = {"pk_end_oak": 0.6, "pk_end_white": 0.62, "pk_end_black": 0.6, "pk_sideboard_greywash": 0.85,
           "pk_sideboard_black": 0.85, "pk_sideboard_white": 0.85, "pk_console_oak": 0.78}


def living(g, sofa, sofa_w, chairs=None, table="pk_cocktail_walnut", rug="pk_rug_sisal", end="pk_end_oak", lamp="pk_lamp_gourd", facing_sofa=None):
    """Sofa at the back facing +z, cocktail table, a rug, end tables with lamps either side, and either two
    accent chairs or a second sofa facing it."""
    g.add(rug, 0, 0.2, 90)
    g.add(sofa, 0, -1.25)
    g.add(table, 0, 0.25)
    for s in (-1, 1):
        g.add(end, s * (sofa_w / 2 + 0.35), -1.35)
        g.add(lamp, s * (sofa_w / 2 + 0.35), -1.35, 0, LAMP_ON[end])
    if facing_sofa:
        g.add(facing_sofa, 0, 1.75, 180)
    elif chairs:
        for s, c in zip((-1, 1), chairs):
            g.add(c, s * 0.62, 1.55, 180 - s * 15)
    return g


def sectional(g, sect, ott, rug="pk_rug_cream", extra=None):
    g.add(rug, 0.2, 0.3, 90)
    g.add(sect, 0, -0.6)
    g.add(ott, -0.35, 1.05)
    if extra:
        g.add(extra, 1.9, 1.3, -120)
    return g


def dining_rect(g, table, chair):
    g.add(table, 0, 0)
    for lx in (-0.5, 0.5):
        g.add(chair, lx, -0.62, 0)
        g.add(chair, lx, 0.62, 180)
    g.add(chair, -1.15, 0, 90)
    g.add(chair, 1.15, 0, -90)
    return g


def dining_round(g, table, chair):
    g.add(table, 0, 0)
    for k in range(4):
        a = k * 90 + 45
        lx, lz = rot(0, -0.78, a)
        g.add(chair, lx, lz, a)
    return g


def build():
    # ---------------- Z1 entry showcase: big sectionals either side of the aisle (IMG_4409)
    sectional(group("Z1", "entry: cream sectional + ottoman, west of the aisle", -14.9, -105.3), "pk_sect_cream", "pk_ott_cream",
              extra="pk_accent_cream")
    sectional(group("Z1", "entry: grey sectional + ottoman, east of the aisle", 5.9, -105.3), "pk_sect_grey", "pk_ott_grey",
              rug="pk_rug_vintage", extra="pk_accent_black")
    sectional(group("Z1", "entry: blue-grey sectional", -24.0, -105.3), "pk_sect_bluegrey", "pk_ott_tweed", rug="pk_rug_round")
    g = group("Z1", "entry: end tables and plants by the aisle columns", 0, 0)
    for x, z in ((-7.3, -103.0), (-0.7, -103.0), (-7.3, -107.6), (-0.7, -107.6)):
        g.add(("pk_plant_tall" if x < -3 else "pk_plant_snake") if z > -105 else "pk_end_oak", x, z, 0)
    # ---------------- Z2 west perimeter: black swivel run, bookcase wall, chest, art (IMG_4410)
    g = group("Z2", "west wall: bookcases, chest, plants", -40.0, -103.4, 90)   # back to the west wall, facing east
    g.add("pk_bookcase_walnut", 3.6, 0.25).add("pk_bookcase_walnut", 1.75, 0.25).add("pk_chest_cream", -0.4, 0.3)
    g.add("pk_bookcase_walnut", -2.3, 0.25).add("pk_plant_monstera", -4.2, 0.75)
    g = group("Z2", "swivel chair run", -33.0, -103.6, 90)
    for k in range(5):
        g.add("pk_accent_black" if k % 2 == 0 else "pk_accent_navy", (k - 2) * 1.05, 0)
    living(group("Z2", "white slipcover sofa group", -31.0, -107.6, 0), "sofa_cream", 2.36, chairs=["pk_accent_green", "pk_accent_green"],
           table="pk_cocktail_round", rug="pk_rug_round", end="pk_end_white", lamp="pk_lamp_brass")
    # ---------------- Z3 R2 motion room: power sofa + loveseat groups on round tables (IMG_4411 t037-047)
    for name, oz, sofa, love, rug in (("grey", -113.6, "pk_motion_grey", "pk_love_grey", "pk_rug_vintage"),
                                      ("cognac", -124.6, "pk_motion_cognac", "pk_love_cognac", "pk_rug_taupe")):
        g = group("Z3", "motion group: %s sofa + loveseat" % name, -32.2, oz, 0)
        g.add(rug, 0, 0.1, 90).add(sofa, 0, -1.2).add("pk_cocktail_round" if name == "grey" else "pk_cocktail_glass", 0, 0.35).add(love, 2.35, 0.55, -90)
        g.add("pk_end_black", -1.45, -1.3).add("pk_lamp_glass", -1.45, -1.3, 0, 0.6)
    g = group("Z3", "R2 west wall: brown leather motion sofas", -40.0, -118.6, 90)
    g.add("pk_motion_brown", 2.4, 0.55).add("pk_end_black", 0.95, 0.3).add("pk_motion_taupe", -0.6, 0.55).add("pk_love_brown", -2.9, 0.55)
    # ---------------- Z4 centre-west living: wingbacks, consoles + lamps, the cognac group (IMG_4411 t007-035)
    living(group("Z4", "leather sofa group", -23.6, -114.0, 0), "sofa_leather", 2.32, chairs=["pk_accent_cognac", "pk_accent_cognac"],
           table="pk_cocktail_oak", rug="pk_rug_taupe")
    living(group("Z4", "taupe slipcover facing sage", -14.2, -114.0, 0), "sofa_taupe", 2.22, facing_sofa="sofa_sage",
           table="pk_cocktail_walnut", rug="pk_rug_sisal", end="pk_end_white", lamp="pk_lamp_brass")
    g = group("Z4", "accent chairs + ottomans, console with lamps", -23.8, -123.4, 0)
    g.add("pk_rug_round", 0, 0, 0)
    for s in (-1, 1):
        g.add("pk_accent_cream", s * 0.9, -0.5, s * -20).add("pk_ott_tweed", s * 0.9, 0.75, 0)
    g.add("pk_console_oak", 0, -1.9).add("pk_lamp_gourd", -0.55, -1.9, 0, 0.78).add("pk_lamp_gourd", 0.55, -1.9, 0, 0.78)
    g = group("Z4", "cream leather sectional", -14.2, -123.6, 0)
    sectional(g, "pk_sect_creamleather", "pk_ott_cream", rug="pk_rug_vintage")
    # ---- pass 2b: density (the footage packs the floor: a second group in every open bay, the front strip filled)
    living(group("Z1", "entry: leather sofa + cognac chairs", -10.6, -105.0, 0), "sofa_leather", 2.32, chairs=["pk_accent_cognac", "pk_accent_cognac"],
           table="pk_cocktail_oak", rug="pk_rug_taupe", end="pk_end_black", lamp="pk_lamp_glass")
    living(group("Z1", "entry: taupe sofa + navy chairs", -19.6, -105.0, 0), "sofa_taupe", 2.22, chairs=["pk_accent_navy", "pk_accent_navy"],
           table="pk_cocktail_walnut", rug="pk_rug_sisal", end="pk_end_white", lamp="pk_lamp_gourd")
    g = group("Z1", "entry front row facing the mall (west of the mouth)", -21.3, -99.3, 0)
    g.add("sofa_cream", -2.6, 0).add("pk_end_oak", -0.95, 0).add("pk_lamp_brass", -0.95, 0, 0, 0.6).add("sofa_sage", 0.75, 0)
    g.add("pk_end_oak", 2.35, 0).add("pk_lamp_gourd", 2.35, 0, 0, 0.6).add("pk_accent_green", 3.6, 0.1, -20)
    g = group("Z1", "entry: accent chairs by the east aisle column", 1.8, -105.4, 0)
    g.add("pk_accent_cream", 0, -1.0, 90).add("pk_end_white", 0, 0).add("pk_lamp_gourd", 0, 0, 0, 0.62).add("pk_accent_cream", 0, 1.0, 90)
    g = group("Z2", "white sofas facing the mall", -33.4, -99.3, 0)
    g.add("sofa_cream", -1.3, 0).add("pk_end_white", 0.2, 0).add("pk_lamp_gourd", 0.2, 0, 0, 0.62).add("sofa_cream", 1.7, 0)
    g = group("Z4", "wingback-style chairs + ottomans (pack tub chairs)", -19.6, -114.4, 0)
    g.add("pk_rug_round", 0, 0, 0)
    for s_ in (-1, 1):
        g.add("pk_accent_green", s_ * 0.85, -0.45, s_ * -25).add("pk_ott_grey", s_ * 0.85, 0.8, 0)
    g.add("pk_end_oak", 0, -1.0).add("pk_lamp_brass", 0, -1.0, 0, 0.6)
    g = group("Z4", "cognac chairs and a console by the aisle", -10.4, -114.4, 0)
    g.add("pk_accent_cognac", -0.6, 0.2, 15).add("pk_accent_cognac", 0.6, 0.2, -15).add("pk_cocktail_round", 0, 1.35)
    g.add("pk_console_oak", 0, -1.2).add("pk_lamp_gourd", -0.5, -1.2, 0, 0.78).add("pk_lamp_gourd", 0.5, -1.2, 0, 0.78)
    living(group("Z4", "brown motion sofa group", -19.8, -123.6, 0), "pk_motion_brown", 2.15, chairs=["pk_reclc_brown", "pk_reclc_beige"],
           table="pk_cocktail_walnut", rug="pk_rug_taupe", end="pk_end_black", lamp="pk_lamp_glass")
    g = group("Z4", "cream accent chairs and a sideboard by the aisle", -10.4, -123.6, 0)
    g.add("pk_sideboard_white", 0, -1.3).add("pk_lamp_brass", -0.55, -1.3, 0, 0.85).add("pk_plant_small", 0.5, -1.3, 0, 0.85)
    g.add("pk_accent_cream", -0.6, 0.1, 15).add("pk_accent_black", 0.6, 0.1, -15).add("pk_end_oak", 0, 1.0)
    # ---------------- Z5 R1 recliner gallery: two facing runs along a cross aisle, curtain to the back (IMG_4412 t001-011)
    cols = ["pk_reclc_brown", "pk_reclc_beige", "pk_reclc_grey", "pk_recl_cognac", "pk_reclc_brown", "pk_recl_black",
            "pk_reclc_beige", "pk_recl_quilt", "pk_reclc_grey", "pk_recl_brown", "pk_reclc_beige", "pk_recl_grey",
            "pk_reclc_brown", "pk_recl_beige"]
    for name, z, yaw in (("south run", -133.9, 180), ("north run", -140.3, 0)):
        g = group("Z5", "recliners: %s" % name, 0, 0)
        k = 0
        x = -38.9
        while x < -19.0:
            if not any(abs(x - cx) < 1.25 for cx in (-35.5, -26.5)):
                m = cols[k % len(cols)]
                g.add(m, round(x, 2), z + (0.12 if m.startswith("pk_recl_") and yaw == 0 else -0.12 if m.startswith("pk_recl_") else 0), yaw)
                k += 1
            x += 1.2
    g = group("Z5", "recliners along the north wall + the curtain to the back", 0, 0)
    for k in range(12):
        g.add(["pk_reclc_grey", "pk_reclc_brown", "pk_reclc_beige"][k % 3], -38.9 + k * 1.2, -145.4, 0)
    g.add("pk_curtain_beige", -21.0, -145.8, 0)
    # ---------------- Z6 R4 counter room: counter tables + stools, a white iron bed by the mint door (IMG_4412 t013-021)
    g = group("Z6", "counter tables and stools", 0, 0)
    for tx, tz in ((-14.6, -139.6), (-14.6, -143.4)):
        g.add("pk_tcounter_oak", tx, tz, 0)
        for lx in (-0.42, 0.42):
            g.add("pk_stool_oak" if tz > -141 else "pk_stool_black", tx + lx, tz - 0.62, 0)
            g.add("pk_stool_oak" if tz > -141 else "pk_stool_black", tx + lx, tz + 0.62, 180)
    for k in range(4):
        g.add("pk_stool_black" if k % 2 else "pk_stool_oak", -17.0, -144.9 + k * 0.6, 90)
    g.add("pk_bediron_white", -11.0, -144.6 + 1.1, 0)   # head on the north wall
    # ---------------- Z7 R3 mattress gallery: the slatwall on the back wall, an island row, beds on the partition
    g = group("Z7", "mattress wall: sets with their heads on the slatwall", 0, 0)
    mats = ["pk_mat_navy", "pk_mat_navy", "pk_mat_grey", "pk_mat_navy", "pk_mat_white", "pk_mat_navy", "pk_mat_grey", "pk_mat_navy"]
    for k, x in enumerate([11.2, 13.4, 15.6, 17.8, 20.0, 22.2, 24.4, 26.6]):
        g.add(mats[k], x, -144.9, 0)
    g.add("pk_mat_adjustable", 28.8, -144.9, 0)
    g = group("Z7", "island row between the pipe columns", 0, 0)
    for x, m in ((11.6, "pk_mat_adjustable"), (16.0, "pk_mat_navy"), (17.6, "pk_mat_grey"), (21.5, "pk_mat_adjustable"),
                 (23.1, "pk_mat_navy"), (27.3, "pk_mat_white")):
        g.add(m, x, -135.0, 0)
    g = group("Z7", "beds on the south partition (heads on the wall)", 0, 0)
    for x, m in ((21.95, "pk_bediron_black"), (24.1, "pk_bediron_bronze"), (26.2, "bed_glam")):
        g.add(m, x, -129.25, 180)
    g.add("pk_pillowtower", 11.2, -128.6, 180)
    g = group("Z7", "adjustable bases on the west partition", 0, 0)
    for z in (-141.6, -139.6):
        g.add("pk_mat_adjustable", 10.65, z, 90)
    # ---------------- Z8 dining hall: sets in rows, sideboards on the R5 / R4 walls (IMG_4412 t049-083)
    sets = [("pk_trect_oak", "pk_chair_cush_white"), ("pk_trect_black", "pk_chair_ladder_black"), ("pk_trect_greyoak", "pk_chair_cush_grey"),
            ("pk_trect_oak", "pk_chair_ladder_espresso"), ("pk_trect_black", "pk_chair_cush_white"), ("pk_trect_greyoak", "pk_chair_ladder_black")]
    k = 0
    for x in (3.0, 7.0):
        for z in (-113.0, -116.4, -122.0, -125.4, -131.0, -134.4):
            t, c = sets[k % len(sets)]
            dining_rect(group("Z8", "dining set %d" % (k + 1), x, z, 0), t, c)
            k += 1
    rsets = [("pk_tround_espresso", "pk_chair_ladder_espresso"), ("pk_tround_white", "pk_chair_cush_grey"),
             ("pk_tround_oak", "pk_chair_cush_white"), ("pk_tround_espresso", "pk_chair_ladder_black")]
    for k, (x, z) in enumerate(((-14.6, -130.8), (-11.0, -130.8), (-14.6, -134.4), (-11.0, -134.4))):
        dining_round(group("Z8", "round dining set %d" % (k + 1), x, z, 0), *rsets[k])
    g = group("Z8", "sideboards on R5's wall (the corbel wall)", 0, 0)
    for x, m, l in ((1.9, "pk_sideboard_greywash", "pk_lamp_gourd"), (4.75, "pk_sideboard_black", "pk_lamp_brass"), (7.55, "pk_sideboard_white", "pk_lamp_glass")):
        g.add(m, x, -136.62, 0).add(l, x - 0.5, -136.62, 0, 0.85).add("pk_plant_small", x + 0.45, -136.62, 0, 0.85)
    g = group("Z8", "sideboards on R4's wall", 0, 0)
    for x, m in ((-16.0, "pk_sideboard_white"), (-13.0, "pk_sideboard_greywash"), (-10.0, "pk_sideboard_black")):
        g.add(m, x, -136.62, 0).add("pk_lamp_gourd", x + 0.5, -136.62, 0, 0.85)
    # ---------------- Z9 east living: the phase-1 pairs get tables and lamps; the glam group, cream leather (IMG_4413)
    for ox, oz, end, lamp in ((14.0, -114.5, "pk_end_white", "pk_lamp_gourd"), (23.0, -114.5, "pk_end_oak", "pk_lamp_brass"),
                              (14.0, -123.5, "pk_end_black", "pk_lamp_glass"), (22.0, -123.5, "pk_end_oak", "pk_lamp_gourd")):
        g = group("Z9", "tables for the phase-1 pair at %.0f, %.0f" % (ox, oz), ox, oz, 0)
        g.add("pk_cocktail_burl" if ox < 20 else "pk_cocktail_oak", 0, 0)
        for lz, s in ((1.5, 1), (-1.5, -1)):
            g.add(end, 1.5, lz).add(lamp, 1.5, lz, 0, LAMP_ON[end])
    living(group("Z9", "glam group: sage sofa, burl table, green chairs", 14.0, -105.0, 0), "sofa_sage", 2.25,
           chairs=["pk_accent_green", "pk_accent_green"], table="pk_cocktail_burl", rug="pk_rug_cream", end="pk_end_white", lamp="pk_lamp_brass")
    g = group("Z9", "grey chenille sectional", 22.6, -105.0, 0)
    sectional(g, "pk_sect_grey", "pk_ott_grey", rug="pk_rug_vintage", extra="pk_accent_cream")
    # ---------------- appliances by the east customer entrance (Steven's Nov 4 spec; not in the 2026 footage: question)
    g = group("Z12", "appliances by the east storefront (Steven's spec)", 29.35, -112.6, -90)
    g.add("pk_fridge_steel", -1.6, 0.0).add("pk_range_steel", -0.5, 0.05).add("pk_washer_white", 0.35, 0.05).add("pk_dryer_white", 1.15, 0.05)
    # ---------------- Z11 side-exit corner: sales desk, black sideboard, cream chest, toile chair (IMG_4413 t001-041)
    g = group("Z11", "sales desk", -7.3, -139.0, 90)
    g.add("pk_desk_white", 0, 0).add("pk_monitor", -0.35, -0.12, 180, 0.76).add("pk_monitor", 0.35, -0.12, 180, 0.76).add("pk_taskchair", 0, -0.75, 0)
    g = group("Z11", "black sideboard, cream chest, accent chair", 0, 0)
    g.add("pk_sideboard_black", 0.05, -139.4, -90).add("pk_lamp_glass", 0.05, -139.9, -90, 0.85)
    g.add("pk_chest_cream", -0.05, -142.2, -90).add("pk_accent_cream", -0.9, -137.9, -135).add("pk_rug_taupe", -7.4, -138.4, 90)


# ------------------------------------------------------------------ checks
def fp(models, it):
    m = models.get(it[0])
    if m is None:
        return None
    hw, hd = m["size"][0] / 2, m["size"][1] / 2
    a = math.radians(it[3])
    ex = abs(math.cos(a)) * hw + abs(math.sin(a)) * hd
    ez = abs(math.sin(a)) * hw + abs(math.cos(a)) * hd
    return [it[1] - ex, it[2] - ez, it[1] + ex, it[2] + ez]


def hit(a, b, pad=0.0):
    return a[0] < b[2] + pad and a[2] > b[0] - pad and a[1] < b[3] + pad and a[3] > b[1] - pad


def check(groups, models):
    probs = []
    solids = []
    for c in COLS_X:
        for z in COLS_Z:
            solids.append(([c - 0.35, z - 0.35, c + 0.35, z + 0.35], "column %.1f,%.1f" % (c, z)))
    for x, z in PIPES:
        solids.append(([x - 0.12, z - 0.12, x + 0.12, z + 0.12], "pipe column"))
    solids.append(([-18.2, -119.7, -16.8, -118.3], "chase"))
    for pr in PARTS:
        x0, z0, x1, z1, gaps = pr
        along_x = abs(x1 - x0) > abs(z1 - z0)
        lo, hi = (x0, x1) if along_x else (z0, z1)
        segs = []
        cur = lo
        for g0, g1 in sorted(gaps):
            segs.append((cur, g0)); cur = g1
        segs.append((cur, hi))
        for s0, s1 in segs:
            r = [s0, z0 - 0.1, s1, z0 + 0.1] if along_x else [x0 - 0.1, s0, x0 + 0.1, s1]
            solids.append((r, "partition"))
        for g0, g1 in gaps:   # keep 1.0 m in front of and behind every doorway clear
            r = [g0, z0 - 1.0, g1, z0 + 1.0] if along_x else [x0 - 1.0, g0, x0 + 1.0, g1]
            solids.append((r, "doorway"))
    for k in KEEP_CLEAR:
        solids.append((k[:4], k[4]))
    placed = []
    for g in groups:
        for it in g["items"]:
            m = models.get(it[0])
            if m is None:
                probs.append("%s: unknown model %s" % (g["name"], it[0])); continue
            r = fp(models, it)
            if r[0] < X0 + 0.02 or r[2] > X1 - 0.02 or r[1] < ZB + 0.02 or r[3] > ZF:
                probs.append("%s: %s outside the box %s" % (g["name"], it[0], [round(v, 2) for v in r]))
            if m.get("walk"):
                continue
            onfloor = len(it) < 5
            for s, why in solids:
                if hit(r, s):
                    if why == "doorway" or why in [k[4] for k in KEEP_CLEAR] or onfloor:
                        probs.append("%s: %s hits %s" % (g["name"], it[0], why))
            if onfloor:
                for (r2, n2, g2) in placed:
                    tucked = any(n2.startswith(t) for t in ("pk_trect", "pk_tround", "pk_tcounter", "pk_desk")) and \
                        any(it[0].startswith(c) for c in ("pk_chair", "pk_stool", "pk_taskchair"))
                    if hit(r, r2, -0.03) and not tucked:
                        probs.append("%s: %s overlaps %s (%s)" % (g["name"], it[0], n2, g2))
                placed.append((r, it[0], g["name"]))
    return probs


def write_manifest(d, man, cfg):
    """design/lynns/asset-manifest.md: the generated table between the AUTO markers (the prose around it is kept)."""
    path = os.path.join(P, "..", "..", "..", "design", "lynns", "asset-manifest.md")
    use = {}
    for g in d["groups"]:
        for it in g["items"]:
            u = use.setdefault(it[0], {})
            u[g["zone"]] = u.get(g["zone"], 0) + 1
    src = {e["id"]: e for e in cfg["models"]}
    rows = ["| Model (`models/lynns/pack/`) | Family | Source file | Licence | Size W x D x H (m) | Tris | KB | Placed (zone x count) |",
            "|---|---|---|---|---|---|---|---|"]
    for k in sorted(man):
        v = man[k]
        kind, name = v["src"].split(":", 1)
        sf = {"q": "Quaternius `FBX/%s.fbx`" % name, "k": "Kenney `%s.glb`" % name, "gen": "built in the script (`%s`)" % name}[kind]
        lic = "CC0 1.0" if kind in ("q", "k") else "project"
        pl = ", ".join("%s x%d" % (z, n) for z, n in sorted(use.get(k, {}).items())) or "not placed yet"
        rows.append("| `%s.gltf` | %s | %s | %s | %.2f x %.2f x %.2f | %d | %d | %s |" % (k, v.get("family", ""), sf, lic, v["size"][0], v["size"][1], v["size"][2], v["tris"], v.get("kb", 0), pl))
    gen = sorted(k for k in d["models"] if not k.startswith("pk_"))
    rows += ["", "Generator models (own, `models/lynns/bl_ly_*`, baked 3-map textures) placed in the store:", ""]
    rows += ["- `%s`: %s" % (k, ", ".join("%s x%d" % (z, n) for z, n in sorted(use.get(k, {}).items())) or "not placed") for k in gen]
    auto = "<!-- AUTO: tools/stores/sears/lynns_fill.py -->\n" + "\n".join(rows) + "\n<!-- /AUTO -->"
    txt = open(path).read() if os.path.exists(path) else "<!-- AUTO: tools/stores/sears/lynns_fill.py -->\n<!-- /AUTO -->\n"
    txt = re.sub(r"<!-- AUTO: tools/stores/sears/lynns_fill.py -->.*?<!-- /AUTO -->", lambda _: auto, txt, flags=re.S)
    open(path, "w").write(txt)


def main():
    d = json.load(open(PL))
    man = json.load(open(MAN))
    cfg = json.load(open(os.path.join(P, "data", "lynns", "pack_models.json")))
    walk = {e["id"] for e in cfg["models"] if e.get("walk")}
    for k in [k for k in d["models"] if k.startswith("pk_") and k not in man]:
        del d["models"][k]
    for k, v in man.items():
        d["models"][k] = {"scene": "res://models/lynns/pack/%s.gltf" % k, "size": [v["size"][0], v["size"][1]], "h": v["size"][2],
                          "family": v.get("family", "")}
        if k in walk:
            d["models"][k]["walk"] = True
    if "--check-only" not in sys.argv:
        build()
        keep = [g for g in d["groups"] if g.get("pass") != 2]
        new = []
        for g in GROUPS:
            rs = [fp(d["models"], it) or [it[1], it[2], it[1], it[2]] for it in g.items]
            rect = [round(min(r[0] for r in rs), 2), round(min(r[1] for r in rs), 2), round(max(r[2] for r in rs), 2), round(max(r[3] for r in rs), 2)]
            new.append({"pass": 2, "zone": g.zone, "name": g.name, "rect": rect, "items": g.items})
        d["groups"] = keep + new
        d["replace_boxes"] = True
        d["_"] = d["_"].split(" Phase 1:")[0] + (" Items may carry a 5th value y (on top of another piece). Models with walk=true (rugs) are"
                                                 " not obstacles. replace_boxes: store.gd's old box dressing is skipped (the R3 slatwall stays)."
                                                 " Pass 2 (pack furniture) groups carry \"pass\": 2 and are rewritten by tools/stores/sears/lynns_fill.py.")
        txt = json.dumps(d, indent=1)
        # one item / size / rect per line, so Steven can nudge a piece in a text editor
        txt = re.sub(r"\[\s+([^\[\]{}]*?)\s+\]", lambda mm: "[" + re.sub(r"\s+", " ", mm.group(1)) + "]", txt)
        open(PL, "w").write(txt + "\n")
    write_manifest(d, man, cfg)
    probs = check(d["groups"], d["models"])
    n = sum(len(g["items"]) for g in d["groups"])
    print("LYNNS groups=%d items=%d problems=%d" % (len(d["groups"]), n, len(probs)))
    for p in probs:
        print("  ", p)


main()
