"""Corrections to the outside's footprint (Workstream F, Nov 1 2026; design/godot-exterior.md
"Fake walls"). tools/make_exterior.py traces the building from the 1995 map's store rectangles, and
where the map's rectangles stop short of the real building it left notches and steps whose walls
do not exist (Steven, Oct 28: "random fake walls that aren't supposed to be there"). Each fix below
is checked against the Oct 23 footage, the 2026 directory map (refs/derived/photos/IMG_4455.jpg) and
the Morguard site plan (design/exterior/morguard-site-plan-2024.png).

All rectangles in metres (+x east, +z south), [x0, z0, x1, z1].
"""

# Tiles added to the building (filled notches). name: what the new wall is called (exterior.gd's
# skin() reads it); owner: the store id the filled tiles join, or "" for a plain wall.
FILLS = [
    # F1. The service notch on the east facade behind Philly's / Mastercuts / Father & Son
    # (x 30..44, z -54..-38: 14 m deep, 16 m wide). Real: the facade runs straight from
    # Hypervelocity (K&B) to The Red Seal (Cucos) with one roofed drive-in trash / transformer bay
    # about 8 m wide and 6 m deep (4406 f011-015, 4493 f030-032; the directory map shows a straight
    # east face). Filled to x = 44 except that bay (BAY below).
    dict(rect=[30, -54, 44, -50], owner="", name="EAST FACADE"),
    dict(rect=[30, -42, 44, -38], owner="", name="EAST FACADE"),
    dict(rect=[30, -50, 38, -42], owner="", name="SERVICE BAY"),
    # F2. The notch behind Radio Shack / GNC (x 32..44, z 26..38: 12 m deep). Real: one flush box,
    # Shoe Dept. today (ex-Forever 21, the old Coach House / Radio Shack / GNC / Avenue row), with its
    # ACM front running straight on (4492 f081-f099; the directory map's flush teal block).
    dict(rect=[32, 26, 44, 38], owner="", name="EAST FACADE"),
    # F3. The steps between JCPenney's south face and the south entrance: a 14 m west-facing wall
    # (x = -154, z 74..88, Zales / TGO's backs) and an 8 m south one (z = 88). Real: walking east
    # along JCPenney's south face you reach the entrance pavilion directly, past a short set-back
    # link wall (4489 f001-f035, "JCPenney's brick ends in a brick pilaster strip, then a set-back
    # EIFS link wall"); site plan and directory map: JCPenney's south face is about level with the
    # wing. JCPenney's box is carried south to the pavilion's front (z = 92) and the link fills
    # the corner beside the pavilion.
    dict(rect=[-202, 74, -154, 92], owner="s6", name="JCPENNEY"),
    dict(rect=[-154, 88, -146, 92], owner="", name="LINK"),
    # F4. The 4 m jog at the restrooms (x -58..-42, z 96..100). Real: the low wing wall runs
    # straight from the pavilion to the service alley by Dillard's (4489 f059-f069, "blank, no
    # doors"; the directory map's straight food-court edge).
    dict(rect=[-58, 96, -42, 100], owner="", name=""),
]

# ---- Workstream EXT-B (Nov 4 2026; design/exterior-sequence.md §5 and Steven's decisions §9, "you
# nailed it" on the red-box plan): the real footprint read from the Oct 23 footage and the Morguard
# site plan. Numbers are §5's proposals; where one was changed here the reason is next to it.
FILLS += [
    # #1 Sears / Lynn's: 115 x 50 m, flush with the east facade, its west face ~10 m east of the
    # cinema-side exit (4486 f002-010, 4406 f031-035, site plan 76,335 SF). Workstream E's walkable
    # Sears (wing 4, to z -146) now sits inside its own shell.
    # EXT-LAYOUT (Nov 8 2026): the west face is at x -84, 6 m west of the cinema-wing exit's glass
    # (x -78), not 7 m east of it: the exit stands at the end of a 10 m wide channel between Lynn's SW
    # corner (white, left) and the cinema's north face (salmon, right) (4486 f014, f001, 4416 f002; the
    # site plan: the channel's north side ~6 m, its south side ~22 m)
    dict(rect=[-84, -146, 44, -96], owner="s1", name="SEARS"),
    # the low white painted-brick block at Lynn's SW corner, the bike rack on its west face, a door on
    # its north face toward the dock (4416 f009-011, 4486 f002-003, f006-008)
    dict(rect=[-88, -100, -84, -96], owner="", name="SEARS RETURN"),
    # #2 the cinema box. EXT-LAYOUT (Nov 8 2026): its west face is x -98, 20 m west of the exit's glass
    # (4486 f014, f016: the NW corner with a door on the north face; f001: the north face from the exit;
    # site plan ~22 m), then 44 m south to its south face (4486 f016-f037)
    dict(rect=[-98, -86, -52, -42], owner="s40", name="SOUTHLAND CINEMA"),
    # #5 JCPenney: 60 x 120 m to z -14 (docks 1-2 and the Package Pick-up on the north face, 4486
    # f103-116, 4487), the tall rear block on the west (4487 f011-054), the south face at z 106
    dict(rect=[-214, -14, -154, 32], owner="s6", name="JCPENNEY"),
    dict(rect=[-214, 32, -202, 106], owner="s6", name="JCPENNEY"),
    dict(rect=[-202, 92, -154, 106], owner="s6", name="JCPENNEY"),
    dict(rect=[-228, -6, -214, 32], owner="s6", name="JCPENNEY"),
    # #8 the south side (Steven: "the pavilion wall needs to be from JCPenney to the Dillard's side,
    # at least 3/4 of that length"): the set-back link off JCPenney's SE corner to z 110, the
    # pavilion's solid part to its loggia (z 112; the loggia to z 118 is built by exterior.gd), the
    # blank wing wall in line with the pavilion's front from the pavilion to the service lane
    dict(rect=[-154, 92, -146, 110], owner="", name="LINK"),
    dict(rect=[-146, 92, -134, 112], owner="", name="PAVILION"),
    dict(rect=[-134, 100, -42, 118], owner="", name=""),
    # #7 Dillard's: 87 x 58 m, flush with the facade, the south face (the gallery and the portal) at
    # z 138. CHANGED from §5: its west face stays at x -38 north of z 118 so the 4 m service lane
    # between the wing's back (x -42) and Dillard's (4490 f006-028: doors 3026-3029, the lane to the
    # dock) stays open to the south; §5's x -43 would close it (the built wing reaches x -42).
    dict(rect=[30, 80, 44, 118], owner="s2", name="DILLARD'S"),
    dict(rect=[-38, 118, 44, 138], owner="s2", name="DILLARD'S"),
    # the east facade between the Shoe Dept box and Dillard's (the plan's flush block, 4492 f081-108:
    # the blank ACM wall and the loading lane run straight on to Dillard's NE corner)
    dict(rect=[30, 50, 44, 80], owner="", name="EAST FACADE"),
]

# The trash / transformer bay left open in F1: roofed at 4.6 m, louvers and steel doors inside.
BAY = [38, -50, 44, -42]

# F5. Standalone buildings. The map's block n2 (x -230..-216, z -10..26, "the original 1969
# standalone Sears, Unitech today") stood west of JCPenney's back lot, where the site plan and the
# directory map show only parking and the soccer fields. Unitech is NORTH of Lynn's (old Sears), by
# Armour Dr (site plan "UNITECH 15,600 SF"; directory map "UNITECH" north-west of Lynn's; 4486 f010:
# "that building back there", looking north from the cinema-side exit).
# EXT-LAYOUT (Nov 8 2026, Steven): Unitech at the site plan's footprint, x -122..-82 (its east edge about in line
# with Lynn's west face) by Armour Dr, 15,600 SF (40 x 36.2 m = 1,448 m2). "Old Sears Hardware" per Steven's
# annotated plan; unsigned in both years until the mall historian settles what it read in the 1990s.
STANDALONE = [dict(name="UNITECH", rect=[-122.0, -232.2, -82.0, -196.0])]   # was EXT-B #3: -85, -236, -57, -207

# EXT-B: map blocks left out of the building altogether (n2 would join JCPenney's rear block)
DROP = ["n2"]

# EXT-B #3 / #9: the map grows on three sides (Steven, Nov 3: "yes"): Armour Dr to z -252, Bayou
# Gardens Blvd to z 216, West Park Ave to x 112, the west lot to x -360. Tiles (2 m) added to the
# 1995 map's 201 x 201 grid on each side; tools/make_exterior.py writes the grown walk grid and its
# origin, player.gd reads the origin from wing 3's wing.json.
GROW = dict(west=47, north=35, east=12, south=19)

# EXT-B: the outside face of the doors whose wall moved. The inside spot, the wing and the facing
# stay (the inside wings do not change); `a`, `b` and `out` are where the door is outside now, depth
# the step from the door plane to the walk (capture_doors.gd stands there).
DOOR_MOVES = {
    # the south entrance: the doors at the back of the loggia (front z 118)
    "s55": dict(a=[-144.0, 112.0], b=[-136.0, 112.0], depth=0.3),
    # Lynn's / Sears customer entrance on the east face, now flush with the facade (x 44)
    "s1e": dict(a=[44.0, -121.0], b=[44.0, -115.0], depth=0.3),
    # Dillard's gallery entrance on the east face (x 44) and the portal on the south face (z 138)
    "s2e": dict(a=[44.0, 95.0], b=[44.0, 101.4], depth=0.3),
    "s2s": dict(a=[-17.4, 138.0], b=[-12.6, 138.0], depth=0.3),
    # EXT-LAYOUT (Nov 8 2026): the cinema-wing exit's glass stands 2 m back under the fascia's soffit
    # (4416 f002-f005), x -78; the out spot stays at x -81.5, just past the fascia
    "s41": dict(a=[-78.0, -96.0], b=[-78.0, -86.0], depth=1.3),
}

# EXT-LAYOUT (Nov 8 2026): building tiles the walk grid opens again (x0, z0, x1, z1): the 2 m recess
# under the cinema-wing exit's fascia, so the player can walk up to the glass (4416 f002)
WALK_OPEN = [[-80.0, -96.0, -78.0, -86.0]]

# EXT-ENTRANCES-BUILD (Nov 11 2026; design/exterior/entrances-2026-11-09.md "The main entrance, measured"): the
# main entrance's porch. The 4406 f002-f003 frames, solved by their vanishing points, put the tower's two front
# piers in the facade's plane (x 44), not out on the lot: the porch is the recess BEHIND them, the 8 m between
# the facade and the doors that the 1995 map already gives s39 (its door edge is at x 36, depth 8). So the
# outside (wing 3) opens that recess: its tiles are walkable (make_exterior.py adds PORCH to the walk grid; the
# building's outline, segments and roofs stay as they are, exterior.gd build() cuts the porch out of the
# footprint's obstacle) and the door's outside spot stands in front of the doors, in the porch (DOOR_OUT).
PORCH = [36.0, -6.0, 44.0, 6.0]
DOOR_OUT = {"s39": [38.0, 0.0]}

# Where Workstream E (the walkable old Sears) can put Sears's own exterior doors: the east face, by
# the Lynn's script sign and black awning (4406 f031-035) and the side exit with Big Lots across the
# drive (4413 f001-f008, f033). Not doors yet: player.gd only reads "doors". E: move a spot into
# "doors" (fill wing / inside / yaw_in) once the inside is walkable.
# EXT-B: both are real doors now (s1e on the east face at x 44, s1x on the north face, make_exterior.py
# and DOOR_MOVES); the side exit is on the north face (4413 f004: the afternoon sun shines in), not
# the east one. Nothing left here.
DOOR_SPOTS = []

# EXT-LAYOUT (Nov 8 2026; Steven's annotated site plan "Sears Entrance"): a customer entrance on Lynn's /
# Sears's north face toward the Armour Dr lot, kept beside the east-face doors (s1e) and the shutter side
# exit (s1x). On the plan the entrance's bump sits at x -39..-12 on the north face (mapped between Lynn's
# corners, -84 and 44): centred x -24, an 8 m storefront. Inside it lands at the north end of the walkable
# Sears's main aisle at first; since Steven's Nov 8 follow-up it lands in its own vestibule inside the north
# wall (tools/stores/sears/store.gd north_entry), facing south into the store.
# Appended after the other doors so door_view.gd's atlas rows stay as they are.
NEW_DOORS = [
    dict(store="s1n", kind="exit", a=[-28.0, -146.0], b=[-20.0, -146.0], n=[0, 1], depth=1.3, wing=4,
         inside=[-24.0, -143.5]),
]
