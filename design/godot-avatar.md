# The avatar and first / third person (Godot mall, workstream V, Nov 1 2026)

**Asked for (Steven, Nov 1):** a basic avatar creator when the game starts (and from a button later):
body from the Mixamo characters the shoppers use, skin tone, hair, top and bottom colours, the shirt
words; 1995 clothes on the 1995 map, anything plausible in 2026; saved in localStorage across reloads
and wing loads; skippable with one tap. A first / third person switch (key, gamepad, touch): in third
person the avatar walks with the NPC walk clip at ground speed and idles when still, under a camera
that doesn't go through walls or store glass and works in tight stores and the arcade; first person
exactly as before. Reuse the NPC body and `npc_rig.gd`; the held item (B+C) in the right hand; phones
keep the two-thumb controls; VR stays first person. The 2D game's character creator (index.html
`lk-engine`: skin, hair, clothes, as swatches and choices) is the model for the creator's spirit.

Built on `ws/bc-interaction` (the interaction system, the bag, the owner-only HUD).

## Files
| File | What |
|---|---|
| `scripts/avatar.gd` | In the mall: the avatar's body in the world, the third-person camera, gaits, the view switch, the held item, the View / Avatar buttons, opening the creator. Made by `player.gd` as its child `Avatar`, after `Interact`. |
| `scripts/avatar_creator.tscn`, `scripts/avatar_creator.gd` | The creator (a CanvasLayer, layer 40): a turning preview and the rows. |
| `scripts/avatar_body.gd` | The avatar's body: `extends NpcBody` (the shoppers' body, clips and `NpcRig`, unchanged), plus the recoloured mesh, the shirt words and a right-hand holder. |
| `scripts/avatar_look.gd` | The look as data: palettes per year, the default, sanitising, localStorage. |
| `scripts/avatar_recolor.gdshader` | Skin, hair, top and bottom colours over the body's own texture. |
| `scripts/avatar_bodies.json` | Generated: the bodies, their islands and colours, the chest point. |
| `tools/avatar/analyze_bodies.gd` | Writes `avatar_bodies.json` (native, it decompresses textures). Rerun after the NPC skins are rebaked. |
| `tools/qa/avatar_sheet.gd` | Every body in its own colours and recoloured, one sheet (native). |
| `tools/qa/avatar_test.gd` | Native, unbaked: creator at three sizes, third person walking / idle per spot, the camera clear, first person unchanged, the held item, the fps cost. |
| `tools/qa/avatar_webtest.py` | The web build: creator on first visit (desktop, phone portrait / landscape), Done / Skip, V, the touch View button, a touch walk in third person, the reload, a `?cam=` link. |

Shared files, small hunks marked `V`:
- `scripts/player.gd`: `var avatar`, `var move_scale` (1.0 = as before; the walking step is multiplied
  by it), making `Avatar` after `Interact`.
- `scripts/signs.gd` `_near_check()`: an arcade cabinet's Play is judged from the player's eye
  (`player.cam`), not the view camera, which in third person is behind the avatar. The player is
  found through the group `mall_player` (added by `avatar.gd`).
- `export_presets.cfg`: the four 2026 presets and the two outside presets now ship `npc/anims.res` and
  the crowd's Mixamo skins (`npc/skins/Ch*`, `npc/skins/Remy*`, minus Ch06, Ch17, Ch36, which the
  avatar doesn't offer); they used to exclude `npc/*`. Pack cost: see "Phones".

## The creator
Opens by itself on a visitor's first load (nothing in localStorage `mall-avatar-1`), except when the
address has `?cam=` (tests, shared spots, and every wing / year crossing, which only happens after the
first load anyway). `?avatar=1` opens it whatever is saved. Later: the **Avatar (C)** button, **C**,
or a gamepad's **Start**.

| Row | Choices |
|---|---|
| Body | < n of 16 >: the crowd's bodies (`npcs.json` groups with weight, minus its `exclude`: Ch01, Ch02, Ch08, Ch12, Ch13, Ch21, Ch22, Ch23, Ch26, Ch27, Ch28, Ch37, Ch38, Ch41, Ch42, Remy). Each brings its own face, hairstyle and cut of clothes. |
| Skin | its own (•), then 7 tones, light to deep |
| Hair | its own (•), then natural colours (2026 adds a pink dye). Greyed for a body without hair (Ch01). |
| Top | its own (•), then the year's palette |
| Bottom | its own (•), then the year's palette |
| Words | < > through a few (none, HOUMA, BAYOU, …) or **Type** (the browser's text box, so a phone's keyboard works), up to 12 letters, upper case |
| | **Random** · **Skip** (first time; **Back** later) · **Done** |

Layout: the preview left (a third of the width) on a wide screen, on top (36 %) on a tall one; rows
sized from the height, so it fits a phone held either way (checked at 390×844, 844×390, 1280×720).
Drag the preview to turn it. Input: mouse; touch (tapped by hand: the project turns mouse emulation
off); keyboard ↑↓ rows, ←→ change, Enter Done, Esc Skip / Back, R Random; gamepad d-pad, A Done,
B Skip / Back, X Random. The player is frozen while it is open.

**Skip** saves the default (Ch01 in his own clothes, first person) and doesn't ask again. **Done** on
the first visit switches to third person (you just made it: see it); later Done keeps the view.

### Period clothes (guesses, `scripts/avatar_look.gd`)
Clothes and words are kept per year (`y1995`, `y2026`), so a 2026 colour never shows in 1995.
- **1995 tops:** white, black, heather grey, teal, plum, hunter green, burgundy, mustard, navy, red.
  **Bottoms:** light stonewash, mid denim, dark denim, black, khaki, olive, off-white.
  **Words:** HOUMA, BAYOU, CAJUN, TERREBONNE, LOUISIANA.
- **2026 tops:** white, black, charcoal, oatmeal, sage, rust, navy, lavender, red.
  **Bottoms:** light wash, dark indigo, black, tan, olive, grey. **Words:** HOUMA, BAYOU, GEAUX, 985, LOUISIANA.
- The bodies' **cuts** are the Mixamo models' own (hoodies, a suit, a chef-style jacket, shorts): the
  creator changes colours, not cuts. A couple of cuts read modern (Ch13's chef jacket, Ch42's slim
  joggers); they are the same bodies the 1995 crowd already wears. The "own" swatch keeps a body's
  original colours, which include a few prints (Ch42's red graphic tee, Ch37's stripes); **none of
  the bodies carry a real logo** (checked on the sheet), and typed words are the player's own.
- No real brand words in the presets (IP rule).

## How the colours are painted
The bodies are Mixamo characters with photo-like textures, one UV island per piece, and Mixamo names
each piece's mesh (`Ch21_Shirt`, `Ch21_Pants`, `Ch21_Hair`, `Ch21_Body`, …). `analyze_bodies.gd`
sorts every island once, offline:
- by its mesh's name: hair / beard → **hair**; shirt, hoodie, suit, coat, top → **top**; pants,
  shorts, bottoms → **bottom**; shoes, sneakers, heels, socks, belt, zipper, eyelashes → kept;
- in the Body mesh: the face (its biggest island) and every island near the face's colour → **skin**
  (eyes, teeth, brows stay); body islands under the clothes follow the clothes by body part;
- a mesh that holds everything (Ch12) or both garments (Ch02's "Cloth"): by the bone that moves the
  island most (head / torso and arms / hands / hips and legs / feet) and its colour against the face.
It writes each island's class and mean colour, and per vertex its island (base64 uint16), so the
browser never decodes a texture. At load, `avatar_body.gd` copies the mesh with the island's mean
colour in COLOR.rgb and class in COLOR.a; the shader repaints a changed class at the texel's own
brightness against its island's mean (multiplied for dark colours, added in sRGB for light ones, so a
white top keeps its folds), and skin per channel, only where a texel is close to its island's colour
(the eyes and lips painted into the face keep theirs). Unchanged classes ("own") are untouched.

**The shirt words** are a Label3D (the Forza face of Ch02's HOUMA) on a BoneAttachment3D riding
Spine2, at the chest point (sternum height, 74.5 % of standing height, front-most spine vertex),
shrunk to the chest's width, dark ink on a light top and light on a dark one. They don't wrap round a
curved chest; on the bodies they read flat and sit on the cloth (the sheet).

## Third person
| | Keyboard / mouse | Gamepad | Touch |
|---|---|---|---|
| First / third person | **V** | right-stick click | **View** button (top right, under Bag) |
| The creator | **C** | **Start** | **Avatar** button |
Saved with the look (`view`). `?view=third|first` sets it for one load (tests).

- **The body** stands at the player's position, turns (smoothly) to the way it walks, keeps its
  facing when still. It is an `NpcBody`, so it plays the shoppers' clips through the same `NpcRig`
  retargeting.
- **Walking pace:** third person walks at **2.0 m/s** at full stick (first person stays 4.0, untouched:
  `player.move_scale` is 1.0 there); running (X / Shift / the right mouse button, ×2.2) is 4.4 m/s.
  A guess: 4 m/s is a jog, and the brief asks for the walk clip.
- **Gaits:** walk below 2.4 m/s (`walk_m` / `walk_f` by the body's sex in `npcs.json`), jog to 3.6,
  run to 5.4, sprint above, with a little hysteresis. **Playback = ground speed / the clip's own
  speed** from `npc/anims.json`: `walk_m` 1.616 m/s, `walk_f` 1.623, `jog` 2.512, `run` 4.555, `sprint`
  5.973 (the 1.765 m/s in the brief was the retired Demo 36 clip, still in `npc/skins.json`
  `walk_mps`). So a full-stick walk plays `walk_m` at ×1.24 and a run plays `run` at ×0.97; a half
  stick plays the walk slower. The test checks the playback against the measured speed.
- **Idle** (`idle`) when the ground speed drops under 0.15 m/s.
- **The camera** rides a boom from a pivot 1.5 m up and 0.35 m to the right, 2.4 m back along the
  view (pitch limited to −60°…+29° in third person). Before every frame the boom is marched in 6 cm
  steps against **the same walk grid and obstacle list the player walks on** (walls, store fronts,
  the glass rects, columns, the arcade's machines, the benches when shown), with 14 cm clearance;
  it is pulled in at once and let out slowly (no pumping). It is also kept under 2.7 m (store
  ceilings are ~3.2 m) and over 0.35 m.
- **Tight spots:** when the normal boom is under 1.5 m, a **high boom** is tried: the camera looks
  down at least 46° from up to 2.7 m, and box-shaped obstacles (machines, counters, gondolas: rects at
  least 0.55 m deep both ways) don't stop it, since it passes over them; walls, columns and the thin
  glass rects still do. It blends in and out over 0.4 s.
- **Very close in** (boom under 0.75 m: against a wall) the avatar is hidden, so the view is never
  from inside its head.
- **The rest of the game** still asks the eye: interaction reach and facing (`interact.gd`), the
  prize counter's zones and closer look (`prizes.gd`, from `player.cam`), an arcade cabinet's Play
  (`signs.gd`, patched), the seam and door prompts. The floor reflection and the Runner's "seen"
  test use the view camera, as they should.
- **Frozen moments** (the prize counter's closer look, the creator) hide the avatar and leave the
  camera to whoever froze the player; the third-person camera takes over again after.

**The held item** (B+C `interact.gd` `hand_item`) moves into the avatar's right hand in third person
(a holder on the RightHand bone, the item's own Grip, a fixed turn onto the hand), and back to the
first-person hand in first person. The swing's turn is copied onto it. The fuzzy dice hang from the
fist (`wsV-tp-hand-unbaked.jpg`).

## Phones
- The creator fits an iPhone held either way; touch works by hand-tapping (as the rest of the HUD).
- Third person keeps the two thumbs (left drag walks, right drag looks); the View and Avatar buttons
  are under Bag in the top-right column.
- **The cost of one more skinned character:** RESULTS_FPS
- **Pack sizes:** RESULTS_PACKS

## VR (design/godot-vr.md)
Always first person in VR: the avatar is hidden and its camera never made current while `vr_on`;
V / the View button do nothing; the buttons hide. Leaving VR restores the saved view. The flat
`player.cam` that VR hands back to is untouched.

## Not done / open
- Hair **style** is the body's (16 hairstyles across the bodies, Ch01 bald); only its colour changes.
- The words are flat on the chest; on a body leaning forward they can float a few millimetres.
- The arm swing doesn't hold the item differently: the walk clip's right arm swings with it.
- In a crowd the avatar can pass through a shopper (no physics, as before in first person).
- The palettes and the 2.0 m/s pace are guesses for Steven to tune (`avatar_look.gd`, `avatar.gd` `TP_WALK`).
- First-visit creator for a shared `?cam=` link is skipped on purpose; the button is there.
