# The Rougarou: the mall's first NPC (Godot mall, since Demo 25, Oct 14 2026)

> **REMOVED on Nov 16, 2026, by Steven's decision.** Out of the game since Oct 16 2026 (the Runner,
> `scripts/runner_ai.gd`, replaced it); on Nov 16 its code and suites were deleted: `scripts/rougarou_ai.gd`,
> `scripts/rougarou.gd`, `scripts/rougarou.json`, `tools/qa/rg_spawn.gd`, `rougarou_shot.gd`, `rougarou_test.gd`,
> `rougarou_stalk_test.gd`, `rougarou_story_test.gd`, `rougarou_woolworth_test.gd` (workstream TEST-DEBT,
> `production/session-handoff-2026-11-16-TEST-DEBT.md`). **Everything below is history**: the files it names
> are gone (git history has them, last at `d065c03` on `ws/test-debt`). What still carries the name (the
> Pocket Change claw prize "Rougarou plush", Merry-Go-Round's `dyn_rg_mannequin` form, now the Runner's) is
> listed in that handoff and was left alone.

**Asked for (Steven, Oct 14, 16:23):** "the first NPC that we'll have in the game ... the
Rougarou. It's a thing of Cajun folklore, a monster that's in the swamp, akin to a werewolf but
it's not." When you log in it's not there; after a few minutes you see it at the far side of the
mall, just standing; sometimes it shows up right behind you; very ominous, hunched over. It
doesn't attack. When you turn and see it, it runs: scatters off behind another wing or into a
store. His reference pictures: the Audubon Zoo's Rougarou sign, a swamp painting, a poster and a
Halloween animatronic — the mood, not a model.

## The figure (`scripts/rougarou.gd`)
- **The paradigm (Steven, 16:50): the old engraving "Le Rougarou, animal légendaire des Bayous de
  la Louisiane / Le Loup-garou des Créoles"**: a tall gaunt man-wolf stooped forward, the long
  back arched into a hump at the shoulders, the head thrust forward on the neck with the jaws
  open and the ears laid back, long sinewy arms hanging past the knees with clawed fingers, thin
  bent digitigrade legs in a stride, a bushy tail to the ground, a shaggy mane. The pose in
  `_pose()` is set to it; the first build (upright, head up, short arms) was "postured weird".
- Our own build from the folklore and that plate; no film or game creature is copied. Stooped,
  the top of its head is about 1.8 m up (it would be about 2.3 m upright).
- Built from primitives at runtime, no model file: a joint tree of Node3D pivots (`J`) carrying
  tapered cylinders and spheres; the fur is MultiMesh spikes riding each part (about 600 in all).
  Materials are flat colours; the eyes are emissive (energy 3) so they bloom at distance.
- Procedural animation in `_process`: breathing and a slow sway while standing; the head turns
  to `watch` (a world point) or scans; a lope when `gait` is 1 (legs and arms crossing, a bob, a
  lean, the jaw open). `hunch` 0..1 sets the pose.
- Faces -Z like a camera, so `look_at` points it at things.
- Cost: about 110 draw calls. Fine for one. If more appear, merge the body into one mesh.

## Stalk mode, the default since Demo 26 (Steven, Oct 14, 20:48)
"Make the rougarou immediately visible down the first long corridor you travel, in front of you at
a distance. If you try to get close to it it runs away. But you always see it at a distance."
- 1.5 s after the wing loads it stands 18–28 m ahead (`stalk_m`), in line of sight, within 30°
  of where the camera looks (`stalk_cone_deg`), facing the player. From the default spawn that
  is the far end of the main entrance hall, at the Shoe Dept. court.
- Walk within 12 m (`flee_m`) and it lopes off at 7.5 m/s (`flee_mps`) along the walk grid to the
  nearest tile at least 24 m away (`flee_to_m`) that the player can still see; only if there is
  none does it go round a corner. Then it stands and watches again. It never runs past the player.
- Out of sight (behind them, round a corner, or beyond 45 m, `lost_m`) for 1 s
  (`relocate_after_s`), it is put ahead of them again; if the view is short it widens the search.
- `"mode": "sightings"` in `rougarou.json` (or `?rougarou=now|behind`) brings back the cycle below.
- Check: `tools/qa/rougarou_stalk_test.gd` (STALK TEST OK, 10 checks); evidence
  `production/qa/evidence/d26-rougarou-stalk*.png`.

## The coat (Demo 33, Steven Oct 15 12:30)
- The first fur was thin cone spikes and read as quills up close. Now the body parts carry a
  streaked dark-brown hair texture (`_tex_coat`, long along each part), and the fur is soft cards:
  quads of a dozen wavy, tapering strands cut out by alpha (`_tex_strands`), hanging from each
  part's surface along its droop, faces turned out. About 1,100 cards (chest/mane 260, spine 110,
  each arm 94, each leg 90+), one draw call per part.

## Demo 32 changes (Steven, Oct 15 11:43)
- It got stuck at the corner (the shelves counted as blocking your view of it). Now the corner
  counts as seen when it is in your view cone with no wall between (`_seen_wall`), and once you
  have watched it it slides straight into the wall in front of it and is gone (≤ 0.7 s).
- The walk to the corner runs at 93 % of your running speed (`story_exit_frac`), and pulls away
  at 112 % if you get within 2.5 m: running, you nearly catch it but stay a metre or two behind.
- The route to the corner is found again (the corner tile sat on the edge of the search area).

## Demo 31 changes (Steven, Oct 15 10:26)
- Pocket Change sets it off the moment you are inside (the swap waits until the window is out of
  your view), so you can turn round in the arcade and see it in the window.
- Cucos: runs at 8 m, or walking at it inside 11 m (half of before).
- Woolworth finale: it walks to just in front of the back corner and stops, turned to you, until
  you have watched it for 0.8 s (`story_wall_look_s`); then it steps into the wall at 1.1 m/s, and
  freezes half in whenever you look away.

## Story mode, the default since Demo 28 (Steven, Oct 15, 06:45)
He played five minutes without a sighting, so it now follows a route set off by a place:
1. **Idle** until you walk into Pocket Change (past its threshold, by the Whirlwind) and back out.
2. **The window.** It stands stock-still (no breath, no scan; head turns to you once you are
   near) in Merry-Go-Round's right-hand window, exactly where the form stood; that form is its
   own mesh (`dyn_rg_mannequin`, `more.gd windows(own_k, own_group)`) and is hidden from now until
   the route ends. It stays stock-still until you are within 5 m (Demo 29, Steven Oct 15 07:47:
   "the only time you can get close"; it had bolted on the walk out of Pocket Change), then it
   runs to the back of the store and is gone.
3. **Cucos** (Wing 1). It stands at the doors. Within 16 m, or walking at it inside 22 m, it runs
   in and is gone.
4. **Woolworth.** It lurks at the back, turned to you, ducking to another spot out of your sight
   (5 m+ from where it was, 10 m+ from you, paths kept clear of the shelves) when you see it
   inside 22 m, come within 8 m, or every 6–11 s. A close look (seen within 10 m, shelves
   counted) and it runs and is gone.
5. Back to idle: the form returns to the window; Pocket Change starts it again.
- The stage survives crossing wings (`sessionStorage` "mall-rg"; `Engine` meta natively).
- Tunables `story_*` in `rougarou.json`; `?rougarou=s1|s2|s3` jumps to a stage, `?rougarou=stalk`
  the stalk mode below.
- Test `tools/qa/rougarou_story_test.gd` (STORY TEST OK, 18 checks); evidence
  `production/qa/evidence/d28-*`.

## Stalk tuning, Demo 27 (Steven, Oct 15, 05:16: "a happy medium")
- First appears 30 s into play (`stalk_first_s`), always ahead: 27–34 m off (`stalk_m`).
- Runs when you get within 24 m (`flee_m`, doubled from 12), toward the nearest tile out of
  sight, and is gone the moment it is out of view.
- Stays away a fresh random 30 s – 2 min every time (`reappear_s`), then stands ahead again.
- If there is no spot far enough ahead (a short hall), it waits out of sight instead of standing
  behind you.
- Test: `rougarou_stalk_test.gd --fast` (STALK TEST OK, 10 checks); evidence
  `production/qa/evidence/d27-rougarou-stalk-test.png`.

## The sightings cycle (`scripts/rougarou_ai.gd`, tunables in `scripts/rougarou.json`)
A node under the wing, made by `player.gd`. States:
- **hidden:** nothing for `first_sighting_s` (180 s) after the game starts, then
  `between_sightings_s` (45–120 s) between sightings.
- **far:** it stands, hunched, 25–45 m from the player (`far_m`) in their line of sight, with a
  70 % preference for somewhere behind them, head turned to them. Unseen for `stand_timeout_s`
  (40 s), it fades out.
- **behind:** `behind_m` (3.2 m) straight behind the player, facing them. From the second
  sighting on, `behind_chance` (30 %) of sightings are this. If the player turns and sees it, it
  bolts after `behind_look_to_bolt_s` (0.35 s); otherwise it leaves after `behind_timeout_s`.
- **bolt:** once looked at for `look_to_bolt_s` (1 s), it runs at `bolt_mps` (6.8 m/s) along the
  walk grid to the nearest tile at least `hide_m` (14 m) from the player and out of their line of
  sight (round a corner, into a side hall, into an open store), and vanishes there, or earlier
  once it has been out of sight for `gone_after_unseen_s`.
- **Seen** means: within `see_m` (70 m), inside `see_cone_deg` (28°) of the camera's forward,
  and the straight line to it crosses only walkable tiles (`_los`). Line of sight uses the walk
  grid, so glass storefronts count as walls; good enough for v1.
- It never collides with the player and never attacks.
- URL: `?rougarou=0` keeps it away; `?rougarou=now` brings the first sighting at once;
  `?rougarou=behind` makes it the behind-you one. Scheduled tests and screenshots are not
  affected: the first sighting is three minutes in.

## Checks
- `tools/qa/rougarou_shot.gd`: renders the figure in a studio (`--studio`) or in a wing at night
  (`--wing=1 --npc=x,z,yaw,hunch,gait --cam=...`).
- `tools/qa/rougarou_test.gd`: plays the cycle natively and prints ROUGAROU TEST OK: the far
  sighting in sight and in range, the bolt once looked at, the vanish, the behind-you sighting,
  its bolt. Screenshots at each beat.
- Evidence: `production/qa/evidence/d25-*`.

## Guessed, open
- Every number above is a first guess; Steven tunes `rougarou.json`.
- Not yet: sound (a breath, claws on terrazzo), a glimpse through a storefront, it watching from
  a store doorway, the day mode (it appears by day too for now), VR (it works, untested there).
- The bolt path can cut a corner of a storefront since it follows tile centres.

## Checks after the Demo 54 layout (TEST-DEBT, Nov 16 2026)
- `tools/qa/rougarou_test.gd`: ROUGAROU TEST OK (12). `rougarou_stalk_test.gd --fast`: STALK TEST OK (10).
- `tools/qa/rougarou_woolworth_test.gd` (new): story stage 3 in Woolworth's aisles: 148 lurk spots in
  the back half, all joined to the front on free floor and all with a route to the back corner;
  live, three ducks, the exit walk (17 steps) to the corner, into the wall, the Stockrooms door
  open; on free floor every running frame; longest run 2.4 s. WOOLWORTH RG TEST OK (12).
  Evidence `production/qa/evidence/wsTEST-DEBT-rg-wool-*`.
- `rougarou_story_test.gd` still waits for a node the game does not make (not in TEST-DEBT's scope;
  one `rg_spawn` call would fix it).

