# The Runner (Godot mall, Oct 16 2026)

Steven, Oct 16: replace the Rougarou with one of the window mannequins, animated, "doing similar
things to what the Rougarou did" on a new path. This build has two beats, both in Wing 2. The
Sears side comes later.

Code: `prototypes/godot-mall/project/scripts/runner_ai.gd`. Knobs: `scripts/runner.json`. Test:
`tools/qa/runner_test.gd`. The Rougarou's scripts (`rougarou_ai.gd`, `rougarou.gd`, `rougarou.json`)
and its suites were deleted on Nov 16, 2026 (Steven's decision; workstream TEST-DEBT). Its design note,
`design/godot-rougarou.md`, is kept as history.

## Who he is
He is Ch36, the featureless Mixamo figure that stood in every window in Demo 36. His clips come
from Steven's Oct 16 Mixamo downloads, baked into `npc/anims.res` (`tools/npc/bake_clips.gd`):
- `surprised`: the startle, about the first 0.9 s of it
- `run`: inside stores
- `sprint`: in the halls

Both runs are de-travelled; the stride is scaled to his ground speed. He runs at 1.15 × the
player's sprint (8.8 m/s), about 10.1 m/s, so a sprinting player falls behind.

## Beat 1: Merry-Go-Round
He stands frozen in Merry-Go-Round's right-hand window, in the old stand-in form's place.
`dyn_rg_mannequin` is now always hidden.
- **Trigger:** the player comes within 5 m.
- **Startle and exit:** he startles, then runs back through the store and out its door.
- **Route:** east down the Concourse toward Payless, weaving round shoppers and the player. He
  never goes through a wall or a fixture.
- **Exit:** at the court he turns right and runs up Dillard's entry, where he is gone.

## Beat 2: Saadi's
- **Placement:** while it is out of the player's sight, he takes his place in Saadi's second
  window from the left (as you face the store).
- **Disguise:** he is frozen like a form on a platform. From across the court he looks like just
  a mannequin.
- **Trigger:** the player comes within 3 m of that window.
- **Exit:** he bursts out the door past the player, runs back across the court and along the
  Concourse into Wicks 'N' Sticks, and vanishes at its back door, the one with the exit sign.

## State
- **Storage:** the beat is kept in sessionStorage `mall-runner` (1, 2, 3 = done), so it survives
  crossing wings and reloads in the same tab.
- **URL:** `?runner=0` turns him off; `?runner=1` or `?runner=2` starts at that beat.

## Also changed with him
The Stockrooms no longer wait for the Rougarou's Woolworth exit. The door behind Woolworth's back
corner is open for everyone from the first visit (Steven: "not tied to following the Rugaru on
those three paths anymore").
