"""Opens the customer areas of fully built stores in layout_mall.json's walk grid.

convert_map.py marks every store tile as blocked; stores built in full 3D
(design/storefronts/*.md) let the player walk in. Each entry lists the map
tiles (x, y ranges, inclusive) that become floor; the furniture and counters
are obstacles placed by the store's builder. Run after convert_map.py:
  python3 tools/open_interiors.py   (from the project folder)
"""
import json, os

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.join(HERE, "..")
OPEN = {
    # Corn Dog 7 (s54, tiles x 79-84, y 134-139, faces west): the queue in front
    # of the counter, and the dining room along the north wall (it runs behind the mall wall)
    "s54": [(79, 80, 134, 139), (81, 84, 134, 136)],
    # Pocket Change (s52b, tiles x 93-96, y 130-149, faces north): the whole arcade
    "s52b": [(93, 96, 130, 149)],
    # Kay-Bee Toys (s18, tiles x 131-142, y 71-73, faces east): the whole store
    "s18": [(131, 142, 71, 73)],
    # Gumballs (s8, tiles x 138-142, y 118-123, a corner open to the east hall and the
    # Dillard's court): the whole store
    "s8": [(138, 142, 118, 123)],
    # JW (n33, tiles x 108-110, y 110-123) and 5-7-9 (n33b, x 111-113), side by side on the
    # Concourse's north side, facing south; County Seat (n46, x 101-104, y 130-149) facing north
    "n33": [(108, 110, 110, 123)],
    "n33b": [(111, 113, 110, 123)],
    "n46": [(101, 104, 130, 149)],
    # Babbage's (n39b, tiles x 83-85, y 130-133, faces north, by Corn Dog 7; the 2 m jog on
    # its right is x 82, y 131-133) and Sound Shop (s19, x 131-142, y 68-70, faces east,
    # beside Kay-Bee): the whole stores (design/storefronts/babbages.md, sound-shop.md)
    "n39b": [(83, 85, 130, 133)],   # the 2 m jog went with the corner's new diagonal (Oct 8)
    "s19": [(131, 142, 68, 70)],
    # Woolworth (s13, tiles x 125-142, y 93-110, faces east; 36 m x 36 m with the restaurant)
    "s13": [(125, 142, 93, 110)],
    # Wave 4 clothing stores (tools/stores/apparel/more.gd): Lerner Shop (s10, east hall),
    # Lane Bryant (n10), Miller's Outpost (s17), Gadzooks (n35, north side), The Limited (s50)
    "s10": [(129, 142, 111, 117)],
    "n10": [(131, 142, 64, 67)],
    "s17": [(129, 142, 74, 79)],
    "n35": [(117, 122, 112, 123)],
    "s50": [(82, 86, 110, 123)],
    # Wave 5 small shops (tools/stores/small/store.gd): Coach House Gifts (s21), GNC (s21c),
    # MasterCuts (s24mc) facing west onto the east hall, Wicks 'N' Sticks (s44), Chick-fil-A (s64)
    "s21": [(149, 160, 108, 112)],
    "s21c": [(149, 155, 117, 118)],
    "s24mc": [(149, 155, 76, 77)],
    "s44": [(130, 131, 118, 123)],   # narrowed Oct 7
    "s64": [(97, 100, 130, 142)],   # deepened to 26 m Oct 8 (the video's long dining room)
    # Wave 6 (tools/stores/small/store2.gd): Radio Shack (s21b), B. Dalton (s48), and the
    # corner shops Karmelkorn (s57) and Zales (s7), open on two halls
    "s21b": [(149, 156, 113, 115)],   # narrowed Oct 7
    "s48": [(93, 96, 114, 123)],
    "s57": [(130, 137, 130, 134)],
    "s7": [(71, 74, 134, 138)],
    # Wave 7 (tools/stores/small/wave7.gd), from the facade records
    "s47": [(97, 100, 114, 123)],
    "s16": [(131, 142, 80, 84)],
    # Champs Sports (s49) and Sports Avenue (s8b): shut for now, see narrow_stores.py
    "smuopv1vy0": [(132, 134, 118, 123)],
    "s60": [(119, 122, 130, 137)],
    "n56": [(128, 129, 130, 135)],
    "s34": [(154, 155, 103, 107)],   # moved up into line with Tee Tai's (Oct 8)
    "s29": [(149, 153, 91, 94)],
    # Wave 8 (tools/stores/small/wave8.gd): Cucos (x 22-36, z -86..-70), Claire's corner
    # (x 12-20, z -16..-6), Mitchell's (x 20-24), Tee Tai's customer strip in front of its
    # counter, Optical Outlet, Saadi's (x 2-16, z 66-74). Golden Chain Gang is served over a
    # counter at the front line: nothing to open.
    "s42": [(159, 165, 57, 64)],
    "s30": [(154, 157, 92, 96)],
    "s31": [(158, 159, 91, 96)],
    "s35": [(156, 158, 103, 103)],
    "s36": [(159, 162, 103, 107)],
    "s20": [(149, 155, 133, 136)],
    # Wave 9 (tools/stores/small/wave9.gd): Solarium's lobby (x -16..-10, z -86..-80), Rave
    # (x -22..-10, z -80..-72), Concepts (x -68..-58, z 60..74), Country Fair (x -124..-118,
    # z 60..70), Lion's Share's passage and dining room (x -50..-38, z 36..48; the closed rooms
    # either side of the passage are obstacles). American Bank's gate is closed.
    "n8": [(140, 142, 57, 59)],
    "n9": [(137, 142, 60, 63)],
    "s61": [(114, 118, 130, 136)],
    "n42": [(86, 88, 130, 134)],
    "n36": [(123, 126, 118, 123)],   # narrowed Oct 7 (narrow_stores.py)
    # Workstream E (Nov 1, tools/stores/sears/, tools/stores/dillards/): the old Sears box, the map
    # rect s1 (x 128-162, y 33-51) plus 6 rows deeper to y 27 (50 m, design/godot-sears.md), and
    # Dillard's level 1 (s2, x 129-162, y 140-158, design/godot-dillards.md)
    "s1": [(128, 162, 27, 51)],
    "s2": [(129, 162, 140, 158)],
}


def main():
    p = os.path.join(PROJ, "layout_mall.json")
    L = json.load(open(p))
    rows = [list(r) for r in L["walk"]]
    n = 0
    for sid, rects in OPEN.items():
        for (x0, x1, y0, y1) in rects:
            for y in range(y0, y1 + 1):
                for x in range(x0, x1 + 1):
                    if rows[y][x] != "1":
                        rows[y][x] = "1"
                        n += 1
    L["walk"] = ["".join(r) for r in rows]
    L["interiors_open"] = sorted(OPEN.keys())
    json.dump(L, open(p, "w"), indent=1)
    print("opened", n, "tiles for", list(OPEN))


if __name__ == "__main__":
    main()
