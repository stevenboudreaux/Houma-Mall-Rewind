# Solarium: front and store (1995 map, store n8)

**Nov 1, 2026: rebuilt as a clothing store (workstream D).** Steven (Nov 1): "NOT a tanning salon. It is the teal clothing store from the 2D game", and, asked whether "a Cleo" meant the chain: "solarium is just a clothing shop."

**Sources.**
- **The 2D game (index.html, year maps, store n8 "SOLARIUM").** Sign band `#1f6f78` (teal), letters `#f6e7c0` (cream), merchandise colours cream, teal and white. The data names no chain and has no sign text beyond the store name (the same record is used for n62).
- **Steven (Nov 1): "just a clothing shop".** Not a Cleo store: a generic teal 1990s clothing shop under its own name, Solarium, with no chain branding.
- **Superseded:** the Oct 7 build from the facade record (level 1, memory): a pale stone fascia, aqua neon, a tanning-salon lobby with two tanning rooms. Steven says that record is wrong for this store.

**Accuracy level:** 1 (colours from the 2D game; everything else guessed).

**Frame.** A 6 m front facing east at x = -10 (z -86 to -80), beside Rave, built 8 m deep (of the 26 m stall). Map tiles x 140–142, y 57–59.

## Front
- Teal fascia (`w9_sol_teal`, #1f6f78) with "solarium" in lit cream channel letters (the Oct 7 outlines, Poppins Medium, `sol_letters.json`; lower case kept) between two fine cream rules.
- Teal piers; glass in brushed-metal frames on a low kick, the door in the middle.
- Two forms in the windows: one in a teal top over a cream skirt, one in cream over teal.

## Inside (walkable)
- Teal carpet, warm white walls, lay-in ceiling.
- White slatwall face-out walls down both sides (apparel kit), a table of folded knits by the door, a round rack and a four-way down the middle.
- The cash wrap at the back right with a teal front; two fitting rooms at the back left; the stockroom door behind.

**Guessed:** all of the layout and fixtures, the lower-case name on the fascia (the 2D game only gives the name), the letter style, the depth. **Period check (1995):** slatwall, round racks, four-ways, teal-and-cream palette are all period; nothing later than 1995.

## Files
`tools/stores/small/wave9.gd` (`solarium()`, materials `w9_sol_*`). Hooks unchanged in `tools/build_mall.gd` and `tools/open_interiors.py`. Evidence: `production/qa/evidence/wsD-solarium-preview-unbaked.jpg`, `wsD-solarium-ingame-unbaked.jpg`.

## Nov 2, 2026: answered (Steven)
Solarium is **a women's clothing store, not a chain**, and not "Cleo" (he never meant a chain). The Cleo question is closed; nothing to ask. No geometry change: the Nov 1 build (a generic teal clothing shop under its own name) already fits; the stock reads as women's clothing.
