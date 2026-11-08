# Characters: ready-made sources vs the built pipeline (workstream CHAR-SOURCES, Nov 8 2026)

Branch `ws/char-sources` (from `main`). Follows `design/godot-characters-research.md` (on `ws/char-research`:
options A–D, pipeline B recommended) and `design/research/character-pipeline-2026-11.md`. Already rejected
there and **not re-evaluated**: Quaternius / Kenney, VRoid, MetaHuman, raw Mixamo faces.
Evidence: `production/qa/evidence/wsSRC-sidebyside.jpg`, `wsSRC-rocketbox-sheet.jpg`.

## The recommendation in five lines

1. **Use Microsoft Rocketbox (MIT) as the source for talk-close people.** It is the only candidate that was
   reachable, licence-clean, and stood at the RadioShack counter in Godot today with a real face rig.
2. **It fits the phone:** 7.4k–9.9k tris, 3 draw calls, head 2048² + body/hair 1024², 52 ARKit + 15 viseme
   morphs, eye and jaw bones. The game's Mixamo clips play through `NpcRig` once the converter gives it Ch01's bone rests.
3. **For CHAR-BUILD: feed it, don't replace it wholesale.** Keep the one-file-per-person / one-loader rules;
   make the source a converted Rocketbox body (repainted clothes, `HEAVY`-style build edits) instead of hm08 + formula paint.
   Keep pipeline B for whoever Rocketbox can't cover (Houma Nation, older women, kids, very heavy bodies).
4. **For CHAR-STRIP: unchanged.** Strip the editor and both avatar systems as planned; Rocketbox needs none of them.
5. **Ready Player Me is gone** (closed Jan 31 2026); MakeHuman's asset library and Sketchfab could not be
   reached from the cloud box, so #2 and #3 are assessed on paper only. Steven: see "Open questions".

## The table

| # | Candidate | Licence | Reached from cloud? | Phone cost / person | Face rig (TALK) | Clothes / hair | Verdict |
|---|---|---|---|---|---|---|---|
| 1 | Ready Player Me | proprietary; **service closed Jan 31 2026** (Netflix bought it, Dec 2025) | no (`readyplayer.me` blocked; API dead anyway) | was ~10–20k, 2–6 draws | was ARKit 52 + visemes | — | **Dropped**: no platform, no export |
| 2 | MakeHuman / MPFB community assets (skins, hair, brows, lashes, teeth, eyes, clothes) | system assets CC0; community packs mixed CC0 / CC-BY (check each) | **no**: `static.makehumancommunity.org` and `files.…` are blocked; the assets are not mirrored on GitHub (the `makehuman` and `mpfb2` repos carry base mesh, targets, rigs, no skins/hair) | same as pipeline B, ≈12–15k after hiding | CC0 expression units (pipeline B) | proxy-fitted (`.mhclo`) to hm08 | **Not built.** Still the right test of "pipeline vs paint"; needs Steven to download the packs (below) |
| 3a | **Microsoft Rocketbox** (115 rigged people, 2022 facial update) | **MIT** ([LICENSE.md](https://github.com/microsoft/Microsoft-Rocketbox/blob/master/LICENSE.md), "Nov 2020 License Update: … MIT"). Credit the copyright line in the game's credits | **yes** (git, sparse checkout) | **7,364** (Male_Adult_08), **8,896** (Female_Adult_11), **8,966** (Business_Female_01), **9,874** (Female_Party_02) tris; **3 draw calls** (body, head, hair/lashes alpha); textures 2048 TGA source, shipped 2048 head / 1024 rest | **best of all**: `_facial.fbx` has 175 shapes (ARKit 52, 15 visemes, FACS, Vive), **eye bones** (`LeftEye`/`RightEye`), jaw + 30 face bones | baked into the body mesh and texture (one outfit per person; a new outfit = repaint, or a mesh edit); hair = alpha cards in the third material | **Recommended** (proof below) |
| 3b | Sketchfab CC0 / CC-BY rigged realistic humans | per model (CC-BY needs attribution) | **no** (`sketchfab.com` blocked); search found no realistic, rigged, face-rigged CC-BY human that beats Rocketbox; realistic ARKit-rigged humans are sold on RenderHub / Superhive / CGTrader under their own licences | — | — | — | **Not assessed** beyond search; none committed |
| 3c | Avatar SDK MetaPerson Creator (the RPM replacement vendors push) | proprietary; first avatar free, then credits; commercial terms "Enterprise", not stated for a shipped game | no (vendor site; GUI / API key) | ~10–20k, GLB with Mixamo-compatible rig per the vendor | ARKit per the vendor | per avatar | **Not recommended**: unclear game licence |
| 4a | Reallusion Character Creator 5 (+ iClone 8) | proprietary; content packs need export licences | no: Windows GUI only (no Linux, no command line) | heavy unless its game-base LOD is used | full (CC facial profile, ARKit export) | conforming clothes, card hair | **priced only**: CC5 ≈ $299 perpetual (Aug 2025 news), one review quotes $498 bundle; subscriptions since Jan 2026 (CC 365 ≈ $8.25/mo, Pro ≈ $33.25/mo); iClone 8 ≈ $599. Unverified (vendor pages blocked) |
| 4b | Human Generator Ultimate (Blender add-on) | add-on licence shown as royalty-free / GPL in different snapshots; check assets | headless in principle (bpy), add-on not downloadable here | realistic, high-poly; needs decimation | expressions, shape keys | its own clothes; particle hair needs converting to cards | **priced only**: $128 commercial / $68 personal (Blender Market / Superhive listings, undated) |
| 4c | Hair Tool (Bartosz Styperek) | commercial add-on | headless partly | — | — | hair cards + atlas baking | **priced only**: ≈ $52 (Nov 4 research; gumroad page blocked today) |

Rocketbox coverage for Houma (from the 115 thumbnails, `wsSRC` contact sheet in the session only): white
men and women of several ages, Black men (Male_Adult_04, _12, _18; Business_Male_05), Black women
(Business_Female_01, Female_Party_02, Female_Adult_11 reads lighter), East / South-East Asian adults
(Male_Adult_09, Business_Male_02, Female_Adult_03, Medical_Female_01), Middle-Eastern and South-Asian men,
4 children, older white men. **Gaps:** no Houma Nation / Native American faces, no heavy bodies, few older
women, no teenagers (the 18-year-old GAC line reads mid-20s), and the clothes are 2010s casual / business /
uniform. Every 1995 outfit is a repaint at least.

## The proof (what was built and looked at)

- **Converter** `tools/blender/cast_sources/rb2glb.py` (headless `bpy` 5.2.3): Rocketbox `_facial.fbx` →
  bones renamed Bip01 → `mixamorig:*` (eyes `LeftEye`/`RightEye`, jaw `Jaw`); arms, fingers and legs
  re-posed to a T-pose and applied as rest, with every shape key carried through; **every Mixamo-named bone
  given Ch01's rest orientation** from `npc/anims.json` (worst error 0.04°), so `NpcRig` has nothing to fix
  and TALK's `eye_point` / head look (which read the pose before retargeting) work as on a Mixamo skin; only
  ARKit + viseme shapes kept (67, ARKit names: `JawOpen`, `EyeBlinkLeft`, `MouthSmileLeft`, `viseme_aa` …);
  textures downsized; optional `HEAVY=<k>` pushes the trunk out along smoothed normals by skin weight.
  Runs in ~20 s per person.
- **In the mall:** `tools/qa/cast_preview_shots.gd` (dev only; needs `ws/talk`'s `TalkCamera`) is TALK's
  `talk_shots.gd` plus `--cast=res://cast_preview/<file>.glb`: the RadioShack attendant's body is replaced by
  an `NpcBody` wearing the candidate, then TALK's real camera, lights and look run. Same camera for every
  column. `wsSRC-sidebyside.jpg`: TALK's current attendant | the CHAR-BUILD stand-in (see below) | Rocketbox
  neutral | talking | heavier | Business_Female_01 | TALK's baked reference.
- **Turntable + face sheet:** `tools/qa/cast_turntable.gd` (dev only): `wsSRC-rocketbox-sheet.jpg`, six
  angles holding the `idle` clip through `NpcRig`, and neutral / talk / smile / blink / oh / look-left.
- **CHAR-BUILD's latest:** `origin/ws/char-build` does not exist (checked Nov 8, ~22:00 UTC). The column uses the
  pipeline-B test render from `ws/char-research` (`wsCHAR-radioshack-before-after.jpg`, middle panel: Cycles,
  not in game), labelled so. **Steven: paste CHAR-BUILD's latest RadioShack render** and the sheet gets redone.
- Not done: no 1995 repaint, no name badge (none invented), nothing on a phone, no LOD.

**What it shows:** at TALK's framing the Rocketbox face is a different class from both built faces: photo
skin, real eyelids and lashes, eyes that look into the camera, a mouth that opens. The body plays the
game's clips without retarget fix-ups. The heavier build reads in profile; the face stays slim.

**Faults seen (honest):**
- The open mouth shows a dark blue interior (no lit teeth / tongue): needs a mouth material fix or tint.
- `EyeBlink*` at 1.0 leaves a slit; use 1.0 + `EyeSquint*` 0.3, or the FACS `AU_45_Blink` (dropped by the converter).
- Hair cards: a dark seam at the parting on Male_Adult_08 (alpha sorting; set the hair material to alpha
  scissor / hash in Godot).
- TALK's look today drives eye bones but blinks only on UBC eyes (`npc_look.gd`): blink and lip flap need a few
  lines there to drive the `EyeBlink*` / `JawOpen` morphs. That is TALK's file; not touched here.
- The `HEAVY` push opens the shirt hem a little at the waist and leaves the face thin; a full heavy person
  needs a cheek/neck fill as well.

## What each candidate would mean for CHAR-BUILD and CHAR-STRIP

| Candidate | CHAR-BUILD (pipeline B) | CHAR-STRIP |
|---|---|---|
| Rocketbox (recommended) | **Feed it**: the generator's input becomes "Rocketbox person id + repaint + build edits" instead of hm08 macros + formula paint; its output contract (one `.glb` per person, Mixamo names, Ch01 rests, named morphs, eye bones) is exactly what `rb2glb.py` already writes. Keep hm08 for people Rocketbox lacks. | No change. The strip removes the editor and both avatar systems; the cast loader then loads these files. |
| MakeHuman assets (#2) | Would **feed** pipeline B directly (proxy-fitted skins, hair, brows, lashes, teeth). Decides whether B's problem is the paint. | No change. |
| Ready Player Me | — (closed) | — |
| CC5 / Human Generator | Would **replace** the generator with a GUI that Steven drives by hand (CC5, Windows) or a paid add-on of unclear licence. Not recommended. | No change. |

## Licence and repo notes

- Rocketbox is MIT: the converted `.glb` files may be committed and shipped with the MIT notice in the credits.
  They were **not** committed here (11–15 MB each, nothing in the game loads them yet). They live in the
  session's `cast_preview/` (git-ignored locally) and are rebuilt by the converter in seconds.
- Nothing paid was bought. No Sketchfab, RPM or MakeHuman-community asset was downloaded.

## Open questions for Steven

1. **Go with Rocketbox for the talk-close cast?** If yes, which person per line (`refs`-style contact sheet on request):
   RadioShack = Male_Adult_08 heavier? GAC = Business_Female_01 repainted?
2. **The MakeHuman test (#2):** download "MakeHuman system assets" + "skins 01/02" (CC0) and, if wanted,
   Hair 01 (CC0) from static.makehumancommunity.org/assets/assetpacks.html and push the zips to the `refs`
   branch (`refs/new/makehuman/`), or allow that host in the environment. Then the hm08 RadioShack person can be
   rebuilt with real skins and hair to settle "pipeline or paint".
3. Allow `sketchfab.com` (and an API token) if you want 3 hand-picked CC-BY models compared too.
4. 1995 outfits: repaint the Rocketbox clothes per person (Claude, scripted), or swap clothes meshes (bigger job)?

## Sources

- RPM closure: [Genies, "Ready Player Me Shutdown"](https://genies.com/blog/ready-player-me-shutdown),
  [Avatar SDK, "Avatar platforms 2026"](https://avatarsdk.com/blog/2026/08/31/avatar-platforms-2026-whos-alive-whos-gone/),
  [PocketGamer.biz, Netflix acquires RPM](https://www.pocketgamer.biz/netflix-acquires-avatar-creation-platform-ready-player-me)
  (no official Netflix/RPM notice found; vendor blogs are competitors).
- Rocketbox: [github.com/microsoft/Microsoft-Rocketbox](https://github.com/microsoft/Microsoft-Rocketbox) (README:
  2/2022 facial blendshapes, 6/2022 ARKit; LICENSE.md MIT), [Headbox](https://github.com/openVRlab/Headbox).
- MakeHuman packs: [asset packs page](https://static.makehumancommunity.org/assets/assetpacks.html) (blocked
  from the box; read through search results only).
- Reallusion prices: [CG Channel, Jan 2026 licensing change](https://www.cgchannel.com/2026/01/reallusion-switches-up-iclone-and-character-creator-licensing/),
  [Creative Bloq CC5 review](https://www.creativebloq.com/3d/reallusion-iclone-8-the-gold-standard-for-fast-and-effective-character-animation) (via search; pages blocked).
- Human Generator: [Superhive listing](https://superhivemarket.com/products/humgen3d), [Blender Market FAQ](https://blendermarket.com/products/humgen3d/faq) (via search).
- MetaPerson: [avatarsdk.com/metaperson-creator](https://avatarsdk.com/metaperson-creator/) (via search).
- Network: blocked from this cloud box on Nov 8: `static.makehumancommunity.org`, `sketchfab.com`, `readyplayer.me`,
  `models.readyplayer.me`, `download.blender.org`, `cgchannel.com`, `superhivemarket.com`, gumroad.
