# Character pipeline: alternatives and add-ons (research, workstream CHAR-EDITOR, Nov 4 2026)

**Asked for (Steven, Nov 4):** today's pipeline is Blender + Mixamo. Look at alternatives and add-ons for
building and texturing stylised game characters with consistent bodies, hair cards and clothing that fit
(MakeHuman / MPFB, Character Creator, Blender add-ons, AI texturing, Godot-side solutions): what each
costs, whether it can run headless in a cloud session, and what Steven would do by hand. Report before
any big rebuild; **nothing here is rebuilt yet.**

## What we have today (for comparison)

| Part | Today | Where |
|---|---|---|
| Bodies, shape keys, joints | MakeHuman hm08 base mesh and targets (**CC0 data**), read from MPFB2's repo; our own macro code (`mh.py`), decimated to 14.8k tris | `tools/blender/characters/` (B1), `design/godot-characters.md` |
| Rig, weights | MPFB's Mixamo-named rig and weights (CC0 data), rest = Ch01's T-pose, so every Mixamo clip plays | same |
| Hair | 11 styles per sex, **solid shells** ray-cast onto the scalp, one tinted strand texture, rigid on the Head bone, blend shapes from the 8 nearest head / neck vertices | `hair.py` |
| Clothes | 71 pieces **cut from the body's own skin** and offset by layer, bound to the 8 nearest skin vertices per blend shape, region hiding below | `garments.py`, `pieces.py` |
| Textures | procedural (numpy / Cycles bakes): skin, fabric tiles, strand texture | `tex.py`, `fabric.py` |
| Animation | Mixamo clips (Steven's Oct 16 download), retargeted at runtime (`NpcRig`) | `npc/anims.res` |
| Runs | headless: `bpy` (Blender as a Python module, `pip install bpy`, 5.2.x is on PyPI for Python 3.13) + numpy; Godot headless | cloud or Mac |

Strengths: everything is a script, CC0 data, one skeleton for bodies, hair and clothes, so fits can be
checked by code and rebuilt in minutes. Weaknesses found this sprint (`design/godot-character-editor.md`
"Hair fit"): **shell hair** reads as a helmet and its curtain did not follow the shoulders / chest (fixed
at runtime by `scripts/chars/char_fit.gd`, but the real fix is better binding and hair cards); clothes are
plain (no seams, no folds beyond the normal tile); faces are MakeHuman's average at 3.1k tris.

## The options

### 1. MPFB 2 itself (MakeHuman for Blender), headless
- **What:** the MakeHuman character generator inside Blender (body sliders, skin materials, rigs incl. game
  rigs and Rigify, a clothes / hair / eyebrows / eyelashes library, **MakeClothes** and **MakeTarget**
  tools). Assets are fitted by MakeHuman's *proxy* method: every clothes / hair vertex is stored as a
  point on a base-mesh triangle (barycentric + offset), so it follows **every** shape exactly; that is the
  method that makes hair and clothing "always fit". Exports glTF / FBX / USD.
- **Cost:** free. Code GPLv3 (we would only *run* it, not ship it; output is ours), bundled assets CC0;
  the MakeHuman community asset library is mixed (many CC0, some CC-BY): check each asset's licence.
- **Headless here:** yes in principle: `pip install bpy` + the MPFB extension enabled in a script
  (Blender 4.2+). Not tried this session. Its UI-driven tools (MakeClothes) are scriptable through its
  Python services, but expect a day of setup.
- **By hand (Steven):** nothing required. Optional: pick community hair / clothes he likes.
- **Fit for us:** high. We already use its data; adopting its **proxy fitting** for our own hair and
  clothes (instead of "8 nearest vertices") is the single biggest reliability gain. Its stock clothes
  and hair are realistic-generic, not 1995 mall; we'd still make our own.

### 2. Reallusion Character Creator 5 (CC5)
- **What:** the most complete commercial character system: high-quality morph bodies and heads,
  conforming clothes (auto-fit to any morph), hair (strand and card hair through add-ons / content
  packs), skin and texture editing, LOD and "game base" export, AccuRIG built in, FBX / OBJ out
  (plugins for Blender, Unity, Unreal).
- **Cost:** CC5 **$299** perpetual (Deluxe bundle with ActorMixer Pro and HD morphs $499, Aug 2025).
  Content is licensed separately: base content may be used in games in compiled form; many content-store
  packs need an **export licence** for a game (check each pack: Reallusion's content policy page).
- **Headless here:** **no.** Windows 10+ only, GUI only; no Linux, no command line. Steven's machine is
  a Mac (the integration bakes run there), so he would also need a Windows PC or VM.
- **By hand (Steven):** everything: build each character in the GUI, export FBX, hand the files over.
  We would then re-rig / rename onto our skeleton (CC's own rig is not Mixamo-named; it maps to it).
- **Fit for us:** low. Best quality per hour of a skilled user, but it breaks "every asset is a
  script Claude can rebuild and check", costs a Windows machine, licence bookkeeping per pack, and CC
  characters are heavy for a phone (needs its game base / LOD path).

### 3. Other generators
- **MetaHuman (Epic):** photoreal; since mid-2025 the licence allows use in other engines, but the meshes,
  grooms and materials are far beyond an iPhone web budget and the look is not stylised. Not a fit.
- **VRoid Studio (Pixiv):** free, Windows / Mac, GUI; built-in hair cards and clothing textures; anime
  style only, VRM export. The style doesn't match the mall. Not a fit.
- **Humanizer (Godot 4 add-on, MakeHuman → Godot, GDScript):** a runtime MakeHuman in Godot. **AGPL-3.0**
  code (shipping it in the game would put the game under AGPL), little activity since late 2025. We already
  have our own runtime (`CharBody`): not needed. Worth reading for ideas only.

### 4. Blender add-ons (to keep our pipeline and fix its weak parts)
| Add-on | What | Cost | Headless | Note |
|---|---|---|---|---|
| **Hair Tool** (Bartosz Styperek) | hair cards from curves, card UVs onto an atlas, texture baking with channel packing | $52 | partly (bpy operators; untested here) | the standard tool for card hair |
| **Free hair-cards-from-curves** (Daniel Bystedt, geometry nodes) | cards along Blender's hair curves | free | yes (geometry nodes evaluate in bpy) | a good starting point to script ours |
| **Blender's own hair curves + geometry nodes** | guide curves on the scalp → card strips → bake strands to an alpha atlas | free | yes | what I'd use: no dependency, fully scriptable |
| Auto-Rig Pro | rigging, game export, retargeting | ~$40 | partly | not needed: our skeleton is fixed and matches Mixamo |
| Rigify | rig generator | free | yes | not needed for the same reason |
- Mixamo: still free with an Adobe ID, royalty-free in games; keep it **for animation clips only**.
  AccuRIG 2 (Reallusion, free, GUI) is the fallback auto-rigger if a new humanoid ever needs one.

### 5. AI texturing / generation
| Tool | Textures an existing mesh? | Cost | Headless here | Note |
|---|---|---|---|---|
| Meshy (retexture) | yes, prompt or image | subscription (~$20/mo tier) + API credits | API over HTTPS, if the egress allowlist allows it | game-oriented; output needs checking for text / logos (IP rule) |
| Tripo, Rodin (Hyper3D) | mostly at generation time | subscription / credits | API | generation tools; their meshes don't share our skeleton or topology |
| Hunyuan3D-2 Paint (Tencent, open weights) | yes | free weights | **no**: needs a CUDA GPU (we have 2 CPUs); its licence excludes the EU, UK and South Korea | |
| StableProjectorz | yes (projection painting) | free | no (Windows GUI) | |
| Substance 3D Painter | manual + AI-assisted | subscription or Steam perpetual | no (GUI) | the industry standard for hand texturing |
- **For us:** AI texturing helps most on things we can't paint procedurally: **fabric prints, faces' skin
  detail, worn denim**, used as *tiles or reference* that we then bake through our own UVs, with every
  output looked at for words, logos and faces of real people. Generated *meshes* don't help: they don't
  share our skeleton, topology or blend shapes, so nothing would fit.

### 6. Godot side
- Keep our runtime (`CharBody`, `CharPreset`, `CharFit`): blend shapes + joint offsets + region hiding +
  baking for NPCs already do what the add-ons would.
- Godot 4.7 has no built-in cloth or hair-card system; card hair is ordinary alpha-scissor (or alpha
  to coverage) geometry with a strand texture, which the Compatibility renderer (the web build) draws
  fine. Strand / groom hair is not an option on WebGL 2 phones.

## Recommendation

1. **Keep Blender + our scripts + MakeHuman's CC0 data; don't buy Character Creator.** CC5 is the best
   GUI tool but it is Windows-only and hand-driven, so Steven would become the character factory and we
   lose the rebuild-and-check loop that caught this sprint's problems.
2. **Next character rebuild (a session with `pip install bpy`), in this order:**
   a. **Proxy binding** (MakeHuman's method) for every piece, replacing "8 nearest skin vertices": each
      piece vertex stored on a body triangle (barycentric + normal offset), evaluated per blend shape. This
      makes hair and clothes follow every slider exactly and removes most of `fitcheck.py`'s failures. It
      can be written in our own `pieces.py` from the published method (no GPL code copied).
   b. **Hair cards** for the long and textured styles (shoulder, long, perm, braids, puffs, elderly):
      guide curves on the scalp → card strips (geometry nodes or our numpy builder) → a baked strand
      atlas (albedo with alpha, a root-to-tip gradient, a flow normal), 2–6k tris per style (the old cap
      was 2k; files can be bigger now that R2 has no pack limit). Short styles (crew, fade, bowl,
      sidepart, balding) stay shells with a better strand texture and a feathered hairline card ring.
      Hair Tool ($52) is worth buying only if the scripted cards stall.
   c. **Curtain skinning** baked in Blender (what `CharFit` does at runtime today: below the jaw the hair
      rides Neck and Spine2), plus collision against the shoulders in the generator.
   d. **The face pass** on the `_hi` head (hm08's quads), when Steven wants faces to read up close.
3. **Mixamo stays for animation.** AI texturing only as reviewed tiles / references, never in the
   automated build.
4. **What Steven does by hand:** nothing for (a)–(c). For (d) and for any AI-made print: look at the
   sheets and say yes / no.

Until that rebuild, `scripts/chars/char_fit.gd` keeps every hair clear of the body at load (see the grids).

## Sources
- MPFB 2: [CG Channel, Mar 2025](https://www.cgchannel.com/2025/03/check-out-open-source-blender-character-generation-plugin-mpfb-2),
  [extensions.blender.org/add-ons/mpfb](https://extensions.blender.org/add-ons/mpfb/)
- Character Creator 5: [CG Channel, Aug 2025](https://www.cgchannel.com/2025/08/reallusion-releases-character-creator-5/),
  [Reallusion content policy](https://www.reallusion.com/license/content.html)
- Hair Tool: [bartoszstyperek.gumroad.com/l/hairtool](https://bartoszstyperek.gumroad.com/l/hairtool);
  free cards from curves: [80.lv](https://80.lv/articles/free-hair-cards-from-curves-setup-for-blender)
- Mixamo and alternatives: [cinevva guide (2026)](https://app.cinevva.com/guides/free-character-animations-rigging),
  [AccuRIG 2.0, CG Channel](https://www.cgchannel.com/2025/07/rig-and-animate-3d-characters-for-free-with-accurig-2-0/)
- AI texturing overview: [3D AI Studio, 2026](https://www.3daistudio.com/blog/best-ai-texture-and-pbr-generators-2026)
- Humanizer: [github.com/NitroxNova/humanizer](https://github.com/NitroxNova/humanizer) (AGPL-3.0)
- `bpy` on PyPI: `pip download bpy` lists 5.1.0 – 5.2.3 for Python 3.13 (checked in this session).
- Not verified this session (stated from general knowledge, check before relying on them): MetaHuman's
  cross-engine licence change (2025), Meshy's current prices, Hunyuan3D's licence territory exclusions,
  Auto-Rig Pro's price.

## Addendum (director, Nov 4 evening): ready-made hair and body assets to import

Steven asked for options to import better hair and body assets for Blender and Godot. Ranked by how well
they fit our pipeline (MakeHuman hm08 body, Mixamo-named rig, proxy fitting planned in the rebuild):

| Option | What | Licence / cost | Fit with our bodies |
|---|---|---|---|
| **MakeHuman community asset packs** | Hair 01 (mostly low-poly, stylized, **CC0**), Hair 02 (high-poly, CC-BY), Hair 03 (CC-BY); skins, eyebrows, eyelashes, shirts, pants, shoes, hats, glasses, beards (CC0 and CC-BY packs) | free; CC0 packs need nothing, CC-BY packs need a credit line | **Best**: made for the hm08 base mesh we already use, fitted by MakeHuman's proxy method, so they follow every slider once the rebuild's proxy binding is in. Loads through MPFB 2 (needs the "system assets" pack) |
| **Quaternius Universal Base Characters** | 6 bodies (regular, teen, superhero; m/f), 20 hairstyles, humanoid rig, ~13k tris; Source version has .blend + a Godot 4.3 project | **CC0**; Standard free, Source via Patreon credits ($10+/mo) | Good as a hair/NPC source: stylized, game-ready, tested in Godot. Different body, so hair needs refitting onto hm08 (or use its bodies for background NPCs) |
| **Stylized Hair Asset Library** (Superhive) | 200 static hair meshes (100 m / 100 f), 3.5–10k faces each, .blend + .fbx | $99.99 standard / $199 commercial licence | Medium: anime/stylized look, no UVs, materials or rig; fitting heads vary, so each needs placing, UVs and a strand texture |
| **Human Generator Ultimate** (Blender add-on) | realistic humans, hairstyles, clothing, expressions, rig | $128 commercial ($68 personal); add-on is GPL, check its asset terms | Low: realistic and heavy for iPhone web; hair likely particle hair needing conversion to cards; second body system |
| **Blender Studio Human Base Meshes** | 17 meshes (realistic + stylised bodies, heads, hands), clean quads, UDIM UVs | **CC0**, free | Low for now: sculpting bases, no rig or hair |
| **Hair Tool** (Bartosz Styperek) | tool, not assets: make our own hair cards and bake strand atlases | $52 | Only if scripted cards stall (see recommendation 2b) |

**Suggested path:** start the rebuild with the MakeHuman CC0 hair, eyebrow, eyelash and skin packs (zero licence
work, already fit our body), add Quaternius hair as a stylized second source, and use CC-BY packs only with an
in-game credits line. Every imported piece still goes through the hair/clothing grid check by looking.

Sources: [MakeHuman asset packs](https://static.makehumancommunity.org/assets/assetpacks.html),
[Quaternius Universal Base Characters](https://quaternius.com/packs/universalbasecharacters.html),
[Stylized Hair Asset Library](https://superhivemarket.com/products/stylized-hair-asset-library--100-male--100-female--200-bundle),
[Human Generator Ultimate](https://superhivemarket.com/products/humgen3d),
[Blender Studio Human Base Meshes (CG Channel)](https://www.cgchannel.com/2023/06/download-blender-studios-free-human-base-meshes)
