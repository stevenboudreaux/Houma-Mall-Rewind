# Characters: options sheet (CHAR-RESEARCH, Nov 8 2026)

One page for deciding. The evidence and detail are in `design/godot-characters-research.md`. Numbers marked ≈ are
estimates; "today" numbers are measured from the repo's files. Nothing was measured on an iPhone.

| | **A. Mixamo bodies + new heads** | **B. MakeHuman hm08 cast (recommended)** | **C. CC0 stylised pack (UBC / Kenney)** | **D. VRoid / VRM** |
|---|---|---|---|---|
| What | the 19 Mixamo people, heads, hair and clothes reworked in Blender, 8–12 fixed | CC0 base mesh + targets, a fixed cast built by script, one `.glb` each | Quaternius UBC (today) or Kenney, adapted | VRoid Studio characters → VRM 1.0 → godot-vrm addon |
| Licence | Mixamo terms (in-game OK, sources not redistributed) | CC0 data (GPL code not used); MPFB viseme packs: check | CC0 | tool free; each model's VRM licence; addon MIT |
| Cost | free | free | free (UBC Source: Patreon) | free |
| Tris per person (iPhone) | 6–10k today + new head ≈ 3–5k | ≈ 12–15k LOD0, ≈ 5k crowd LOD | today 22–26k (8–12 draw calls); merged ≈ 20k | ≈ 15–25k after reduction |
| Draw calls | 2–3 | 2–3 | 2–3 if merged | 4–8 (MToon) |
| Clothes / hair | baked; outfits = remodel the body | baked per person; short hair painted + shell, long hair = cards (unproven) | 6 free hairstyles; swappable or baked | baked; good hair cards |
| Face rig for TALK | **none** | **34 CC0 expression units** (blink, smile, mouth open, brows …) + eye / jaw joints | **none** (rigid eyes / brows) | **best**: VRM expressions + visemes + eye bones |
| NPC + player share | yes (same rig as the crowd) | yes: one loader, one file per person | yes | yes, through a bone-name map |
| Claude builds it in the cloud | partly (19 different topologies, neck seams) | **yes, fully** (`bpy`; this spike's render) | yes | **no**: VRoid is a GUI, Steven makes each |
| Risk of the old bugs | low (fixed files) | low with the rules (one file, id, key, loader; no fallback) | low only without the editor | low |
| Look for a 1990s Houma mall | stock photo faces that can't talk | realistic, any age and ethnicity, stylised by paint | the set judged "not compelling" | anime: wrong style |
| Verdict | cheap, but fails TALK | **fits** | rejected look | wrong style, hand-made |

**First five on B:** RadioShack → the Cuco's owner (TALK) → Great American Cookie → Auntie Anne's → Spencer's.
Steven gives one line each.

**Delete:** the editor, both avatar systems, the presets, `models/ubc/` (54 MB), the shape sliders.
**Keep:** `npc_rig.gd`, `npc_body.gd`, `npc/anims.res`, the Mixamo crowd, `npc_warmup.gd`, `avatar.gd`'s camera and gaits.
Shirt words: Steven's call.

**Proof:** `production/qa/evidence/wsCHAR-radioshack-before-after.jpg`.
