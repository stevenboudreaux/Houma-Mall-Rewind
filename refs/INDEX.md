# Southland Mall reference pack (refs branch)

Everything a cloud session needs from Steven's MacBook Air, which it cannot see. Built Nov 1, 2026 from
`~/GodotProjects/2026 Mall/` (the Oct 23, 2026 site visit) and `~/GodotProjects/Southland Mall/` (1995-era pictures).
The originals (4K iPhone .MOV/.JPG, ~6.8 GB) stay on the Mac. If a frame you need is missing, say which video and
which seconds, and Steven's chat can cut it.

Get it (from the repo root, ~440 MB):

```bash
git fetch --depth=1 origin refs && git archive FETCH_HEAD refs | tar -x   # → ./refs/ (keep it out of commits; it's in .gitignore as /refs/)
```

To get only one folder: `git archive FETCH_HEAD refs/new/sears | tar -x`.

## Layout

| Folder | What | Size |
|---|---|---|
| `notes/BRIEF.md` | The brief the Oct 23 analysis worked from: 1995 map orientation, zone names (C1–C4, H1–H6), what 2018 established | |
| `notes/notes_A.md … notes_E.md` | **Read these first.** Per-video analysis: route, structure, storefronts, interiors, exterior, Steven's build directions, best frames, 2026 tenant table | |
| `notes/transcripts/<video>.txt` | Steven's narration, `[ Ns]` = seconds into the video. Misheard names: "cuccos" = Cucos, "lens interiors" = Lynn's Interiors, "a plane's his" = appliances, "Thumbdoll's"/"Karen McCorn" = KarmelKorn, "Conch House" = Coach House, "tea ties" = Tee Tai's | |
| `notes/build_2026.py` | Script that produced `eras_2026.json` | |
| `derived/frames/<video>/fNNN.jpg` | Every video at one frame per 2 s, 960 px. **fNNN ≈ (NNN−1)×2 s** | 1,059 frames |
| `derived/sheets/<video>_NN.jpg` | Contact sheets (30 labelled frames each). Fastest way to scan a video | 56 |
| `derived/signs/<store>_<video>_fNNN.jpg` | Sharp full-res crops of 2026 storefront signs | 69 |
| `derived/photos/IMG_44xx.jpg` | The still photos, 1600 px | 40 |
| `derived/full/{att,games,journeys}/` | Full-res frame runs for three storefronts (Demo 43–46) | |
| `derived/map_2026.md`, `derived/eras_2026.json` | 2026 tenant map in the 1995 rect format (id, 1995 name, 2026 name, rect, status, confidence, clips) | |
| `new/<topic>/<video>_tSSS_NNN.jpg` | **New Nov 1 cuts**, sharp, up to 1600 px. Frame time = SSS + (NNN−1)/fps; fps is 2 unless noted below | 1,143 |
| `era_1995/` | 1995-era pictures (photos, newspaper ads, the site plan). See the bottom of this file | 22 |

## new/ (cut Nov 1 for the cloud workstreams)

| Folder | Source | Shows |
|---|---|---|
| `directory/` | IMG_4408 50–72 s; IMG_4461 8–16 s | **2026 mall directory kiosk**, H2 north end by the Sears court: grey cabinet, arched top, silver Art-Deco fan finial, lit "Welcome!" / "STORES BY CATEGORY" / "MALL DIRECTORY" panel, colour site map. Best: IMG_4408 t050_017–027 (straight on), t050_011 (in the hall, scale), IMG_4461 t008_010 (second kiosk at C4 by the kiddie rides). Legible map: `derived/photos/IMG_4455.jpg` |
| `dillards_directory/` | IMG_4490 136–152 s | Dillard's in-store 3-level directory (black lacquer frame, gold header) — the L1/L2/L3 department plan |
| `dillards_L1/` | IMG_4490 110–166 s, IMG_4491 0–16 s | Dillard's level 1: entrance vestibule, men's, cosmetics, curved cove-lit soffits, mirror columns, travertine aisles, escalator, out through the mall opening into C3 |
| `dillards_exterior/` | IMG_4490 56–106 s, **1 fps** | Dillard's front: peach EIFS, cast-iron lace gallery on bronze columns, sunburst fanlights, entrance portal |
| `sears/` | IMG_4409–4413 complete | **Old Sears = Lynn's Interiors**: mall threshold, 9 m column grid, soffit beams, the "separator" partitions with corbel brackets, mint door, navy back corner, mattress gallery, side exit with roll shutter, exterior storefront, axis view back to Dillard's (IMG_4413 t000_033–037) |
| `woolworth_corner/` | IMG_4492 26–48 s | C2 Shoe Dept court corner: Zales, the Billiard Room (= 1995 Woolworth s13) with its black/gold front, Claire's, the sage/white checker court floor, H3 toward the main entrance |
| `radioshack_1999/` | `Southland Mall/christmas-shopping-at-radioshack-in-1999.mp4` (6:44, 640×360), **1 fps**, whole video | The RadioShack interior Demo 41 was built from: cash wrap with CRT terminals, glass showcase, phone wall, PowerZone battery wall, back-of-store shelving, R/C boxes. NB: frames show real logos and products — use for fixtures, colours and layout only (IP rule) |
| `monument_candidates/` | IMG_4489 80–94 s; IMG_4492 104–134 s; IMG_4486 130–160 s (1 fps) | Road edges where the monument signs would be: Bayou Gardens corner by the south entrance, the palm-lined West Park drive, the west lot. **No monument sign is close or legible in any of the footage** (checked every exterior contact sheet). See "Gaps" |

## Per video (Oct 23, 2026 visit; 1995 map terms; zones per notes/BRIEF.md)

| Video | Len | Notes | Where / what |
|---|---|---|---|
| IMG_4406 | 84 s | A | Exterior east side, main-entrance tower north to the east entrance: K&B back (Hypervelocity), Cucos side (The Red Seal), s43 EXIT |
| IMG_4407 | 40 s | A | Inside the east entrance, H1b east end: Red Seal mall front (s42 Cucos), SOUTHLAND MALL panel + deco fans |
| IMG_4408 | 84 s | A | H1b west → C1 Sears court (vault, lantern skylight, pink arch stripe), Lynn's portal, zig-zag Solarium-spot front, **directory kiosk**, H2 north end |
| IMG_4409–4413 | 6/2/24/42/72 s | A | **Inside the old Sears** (Lynn's): threshold, perimeter, appliances/computers zone, separator walls, side exit and exterior storefront |
| IMG_4414 | 38 s | A | H1a cinema wing west to the s41 exit: closed cinema front, skylight wells |
| IMG_4415 | 2 s | A | Accidental |
| IMG_4416 | 36 s | A | Exterior at the cinema-wing west exit, cinema box, bike rack |
| IMG_4426 | 14 s | A | Main entrance s39, inside and out |
| IMG_4437 | 4 s | B | C2 SE corner / H3 mouth (Frank's s33 / Orange Julius s34) |
| IMG_4438 | 38 s | B | C3 Dillard's court, H4 → C3 |
| IMG_4439 | 76 s | B | H5 concourse west from C3 to the restroom hall (Regis / Concepts / Lion's Share = maurices) |
| IMG_4440 | 62 s | B | H5 mid-concourse skylight node (Blockbuster / Chick-fil-A stretch; Wicked Wingz) |
| IMG_4441 | 12 s | B | H5 west third toward JCPenney |
| IMG_4442 | 18 s | B | H5 south side, vacant aqua-tile store (1995 s52b Pocket Change) |
| IMG_4443–4444 | 62/4 s | B | games, inc. arcade (s52 Blockbuster Music) and inside |
| IMG_4457–4459 | 8/14/32 s | B | C4 JCPenney court, H5 west end (Shoe Dept s51 = Impressive Prints) |
| IMG_4461 | 90 s | B | H6 south exit, C4 (**second directory kiosk**, Corn Dog 7), whole H5 south side eastbound, food-court wall, Treasure Island |
| IMG_4484 | 136 s | C | **H2 walked north** from Claire's/C2 to C1: Woolworth/Kay-Bee row (Billiard Room, Prime Time Fitness), **Sound Shop's surviving black curved fascia (now SOLA)**, K&B (Hypervelocity) |
| IMG_4485 | 70 s | C | H1a cinema wing west to the s41 exit; American Bank's walled arch; ad picture windows |
| IMG_4486 | 232 s | C | Exterior: s41 exit, cinema west wall, staff lot behind the H5 north row, water tank, JCPenney north wall and docks |
| IMG_4487 | 108 s | D | JCPenney north face, NW corner, back (west) lot |
| IMG_4488 | 52 s | D | JCPenney west face, tree-side entrance, wordmark wall |
| IMG_4489 | 166 s | D | JCPenney south face (red arcade) → south entrance pavilion (H6/s55) → wing wall → Dillard's west end; Bayou Gardens Blvd |
| IMG_4490 | 166 s | E | Wing service lane, Dillard's dock, **Dillard's exterior gallery and entrance, inside Dillard's L1**, the Dillard's directory |
| IMG_4491 | 16 s | E | Dillard's cosmetics out into C3 |
| IMG_4492 | 221 s | E | H4 → C2 (Rainbow, Aéropostale, **Billiard Room = Woolworth**, Zales, Claire's) → H3 → out the main entrance; palm drive; east facade south (T-Mobile, Shoe Dept exterior) to the Dillard's corner |
| IMG_4493 | 88 s | E | East facade north from the main entrance: Hypervelocity, dumpster room, The Red Seal side |

Photos: IMG_4417–4424 (A: cinema exit, H2 north/C1 fronts), IMG_4427–4436 (A: main entrance porch, H3, C2),
IMG_4445/4455/4456/4460/4464–4483 (B: games inc, **IMG_4455 = the 2026 directory map, legible**, Cinnamonster/KarmelKorn
corner, PINK, Victoria's Secret, H4 east side, Rainbow/Aéropostale).

## Per workstream: what to read

| Workstream | Read |
|---|---|
| **A — Mall directory** | `new/directory/`; `derived/photos/IMG_4455.jpg` (the 2026 map + full tenant list, also transcribed in notes_B "IMG_4455"); `derived/signs/directory_IMG_4408_f031.jpg`; notes_A IMG_4408 "Mall Directory kiosk"; notes_B §4 "Directory totems"; `derived/map_2026.md` + `eras_2026.json` (2026 stalls). The 1995 directory look: **no 1995 directory picture exists in this pack** (see Gaps). Mr. Silverman's kiosk: notes/BRIEF.md (2018 walkthrough: "Mr. Silverman island" jewelry kiosk with lit rings) |
| **B+C — Interaction, inventory, owner HUD** | Nothing needed |
| **D — 1995 store fixes, RadioShack** | `new/radioshack_1999/` (back-of-store, cash wrap, walls); `era_1995/stores/Sound_Shop.jpg` (a lit Sound Shop front, source/mall not recorded); notes_C IMG_4484 (Southland's surviving Sound Shop fascia, s19) + `derived/frames/IMG_4484` f040–f052 + `derived/signs/sola_IMG_4484_f055.jpg`; `new/woolworth_corner/` + `era_1995/stores/Woolworth.jpg` (a Woolworth lunch counter) + notes_E "The Billiard Room"; `era_1995/other/other_1.jpg` (Tee Tai's / Optical Outlet, 1990s); `era_1995/ads/ad_6.jpg` (Concepts ad, "display in front of Chick-fil-A"); `era_1995/ads/ad_7.jpg` (Scatterbar's) |
| **E — Sears skeleton, Dillard's L1** | `new/sears/`; notes_A summary "Old Sears interior" + IMG_4409–4413; `new/dillards_L1/`, `new/dillards_directory/`, `new/dillards_exterior/`; notes_E IMG_4490/4491 |
| **F — Outside, monument signs** | notes_C IMG_4486, notes_D (whole), notes_E IMG_4490/4492/4493; `new/monument_candidates/`; `era_1995/other/other_3.jpg` (1997 United Artists **Southland Cinema roadside marquee sign**, the only period road sign in the pack); `era_1995/layout_screenshot_2026-09-19.jpg` (Morguard site plan) |
| **G — 2026 sprint remainder** | Wicked Wingz: `derived/frames/IMG_4441` f003–f006, `IMG_4461` f028–f033, `derived/signs/wingz_IMG_4441_f006.jpg`. Cinnamonster: `derived/photos/IMG_4464–4468` (shot upside down: rotate 180°). Glass fronts: `derived/signs/*`, notes_B. Weak signs: `derived/signs/` |
| **H — Engine debt** | Nothing needed |

## era_1995/

| File | What |
|---|---|
| `stores/Sound_Shop.jpg` | Lit "SOUND SHOP" letters (yellow-orange) on a dark fascia, glass front behind a grille. Which mall is not recorded |
| `stores/Woolworth.jpg` | B/W, a Woolworth lunch counter with stools |
| `stores/Southland_Cinema.jpg` | Southland Cinema mall front: white brick, arched entry, lantern sconces, poster cases |
| `stores/Orange_Julius.jpg`, `Gumballs.jpg`, `county_seat.jpg`, `gadzooks_front.jpg`, `gadzooks_ad.jpg` | Store references already used in earlier demos |
| `other/other_1–5.jpg` | Steven's captioned pictures (captions in `other/CAPTIONS.txt`): Tee Tai's/Optical Outlet; cinema concession; **cinema roadside marquee**; cinema storefront inspiration; the old cinema hall today |
| `ads/ad_1–8.jpg` | Newspaper ads: Dippin' Dots ("across from Pocket Change"), TGMC OutReach, Radiofone pagers, Vision Plaza, Gryder's Shoes, Concepts (Eastpak), Scatterbar's Buffet, Saadi's |
| `layout_screenshot_2026-09-19.jpg` | Morguard site plan |

## Gaps (not in this pack; ask Steven in your session's final message rather than guessing)

- **Hammond Square 1993 commercial** (YouTube `WvaGN9lUpr0`, Sound Shop at 4.3–4.9 s, Radio Shack at 23.8–24.15 s). YouTube is blocked from cloud sessions and the video is not on the Mac. What is already known from it is written in `design/storefronts/sound-shop.md`. A session that needs the frames should say so; Steven's Mac chat can grab them with Claude in Chrome.
- **Monument signs:** not legible anywhere in the footage. Build the structure from the site plan + notes and leave the face as a labelled placeholder, or ask Steven for a photo.
- **The 1995 directory's look:** no picture. Use a period-plausible design and mark it as a guess in the design note.
- **Solarium "teal clothing store from the 2D game":** that is in the repo (`index.html` year maps), not here. Same for Lion's Share's gold lion statues.
