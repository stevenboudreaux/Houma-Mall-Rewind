# Southland Mall (Houma, LA) — 2026 site-visit media analysis brief

You are analyzing frames and narration from a visit to the real Southland Mall on Oct 23, 2026, filmed by Steven. The mall is being recreated in a Godot game ("Houma Mall Rewind") as it was in 1995. Your notes feed three goals:
1. Correct/enrich the 1995 structural model (ceilings, columns, floors, hall ends, courts, storefront framing, anchor fronts).
2. A 2026 store map in the same rect format as the 1995 map (same building, different tenants) so the game can toggle years.
3. A time-agnostic exterior: facades, entrances, canopies, signage pylons, parking lot layout, light poles, landscaping.

## Mall orientation (1995 map, 201×201 tiles, 2 m per tile, y grows southward)
Anchors: **SEARS** north end (x128–163, y33–52, faces S). **DILLARD'S** south end (x129–163, y140–159, faces N). **JCPENNEY** west end (x47–71, y116–137, faces E). **MAIN ENTRANCE** east side (x166–170, y97–103, opens W into the mall).
Zones (Godot names): C1 Sears court (top of the east hall); H1a/H1b Sears hall running west–east along the Sears front (Cinema, Cucos, American Bank, Solarium, Rave, Lane Bryant on it; the cinema wing is the WEST end of this hall, Cucos was x159–170 y57–73 at the EAST end facing N); H2 east hall running south from the Sears court past Sound Shop / Kay-Bee / Woolworth (west side) and Duncan Sports / Footquarters / K&B (east side) to C2 the Shoe Dept court (x~139–149, y~105–113); H3 the main-entrance hall from C2 east to the entrance; H4 east hall continuing south from C2 past Lerner / Coach House / Radio Shack / Payless to C3 Dillard's court; H5 the concourse running WEST from C2 along the south side of the Shoe Dept / Limited / Champs / B.Dalton row and the Blockbuster Music / Pocket Change / Chick-fil-A / County Seat row to the JCPenney court C4 (x~71–79, y~130–144); H6 south exit near JCPenney (x75–79 y144).

## 1995 tenants with rects (id name x y w h face)
See `stores_1995.json`. The 2026 map must reuse these same rects where the space is unchanged; where a space was merged, split, or re-cut, say so explicitly with your best-estimate new rect in tiles.

## What the 2018 walkthrough already established (don't re-prove, do confirm or contradict)
Ribbed white barrel vaults over the main halls with a lit checkerboard band; lower flat cream ceilings with round downlights over the store lanes; half-round arched hall ends. Shoe Dept court: tan plaster segmental vault, clerestory strip, square skylight, brass lantern pendants, round columns. Sears court: skylit clerestory, white arch beam with a pink stripe. Dillard's court: higher flat ceiling, warm cove light, skylight well. Floors: two-tone diagonal checker center, beige plank-laid store lanes, charcoal borders. Benches in facing pairs with round planters, cream tapered trash cans, two jewelry kiosks (gold L by Great American Cookie; Mr. Silverman island) with lit rings. K&B's wall was pink with plum stripes.
Demo 41 changed the Sears halls (Cucos→cinema) to a flat cream drop ceiling at 4.6 m — the 2026 footage should settle whether that's right and whether the Sears court ceiling also drops.

## How to work
- For each video: read its transcript (`transcripts/<id>.txt`, each line `[  Ns]` = seconds into the video) and then view frames in `frames/<id>/fNNN.jpg` (frame fNNN ≈ (NNN−1)×2 s). View every frame at least once — don't sample a few and extrapolate — but spend your words on what changes.
- For photos: view every photo in `photos/`.
- Steven's narration is the authority on *where* he is and what things used to be; the frames are the authority on what is physically there. When narration and frame disagree, say so.
- Transcript names may be misheard ("cuccos" = Cucos, etc.). Fix obvious ones.

## Output format (write to the path you are given, markdown)
For each video (in order), then each photo group:
### <file> (<duration>) — <where in the mall, in 1995 map terms + zone id>
- **Route:** one line on the camera path.
- **Structure:** ceilings (type, approximate height relative to storefront openings, lighting fixtures), columns/pilasters (shape, finish, base bands), floors (pattern, colors, borders, condition), hall ends, skylights, bulkheads, anything the 1995 model should copy. Be specific about materials and colors.
- **Storefronts / tenants:** every store visible: current name (or VACANT / unreadable), what the sign looks like (letter style, color, lit/unlit), entry type (open front, glass doors, roll grille), facade materials, and what Steven says it used to be. Note any 1995 tenant whose space has clearly been re-cut.
- **Interiors:** if the camera enters a store (especially the old Sears), describe layout, ceiling, floor, fixtures, columns, escalators/stairs, back-of-house openings, dimensions you can estimate.
- **Exterior / parking** (if applicable): facade materials, entrance canopies, doors, signage, pylon signs, lot layout (rows, islands, light pole style, curbs), landscaping, loading docks, anchor exteriors.
- **Steven's build directions:** anything he says he wants added/changed in the game, verbatim-ish with the time.
- **Best frames:** 3–6 frame numbers worth keeping as reference textures/photos, with what each shows.
- **Confidence / uncertainty:** what you could not resolve.

End with a **2026 tenant list** section for your batch: `1995 id | 1995 name | 2026 tenant | sign description | rect status (same / re-cut: new rect) | confidence`.
