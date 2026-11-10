# Exterior department-store signs: research (Workstream EXT-SIGNS, Nov 9 2026)

Branch `ws/ext-signs`. Brief: Steven, Nov 9 2026, after the Nov 9 stills and the screen recording
`Screen_Recording_11.38.54`. "Sears" was flat blue text painted on the wall. Dillard's was a flat decal that
shimmered as the camera moved; the letters sat flush on the fascia. K&B was a flat purple oval on a white band.
He wants "realistic 3D signage that was actually there", researched.

Build: `tools/exterior/signs.gd` (placement and game materials), `tools/blender/assets_src/bl_exs_*.py` +
`_exsign.py` (the models, built through the Blender pipeline), `models/exterior/signs/`. The construction follows the
Cucos neon (`tools/stores/signs/cucos_sign.gd`): real geometry standing off the wall, sheet-metal returns, a trim cap,
a face with its own material, and the light in its own emissive channel. `design/godot-exterior.md` has an
"EXT-SIGNS" section with what was built.

**Limits of this research.** The cloud session can run web searches but cannot open most pages (Wikipedia, the
retail blogs and photo archives are outside its network). So everything below rests on search-result
summaries, the Oct 23 2026 footage (`refs/`) and what the project already researched. No period photograph of
Southland's own exterior signs was found. **Steven's Nov 9 stills and the recording are not in the refs pack**:
the "before" shots recreate his viewpoints from his descriptions.

## Sears (1995), the old Sears box (Lynn's Interiors today)

| Question | Finding | Source | Confidence |
|---|---|---|---|
| Wordmark in 1995 | The 1984 identity ("Store of the Future") replaced the 1963 boxed logo. Store signs changed over as stores were remodelled, not all at once. The name was set in capitals, black until 1994 and **blue from 1994**. Lower case came only with the 2004 logo ("no longer in all capital letters") | UPI, Jun 29 1984; logos-world (Sears logo history); Fox News on the 2004 logo | medium-high (the colour change and the capitals agree across sources) |
| How a 1990s mall Sears carried it | Large individual letters on the anchor box, internally lit channel letters on a raceway or as a cabinet. No photo of Southland's was found | general (period mall photos are named in the search results, e.g. the Gandy collection's Sears at Singing River Mall, MS, c.1980, but could not be opened) | low-medium |
| Where | East face over the customer entrance (s1e), where Lynn's sign hangs today (4406 f031-035), plus the west face (dock side) and the north face over s1n. The last two existed as flat labels already; the north one is a GUESS (not filmed) | refs; `design/godot-exterior.md` | east high, others medium |
| Size | Cap 1.6 m centred at 6.6 m on the 9 m white wall (the 2.1 m doors and the 3.65 m canopy for scale) | frames | medium |

**Letterform:** Archivo Black (OFL, `tools/exterior/signs_src/`), a heavy grotesque near the 1990s Sears capitals.
It is not traced from the trademark.

## Dillard's (both years), the D.H. Holmes building

| Question | Finding | Source | Confidence |
|---|---|---|---|
| Era | Dillard's bought D.H. Holmes in 1989. The Houma store is one of the few Dillard's did not convert to the plain Dillard's style: "looks like a DH Holmes on the outside" (the gallery skin as filmed) | southernretail.blogspot (Southland Mall, Jan 2012) and a reader comment there; Wikipedia (D. H. Holmes) via search | medium-high |
| The letters | Black serif "Dillard's" with a curly apostrophe. Deep cans with a thin bronze/brown edge stand off the scored peach EIFS between the cornices; the gap and its shadow show in **IMG_4490 f013** | refs IMG_4490 f002-f016; notes_E | high (2026); the 1995 letters are assumed the same (the skin is unchanged since 1989; a GUESS) |
| Portal | "White stucco with a recessed sign band carrying black serif cut-out 'Dillard's' letters, pin-mounted and slightly faded": thin plates, not cans | refs IMG_4490 f045-f048; notes_E | high |
| Wordmark history | Serif since the mid-1970s, "the 1977-2005 logo kept those letterforms" | logos-world (Dillard's) | low-medium |
| Lit? | Nothing in the daylight frames shows light. Dillard's often used halo-lit (reverse-channel) letters, but nothing confirms it here | — | unknown |
| Size | Wall: the D's cap is ~55 % of the cornice band (9.8-13.4 m), so **2.0 m**, about 9.6 m long. Portal: **0.8 m** cap against the 2.4 m door frames (f046) | frames | medium |

**Letterform:** Libre Caslon Text at weight 600 (OFL, instanced to a static file), a close old-style serif. It is
not a trace of the trademark.

**The shimmer** in Steven's recording came from the old sign: a `Label3D` (an alpha-blended text quad) 8 cm in front of
the wall. It sorted and mip-mapped against the wall as the camera moved. Real geometry 5 cm off the wall on studs
replaces it. Nothing coplanar remains: the contact shadow sits 6 mm off the wall and draws before the wall's
transparent neighbours (`render_priority -1`).

## K&B Drugs (1995 only)

| Question | Finding | Source | Confidence |
|---|---|---|---|
| Logo | A purple oval, gold rim, a thin red line inside it, white "K&B". The project already has this from Steven's photo of a **lit** K&B sign and the 1990s Houma newspaper ad (1.40 : 1) | `tools/stores/signs/make_kb_oval.py`, `design/storefronts/kb.md` | high |
| Colour | "K&B purple" on every sign, register and uniform (since 1911) | Wikipedia (K&B); St Tammany Parish Library "K&B Purple"; dirtycoast.com | high |
| End | Sold to Rite Aid in 1997. The big purple signs came down (a crew took down the Canal Blvd sign), so there is none in 2026. Southland's K&B became a Rite Aid; the bay is Hypervelocity today | myneworleans.com "From K&B, Rite Aid and Onward"; Gambit (Blake Pontchartrain); southernretail blog | high |
| Mounting and lighting | Not documented. Steven's photo shows it lit; a lit oval cabinet is the usual form | — | low (GUESS) |
| 2026 | Hypervelocity's cream channel letters on the same band, left alone (`exterior_2026.gd`) | refs IMG_4493 f008-f023 | high |

## Sears Hardware (1995) / Unitech (2026), the box by Armour Dr

| Question | Finding | Source | Confidence |
|---|---|---|---|
| Sears Hardware | "A Sears Hardware store behind the building, across the parking lot" (2012). Steven's plan: "Old Sears Hardware" = the Unitech box | southernretail blog (Southland, Jan 2012); `design/exterior/site-plan-annotated-2026-11-08.png` | medium (that it existed); **the sign is unknown** |
| A separate "Sears TBA" | A Morguard / LoopNet flyer offers a freestanding "former Sears TBA" (tire, battery, accessories) building at Southland, with Unitech as a neighbour on its site plan. So the auto centre may be a different building | loopnet flyer (search summary) | medium; Steven to confirm which box was which |
| Unitech in 2026 | Unitech Training Academy, 6007 West Park Ave, in Houma since 2006. The site plan writes "UNITECH" on the box. **No frame shows its sign** (IMG_4486 f010, f072: the box is far back), and its logo could not be looked up from the cloud | unitechta.edu (search); plan | name high, **wordmark unknown** |
| Steven, Nov 8 | "Unsigned in both years"; what it read in the 1990s was left to a historian pass | `design/godot-exterior.md` (EXT-LAYOUT §6) | — |

## Options (`production/qa/evidence/wsEXTS-options.jpg`) and picks

Per sign, two treatments mocked in Godot. **Default** (if Steven has not answered): the better-sourced one. The
picks are recorded in `design/godot-exterior.md` "EXT-SIGNS".

| Sign | A (default) | B | Cost A / B |
|---|---|---|---|
| Sears | Blue-faced lit channel letters (blue returns, blue trim cap) on a white raceway | White letters on a lit blue cabinet | 2.6k / 0.8k tris, 1024 atlas each; both emissive at night |
| Dillard's (wall) | Black cans on studs, bronze edge, unlit (as filmed) | The same, halo-lit at night (reverse channel) | 5.5k / 5.8k tris, 1024 atlas; B adds a night-only additive halo |
| Dillard's (portal) | Cut-out plates on studs (as filmed) | — | 2.9k tris, 512 atlas |
| K&B | Lit oval cabinet: purple face, red line, white push-through K&B, gold retainer | Unlit purple panel with lit white K&B channel letters on studs | 1.4k / 1.9k tris, 512 atlas; both emissive |
| Sears Hardware (1995) | SEARS HARDWARE in the Sears letters on a raceway | SEARS over HARDWARE on a lit white cabinet | 4.4k / 1.4k tris, 1024 atlas; GUESS either way |
| Unitech (2026) | Leave it unsigned (Steven, Nov 8; the wordmark is unconfirmed) | Plain white UNITECH capitals, a GUESS | 0 / 1.1k tris |

## Sources

- UPI Archives, "Sears, Roebuck and Company is retiring its 21-year-old logo", Jun 29 1984: https://www.upi.com/Archives/1984/06/29/Sears-Roebuck-and-Company-is-retiring-its-21-year-old-logo/1271457329600/
- Sears logo history: https://logos-world.net/sears-logo/ ; Fox News on the 2004 logo: https://www.foxnews.com/story/sears-new-logo-fresher-friendlier
- Dillard's logo history: https://logos-world.net/dillards-logo/ ; D. H. Holmes: https://en.wikipedia.org/wiki/D._H._Holmes
- Southland Mall, Houma (the Holmes skin, Sears Hardware, the Rite Aid that was K&B): https://southernretail.blogspot.com/2012/01/southland-mall-houma-la.html
- K&B: https://en.wikipedia.org/wiki/K%26B ; https://www.sttammanylibrary.org/blogs/post/kb-purple/ ;
  https://www.myneworleans.com/from-kb-rite-aid-and-onward/ ;
  https://www.theadvocate.com/gambit/new_orleans/news/blake_pontchartrain/blake-pontchartrain-where-was-the-first-k-b-drugstore-how-the-purple-logo-spread-across/article_d8f11dde-a74c-11e9-9d2f-73ae2c9dc695.html ;
  https://dirtycoast.com/blogs/the-dirt2/kb-drugstore-purple-paradise-new-orleans-never-got-over
- Former Sears TBA flyer (Southland): https://images2.loopnet.com/d2/yTVTTrOPb5MmarcYAol5g8IlFBF6K3OX72FFde7XGi0/document.pdf
- Unitech Training Academy, Houma: https://unitechta.edu/location/houma/ ; https://unitechta.edu/blog/unitech-training-academys-houma-campus-celebrates-20-years-of-workforce-training-with-community-open-house/
- Southland Mall (Sears 1966/1969; closed 2016): https://en.wikipedia.org/wiki/Southland_Mall_(Houma,_Louisiana)
- Footage: `refs/derived/frames/IMG_4490` (Dillard's), `IMG_4406` f031-042 (the Sears east face), `IMG_4493` f011
  (the K&B bay), `IMG_4486` f010 / f072 (the Unitech box). The plan: `design/exterior/site-plan-annotated-2026-11-08.png`.
