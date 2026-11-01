# The Stockrooms (Godot mall Easter egg, since Demo 30, Oct 15 2026)

**Asked for (Steven, Oct 15, 08:29 and 08:42):** on the Rougarou's last Woolworth encounter it
walks, a little slower and in plain view, to one patch of wall (the back corner by Domestics,
his screenshot) and through it. That unlocks an Easter-egg level modelled on a found-footage
short he shared: an empty, yellow, fluorescent-lit labyrinth of office back rooms with a little
stuff stacked here and there. No NPCs. Very labyrinth-like, nearly endless, but with a code you
can learn ("right, right, second door on the left, straight through"). The only way out is the
patch of wall you came in through, in a nondescript start room with one small thing in it. No
Jump options for visitors while inside (the owner keeps them). In one hard-to-reach room's
corner, Martin Folse's stick (HTV, Houma: the white pointer he lays on the radar to call
landfall), with a glow; within 2 m a caption names it. No pickup yet. Named "Stockrooms";
no use of the film's name or anything else from it. He picked approach A of the options page.

## The look (from the video, frame every 4 s)
Ochre wallpaper with faint vertical stripes and a damp mottle, beige-green carpet with stains,
a drop ceiling with recessed panels on a 4 x 3 m lattice (12 % dead, 5 % flickering), walls
darker at the foot, everything one hue, haze that eats the far end of every corridor, a
fluorescent hum. Rooms are mostly nothing: some have a table (some with a beige computer), a
camcorder on a tripod with its red light on, stacked boxes, stacked chairs.

## Layout (`tools/stockrooms/make_stockrooms.py` → `scripts/stockrooms_map.json`)
- Grid 360 x 300 cells of 1 m. Corridors 3 m wide, ceiling 2.75 m.
- **Four stations**, each the same shape: an entry corridor from the south, a 13 m bay with four
  column stubs, exits west, east, north.
  - S1: **right** (east). S2: **right** (east); S2's bay has a ladder up to a dark hole (landmark).
  - S3: east is a corridor of rooms; the **second door on the left** opens into a room with one
    folding chair (landmark) and a door in its far wall that goes on.
  - S4: **straight through** (north) into the room with the stick in its far corner.
- **Every wrong move** (S1/S2 west and north, S3 west, north and the rest of the room corridor,
  S4 west and east) ends, after a corner, in a long corridor north into a **copy** of the station
  you left (its entry, bay, bay props and exit stubs; its north exit as long as the real one). A
  **seam** across the copy's entry, 6 m short of the bay, moves you by a fixed offset into the
  real entry: the hall seems to go on and on and brings you back where you were. Fog hides the
  copy's short stubs. 9 seams.
- Long wrong-way corridors get plain side rooms (some furnished) every 9 m.
- **Home** is the code backward; the loops still catch wrong turns. The start room (south of
  S1) holds a small crate by the door wall.

## Runtime (`scripts/stockrooms.gd`, made by `player.gd` in Wing 1)
- Built on first entry from primitives and generated textures at `ORIGIN` (2000, 0, 2000):
  floor, ceiling and wall meshes (about 40k triangles), emissive panels, props, one dim
  directional light, the stick's halo and a small warm light. Nothing in either wing's bake,
  stand-ins or game files changes.
- **Door in:** unlocked per browser (`localStorage` "mall-stockrooms"; set when the Rougarou goes
  through the wall). Walking into Woolworth's back corner (x < −45.0, z 21.0–21.9) fades into the
  start room facing north.
- **While inside:** the mall's nodes hidden, the environment swapped (ambient ochre, haze, glow,
  filmic, desaturated), the floor mirror off, the player's walk grid and obstacles swapped for the
  maze's, the HUD buttons hidden, the Jump menu hidden and locked unless `Signs.is_owner`. The
  Rougarou paused.
- **Door out:** walking into the start room's south wall (the 'X' cells: drawn as wall, walkable)
  fades back to Woolworth's corner facing into the store; everything restored. If the owner jumps
  away, the level notices and restores too.
- URL: `?stockrooms=1` unlocks; `?stockrooms=in` starts inside (owner testing).

## The Rougarou's exit (`scripts/rougarou_ai.gd`, story stage 3)
- In Woolworth, a close look (seen within 10 m), or being spotted again after ducking 3 times
  (`story_ducks_before_exit`), and it walks at 3 m/s (`story_exit_mps`, a slow lope) along free
  floor to the back corner and on into the wall, then the route ends and the door unlocks.

## Demo 31
- The ladder rebuilt upright in a pivot and tilted as one, rungs between the rails.
- Sounds with no source to find: every 15–45 s, 4–9 muffled footsteps walking past, or a paper
  rustle, 9–22 m away (generated PCM, AudioStreamPlayer3D).

## Checks
- `tools/qa/stockrooms_test.gd`: STOCKROOMS TEST OK (12 checks) with renders.
- `tools/qa/rougarou_story_test.gd`: the whole route through the walk into the wall and the unlock.

## Open
- (Nov 1, workstream B+C) The stick is a pick-up item now: held in first person, swings on the
  action button (design/godot-interaction.md); the prompt "Pick up Martin Folse's stick" replaces
  the caption. No sound beyond the hum; VR untested inside (the walk grid swap
  should carry over, the env swap too).
- The stick is a stand-in (white, ~1.22 m, slight taper and worn tip): no close photo found.
- The seam is a pure translation; turning round right after one shows the real entry behind you.
