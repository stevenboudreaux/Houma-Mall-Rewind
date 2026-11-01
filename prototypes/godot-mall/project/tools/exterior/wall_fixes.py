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

# The trash / transformer bay left open in F1: roofed at 4.6 m, louvers and steel doors inside.
BAY = [38, -50, 44, -42]

# F5. Standalone buildings. The map's block n2 (x -230..-216, z -10..26, "the original 1969
# standalone Sears, Unitech today") stood west of JCPenney's back lot, where the site plan and the
# directory map show only parking and the soccer fields. Unitech is NORTH of Lynn's (old Sears), by
# Armour Dr (site plan "UNITECH 15,600 SF"; directory map "UNITECH" north-west of Lynn's; 4486 f010:
# "that building back there", looking north from the cinema-side exit).
STANDALONE = [dict(name="UNITECH", rect=[-68.0, -176.0, -32.0, -150.0])]

# Where Workstream E (the walkable old Sears) can put Sears's own exterior doors: the east face, by
# the Lynn's script sign and black awning (4406 f031-035) and the side exit with Big Lots across the
# drive (4413 f001-f008, f033). Not doors yet: player.gd only reads "doors". E: move a spot into
# "doors" (fill wing / inside / yaw_in) once the inside is walkable.
DOOR_SPOTS = [
    dict(store="s1", kind="sears_entrance", a=[30.0, -124.0], b=[30.0, -118.0], n=[-1, 0], wing=1,
         note="Workstream E: Sears / Lynn's customer entrance, east face (4413 f033, 4406 f031-035)"),
    dict(store="s1", kind="sears_side_exit", a=[30.0, -106.0], b=[30.0, -103.0], n=[-1, 0], wing=1,
         note="Workstream E: Sears side exit with the roll shutter (4413 f001-f008)"),
]
