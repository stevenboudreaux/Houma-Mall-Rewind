# Redemption prizes by ticket tier, 1995 and 2026 (research note)

**Purpose:** a list of prize **options** for the 1995 Pocket Change counter and the 2026 games, inc.
counter, by ticket tier, with period fit, sharing, and how each would be built. Steven chooses; nothing
here is a decision. Layouts are in `design/research/redemption-counters.md`.

**Researched:** Nov 3, 2026.

**Read this first: nothing here is verified against a page.** Every page fetch was refused by this
session's network policy (`en.wikipedia.org`, `replaymag.com`, `elibrary.arcade-museum.com`,
`bowlingindustry.com`, `shop.unistechnology.com`). Only web search worked. Each fact is one of:

- **lead**: what a search engine's summary attributes to the cited URL. I did not open the page.
- **guess**: no source found; inference or proposal.

**IP rule.** Real product names in this file (Tamagotchi, Squishmallows, Pop It, NeeDoh, Koosh,
Slinky, Super Soaker, POG, Tootsie, Ring Pop, Push Pop, Nintendo Switch, PlayStation…) are
**references only**. Every build uses the generic description in the "Generic build" column: no real
name, cover art, character or third-party logo.

## 1. Ticket value: rules of thumb

| Rule | Value | Era | Source |
|---|---|---|---|
| Games set to pay about 6-8 tickets per coin; prizes priced at a cent per ticket | ~1 ¢/ticket | 1996 | lead: https://elibrary.arcade-museum.com/Play-Meter/1996-July/98 |
| "Broad price spectrum, starting with slum merchandise that costs two to five cents apiece"; top prizes 2,000+ tickets at a one-cent ticket | 1 ¢/ticket; top ≈ $20+ cost | 1991 | lead: https://elibrary.arcade-museum.com/Play-Meter/1991-March/72 , https://elibrary.arcade-museum.com/Play-Meter/1991-June/55 |
| Ticket value is set only by the prize markup; standard markup 2× → a $1.00 item = 200 tickets | ~0.5 ¢/ticket | 2016-2022 | lead: https://www.replaymag.com/gameroom-guru-july-2016/?amp=1 , https://replaymag.com/?p=19879 |
| Most value a player gets is ~1 ¢/ticket; as little as 0.2 ¢ on small items | 0.2-1 ¢ | 2020s | lead: https://loyaltyrewardco.com/?p=10498 |
| Dave & Buster's: unofficial ~$3-4 per 1,000 tickets; consoles and Apple products priced off that ratio; PS5 ~120-150k, Switch ~120k tickets | 0.3-0.4 ¢ | 2020s | lead, **low-quality pages**: https://eathealthy365.com/the-ultimate-guide-to-dave-and-busters-prizes/ , https://siegfriedt-survey.umb.edu/pti/how-much-are-dave-and-buster-tickets |
| Chuck E. Cheese: 50,000 e-tickets buys jumbo plush, board and arcade games, playsets | | 2024 | lead: https://amusementtoday.com/2024/02/chuck-e-cheese-to-give-away-50-million-e-tickets |
| Candy and small toys a few tickets; skateboards, low-end electronics several thousand | | general | lead: https://en.wikipedia.org/wiki/Redemption_game |
| Four cost bands match four player types (impulse, trader, saver, super saver); dollar value redeemed roughly equal across them | | 2022 | lead: https://replaymag.com/?p=19879 |
| One law caps ticket value at 5 ¢ (Montana) | | 1999 | lead: https://mca.legmt.gov/bills/1999/mca/23/6/23-6-102.htm |

**Working rule (proposal):** 1995 tickets ≈ 1 ¢ of *prize cost* each (ticket price ≈ wholesale cost ×
100); 2026 tickets ≈ 0.3-0.5 ¢ (ticket price ≈ wholesale cost × 200-300). So the same $1 toy is about
100 tickets in 1995 and 200-300 in 2026, and 2026 top prizes run to 50,000-150,000. Wholesale costs
below are **guesses**.

**Tiers used below:** T1 1-25 · T2 25-100 · T3 100-500 · T4 500-2,000 · T5 2,000-10,000 · T6 10,000+.

## 2. Already in our catalogue (`scripts/prizes.json`, `scripts/redemption.json`)

| Item | Tickets | Fit for 1995 | Note |
|---|---|---|---|
| Chocolate chews | 5 | yes | |
| Chinese finger trap (Blender `bl_pc_fingertrap`) | 15 | yes | shared option for 2026 |
| Jelly finger trap | 20 | plausible (**guess**, no date found) | |
| Candy necklace | 20 | yes (**guess**, long-standing candy) | |
| Candy cigarettes ("CANDY STICKS") | 25 | yes (**guess**) | not a 2026 item (**guess**) |
| Slap bracelet | 75 | yes, past its 1990 peak | craze "fall of 1990": lead https://www.mentalfloss.com/article/620529/slap-bracelet-phenomenon-1990 |
| Pog pack ("MILK CAPS") | 100 | yes, at peak | peak 1994-95, school bans Jan 1995: leads https://www.tampabay.com/archive/1995/01/23/no-pogs-allowed/ , https://csmonitor.com/1994/1221/21014.html , https://www.deseret.com/1994/9/5/19129100/kids-and-adults-flip-over-milk-cap-game/ |
| Rainbow coil spring | 150 | yes (**guess**) | |
| Fuzzy dice / giant fuzzy dice | 300 / 600 | yes (**guess**) | |
| Boom box (Blender) | 500 or 5,000 | yes | at ~1 ¢/ticket a $30-50 boom box is 3,000-5,000 (**guess** cost) |
| Plush bear / bunny / dog (Blender) | 700 | yes | shared option |
| Alien plush | 800 | **early**: "Alien merchandise" listed as hot in June 1997 | lead https://elibrary.arcade-museum.com/Play-Meter/1997-June/127 ; start date not found |
| Basketball | 900 | yes | |
| Virtual pet | 1,500 | **no: US release May 1, 1997** (Giga-pet type also May 1997) | leads https://www.smithsonianmag.com/innovation/keeping-tamagotchi-alive-180979264/ , https://en.wikipedia.org/wiki/Giga_Pet |
| Lava lamp | 2,500 | yes: 1990s revival, 10,000 lamps/yr (1989) to 800,000 (1999) | leads https://en.wikipedia.org/wiki/Mathmos , https://archive.seattletimes.com/archive/19960417/2324647/lava-lamps-keep-churning-sales-keep-burning----hot-waxy-goop-is-way-cool |

## 3. 1995 options (Pocket Change)

Era: **95** = 1995 only, **both** = also sold in 2026. Share: **S** = one model used in both arcades,
**U** = unique to one. Build: **BM** = Blender model (hand item, close-up hero), **BF** = bin filler
(primitive or painted card repeated in bins), **ST** = standing box/shelf item (simple box with a
generic painted face).

| Tier | Generic build (what we'd make) | Reference only | Tickets (guess) | Era | Share | Build | Date note / source |
|---|---|---|---|---|---|---|---|
| T1 | Lollipop | | 3-5 | both | S | BF | **guess** |
| T1 | Tablet-candy roll in clear wrap | Smarties-type | 3-5 | both | S | BF | **guess** (date not checked) |
| T1 | Taffy bar | Laffy Taffy-type | 5 | both | S | BF | **guess** (date not checked) |
| T1 | Powder candy straw | Pixy Stix-type | 3 | both | S | BF | **guess** (date not checked) |
| T1 | Candy ring on a plastic band | Ring Pop-type | 15-25 | both | S | BF | 1979 or 1980 (sources differ): lead https://episteme.tllm.fr/wiki/Ring_Pop , https://247wallst.com/special-report/2022/08/15/best-candies-youll-remember-from-the-90s/2/ |
| T1 | Push-up candy tube | Push Pop-type | 20-25 | both | S | BF | 1986: lead https://www.wxyz.com/heres-candy-came-year-born |
| T1 | Extreme-sour hard candy | Warheads-type | 5 | both | S | BF | 1991 per one source: lead https://www.wxyz.com/heres-candy-came-year-born |
| T1 | Plastic spider ring | | 2-5 | both | S | BF | **guess** |
| T1 | Small high-bounce ball (swirl) | Super Ball-type | 5-10 | both | S | BF | 1965 original; kids spent tickets on them: leads https://en.wikipedia.org/wiki/Super_Ball , https://steamcommunity.com/app/506610/discussions/0/1290691308577426350 |
| T1 | Pencil with eraser topper; novelty erasers | | 5-10 | both | S | BF | **guess** |
| T1 | Sticker sheet; temporary tattoos | | 5 | both | S | BF (flat card) | **guess** |
| T1 | Sticky hand (long-string, translucent) | | 10-15 | both | S | BF | vending staple 1990s-2000s; descends from the early-80s wall-walker: lead, low quality https://dinosaurdracula.com/blog/vintage-vending-wrecking-power/ |
| T2 | Bag of plastic army men / parachute man | | 25-50 | both | S | BF | **guess** |
| T2 | Rubber snake / rubber bug | | 25 | both | S | BF | **guess** |
| T2 | Jelly bracelets (bundle) | | 25-50 | 95 (**guess**) | U | BF | **guess** |
| T2 | Glow bracelet tube | | 25 | both | S | BF | **guess** |
| T2 | Troll-type doll, small, bright hair | Troll doll | 50-100 | 95 | U | BM (small) | early-90s revival: leads https://en.wikipedia.org/wiki/Troll_doll , https://www.museumofplay.org/blog/have-you-hugged-a-troll-doll-lately/ |
| T2 | Slammer (heavy cap) singles | POG slammer | 50-75 | 95 | U | BF | as Pog pack above |
| T2 | Whoopee cushion, kazoo, whistle | | 25-50 | both | S | BF | **guess** |
| T3 | Wooden paddle ball (carded) | | 100-150 | both | S | ST on hook | **guess** |
| T3 | Yo-yo (carded) | | 100-200 | both | S | BM (hand item) | 1998-99 craze date **not confirmed**; plain yo-yos fine for 1995 (**guess**) |
| T3 | Mini squirt pistol (carded) | | 100-200 | 95 (**guess**) | U | ST on hook | |
| T3 | Pump water blaster, small | Super Soaker-type | 400-500 | 95 | U | BM | on sale 1990: lead https://worldstrides.com/blog/2018/12/holiday-toy-throwback-popular-gifts-of-the-90s |
| T3 | Koosh-type rubber-strand ball | Koosh | 150-300 | both | S | BM (simple) | 1987 launch, bestseller 1988: leads https://en.wikipedia.org/wiki/Koosh_ball , https://www.deseret.com/1989/9/7/18822916/koosh-ball-goes-whoosh-on-the-toys-best-seller-list |
| T3 | Neon sunglasses; mood ring | | 150-300 | 95 | U | BF | **guess** |
| T3 | Die-cast-type toy car, blister card | | 200-300 | both | S | ST on hook | **guess** |
| T3 | Harmonica, tin | | 200 | both | S | BF | **guess** |
| T4 | Plush animal, 12 in | | 500-900 | both | S | BM (exist) | — |
| T4 | Bean-bag plush (small, floppy) | Beanie Babies | 300-600 | 95 OK, craze later | S | BM | line began 1993, slow at first; height of craze ~1997: leads https://thebubbleblog.substack.com/p/from-playtime-to-paytime-the-soaring , https://scalar.usc.edu/works/dear-santa-this-year-i-have-been-very-good/beanie-babies |
| T4 | Handheld single-game LCD | Tiger-type | 1,000-1,500 | 95 | U | ST (box) / BM | **guess** |
| T4 | Walkie-talkie pair (boxed) | | 1,500-2,000 | 95 | U | ST | **guess** |
| T4 | Plasma ball | | 1,500-2,500 | both (USB minis today) | S | BM | 1980s novelty fad: lead https://en.wikipedia.org/wiki/Plasma_globe |
| T5 | Cassette player with headphones (boxed) | Walkman-type | 3,000-5,000 | 95 | U | ST | **guess** |
| T5 | Radio-control car (boxed) | | 3,000-6,000 | both | S (box art differs) | ST | **guess** |
| T5 | Skateboard | | 4,000-8,000 | both | S | BM | "skateboards, low-end electronics… several thousand": lead https://en.wikipedia.org/wiki/Redemption_game |
| T5 | 3 ft plush | | 3,000-5,000 | both | S | BM | **guess** |
| T6 | (rare in 1995) small TV/VCR combo or bike as a display piece | | 10,000-20,000 | 95 | U | ST | **guess**; 1991 lead tops out at 2,000+ |

**1995 anachronisms to avoid (flag):** virtual pets and Giga-pet type (May 1997, above); Bop It-type
(1996); Furby-type (fall 1998); fingerboard skateboards (late 1990s); fidget spinners (2017); poppers
(2019+). Leads: https://worldstrides.com/blog/2018/12/holiday-toy-throwback-popular-gifts-of-the-90s ,
https://en.wikipedia.org/wiki/Giga_Pet , https://collectibles.com/collectible-items/40293314 ,
https://en.wikipedia.org/wiki/Fidget_spinner .

## 4. 2026 options (games, inc.)

| Tier | Generic build | Reference only | Tickets (guess) | Era | Share | Build | Date note / source |
|---|---|---|---|---|---|---|---|
| T1 | Candy (lollipops, sour candy, taffy, candy ring) | as above | 5-25 | both | S | BF | stickless candy mixes as prize fill: lead https://bulkvendingworld.com/automated-redemption-prizes/ |
| T1 | Sticky hand, spider ring, bouncy ball, finger trap, stickers | | 5-25 | both | S | BF | as above |
| T1 | Mini eraser figures (food shapes, animals) | | 10-25 | 2026 | U | BF | **guess** |
| T2 | Popper keychain (silicone bubble grid, small) | Pop It | 50-100 | 2026 | U | BF | relaunched 2019; craze 2020-21 after a TikTok video: leads https://en.wikipedia.org/wiki/Pop_it , https://www.ypulse.com/newsfeed/2021/08/20/pop-its-are-the-toy-of-the-pandemic-thanks-to-tiktok/ ; pop-it keychains sold as prize fill: lead https://bulkvendingworld.com/product-tag/arcade-prizes/ |
| T2 | Mini squishy (slow-rise foam food/animal) | | 50-100 | 2026 | U | BF | squishies among the most popular bulk prizes: lead https://bulkvendingworld.com/product-category/redemption/ |
| T2 | Light-up ring | | 25-75 | 2026 | U | BF (emissive) | lead https://bulkvendingworld.com/automated-redemption-prizes/ |
| T2 | Capsule fidget (spinner, flippy chain) | fidget spinner | 50-100 | 2026 | U | BF | spinner craze spring 2017: lead https://en.wikipedia.org/wiki/Fidget_spinner |
| T2 | Slap bracelet (revival) | | 50-100 | both | S | BF | still marketed on nostalgia: lead https://wornandwound.com/fossil-is-banking-on-pure-nostalgia-with-the-rock-candy-slap-watch-which-is-exactly-what-it-sounds-like/ |
| T3 | Squishy dough stress ball | NeeDoh | 200-400 | 2026 | U | BF / BM (hand) | sold-out craze late 2025-2026: leads https://en.wikipedia.org/wiki/NeeDoh , https://www.kbtx.com/2026/06/18/squishy-toy-craze-is-selling-out-stores-across-america/ |
| T3 | Blind-bag mini figure (foil bag, plain pattern) | | 200-500 | 2026 | U | BF (bag) | "collectables and blind boxes are currently leading the way": lead https://www.amusementsandattractions.com/amusements/insights/the-prize-is-right |
| T3 | Popper board, full size | Pop It | 300-500 | 2026 | U | BF | as above |
| T3 | Slime tub | | 200-300 | 2026 | U | BF | **guess** |
| T3 | Emoji-face plush keychain | | 200-400 | 2026 | U | BF | emoji-themed prizes: lead https://www.amusementsandattractions.com/amusements/insights/the-prize-is-right |
| T4 | Round squish-type plush, 8 in (generic animal, no face marks of a brand) | Squishmallows | 800-1,500 | 2026 | U | BM | brand 2017, boom 2020: lead https://www.wsuguardian.com/article/2025/05/the-history-of-squishmallows-claw-machines-to-corporations-and-everything-in-between |
| T4 | Capybara plush | | 800-2,000 | 2026 | U | BM | capybara plush demand through 2025: lead https://www.amusementsandattractions.com/amusements/insights/the-prize-is-right |
| T4 | LED spin wand / light-up glasses | | 500-1,000 | 2026 | U | BF (emissive) | novelty electronics popular: lead https://bulkvendingworld.com/product-category/redemption/ |
| T4 | Phone stand, charging cable (boxed) | | 1,000-2,000 | 2026 | U | ST | **guess** |
| T5 | Mini Bluetooth speaker (boxed) | | 3,000-8,000 | 2026 | U | ST + one BM | **guess**; electronics in Round1-type prize stores: lead https://dvcinquirer.com/?p=2871663 |
| T5 | Wireless earbuds (boxed) | | 5,000-10,000 | 2026 | U | ST | **guess** |
| T5 | Galaxy star projector; LED strip kit | | 3,000-8,000 | 2026 | U | ST | **guess** |
| T5 | Lava lamp | | 4,000-8,000 | both | S | BM (exists, Gumballs') | Mathmos still making them, 60th anniversary 2023: lead https://www.euronews.com/2023/10/26/lava-lamp-inventors-celebrate-60th-anniversary-with-five-new-designs |
| T5 | Squish-type plush, 16 in; alien plush | | 5,000-10,000 | 2026 | U (alien: S option) | BM | **guess** |
| T6 | Jumbo plush, 3-4 ft | | 15,000-50,000 | 2026 | U | BM | jumbo plush at 50,000 e-tickets: lead https://amusementtoday.com/2024/02/chuck-e-cheese-to-give-away-50-million-e-tickets |
| T6 | Over-ear headphones (boxed) | | 15,000-40,000 | 2026 | U | ST | **guess** |
| T6 | Handheld game console (boxed, plain) | Nintendo Switch | 100,000-150,000 | 2026 | U | ST | ~120k at D&B: lead, low quality https://eathealthy365.com/the-ultimate-guide-to-dave-and-busters-prizes/ |
| T6 | Home console (boxed, plain) | PlayStation 5 | 120,000-150,000 | 2026 | U | ST | same lead |
| T6 | Gift card on a rack card | | 10,000-30,000 | 2026 | U | BF (flat card) | **guess**; no source found |
| T6 | Retro mini arcade cabinet; scooter | | 20,000-60,000 | 2026 | U | ST / BM | **guess**; bikes as "Above All" prizes: lead https://bowlingindustry.com/creating-a-moment-for-prize-redemption |

## 5. Suggested additions (choose from)

**Pocket Change 1995, cheap to build (bin fillers, shared with 2026):** lollipops, candy ring,
push-up candy tube, spider rings, bouncy balls, sticky hands, stickers/tattoos, army-men bags.
**1995 hero pieces (Blender):** troll-type doll, pump water blaster, yo-yo, Koosh-type ball,
plasma ball (as the virtual-pet replacement), skateboard.
**1995 standing boxes (ST):** handheld LCD game, walkie-talkies, cassette player, RC car.

**games, inc. 2026 bin fillers:** popper keychains, mini squishies, light-up rings, capsule
fidgets, blind bags, slime tubs, emoji keychains, candy (shared).
**2026 hero pieces (Blender):** round squish-type plush (3 sizes), capybara plush, dough stress ball,
jumbo plush, one Bluetooth speaker.
**2026 standing boxes (ST):** earbuds, headphones, projector, plain console boxes, gift-card rack.

**Shared models (build once):** finger trap, bouncy ball, sticky hand, spider ring, candy set,
slap bracelet, plush 12 in, lava lamp, skateboard, RC car (different box faces).

## 6. Big uncertainties

- No 1995 ticket price list was found for any real counter; all ticket numbers are **guesses** scaled
  from the ~1 ¢/ticket leads.
- Dave & Buster's console figures come from low-quality SEO pages.
- Alien plush start date not found (hot by June 1997); for 1995 it is plausible-to-early.
- Pog peak is well supported for 1994 into early 1995; slap bracelets were past peak by 1995.

## Sources

All seen in web search results on Nov 3, 2026; none opened (fetch blocked).

- https://elibrary.arcade-museum.com/Play-Meter/1996-July/98
- https://elibrary.arcade-museum.com/Play-Meter/1991-March/72
- https://elibrary.arcade-museum.com/Play-Meter/1991-June/55
- https://elibrary.arcade-museum.com/Play-Meter/1997-June/127
- https://www.replaymag.com/gameroom-guru-july-2016/?amp=1
- https://replaymag.com/?p=19879
- https://loyaltyrewardco.com/?p=10498
- https://eathealthy365.com/the-ultimate-guide-to-dave-and-busters-prizes/
- https://siegfriedt-survey.umb.edu/pti/how-much-are-dave-and-buster-tickets
- https://amusementtoday.com/2024/02/chuck-e-cheese-to-give-away-50-million-e-tickets
- https://en.wikipedia.org/wiki/Redemption_game
- https://mca.legmt.gov/bills/1999/mca/23/6/23-6-102.htm
- https://www.mentalfloss.com/article/620529/slap-bracelet-phenomenon-1990
- https://www.tampabay.com/archive/1995/01/23/no-pogs-allowed/
- https://csmonitor.com/1994/1221/21014.html
- https://www.deseret.com/1994/9/5/19129100/kids-and-adults-flip-over-milk-cap-game/
- https://www.smithsonianmag.com/innovation/keeping-tamagotchi-alive-180979264/
- https://en.wikipedia.org/wiki/Giga_Pet
- https://en.wikipedia.org/wiki/Mathmos
- https://archive.seattletimes.com/archive/19960417/2324647/lava-lamps-keep-churning-sales-keep-burning----hot-waxy-goop-is-way-cool
- https://www.euronews.com/2023/10/26/lava-lamp-inventors-celebrate-60th-anniversary-with-five-new-designs
- https://episteme.tllm.fr/wiki/Ring_Pop
- https://247wallst.com/special-report/2022/08/15/best-candies-youll-remember-from-the-90s/2/
- https://www.wxyz.com/heres-candy-came-year-born
- https://en.wikipedia.org/wiki/Super_Ball
- https://steamcommunity.com/app/506610/discussions/0/1290691308577426350
- https://dinosaurdracula.com/blog/vintage-vending-wrecking-power/
- https://en.wikipedia.org/wiki/Troll_doll
- https://www.museumofplay.org/blog/have-you-hugged-a-troll-doll-lately/
- https://worldstrides.com/blog/2018/12/holiday-toy-throwback-popular-gifts-of-the-90s
- https://en.wikipedia.org/wiki/Koosh_ball
- https://www.deseret.com/1989/9/7/18822916/koosh-ball-goes-whoosh-on-the-toys-best-seller-list
- https://thebubbleblog.substack.com/p/from-playtime-to-paytime-the-soaring
- https://scalar.usc.edu/works/dear-santa-this-year-i-have-been-very-good/beanie-babies
- https://en.wikipedia.org/wiki/Plasma_globe
- https://collectibles.com/collectible-items/40293314
- https://en.wikipedia.org/wiki/Fidget_spinner
- https://bulkvendingworld.com/automated-redemption-prizes/
- https://bulkvendingworld.com/product-tag/arcade-prizes/
- https://bulkvendingworld.com/product-category/redemption/
- https://en.wikipedia.org/wiki/Pop_it
- https://www.ypulse.com/newsfeed/2021/08/20/pop-its-are-the-toy-of-the-pandemic-thanks-to-tiktok/
- https://wornandwound.com/fossil-is-banking-on-pure-nostalgia-with-the-rock-candy-slap-watch-which-is-exactly-what-it-sounds-like/
- https://en.wikipedia.org/wiki/NeeDoh
- https://www.kbtx.com/2026/06/18/squishy-toy-craze-is-selling-out-stores-across-america/
- https://www.amusementsandattractions.com/amusements/insights/the-prize-is-right
- https://www.wsuguardian.com/article/2025/05/the-history-of-squishmallows-claw-machines-to-corporations-and-everything-in-between
- https://dvcinquirer.com/?p=2871663
- https://bowlingindustry.com/creating-a-moment-for-prize-redemption
