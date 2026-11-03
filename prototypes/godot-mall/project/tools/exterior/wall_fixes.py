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

# ---------------------------------------------------------------------------------------------
# Workstream EXT-B (Nov 3 2026): the real outside, from design/exterior-sequence.md (§4 the faces,
# §5 the mismatches #1-#15, §9 Steven's decisions). The map's anchors were half their real size and
# the outside went wrong behind Sears; these fills give each anchor its real footprint (read from
# the Oct 23 footage and the Morguard site plan, snapped to the walkable interior). Tile-aligned to
# the 2 m grid, so the plan's odd numbers are rounded (Sears's west face -71 -> -72 and so on).
FILLS += [
    # #1 Sears / Lynn's, 116 x 50 (plan 115 x 50, 76,335 SF): east face flush with the facade (x 44),
    # west face ~10 m east of the cinema exit's face, the Sears hall's north wall its south wall. The
    # walkable Sears (wing 4, x -40..30) sits inside its own shell.
    dict(rect=[-72, -146, 44, -96], owner="s1", name="SEARS"),
    # the white painted brick return north of the cinema exit's glass: the bike rack stands against
    # its west face, the truck well lies north of it (4416 f009-011, 4486 f002-010). Part of Sears.
    dict(rect=[-82, -100, -72, -96], owner="s1", name="SEARS"),
    # #2 the cinema exit's buff return south of the glass (the poster case, 4417), then the cinema
    # box: one straight salmon wall flush with the exit block for 44 m, then the south face (4486
    # f014-037; plan x -87..-49, z -86..-36)
    dict(rect=[-82, -86, -80, -84], owner="", name="BUFF RETURN"),
    dict(rect=[-82, -86, -52, -42], owner="s40", name="SOUTHLAND CINEMA"),
    # #5 JCPenney 60 x 120 (plan 96,108 SF) to z -14, its tall blank rear block on the game west
    # (4486 f103-116, 4487, 4488, 4489 f001-030)
    dict(rect=[-214, -14, -154, 32], owner="s6", name="JCPENNEY"),
    dict(rect=[-214, 32, -202, 106], owner="s6", name="JCPENNEY"),
    dict(rect=[-202, 92, -154, 106], owner="s6", name="JCPENNEY"),
    dict(rect=[-228, -6, -214, 32], owner="s6", name="JCPENNEY"),
    # #8 (Steven, §9 q1: "the pavilion wall needs to be from JCPenney to the Dillard's side"): the
    # set-back link off JCPenney's SE corner, the south pavilion to z 112 (its loggia z 112..118 is
    # drawn by exterior.gd), the low blank wing wall straight on at z 118 to the Dillard's lane
    dict(rect=[-154, 92, -148, 110], owner="", name="LINK"),
    dict(rect=[-148, 92, -136, 112], owner="", name="PAVILION"),
    dict(rect=[-136, 100, -46, 118], owner="", name="WING WALL"),
    # #7 Dillard's 82 x 58 (plan 87 x 58, 153,672 SF on 3 floors): east face flush with the facade,
    # south face on Bayou Gardens with the entrance portal and the gallery (§9 q5). The west face
    # stays at the walkable box's (x -38; the plan's -43 is inside its +-5 m), so the service lane
    # between the wing and Dillard's keeps the game's proportions (the restrooms are at x -58..-42).
    dict(rect=[30, 80, 44, 138], owner="s2", name="DILLARD'S"),
    dict(rect=[-38, 118, 30, 138], owner="s2", name="DILLARD'S"),
]

# Tiles taken out of the building: #12 the east entrance (s43) recess, ~10 m deep between The Red
# Seal's (Cucos's) pier and Lynn's box (4406 f036-042); the doors move to its back (x 34).
CARVES = [[34, -96, 44, -86]]

# The outside spots that move with the new faces (Workstream EXT-B). "out": where you land outside;
# "view": the doorway on the outside face, where tools/exterior/capture_doors.gd stands to picture
# the lot for the inside wings (default: the door's hall edge plus its depth). Inside spots, wings
# and facings do not change.
DOOR_MOVES = {
    "s43": dict(out=[35.5, -91.0]),                          # #12 in the deep recess (view: default, the inside glass's line)
    "s55": dict(out=[-142.0, 113.5], view=[-142.0, 112.3]),  # #8 the loggia's back wall, z 112
    "s1e": dict(out=[45.5, -118.0], view=[44.3, -118.0]),    # #1 Lynn's east face, x 44
    "s2e": dict(out=[45.8, 98.2], view=[44.3, 98.2]),        # #7 Dillard's east face, x 44, in the gallery
    "s2s": dict(out=[-15.0, 139.5], view=[-15.0, 138.3]),    # #7 the south portal, z 138
}

# #1 the Sears loading dock on the WEST face (4486 f004-010, 4416 f012-017; Steven's anchor "take
# note of this"): a flat white canopy on pipe columns over the at-grade dock, the truck well in front
# sunk 1.2 m with the yellow pipe rail, its ramp up to the staff lot. Not walkable (the well).
SEARS_DOCK = dict(canopy=[-80, -126, -72, -100], well=[-96, -118, -80, -100], ramp=[-116, -118, -96, -100])

# The 1995 map's blocks that are not buildings: n2 (west of JCPenney's back lot; Workstream F already
# dropped it as a standalone, and JCPenney's real rear block now touches its tiles)
DROP = ["n2"]

# F5 / #3 Standalone buildings: Unitech, the long low white box by Armour Dr ("that building back
# there", 4486 f010; site plan "UNITECH 15,600 SF"), 70 m north of where Workstream F put it.
STANDALONE = [dict(name="UNITECH", rect=[-86.0, -236.0, -58.0, -208.0])]

# Where the lot is not walkable although the grid is outside the building: the apartments' land in
# the parcel's cut-out north-west corner (behind their wood fence) and the soccer fields past the
# lot's west edge (black picket fence), design/exterior-sequence.md §4 "Roads".
WALK_BLOCK = [[-390, -270, -120, -150], [-390, -150, -362, 240]]

# Workstream E's door spots: none left. Sears / Lynn's customer entrance (s1e, x 44) and the north
# side exit (s1x) are real doors now (exterior.json "doors"); the east-face side exit Workstream F
# put at z -106 is not there (the roll-shutter door of 4413 is s1x on the north face, §5 #1).
DOOR_SPOTS = []
