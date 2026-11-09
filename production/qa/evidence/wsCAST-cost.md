# Cast cost (CHAR-BUILD item 9, Nov 9 2026)

`tools/qa/cast_perf.gd`: N bodies holding the idle clip through NpcRig in a bare scene (one directional light),
240 frames after a 40-frame warm-up, uncapped. Godot 4.7.2, **Compatibility renderer (opengl3), the web build's
renderer path, on llvmpipe (software GL on this box's CPU) under xvfb**. Relative numbers only: compare rows,
not devices. Not run as a web export in headless Chromium (that would need a benchmark main scene in a full
export of the project); the renderer path is the same, the JavaScript/WASM overhead is not included.

## Per person (from the build records, `cast/<id>.json`)

| person | source | LOD0 tris | LOD1 tris | draw calls | morphs (face mesh verts) | textures | .glb |
|---|---|---|---|---|---|---|---|
| radioshack_1995 | Rocketbox Male_Adult_08 | 7,512 | 5,599 | 3 | 35 (1,677) | head 2048 RGB, body 1024 RGB, hair 1024 RGBA, 2 normals 1024 | 9.8 MB |
| cucos_owner_1995 | Male_Adult_07 | 7,588 | 5,600 | 3 | 35 (1,711) | same | 10.2 MB |
| gac_1995 | Female_Party_02 | 10,098 | 5,600 | 3 | 35 (1,925) | same | 13.3 MB |
| auntie_annes_2026 | Male_Adult_16 | 7,824 | 5,600 | **2** (no hair material) | 35 (1,704) | head 2048, body 1024, 2 normals | 8.8 MB |
| spencers_2026 | Business_Female_01 | 8,966 | 5,600 | 3 | 35 (1,836) | same as RadioShack | 11.4 MB |
| *Mixamo shopper Ch22* | `npc/skins` | 6,905 | — | 5 | 0 | 1 texture | — |

Texture memory per person on a phone (ETC2/ASTC 8 bpp RGBA, 4 bpp RGB, + mips): head ≈ 2.7 MB, body ≈ 0.7 MB,
hair ≈ 1.3 MB, normals ≈ 1.4 MB → **≈ 6 MB per cast member** (a Mixamo shopper ≈ 0.7–1.4 MB). Blend shapes:
35 × ≈ 1,800 face vertices ≈ 1.3 MB per person (the body mesh carries none).

## Frame cost (llvmpipe, mean / p95 ms; "none" = the empty scene)

| case | 1 body near | 10 bodies near | 1 body far (LOD1) | 10 bodies far (LOD1) |
|---|---|---|---|---|
| none | 7.7 | — | 8.8 | — |
| Mixamo Ch22 | 19.5 / 23.8 | 58.0 / 67.6 | 19.7 / 25.9 | 64.7 / 76.2 |
| radioshack_1995 | 23.7 / 30.6 | 64.1 / 74.8 | 17.8 / 21.7 | 67.8 / 80.2 |
| cucos_owner_1995 | 21.1 / 25.0 | 63.6 / 71.4 | 18.0 / 22.7 | 66.1 / 77.2 |
| gac_1995 | 24.1 / 27.4 | **83.8 / 93.8** | 21.9 / 26.7 | 78.8 / 91.4 |
| auntie_annes_2026 | 21.5 / 25.5 | 64.3 / 74.4 | 18.7 / 22.2 | 71.6 / 82.3 |
| spencers_2026 | 22.6 / 25.6 | 65.9 / 73.8 | 19.7 / 23.8 | 76.3 / 89.7 |

Reading it: one cast member costs about the same as one Mixamo shopper (+5–20 % near, ±10 % far): fewer draw
calls (3 vs 5), slightly more triangles near. Ten at once: +10 % (+45 % for gac_1995, whose big curly hair is
many alpha-tested cards = overdraw). The far rows barely improve on the near ones here because llvmpipe's cost
is dominated by skinning and full-screen work, not triangles; on a GPU the LOD1 switch matters more.
First-load build time is 0.25–1.7 s per person (texture import on first use); later bodies of the same person
≈ 30 ms.

## What to expect on an iPhone (not measured)

- **Draw calls and triangles:** at or below a Mixamo shopper; attendants are one or two people per wing, so the
  frame cost is small. The crowd stays Mixamo.
- **Memory is the real cost:** ≈ 6 MB of textures + ≈ 1.3 MB of blend shapes per cast member, against ≈ 1 MB for a
  shopper. Five people ≈ 35 MB if all are loaded; load only the wing's people (pack them per wing).
- **Alpha-tested hair** (GAC most of all) is the expensive pixel work on Apple's tile GPUs (discard defeats
  hidden-surface removal). If GAC's counter view drops frames on a phone: thin her LOD1 hair cards first.
- **Download:** the `.glb` files are 8.8–13.3 MB with PNG textures; the web export re-encodes textures, so the
  pack cost is closer to the texture memory above. Downsizing the 2048 head textures to 1024 for LOD1-only
  people would halve it (picture quality: Steven's call).
