#!/usr/bin/env python3
"""PRIZES (Nov 3 2026; design/godot-prize-counter.md "PRIZES"): writes the redemption items, their scenes and both years' stock lists.
Run from the project folder. Kept as tools/prizes/make_items.py."""
import json, os, sys, collections
O = collections.OrderedDict

P95 = json.load(open("scripts/prizes.json"), object_pairs_hook=O)["items"]
P26 = json.load(open("scripts/prizes_2026.json"), object_pairs_hook=O)["items"]

# --- the items: [id, prize key (1995 or g_ 2026), kind for prize_model, class, year]
SHARED = {"lollipop", "sour_candy", "candy_ring", "bounce_ball", "eraser", "stickers", "sticky_hand"}
ITEMS_95 = [
    ("pc_lollipop", "lollipop", "pocket"), ("pc_candy_roll", "candy_roll", "pocket"), ("pc_taffy", "taffy", "pocket"),
    ("pc_powder_straw", "powder_straw", "pocket"), ("pc_sour_candy", "sour_candy", "pocket"), ("pc_candy_ring", "candy_ring", "pocket"),
    ("pc_spider_ring", "spider_ring", "pocket"), ("pc_bounce_ball", "bounce_ball", "pocket"), ("pc_pencil", "pencil", "pocket"),
    ("pc_eraser", "eraser", "pocket"), ("pc_stickers", "stickers", "pocket"), ("pc_sticky_hand", "sticky_hand", "pocket"),
    ("pc_jelly_bracelet", "jelly_bracelet", "pocket"), ("pc_glow_bracelet", "glow_bracelet", "pocket"), ("pc_army_men", "army_men", "pocket"),
    ("pc_rubber_snake", "rubber_snake", "pocket"), ("pc_slammer", "slammer", "pocket"), ("pc_paddle_ball", "paddle_ball", "hand"),
    ("pc_water_pistol", "water_pistol", "hand"), ("pc_sunglasses", "sunglasses", "pocket"), ("pc_mood_ring", "mood_ring", "pocket"),
    ("pc_toy_car", "toy_car", "hand"), ("pc_harmonica", "harmonica", "pocket"), ("pc_lcd_game", "lcd_game", "hand"),
    ("pc_walkie", "walkie", "hand"), ("pc_cassette", "cassette", "hand"), ("pc_rc_car", "rc_car", "hand"), ("pc_big_bear", "big_bear", "hand"),
]
ITEMS_26 = [
    ("gi_popper_key", "popper_key", "pocket"), ("gi_squishy", "squishy", "pocket"), ("gi_light_ring", "light_ring", "pocket"),
    ("gi_fidget", "fidget", "pocket"), ("gi_slime", "slime", "hand"), ("gi_blind_bag", "blind_bag", "pocket"),
    ("gi_emoji_key", "emoji_key", "pocket"), ("gi_popper_board", "popper_board", "hand"), ("gi_led_wand", "led_wand", "hand"),
    ("gi_play_ball", "play_ball", "hand"), ("gi_bubbles", "bubbles", "hand"), ("gi_squish_big", "squish_big", "hand"),
    ("gi_jumbo", "jumbo", "hand"), ("gi_phone_stand", "phone_stand", "hand"), ("gi_cable", "cable", "hand"),
    ("gi_earbuds", "earbuds", "hand"), ("gi_speaker", "speaker", "hand"), ("gi_projector", "projector", "hand"),
    ("gi_ledstrip", "ledstrip", "hand"), ("gi_headphones", "headphones", "hand"), ("gi_giftcard", "giftcard", "pocket"),
    ("gi_arcade", "arcade", "hand"), ("gi_handheld", "handheld", "hand"), ("gi_console", "console", "hand"),
]
# prizes with a Blender model (tools/blender/assets_src/<id>.py; its item entry is written by the build)
BL_95 = {"troll": "bl_pc_troll", "yoyo": "bl_pc_yoyo", "koosh": "bl_pc_koosh", "blaster": "bl_pc_blaster",
         "skateboard": "bl_pc_skateboard", "plasma": "bl_pc_plasma"}
BL_26 = {"g_squish": "bl_gi_squish", "g_capybara": "bl_gi_capybara", "g_dough_ball": "bl_gi_doughball"}

SCENE = """[gd_scene format=3]

[ext_resource type="Script" path="res://scripts/items/prize_model.gd" id="1_pm"]

[node name="{id}" type="Node3D"]
script = ExtResource("1_pm")
kind = "{kind}"
"""


def entries(rows, cat, year, store):
    out = []
    for id_, kind, cls in rows:
        key = kind if year == 1995 else "g_" + kind
        year_v = "both" if kind in SHARED else year
        e = O([("id", id_), ("name", cat[key]["name"]), ("class", cls), ("scene", "res://scripts/items/%s.tscn" % id_),
               ("icon", "res://tex/items/%s.png" % id_), ("year", year_v), ("store", store), ("tickets", cat[key]["tickets"]),
               ("prize", key)])
        out.append(e)
        open("scripts/items/%s.tscn" % id_, "w").write(SCENE.format(id=id_, kind=kind))
    return out


e95 = entries(ITEMS_95, P95, 1995, "POCKET CHANGE")
e26 = entries(ITEMS_26, P26, 2026, "GAMES, INC.")
# ws/items (Nov 4 2026; design/godot-items.md): the entries go into the store files (data/items/pocket_change.json,
# games_inc.json) through tools/items/items_io.py, updated where they are, their category kept
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "items"))
import items_io
items_io.upsert(e95)
items_io.upsert(e26)

# --- the prizes shared with 2026: their existing items become year "both"
def set_both(ids):
    items_io.set_field(ids, "year", "both")

# --- the stock lists (redemption.json)
id95 = {k: i for i, k, _ in ITEMS_95}
id95.update({"chew": "pc_chew", "finger_trap": "bl_pc_fingertrap", "jelly_trap": "pc_jelly_trap", "candy_neck": "candy_neck",
             "candy_cig": "pc_candy_cig", "slap": "slap", "pogs": "pogs", "spring": "spring", "dice": "dice", "boombox": "bl_pc_boombox",
             "big_dice": "pc_big_dice", "alien": "pc_alien", "ball": "pc_ball", "vpet": "pc_vpet", "lava": "pc_lava",
             "plush_bear": "bl_pc_plush_bear", "plush_bunny": "bl_pc_plush_bunny", "plush_dog": "bl_pc_plush_dog"})
id95.update(BL_95)
id26 = {"g_" + k: i for i, k, _ in ITEMS_26}
id26.update({"g_lollipop": "pc_lollipop", "g_bounce_ball": "pc_bounce_ball", "g_candy_ring": "pc_candy_ring", "g_sour_candy": "pc_sour_candy",
             "g_finger_trap": "bl_pc_fingertrap", "g_sticky_hand": "pc_sticky_hand", "g_stickers": "pc_stickers", "g_slap": "slap",
             "g_plush_bear": "bl_pc_plush_bear", "g_plush_bunny": "bl_pc_plush_bunny", "g_plush_dog": "bl_pc_plush_dog", "g_lava": "pc_lava",
             "g_eraser": "pc_eraser"})
id26.update(BL_26)
STEVEN = {"boombox": "5,000 tickets, the wall tags' number (Steven, Nov 3)", "plush_bear": "700 stays (Steven, Nov 3)",
          "plush_bunny": "700 (Steven, Nov 3)", "plush_dog": "700 (Steven, Nov 3)"}


def stock(cat, ids, steven):
    rows = []
    for key in sorted(cat, key=lambda k: (cat[k]["tickets"], k)):
        if key not in ids:
            raise SystemExit("no item for prize " + key)
        r = O([("item", ids[key]), ("prize", key)])
        if key in steven:
            r["_"] = steven[key]
        else:
            r["guess"] = True
        rows.append(r)
    return rows


R = O()
R["_"] = ("The redemption counters' stock (scripts/redemption.gd; design/godot-prize-counter.md 'Redemption' and 'PRIZES'). "
          "'stock' is Pocket Change's, 1995 (prices from scripts/prizes.json), 'stock_2026' games, inc.'s (prices from scripts/prizes_2026.json); "
          "each year's counter spends only that year's tickets (mall.spend_tickets). One entry per prize, shown in this order (by price). "
          "item: the data/items/*.json id the player receives (design/godot-items.md); prize: the catalogue key it stands for (its name and ticket price come from "
          "there, so the tag in the case and this screen agree); tickets: a price that overrides it. guess: true = a price Steven has not "
          "given (a guess from design/research/redemption-items.md; only the boom box 5,000 and the plush 700 are his). "
          "Written by tools/prizes/make_items.py; Steven changes the numbers in prizes.json / prizes_2026.json.")
R["stock"] = stock(P95, id95, STEVEN)
R["stock_2026"] = stock(P26, id26, {})
open("scripts/redemption.json", "w").write(json.dumps(R, indent=1, ensure_ascii=False) + "\n")
print("items", len(e95), len(e26), "stock", len(R["stock"]), len(R["stock_2026"]))

set_both({"bl_pc_fingertrap", "bl_pc_plush_bear", "bl_pc_plush_bunny", "bl_pc_plush_dog"})
# (slap and pc_lava were set to "both" by hand in their files, keeping their layout)
