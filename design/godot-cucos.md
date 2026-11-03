# The football lady, the coupon and the Cuco's bar (Godot mall, workstream CUCOS, Nov 3 2026)

**Asked for (Steven, Nov 3):** the first real story chain, 1995 only. A shopper in the purple shirt with
gold letters asks about last night's game; the right answers lead to a coupon for a free top-shelf
margarita at Cuco's. Cuco's gets a bar with a male bartender, a back bar (bottles, beer taps, no prepared
drinks), one or two seated patrons. The bartender sells beer $2, margarita $3, top-shelf margarita $10
through SHOPS's `mall.shop.open("cucos")`; holding the coupon gets the top-shelf margarita free plus, once,
a Cuco's Mardi Gras doubloon that stays in the inventory across years.

**Steven wrote every line**; they are used as written, in `data/story/cucos/*.dialogue`. Lines added here
are marked PLACEHOLDER (list below). Built on the dialogue engine and flags of `design/godot-dialogue.md`
and `design/godot-quests.md`, the wallet of `design/godot-economy.md`.

## Files
| File | What |
|---|---|
| `data/story/cucos/football_lady.dialogue` | Her tree, Steven's lines. |
| `data/story/cucos/bartender.dialogue` | The coupon at the bar (Steven's two lines, the PLACEHOLDER gift line). |
| `data/story/cucos/cucos.json` | The lady's skin, the bartender (an attendant entry), the patrons, the items that travel. |
| `data/story/shops.json` | The shop contract with SHOPS: the `cucos` entry. |
| `data/items/cucos_standin.json` | STAND-INS for FOOD's `cu_*` items (see "Items"). |
| `scripts/story/cucos.gd` | Made by `story.gd` as `Story/Cucos` in every wing and year: the lady, the bar, the travel. |
| `scripts/story/football_lady.gd` | Rides along with the Ch02 shopper; the interactable. |
| `scripts/story/bartender.gd` | An attendant (`attendant.gd`) whose action is the coupon or the shop. |
| `scripts/story/shop_stub.gd` | A STUB for `mall.shop.open(id)` until SHOPS lands. |
| `scripts/items/cucos/cu_*.tscn`, `tex/items/cu_*.png`, `tools/cucos/make_standins.py` | The stand-in models and icons. |
| `tools/qa/cucos_test.gd` | Headless checks (below). `tools/qa/cucos_shots.gd`, `tools/qa/cucos_webtest.py`: the evidence. |

Shared files touched, in small hunks marked `CUCOS`: `scripts/dialogue/story.gd` (makes `Cucos`;
`_act`), `scripts/dialogue/dialogue_state.gd` (`act()`, `can_afford()`, `buy()`), `scripts/npcs.gd`
(`_pick_skin` takes the `always` skins first), `scripts/npcs.json` (`"always": ["Ch02"]`),
`tools/stores/small/wave8.gd` (the beer taps).

## The lady
- **Who:** the crowd shopper wearing **skin Ch02**, the purple sweatshirt. Its words are painted at load
  (`scripts/npc_shirt.gd`): the repo ships **HOUMA** (`scripts/npc_shirt.json`), and the published
  `play/shirt_text.json` overrides it to **LSU** (gold #FDD023, Forza), so visitors see **LSU**. Steven
  remembered HOUMA: **which one, Steven?** (The owner's "Shirt words" button changes it without a build.)
- **Always somewhere:** the crowd is one-of-each (`npcs.json "unique"`), so before this she appeared only
  some of the time. `npcs.json "always": ["Ch02"]` makes the crowd pick her first whenever it adds someone, so
  she is in every 1995 wing whose pack has shoppers (wings 1 and 2), walking her normal shopper's day (stores,
  windows, the hall). In 2026 the crowd is three other people; she isn't there.
- **Talking:** `football_lady.gd` follows her shopper record (`npcs.gd` `shoppers`) and is the interactable
  at her feet: the usual **TALK** prompt within 1.6 m in front of you (`design/godot-interaction.md`). On
  TALK her shopper is held (state `"talk"`, which `npcs.gd` leaves alone), she stops, turns to you and
  idles; the talk camera fixes on her face (`dialogue_ui.gd`). At the end she stands 2–4 s and goes on.
  Not talkable while she's sitting in a salon chair (she isn't walking or browsing then).
- **"She looks confused"** (answer C) is the one-shot `thinking` gesture (`$> act("thinking")`): the rig has
  no "confused" clip. Steven: another clip?
- **No speaker name** shows over her lines: Steven gave none.

### The tree (flags in `mall.flags`, saved in `mall-flags-1`, one store for both years)
| Path | She says | Then |
|---|---|---|
| A "Sure did. Wow, what a win." | "Is that supposed to be some kind of a joke…" | `cu_lady_mad`: every later visit "I'm still mad about the game." |
| C "No, I don't watch football." | (thinking) "Don't watch sports? …" | `cu_lady_cold`: later visits alternate "Well, what are we supposed to talk about…" / "I don't want to talk to you." (`cu_lady_cold_n`) |
| B, then B or C | "I know, right? …" → "Well, have fun with that. Who dat?" | nothing set: the next visit starts over (a guess, below) |
| B, A, then A or B | … "Ain't that the truth? …" → "Well, have fun. Let's get that W. Who dat?" | nothing set: starts over |
| B, A, C (Cuco's) | … "Hey, well, you're in Cuco's, huh? …" | **`give cu_coupon`**, `cu_coupon_given`. Once only: the same answer later gets a PLACEHOLDER line and no coupon |

## The bar (Cuco's, s42, wing 1)
Cuco's already had the bar (`design/storefronts/cucos.md`): along the west wall at the back, the painted
back bar of bottles (`tex/w8/bar.png`: two shelves of bottles, no drinks), a dark counter with a teal top,
red stools. World metres: counter x 23.15–23.75, z −79.0 to −71.6, top at 1.10 m; stools at x 24.45.
- **Beer taps (new, geometry, needs the wing 1 rebake):** a chrome tower on the bartender's side of the
  counter at x 23.33, z −76.2, three handles (red, gold, green: the room's colours) over a drip tray
  (`wave8.gd`, hunk `CUCOS`). FOOD's kit did not exist on this branch; the taps are plain boxes and
  cylinders in vertex colour, ready to be swapped for FOOD's.
- **The bartender:** an attendant (`attendant.gd`, made by `cucos.gd`, not listed in `attendants.json` so
  `dialogue_walk.gd`'s PLACEHOLDER-shape checks stay as they are), name **PLACEHOLDER Cuco's bartender**,
  skin **Ch28** (a PLACEHOLDER pick: a male Mixamo skin free in wing 1; taken out of wing 1's crowd).
  Behind the counter (x 22.78–22.9, z −78.4 to −72.4, between the back bar and the counter), wanders a
  little, faces the player within 3 m. Talk spot: **24.85, −75.35**, between two stools.
- **The patrons (PLACEHOLDER, no dialogue):** Ch08 on the stool at z −77.6 with a beer, Ch37 at z −73.1
  with a regular margarita, sitting (`sit_idle_2`, `sit_f`), their drinks on the counter in front of them.
  Runtime nodes: not baked. No drink is made on screen.

### What the action does at the bar
| You | He |
|---|---|
| hold **the coupon** (in the hand: `cu_coupon` is a "hand" item, so the bag's Hold button works) | "Oh, wow, you have a top-shelf margarita coupon. …" → "Here you go." The coupon is used up (`cu_coupon_used`); **`cu_topshelf`** and, the first time only (`cu_doubloon_given`), **`cu_doubloon`**, with the PLACEHOLDER gift line. Two items, two "You received" cards. |
| anything else (the coupon in the bag included) | the shop: `mall.shop.open("cucos")` |

## The shop contract (with SHOPS)
`data/story/shops.json`:
```json
{"shops": [{"id": "cucos", "attendant": "cucos_bartender",
  "greeting": "Welcome to Cuco's. What can I get for you today?",
  "items": [{"item": "cu_beer", "price_cents": 200, "ready_line": "PLACEHOLDER …"},
            {"item": "cu_margarita", "price_cents": 300, "ready_line": "PLACEHOLDER …"},
            {"item": "cu_topshelf", "price_cents": 1000, "ready_line": "PLACEHOLDER …"}]}]}
```
`bartender.gd` calls **`mall.shop.open("cucos")`** when `mall.shop` exists with `open()`. ws/shops hadn't
landed (no such branch on Nov 3), so until it does **`scripts/story/shop_stub.gd`** runs the entry as a
conversation with the bartender: the greeting, "Beer, $2.00" / "Margarita, $3.00" / "Top-shelf margarita,
$10.00" / "Back". Choosing one: `mall.spend(price)` then the item into the bag and its ready line; short of
money, "You need $10.00. You have $5.00." (the economy's wording) and nothing changes. One purchase per
talk. SHOPS: delete the stub and its fallback branch in `bartender.gd` when `mall.shop` lands.

## Items (FOOD's ids; stand-ins until ws/food lands)
`data/items/cucos_standin.json`: `cu_coupon` (hand), `cu_beer`, `cu_margarita`, `cu_topshelf` (hand),
`cu_doubloon` (pocket, **year "both"**). Models are primitive meshes (`scripts/items/cucos/`), icons say
STAND-IN. When FOOD lands, delete that file, `scripts/items/cucos/` and `tex/items/cu_*.png`; FOOD's entries
must keep `cu_coupon` a **hand** item (or the coupon can't be held) and `cu_doubloon` year `"both"`.

### The doubloon across years
The bag is per year (`mall-state-1995` / `mall-state-2026`); flags are one store. `cucos.json "travels":
{"cu_doubloon": "cu_doubloon_given"}`: whenever a wing loads, in any year, `cucos.gd travel()` puts one
doubloon quietly in this year's bag if the flag is set and this year has none carried or lying on its
floor. So it is in 2026's bag from the first 2026 load after Cuco's. Nothing in 2026 uses it yet (Steven:
later).

## PLACEHOLDERs (lines and choices added here, for Steven)
1. The bartender's name: "PLACEHOLDER Cuco's bartender" (and the label "PLACEHOLDER Bartender" over his
   coupon lines).
2. His gift line with the doubloon: "PLACEHOLDER (he gives you a Cuco's Mardi Gras doubloon too, as a gift; …)".
3. What the lady says if you give the Cuco's answer again after she's handed over the coupon.
4. The three ready lines in `shops.json` ("PLACEHOLDER Here's your beer." …).
5. The patrons (who they are; skins Ch08, Ch37) and the bartender's skin (Ch28).
6. The stub's "Back" response and the "You need …" line (machinery wording, from the economy).

## Guesses (say if wrong)
- After the friendly endings (B-B, B-C, B-A-A, B-A-B) nothing is remembered: the next visit starts from
  "did you watch the game". Only A and C were given a "later visits" rule.
- The coupon's second-time answer (PLACEHOLDER 3) instead of giving another coupon.
- Drinks bought or given go to the bag (hand items); nothing happens when you hold one yet.

## Checks
- `godot --headless --path . --script res://tools/qa/cucos_test.gd` → CUCOS TEST OK.
- Native unbaked shots: `tools/qa/cucos_shots.gd` (see the report); web: `tools/qa/cucos_webtest.py`.
- Evidence: `production/qa/evidence/wsCUCOS-*`.

## Rebake
**Wing 1 (1995), day**: the taps are in the bar's geometry. Then `tools/capture_standin.sh 1` (and 2,
which shows wing 1 across the seam), export, publish. Nothing else is baked (the lady, the bartender, the
patrons and their drinks are runtime nodes). 2026 is untouched.
