# PHONE-MEMORY, stage 2: options for streaming on the iPhone (Tue Nov 17, 2026)

Branch `ws/phone-memory`. **Nothing here is decided: Steven chooses.** iPhone only (Steven has no iPad).
Stage 1 numbers: `wsPHONE-MEMORY-findings.md`. Shots are taken from real web exports (as shipped against the option's
build) in Chromium's software renderer at 1280 x 720, so they show what the phone draws from those packs.

## What is known on Steven's iPhone (Nov 17)
- **One 1990s mall wing runs at about 0.9 GB of video memory** on either pack (desktop pack 909 MB, 45 fps; phone
  pack 895 MB, 32 fps); 832 MB of it is textures; the wasm heap is 142 MB.
- **Two 1990s mall wings crash** on the phone pack (`?pack=mobile&stream=1`).
- Since the device fix (A, pushed), the iPhone gets the desktop pack with phone behaviour: one wing, a load at each
  border, as Demo 54.

## How the estimates are made, and how sure they are
- **Start:** the iPhone's own one-wing figure, 0.9 GB (measured: sure).
- **The second wing:** the test box measured +437 MB of video memory for wing 2 of the 1990s (Chromium, phone pack)
  and +419 MB of textures natively. The iPhone's one-wing textures matched the test box's to 0.3 % (832 vs 830 MB),
  so **two 1990s wings on the iPhone ≈ 1.34 GB** (estimate: fairly sure, ± 0.1 GB).
- **What an option saves:** byte arithmetic over the textures the two-wing scene really uses (533 textures, listed
  natively, each priced from its pack header): sure for the textures, ± 5 %. About 0.3 GB of the engine's own texture
  memory (shadow map, font caches, cubemaps, render targets) is not itemised and no option changes it.
- **Where the crash line is: not known.** Somewhere between 0.9 GB (runs) and about 1.34 GB (crashes), and it moves
  with what else the phone has open. So: **under 0.9 GB = expected to run** (as sure as the 0.9 GB figure is
  repeatable); **0.9 to 1.34 GB = unknown, only the phone can say**; above that = expected to crash.
- 2026 has no iPhone figure yet. Estimated from the test box (one mall wing 0.43 GB, two 0.80 GB): less sure.

## The texture groups (used by options 3 to 5)
Sorted by file path (`tools/qa/phone_options_shots.gd`, the same rules for the numbers and the shots):
- **Group 1, no lettering:** the Blender items' maps (`models/bl_*`: albedo, normal, ORM, 2048 each; one item is up
  to 50 MB), the cast's heads, bodies and normal maps, plain building materials (brick, block, tile, floor, wall,
  wood, metal …). 383 textures in the project.
- **Group 2, shop pictures:** stock, racks, bins, fixtures, counters. May carry small printed text. 531 textures.
- **Kept lossless in every option:** store signs (`tex/sg`), the directory, ads, posters, marquees, menus, lease
  cards, stand-ins, the item icons and UI, and anything named sign / logo / letter / title / text / banner. 319.
1990s, two mall wings: group 1 is 440 MB of video memory, group 2 289 MB, kept 158 MB, already compressed 219 MB.

## The options

| # | Option | 1990s one wing | 1990s two wings | 2026 one / two (estimated) | Download, 1990s wings 1 + 2 | Picture |
|---|---|---|---|---|---|---|
| 0 | As shipped, streaming on | 0.90 GB (runs) | **1.34 GB (crashes)** | 0.43 / 0.80 | 329 MB | as now |
| 1 | Which pack: desktop or phone | same | same | same | same | same; desktop pack 45 fps vs 32 |
| 2 | One copy of each streamed pack in the page | -0 video; page -95 MB | -0 video; page -95 MB | page -79 MB | same | none |
| 3a | Group 1 as ASTC 4x4 (phone pack) | 0.68 | 1.01 | 0.42 / 0.73 | +72 MB | slight (items, faces) |
| 3b | Group 1 as ETC2 (phone pack) or S3TC (desktop pack) | 0.65 | 0.96 | 0.42 / 0.72 | +18 MB | slight, a little more |
| 4a | Groups 1 + 2 as ASTC 4x4 | 0.59 | **0.79** | 0.41 / 0.65 | +121 MB | slight; small print in stock softer |
| 4b | Groups 1 + 2 as ETC2 / S3TC | 0.54 | **0.71** | 0.41 / 0.62 | **+99 MB (measured, was estimated +32)** | more: block edges on stock print |
| 5 | Group 1 at half size (no compression) | 0.68 | 1.01 | 0.42 / 0.73 | -28 MB | items and faces softer up close |
| 6 | The far wing's textures at half size | 0.90 | about 1.10 | 0.43 / 0.68 | +the far copies | the far wing softer until you cross |
| 7 | One wing in memory; the next only when very close | 0.90 | 1.34 at the border | 0.43 / 0.80 | same | as 0, plus a hold at the border |
| 8 | A load at each border (today since A) | 0.90 | never two | 0.43 / never two | one wing at a time | as Demo 54; a load screen at each border |

(GB = video memory on the iPhone. Download: the 1990s mall wings' packs plus items and common; the room wings
change little, as below. **The download estimates for 3a, 3b and 4a are low**: like 4b's (+32 estimated, +99
measured) they leave out the items pack, which roughly doubles when compressed. Read them as about +90 MB more each.)

### 1. Which pack a phone should get (no memory change)
- The iPhone offers both sets. **Desktop pack: 45 fps; phone pack: 32 fps**, one reading each, the same spot, the same
  memory (909 vs 895 MB). Why the phone pack is slower is not known: its lightmaps are ASTC HDR (desktop's BC6H) and
  its surfaces ETC2 (desktop's S3TC); either could be slower to sample on this GPU. One more reading each would say
  whether it repeats.
- **Today (since A) the iPhone takes the desktop pack.** Options 3 and 4 then need the desktop pack's textures
  compressed too (S3TC, the same memory as ETC2), which **changes computers' pictures** as well, or a third pack set
  for phones (desktop formats, compressed surfaces: +1 set of packs on R2, export about 1.5 x as long; computers
  byte-for-byte unchanged). Or phones go back to the phone pack and lose the 13 fps.
- Cost: none in memory or download. Decision: which pack, and if compression is chosen, in which pack.

### 2. One copy of each streamed pack (page memory, no picture change)
- `web/shell.html` keeps every streamed pack twice: the fetched buffer in `window.__mallPre` and the engine's copy
  in its file system. Drop the first once it is copied (and the joined chunks, already short-lived).
- Saves the pack's size in the page's memory for the rest of the visit: 95 MB for 1990s wing 2, 79 MB for 2026 wing
  2, 39 / 40 MB for Sears / Dillard's. Not video memory, so it does not change the table's GB, but the page process is
  what iOS kills ("A problem repeatedly occurred"), and the page holds the wasm heap and these buffers. Sure of the
  saving; how much it moves the crash line is not known.
- Risk: none seen (the cache keeps its own copy on disk). Small change.

### 3. Group 1 compressed (items, cast, plain materials)
- 1990s two wings 1.34 → **1.01 GB (ASTC 4x4)** or **0.96 GB (ETC2 / S3TC)**: still over the known-good 0.9. Not
  enough alone; with option 2 and the crash line unknown, a coin toss.
- Picture: the Blender items up close and the cast's faces (4x4-pixel blocks: ASTC keeps detail well; ETC2 / S3TC
  show faint blocking on smooth gradients and colour edges). No lettering in this group.

### 4. Groups 1 and 2 compressed (plus shop pictures)
- 1990s two wings → **0.79 GB (ASTC 4x4)** or **0.71 GB (ETC2 / S3TC)**: under the known-good 0.9. The first option
  that is expected to fit two 1990s wings (fairly sure: 0.1 to 0.2 GB of margin).
- Picture: as 3, plus shop stock and racks; small print on boxes and packaging goes softer (ASTC) or slightly
  blocky (ETC2 / S3TC). Signs and lettering stay lossless.
- Download, **4b measured** (the preview's export against build58 as shipped, one kind of pack): 1990s wings 1 + 2,
  items and common **329 → 428 MB (+99 MB)**; 2026 271 → 347 MB (+76); every pack of one kind 810 → 975 MB. Most of
  it is the items pack (84 → 176 MB): the Blender items' maps were small as WebP. My estimate (+32 MB) counted the
  mall wings and missed the items pack. 4a (ASTC) would be more again (estimated +121 MB on the mall wings alone,
  so a measured figure would also be higher). First load at 50 Mbit/s: 4b about +16 s. Less CPU decoding (no WebP
  decode for these textures).
- Needs a choice of pack (option 1). If the desktop pack, computers change too unless a third pack set is made.

### 5. Group 1 at half size (no compression)
- The same memory as 3a (a quarter of the pixels), 1.01 GB for two 1990s wings. Smaller download (-28 MB). The
  picture loses resolution evenly (items and faces softer up close) instead of block artefacts. Not enough alone.

### 6. Smaller textures for the far wing only (the brief's option 2)
- The second wing's groups 1 and 2 at half size while it is the far one: two 1990s wings about 1.10 GB. Then at
  every crossing the wing you enter must get its full textures back and the one you leave its small ones: a reload
  of hundreds of textures at each border (a stall on the phone), or a second set of small textures in every pack.
  Over 0.9, costly and fiddly. Not recommended; listed because the brief asked.

### 7. One wing, the next only when very close (the brief's option 3)
- `near_m` / `far_m` small (for example 12 / 20 m): wing 2 comes in only near the line and the far one goes soon
  after. At the line itself both are in, so the peak is still two wings: **1.34 GB for the 1990s, which crashes.**
  It helps only together with 4 (then the peak is 0.71 to 0.79). What the player sees: the stand-in picture of the
  other wing until it is in, then the real wing (the hold and the floor cue at the border if not ready in time).

### 8. A load at each border (the brief's option 4)
- What the iPhone has now (since A). 0.9 GB, known to run. A load screen at the seam and at the department stores.

### Possible combinations (for Steven to weigh; nothing decided)
- **4a or 4b + 2 + phone streaming as built (`near_m` 60, `far_m` 110):** two wings at 0.71 to 0.79 GB. Expected
  to fit; needs a try on the phone.
- **8 for the 1990s, streaming for 2026:** if the phone confirms 2026's two wings fit (estimated 0.80 GB), phones could
  stream in 2026 with no picture change and keep loads in the 1990s. Needs a per-year setting (small).
- **1 alone** (the pack question) matters for any of them.

## Shots (matched, both years, every variant from the same camera)
SHOTS

## What Steven can try on the phone
**Preview `BID_NEW`** (uploaded Nov 18; option **4b** built in: groups 1 + 2 as S3TC in the desktop pack and ETC2
in the phone pack; everything else as this branch, including the device fix). Base address:
`https://pub-848b5102ea0e4d78999797a799545451.r2.dev/builds/BID_NEW/index.html`. The as-shipped control is the Nov 17
preview `20261117-0522-6ba34fcc` (uncompressed; it still picks the behaviour by pack, so it is opened with
`pack=mobile`).

**What to do on every link:** open it on the iPhone and wait for the load screen to lift. From the start, walk to
**Dillard's**: across the border into wing 2 (the hall with the Dillard's court) and in through its entrance. Inside
Dillard's, open the menu, the **QA** tab, and take a screenshot (it shows the wings in, video memory and fps). If
Safari reloads the page or says "A problem repeatedly occurred", open the same link again, go to the menu's QA tab
and screenshot the **LAST VISIT** block instead (the last sample before the crash). Send the screenshot with the
link's number.

| # | What it shows | Link | What it answers |
|---|---|---|---|
| 1 | **4b, desktop pack, 1990s, streaming on** (what an iPhone gets, with streaming turned on) | [link 1](https://pub-848b5102ea0e4d78999797a799545451.r2.dev/builds/BID_NEW/index.html?qa=1&stream=1) | The main question: do two 1990s wings now fit (estimated 0.71 GB)? No load screen at the border if it does. |
| 2 | **4b, phone pack, 1990s, streaming on** | [link 2](https://pub-848b5102ea0e4d78999797a799545451.r2.dev/builds/BID_NEW/index.html?qa=1&stream=1&pack=mobile) | Option 1: is the phone pack still slower (45 vs 32 fps) with the same textures compressed? |
| 3 | **4b, desktop pack, 2026, streaming on** | [link 3](https://pub-848b5102ea0e4d78999797a799545451.r2.dev/builds/BID_NEW/index.html?qa=1&stream=1&year=2026) | 2026 with 4b (estimated 0.62 GB). In 2026 walk to the department store at the end of wing 2 the same way. |
| 4 | **2026 as shipped, streaming on** (the Nov 17 preview, phone pack) | [link 4](https://pub-848b5102ea0e4d78999797a799545451.r2.dev/builds/20261117-0522-6ba34fcc/index.html?qa=1&pack=mobile&stream=1&year=2026) | Does 2026 already fit with no picture change (estimated 0.80 GB)? If yes, 2026 could stream on phones as it is. |
| 5 | **4b, as phones get it today** (streaming off: a load screen at the border, one wing at a time) | [link 5](https://pub-848b5102ea0e4d78999797a799545451.r2.dev/builds/BID_NEW/index.html?qa=1) | One wing's memory and fps with 4b against the 0.9 GB and 45 fps measured on Nov 17; and how 4b looks on the phone. |

Order: 1 first (it decides most), then 5, 2, 3, 4. A crash on 1 is still an answer (LAST VISIT says how far it got).
The ASTC variant (4a) is not built: only if 4b's picture is too rough on the phone.

## Not done
- No option is built into the game. The preview's compressed packs come from a temporary import change in a copy of
  the project (`.scratch/doc/vram_switch.py`), not committed; the branch's import settings are unchanged.
- The run-time texture swap (`tools/qa/phone_options_shots.gd`) was dropped for the shots (the director's call, Nov
  18): its faults were in the method (the game clock ran between variants; swapped characters lost their lighting).
  The shots come from the two real exports instead (`tools/qa/export_shots_webtest.py`).
- No rebake for any option: none touches the lightmaps or the scenes. The stand-ins are not stale.
