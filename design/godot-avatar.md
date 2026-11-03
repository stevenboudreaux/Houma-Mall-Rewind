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
- in the Body mesh: the face (its biggest island), every island near the face's colour, and any
  warm, skin-like island (Remy's limbs are lighter than his face) → **skin** (eyes, teeth, brows
  stay); body islands under the clothes (painted white or grey) follow the clothes by body part;
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
- **Walking pace** (workstream WALK, Nov 3 2026; Steven: "in third person the avatar walks slower than
  first person, it needs a faster cadence, and the run about 50 % faster"): third person walks at
  **3.0 m/s** at full stick (first person stays 4.0, untouched: `player.move_scale` is 1.0 there);
  running (X / Shift / the right mouse button, ×2.2) is **6.6 m/s**. V had 2.0 / 4.4 (a guess: "4 m/s is
  a jog"). Touch keeps the 46 px full stick and the 0.05 deadzone; a gamepad's full stick is 3.0.
- **Gaits** (WALK retune): walk below 3.4 m/s (`walk_m` / `walk_f` by the body's sex in `npcs.json`),
  jog to 4.6, run to 6.0, sprint above, with 0.25 m/s of hysteresis (V: 2.4 / 3.6 / 5.4; a plain speed
  change alone would have made the full-stick walk a jog). **Playback = ground speed / the clip's own
  speed** from `npc/anims.json`: `walk_m` 1.616 m/s, `walk_f` 1.623, `jog` 2.512, `run` 4.555, `sprint`
  5.973 (the 1.765 m/s in the brief was the retired Demo 36 clip, still in `npc/skins.json`
  `walk_mps`), capped at ×2.0 (`GAIT_MAX`). So a full-stick walk plays `walk_m` at **×1.86** (a brisk
  walk: the walk clip's pose and arm swing at a quicker cadence, ~3.6 steps/s, the feet matching the
  ground) and a full run plays `sprint` at **×1.10**; a half stick while running (3.3 m/s) is `walk` at
  ×2.0 just under the jog threshold, then `jog` ×1.35-1.8 and `run` ×1.0-1.3 across the stick. A body
  without a clip falls to the next gait down (not to a sliding walk). The tests check the playback
  against the measured speed, walking and running.
- **Idle** (`idle`) when the ground speed drops under 0.15 m/s.
- **The camera** rides a boom from a pivot 1.5 m up and 0.35 m to the right, 2.4 m back along the
  view (the view pitches −60°…+29° in third person). Before every frame the boom is marched in 6 cm
  steps against **the same walk grid and obstacle list the player walks on** (walls, store fronts,
  the glass rects, columns, the arcade's machines, gondolas and counters, the benches when shown),
  with 14 cm clearance; it is pulled in at once and let out slowly (no pumping). **The pivot rides the
  player exactly** (WALK): V glided the pivot in world space at 6/s, which trailed the player by
  speed / 6 (1.1 m at the new 6.6 m/s run, so the avatar shrank into the frame and the clearance was
  tested from the wrong place); now only the shoulder offset glides, in the player's frame, when the
  camera changes side.
- **Hanging signs** are not in that list, and the lowest hang at 2.0 m (Kay-Bee's sale cards,
  2.0–2.6 m; department boards from 2.56 m). So the camera stays between 0.35 and **1.95 m**: the
  boom tilts only as far as that allows, and the view pitches on its own (looking down, the avatar
  moves up the frame rather than the camera rising). Found by looking: an earlier "rise over the
  machines" camera went through Kay-Bee's 20 % OFF card.
- **Tight spots** (an arcade aisle, a store's gondolas): the other shoulder and straight behind are
  tried too, and the side with the longest clear boom wins (a new side must be 0.4 m better, so it
  doesn't flip). The pivot glides to the new side.
- **Very close in** (boom under 0.75 m: backed against a wall) the avatar is hidden, so the view is
  never from inside its head.
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
- **The cost of one more skinned character** (`tools/qa/avatar_test.gd`, the same view with the
  body shown and hidden, native and unbaked): the avatar adds **7.6k–15.6k triangles and 5–20 draw
  calls** (its body's surfaces, by body) to frames of 0.29–1.43 M triangles and 1.5–4.7k draw calls,
  about **1 %**. Frame time on the cloud's software renderer (llvmpipe): +0.2 % to +4 %, within its
  noise (one run measured it faster with the body shown). It is one skinned mesh (skinned on the GPU
  in the Compatibility renderer) plus one `NpcRig` retarget per frame on the CPU; in 1995 it joins up
  to 17 shoppers (1 in 18 of the skinned load), in 2026 it is the only person. **Not measured on an
  iPhone** (no device in the cloud): check with the owner's fps readout, standing in a busy 1995 hall,
  V on and off. If it costs, the levers: hide it beyond the first metre of boom, or a lighter body
  list for phones.
- **Pack sizes:** the 2026 packs now carry the bodies and clips: `w1y26` 20.7 → 37.9 MB, `w2y26`
  51.6 → 68.8 MB (+17.2 MB each, desktop and mobile alike); 1995 packs +0.5 MB (`avatar_bodies.json`
  and the scripts); the outside (wing 3) gets the same +17 MB when exported. **A decision for
  Steven:** keep that, or later move the bodies and clips into one shared pack loaded once and
  cached across wings and years.

## VR (design/godot-vr.md)
Always first person in VR: the avatar is hidden and its camera never made current while `vr_on`;
V / the View button do nothing; the buttons hide. Leaving VR restores the saved view. The flat
`player.cam` that VR hands back to is untouched.

## Checks (Nov 1, on `ws/v-avatar`)
- Native, unbaked (`xvfb-run -a godot --path . --rendering-driver opengl3 --resolution 1280x720 --script
  res://tools/qa/avatar_test.gd -- --wing=… [--year=2026] --out=… --spots="name:x,z,yaw,pitch;…"`):
  wing 1 (Kay-Bee aisle `-13,-56.2,90,-8`, hall `30,0,90,-8`) **27 checks OK**; wing 2 (hall
  `-20,54,90,-8`, Pocket Change aisle `-105,69,180,-10`, the dice in hand, VR) **31 OK**; wing 2 2026
  (games, inc. `-114,64,180,-10`, hall `-60,54,90,-8`, VR) **29 OK**. Each: walking plays the walk
  clip at ground speed (2.00 m/s / 1.616 = ×1.24 for `walk_m`, / 1.623 = ×1.23 for `walk_f`), idle
  standing, camera current and clear of walls and glass and under 1.95 m, first person = the eye
  camera at 1.62 m with speed ×1 and no body, the creator's controls on screen at 1280×720, 390×844 and
  844×390, a new body animated (not its T-pose).
- Web (`tools/export_web.sh`, both years, wings 1–2; `CHROMIUM=/opt/pw-browsers/chromium python3
  tools/qa/avatar_webtest.py "<build>/index.html?wing=2" <out>`): **AVATAR WEB OK (12 checks), 0
  console errors**: the creator on a first visit (desktop, phone portrait, phone landscape), Enter =
  Done → third person, V → first person saved, a reload keeps both, Escape = Skip → the default in
  first person, a tap on View, a touch-drag walk in third person, a `?cam=` link without the creator.
- `tools/qa/movetest.py` on `?wing=2&view=third`: hall and arcade load with **0 errors**, the touch walk
  moves (MOVED).
- `tools/qa/vrtest.py` (IWER Quest 2 emulator) with `view=third` added to every load: **ALL OK** (25):
  VR enters, walks, turns, jumps, plays a machine and crosses wings as before, in first person.
- `tools/qa/avatar_sheet.gd`: every body in its own colours and recoloured (`wsV-bodies-sheet.jpg`).

**Evidence** (`production/qa/evidence/`): `wsV-*-unbaked.jpg` native without a lightmap;
`wsV-web-*` / `wsV-movetest-*` the web build with the current published lightmaps (nothing baked
changed, so **no rebake is needed** for this workstream).
- Creator: `wsV-web-creator-desktop`, `wsV-web-creator-phone-portrait`, `wsV-web-creator-phone-landscape`
  (and the `-native` ones after Random).
- Third person: `wsV-tp-hall-walk-unbaked`, `wsV-tp-hall-idle-unbaked`, `wsV-tp-store-kaybee-unbaked`,
  `wsV-tp-arcade-pocketchange-unbaked`, `wsV-tp-arcade-gamesinc-2026-unbaked`, `wsV-tp-hall-2026-unbaked`,
  `wsV-tp-hand-dice-unbaked`, `wsV-web-tp-hall-desktop`, `wsV-web-tp-phone-walk`, `wsV-web-tp-phone-portrait`,
  `wsV-movetest-tp-hall`, `wsV-movetest-tp-arcade`.
- First person unchanged: `wsV-fp-hall-unchanged-unbaked`, `wsV-fp-arcade-unchanged-unbaked`,
  `wsV-web-fp-hall-desktop`, `wsV-web-fp-camlink-unchanged`.

## Checks (Nov 3 2026, workstream WALK, on `ws/walk-speed`)
Same tools, retuned for the new pace; nothing baked changed, so **no rebake is needed**. All shots
are unbaked (native) or the web build with the published lightmaps.
- Native, unbaked (`tools/qa/avatar_test.gd`, now also running back the way it came): wing 2
  (hall `-20,54,90,-8`, Pocket Change aisle `-105,69,180,-10`, the dice in hand, VR) **43 checks
  OK**; wing 1 (hall `30,0,90,-8`, Kay-Bee aisle `-13,-56.2,90,-8`) **41 OK**; wing 2 2026 (hall
  `-60,54,90,-8`, Games Inc. `-114,56,180,-10`) **41 OK**. Each spot: walking at **3.00 m/s** plays
  `walk_m` / `walk_f` at ×1.86 / ×1.85; running at **6.60 m/s** plays `sprint` at ×1.10; the camera's
  pivot is on the player (0.35 m, the shoulder; 0.00-0.02 m in a tight aisle, where the boom is 0
  and the avatar hidden as before) and the camera 2.38 m behind in a hall; the runner always ends on
  free floor; letting go goes to `idle`; first person unchanged (eye camera 1.62 m, speed ×1, no body).
- Web (`tools/export_web.sh`, wings 1-2 both years; `tools/qa/walk_webtest.py`, `?warm=0`, the
  default avatar): **WALK WEB OK** in all four, 25 / 16 / 16 / 16 checks, 0 console errors. Ground
  speed over the game's own clock **3.0 m per game second walking and 6.6 running** (keyboard W and
  W+X), `walk_m` ×1.86 and `sprint` ×1.10, the camera 2.34-2.40 m behind the player at both speeds
  (walk and run alike: it no longer trails), the player always on free floor, idle after the run.
  Wing 2 1995 also walks and runs at a 0.2 m glass pane (`-132.25,71.5` facing +z, the pane at
  z = 73.0): the position reaches 72.95 and never crosses, in frames of up to 1.3 s. A phone
  (844×390, touch): a full-stick drag walks at 3.0 m/s with `walk_m`. (The headless renderer draws
  a frame every 3-8 s, so the "frame sequences" are consecutive-ish game frames 0.5-1 game-second
  apart, labelled with the game clock and the position.) **Seen in those strips, not understood:**
  in a few frames the avatar's clothes draw in another skin's colours (a black polo, then a tan
  one, on Ch01's white-polo body: `wsWALK-web-w1-hall-walk-frames`, `-w2-hall-walk-frames`,
  `-w2-2026-hall-walk-frames`). The gait report of the same run says body Ch01, shown, no other
  body within 3 m, and the native (llvmpipe) shots never do it; it happened in every headless run,
  with the NPC warm-up on or off. It looks like the GL Compatibility renderer binding another
  texture to the recolour material for a frame on SwiftShader. Not from this workstream's code
  (`avatar_body.gd` is untouched); worth a look on a phone (V's "not measured on an iPhone").
- Found on the way, fixed here: a stop from jog / run / sprint never returned to idle
  (`NpcBody.set_speed(0)` only knows the walk clips; on a long frame the speed drops straight to 0,
  so it showed in the headless tests at once; on a phone it would have shown as a run-in-place after
  a hard stop). The native test now dismisses the "You received" card (R) before VR and runs back
  the way it came (6.6 m on from Pocket Change's spot is the prize counter's closer look).

**Evidence** (`production/qa/evidence/wsWALK-*`): native `tp-hall-walk-unbaked`,
`tp-hall-run-unbaked`, `tp-hall-idle-after-run-unbaked`, `tp-arcade-pocketchange-run-unbaked`,
`tp-store-kaybee-walk-unbaked`, `tp-store-kaybee-run-unbaked`, `tp-hall-2026-run-unbaked`,
`tp-arcade-gamesinc-2026-run-unbaked`; web frame strips `web-w2-hall-walk-frames`,
`web-w2-hall-run-frames`, `web-w2-hall-idle-after-run`, `web-w2-glass-run-frames`,
`web-w2-phone-touch-walk`, `web-w2-2026-hall-walk-frames`, `web-w2-2026-hall-run-frames`,
`web-w1-hall-walk-frames`, `web-w1-hall-run-frames`, `web-w1-2026-hall-walk-frames`,
`web-w1-2026-hall-run-frames`.

## Not done / open
- Hair **style** is the body's (16 hairstyles across the bodies, Ch01 bald); only its colour changes.
- The words are flat on the chest; on a body leaning forward they can float a few millimetres.
- The arm swing doesn't hold the item differently: the walk clip's right arm swings with it.
- In a crowd the avatar can pass through a shopper (no physics, as before in first person).
- The palettes are guesses for Steven to tune (`avatar_look.gd`). The pace is WALK's 3.0 / 6.6 m/s
  (`avatar.gd` `TP_WALK`, `player.gd` `RUN`); if the ×1.86 walk reads too hurried, the lever is the jog
  threshold (`GAITS`): at 3.0 the `jog` clip would play at ×1.19 instead.
- First-visit creator for a shared `?cam=` link is skipped on purpose; the button is there.
- The Top row's 11 swatches are ~28 px on a 390 px-wide phone, under Apple's 44 pt guideline; they
  tap fine in the test, but a two-row palette may be kinder.
- Entering VR with the creator open closes it (Skip on a first visit); the headset can't show it.
- WALK: in the headless web frame strips the avatar's clothes sometimes draw in another skin's
  colours for a frame (see "Checks (Nov 3 2026)"). Check on a phone; if it shows there, suspect the
  recolour material's texture binding in the Compatibility renderer (`avatar_body.gd` `_build`).
