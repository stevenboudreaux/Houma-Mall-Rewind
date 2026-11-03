# Coin pusher mechanics: research note for COIN COMET

Written Nov 3, 2026 for COIN COMET (a 1990s three-player, two-sided quarter pusher in the mall arcade). Every claim carries its URL. Where sources disagree or run thin, this note says so. **Measured** numbers come from our own teardown (`refs/coin_pusher`); **estimate** means ours, with no source.

**How this was gathered.** The session could run web searches but could not open most pages: `en.wikipedia.org`, `patents.google.com`, `patents.justia.com`, `image-ppubs.uspto.gov`, `data.epo.org`, `www.elaut.com`, `www.bmigaming.com`, `easy.vegas`, `wizardofodds.com`, `www.intergameonline.com`, `pennymachines.co.uk`, `makerworld.com`, `forum.arduino.cc`, `www.instructables.com` and `www.madmodder.net` are outside the session's allowed network domains. Quotes below are the search engine's excerpts of those pages, not full reads. The patents in particular have drawings and dimension text the excerpts do not carry; open them before relying on a number.

## The owner's description (Nov 3, 2026)

The machine is two-tier. The player drops a coin; it lands on a motorized top shelf that slides out toward the glass and back in. The top tier's back wall has a gap when the shelf is out; the goal is to land a coin on the top tier while the shelf is out. When the shelf comes back in, the coins on it get pushed off its edge onto the main tier below, an inch or two lower. When it moves out again, that shelf pushes the main-tier coins forward, and they fall into the payout slot.

## Our measured source

`refs/coin_pusher`, Steven's teardown video of a Silver Falls quarter pusher: plate stroke ≈ 50 mm; crank period ≈ 4.5 s; adjustable lip at the drop edge, set with a Phillips screwdriver; side holes to the house bucket at both sides of the lower shelf; tilt alarm 3 s with a flipper gate in the chute; quarters only.

## 1. How a two-tier pusher works

Wikipedia matches the owner's description: most machines are two-tiered; a stationary barricade pushes coins off the moving upper playfield onto a stationary lower playfield, and the moving playfield then pushes them off that lower edge. "Part of the moving playfield slides underneath the barricade, and the barricade pushes all of the coins toward the overhang." The original Penny Falls (Alfred Crompton Ltd, 1964) had one large playfield moving side to side, split into 12 player sections; the "towards/away" motion came later (https://en.wikipedia.org/wiki/Coin_pusher). A Japanese patent says the same: "the upper field 21 reciprocates along the upper surface of the lower field 20 in the front-rear direction by a pusher table driving mechanism 46 at, for example, a constant cycle" (https://patents.google.com/patent/JP6672231B2/en).

Crompton's 1963 Wheel A Win was a round table with sweeper arms pushing coins to players or down losing holes; players could see the money vanish. Penny Falls (1964; one post says 1966) replaced it with a linear pusher and lose-holes hidden from view (https://pennymachines.co.uk/museum/pushers/, https://pennymachines.co.uk/Forum/viewtopic.php?t=5437). It was never patented: "we offered it to the world" (https://intergameonline.com/coin-op/news/pushing-coins-through-the-ages).

Crompton's later patent (US 4,662,636, 1985) gives the language: the pusher "is arranged to pass backwards and forwards over part of the playfield surface," its motion "perpendicular to the edge 3 and parallel to the playfield surface"; its "lower leading edge has downward projections 8 which sweep across the surface of the playfield and, in the forward motion, urge the coins towards the edge 3"; inserted coins "may pass onto the playfield surface directly or via an upper surface of the money-pusher" (https://patents.google.com/patent/US4662636). GB 2,124,913 (1982) adds that coins "enter through a conventional slot and slide," undersize coins "fall straight into the cash box," and the pusher is "driven by suitable gearing from a motor" (https://patents.google.com/patent/GB2124913A/en). Aruze's 2020 casino pusher calls the top of the pusher the "upper pusher field" and defines a game cycle from the pusher's home position to its next return (https://patents.google.com/patent/US10839652B2/en). US 4,240,536 (1979) describes two boxes, the top one offset and reciprocating across the lower; coins on the top box are pushed off when its forward edge advances (https://patents.google.com/patent/US4240536; a second search could not confirm this from excerpts).

**The drive.** "A low-speed electric motor runs continuously. Instead of complex digital gears, it powers an eccentric arm linkage that translates simple rotary motion into a back-and-forth sliding cycle" (https://www.coinpusher.com/how-do-coin-pushers-work/ or https://tkyclawmachine.com/coin-pusher-machine/; the excerpt did not say which). That is the crank we measured at ≈ 4.5 s.

**Open vs closed loop.** Elaut (owner of Benchmark and Coast to Coast) distinguishes "open loop coin pushers (also known as coin dozer machines)," which return coins, from "closed loop" machines that keep tokens inside and pay tickets or prizes (https://www.elaut.com/all-news/how-do-coin-pushers-work, https://www.elaut.com/company/about-elaut). COIN COMET is open loop.

**The Silver Falls.** Dealers call it "an authentic McGregor Pusher," 60" H x 23.5" W x 31" D, about $1,595. Its coin entry is "a slider that moves from side to side that adds a level of skill for legal purposes," with "a skill button that stops the slider." "If the items fall forward, then the customer wins. If the items fall to the side, then the cabinet owner gets to keep the items that fell." On tilt "a flapper activates that causes any items that fall off the slider to slide to the side rather than forward" (https://pbandjindustries.com/silver-falls-coin-pusher-quarter-slider/, https://pbandjindustries.com/bonus-hole-coin-pusher-quarter-slider/, https://napoleonexhibit.com/store/New-Silver-Falls-Quarter-Coin-Pusher-Slider_186458003007.html). That flapper is our "flipper gate."

**Big multi-player machines.** Coastal Amusements' manuals: each playfield "will require approximately 600 coins to float or prime it" (Star Trek 2-player), about 900 per section (Jack's 4-player), about 800 (Casino Lights 6-player); "the first 90% of the coins may be hand placed in small batches onto the moving pusher box," the rest played in for appearance (https://www.bmigaming.com/Games/Manuals/coastal-amusements/star-trek-2-player-coin-pusher-redemption-game-operators-manual-coastal-amusements.pdf, https://www.bmigaming.com/Games/Manuals/coastal-amusements/jacks-hi-coin-pusher-redemption-game-operators-manual-coastal-amusements.pdf, https://www.bmigaming.com/Games/Manuals/coastal-amusements/casino-lights-6-player-coin-pusher-redemption-game-operators-manual-coastal-amusements.pdf). The manuals call the moving top tier the "pusher box."

**Coin path, step by step** (steps 1 and 7 from the dealer pages and our teardown; 2 to 6 from Wikipedia and the patents above):

1. The quarter goes into the entry (on the Silver Falls, a side-to-side slider with a stop button) and slides down a chute toward the back of the top tier.
2. It lands on the top of the pusher box, or, if the box is in, falls past its front onto the lower field ("directly or via an upper surface of the money-pusher").
3. The box retracts under the fixed back wall. Coins on it cannot pass under the wall, so its bottom edge sweeps them off the box's front onto the lower field.
4. The box's front face advances, pushing the lower heap toward the drop edge.
5. Coins at the front spill over the lip into the payout chute and win cup. Coins that drift sideways drop through the side holes into the house bucket.
6. The box retracts; coins left behind settle; the next drop repeats the cycle.
7. If the cabinet is jostled, the tilt alarm sounds and the flapper diverts the chute to the house for a few seconds.

## 2. Dimensions

No published spec gives stroke, cycle, tier step or field depth; a repair guide only says a replacement plate must match the original's "travel distance" (https://www.palm-fun.com/diy-coin-pusher-repair-guide.html). What exists:

| Quantity | Value | Source | Status |
|---|---|---|---|
| Plate stroke | ≈ 50 mm | `refs/coin_pusher` | measured |
| Crank period | ≈ 4.5 s | `refs/coin_pusher` | measured |
| Cycle, vendor | "Repeat every 2–3 seconds" | https://www.palm-fun.com/how-to-beat-coin-pusher-arcade-games-tips-by-palm-fun.html | vendor, may mean drop interval |
| Cycle, web sims | 2.4 s sine; 3.6 s stroke | https://vibearcade.com/games/pusher, https://github.com/gomyway1216/nextjs-portfolio/pull/1042 | software |
| Motor speed, vendor guides | 25–60 RPM "ideal"; or 5–15 RPM medium, 3–10 RPM large | https://electronics.alibaba.com/buyingguides/coin-pusher-motor-dc-guide-how-to-choose-right, https://www.fengtech.com/coin-pusher-motor/ | vendors disagree |
| Hobby motor speeds | 12 V 20 RPM; TT 59 RPM | https://www.thingiverse.com/thing:6437619, https://makerworld.com/en/models/1292594-martin-s-coin-pusher-v1-2 | hobby |
| Heap thickness, commercial | "up to two inches at times" | https://www.madmodder.net/index.php/topic,8817.0.html | forum |
| Cover-plate clearance over lower field | 19 mm "conveniently, but not essentially" | https://patents.google.com/patent/GB2226766A/en | patent; not the tier step |
| Coin guide gap | "slightly greater than the thickness of the coins" | https://patents.google.com/patent/GB2124913A/en | patent |
| Silver Falls cabinet | 60" H x 23.5" W x 31" D | https://pbandjindustries.com/silver-falls-coin-pusher-quarter-slider/ | dealer |
| Arcadro 365 tabletop | 27 x 14.6 x 17.7 in; coins ≤ 25.75 mm dia, ≤ 2.3 mm thick | https://www.amazon.com/Arcadro%C2%A9-Coin-Pusher-365-Entertainment/dp/B0FF9XJ96K | retail |

A crank at 13 RPM gives a 4.6 s period, so our 4.5 s sits at the low end of the vendor ranges (estimate). **Tier step:** no source; the owner's "inch or two" is the only figure, and madmodder's "two inches" is heap thickness, not the step. **Field depth in coin rows:** no source; the Coastal priming counts are the nearest data. **Gap under the back wall:** no source; it must pass one coin on the plate and stop a stack riding under (estimate). **Drop point:** designs vary. US 6,264,197's chute "is on an incline and fixed" so "the player has no control over the location of the drop"; US 5,275,402 puts chutes "above the level of game board 16 midway between the side walls" with the release end over the board's edge region; US 4,303,248 lets the chute swivel (https://patents.google.com/patent/US6264197, https://patents.google.com/patent/US5275402, https://patents.google.com/patent/US4303248). On Flip-It "coins tend to land in front of the slot they're inserted into" (https://wizardofodds.com/games/flip-it/). The Silver Falls moves the drop point with its slider.

## 3. Timing skill

Guides agree on one thing: the coin must land flat in open space behind the heap. "Each coin should land behind the stacked coins, not on top of them. Coins that land on top usually do nothing"; rapid feeding makes coins "stack on top of each other, drastically reducing their pushing power" (https://www.arcadro.com/blogs/wiki/how-to-beat-a-coin-pusher-machine, https://www.arcadro.com/pages/how-to-win-a-coin-pusher-machine). The coin should "land flat on the empty part of the shelf, then act as a direct battering ram against the stack as the shelf moves forward" (https://www.jiamigames.com/article/coin-pusher-arcade-game/). Easy.vegas: aim so "your coin falls onto a naked space on the tray, behind all the other coins" (https://easy.vegas/games/flipit).

They split on when. Arcadro: "the best moment to insert coins is when the sliding tray has moved IN almost all the way." A UK fairground guide also says drop when the top shelf is "in" (https://www.wearetricycle.co.uk/pages/how-to-beat-the-arcade-coin-pusher); TKY: "right when the moving shelf is fully pulled back" (https://tkyclawmachine.com/coin-pusher-machine/). One low-quality blog says the opposite, drop "as the platform heads toward the edge" (https://digital-dev.lib.calpoly.edu/veilstream-edu/meet-aampv-coin-pusher-a-deep-dive-into-the-world-of-coin-pushers.html). The "in" guides picture one-tier tabletops where the retracted plate exposes the lower field; in a hooded two-tier machine the equivalent is the owner's rule, land on the plate while it is out. A simulation study found "timing to the stroke only loses" and steady feeding matched the best timed play, though medals landing near the pusher's front entered the feature more often (90.2%) than ones landing as it drew back (82.4%) (https://github.com/gomyway1216/nextjs-portfolio/pull/1042; a sim). Laterally: "play the middle slots. Playing the slots on the sides will mean that more of your coins will land on the sides, and you won't get those coins back" (https://wizardofodds.com/games/flip-it/). Look for a "primed" machine, "coins visibly overlapping and sloping downwards toward the drop zone" (Arcadro); Wizard of Odds tested that over 558 coins and finished 9 ahead, "too small to be conclusive." One patent makes timing explicit: a dozer whose travel depends on when the coin drops against a moving needle (https://patents.google.com/patent/US6264197). A 1988 FBI bulletin held that penny falls "lead the player to believe that the game can be beaten by virtue of his skill, when, in reality, it is a game of chance" (https://www.ojp.gov/ncjrs/virtual-library/abstracts/penny-falls-friend-or-foe).

## 4. Side handling

**Side holes are the house take.** Machines have "small, usually hidden gaps at the sides of the playfield where coins can fall. The coins that fall here are not returned to the player, these are the operator's profit" (https://en.wikipedia.org/wiki/Coin_pusher). Most pushers "have slots cut into the side walls of the game board. These will ordinarily be concealed by a mirror or in some other unintrusive fashion" (https://patents.google.com/patent/US6550768). On Flip-It the edge chutes "are hidden behind signs" reading "Spill Pay Area," and "quarters tended to flip to the sides more often than dollars because they're lighter" (https://wizardofodds.com/games/flip-it/). An operator who ran Crompton pushers in the early 1980s says coins "were guided diagonally outwards into the cash box" (https://pennymachines.co.uk/Forum/viewtopic.php?t=5437). Our teardown confirms holes at both sides of the lower shelf.

**Without side loss.** The skill-pusher patent exists because "many jurisdictions, which will allow a 'skill based' game that does not have a set house percentage, prohibit as unlawful the standard coin pusher game which has side slots" (https://patents.google.com/patent/US6550768). Even the home Arcadro 365 has "token drains on either side of the token tray" (https://boardgamequest.com/coin-pusher-365-review-bring-the-arcade-home). Video versions sell the walls: Coin Dozer's "Coin Walls" power-up "temporarily blocks the losing sides" (https://www.bluestacks.com/blog/game-guides/coin-dozer/cds-beginner-guide-en.html); a web medal pusher raises side walls for a 45 s "Fever" with 0% loss (https://github.com/futurecortexlabs/FCTX-Web-Medal-Pusher). Hobby builds mostly omit side holes (section 7). Made for Arcade's machine, on tilt, switches a "diversion valve" to the "house position" (https://madeforarcade.com/manual/coin-pusher-user-manual-2/).

**Quarter pusher vs penny pusher.** UK "penny falls" take real 2p or 10p coins under Category D rules: maximum stake 20p, maximum prize £20 of which no more than £10 cash, set in 2014 (https://www.gov.uk/government/consultations/consultation-on-category-d-gaming-machines-and-licensing-for-bingo-premises/category-d-gaming-machines, https://knyvet.bailii.org/uk/legis/num_reg/2014/uksi_201445_en_1.html). In the US cash pushers "are outlawed in a number of states" (https://coinbooks.org/v25/esylum_v25n34a30.html), quarter pushers "have largely disappeared" from Las Vegas casinos (https://www.lasvegasadvisor.com/question/coin-pushers/), and arcade pushers mostly pay tickets, some settable "to dispense tickets for states that require that feature" (https://pbandjindustries.com/silver-falls-coin-pusher-quarter-slider/). Japan's medal pushers use tokens that cannot be cashed out (https://en.wikipedia.org/wiki/Medal_game). The Silver Falls slider and stop button exist "for legal purposes."

**The lip.** "Increasing the angle of elevation of the hinged lip affects a decrease in payout percentage (i.e. less playing pieces fall over the winning edge, and more playing pieces fall over the or each losing edge)" (https://patents.google.com/patent/US7172197). "The payout rate can be relatively raised or lowered by raising or lowering the edge plate" (https://patents.google.com/patent/JP2006068126A/en). Ours is a Phillips screw.

## 5. How operators tune payout

| Knob | Effect | Source |
|---|---|---|
| Lip / edge plate | Higher lip, fewer wins, more to the sides | US7172197, JP2006068126A above |
| Side-hole width | "narrowing or widening the gaps where coins fall back into the machine" | https://www.palm-fun.com/coin-pusher-setup-placement-tips.html (vendor) |
| Side walls | "walls may be lengthened to produce the opposite effect" | https://patents.google.com/patent/US7172197 |
| Stroke and speed | "longer strokes and higher speeds increase the chance of significant coin displacement"; operators "can shorten the push distance" | https://www.palm-fun.com/how-coin-pusher-arcade-machines-work.html (vendor) |
| Fill level | 600–900 coins per section to prime | Coastal manuals, section 1 |
| Tilt | Coastal: tilt state "about 10 seconds"; Made for Arcade: tilt-bob clapper, sensitivity by screwing the weight up or down; ours: 3 s | https://www.bmigaming.com/Games/Manuals/coastal-amusements/star-trek-8-player-coin-pusher-redemption-game-operators-manual-coastal-amusements.pdf, https://madeforarcade.com/manual/coin-pusher-user-manual-2/ |
| Pusher activation time | setting a1, 1–250, default 30 (electronic pusher) | https://madeforarcade.com/manual/coin-pusher-user-manual-2/ |

**Return to player.** Only hobbyist arithmetic is published. Wizard of Odds counted one dollar Flip-It at 405 coins in, 360 out, about 11.1% house edge, and reports Stanford Wong's 10% estimate because "the holes on the edges comprise about 10% of the total spill area width" (https://wizardofodds.com/games/flip-it/, https://easy.vegas/games/flipit). Easy.vegas puts the range at 10–33%, one machine near 32.5%. Japan: payout rate is "the ratio of the number of medals paid out to the number of medals inserted," learned by saturating the field with a known count out of hours (https://patents.google.com/patent/JP2006068126A/en); no typical percentage found. UK: no percentage found. A vendor's "one coin every four seconds" is marketing (https://www.raisefungame.com/ArcadeCoinPusherMachineSetupTipsforMaximumPlayerEngagement).

## 6. What makes them satisfying

Pusher-specific psychology writing is thin, mostly SEO copy, so the evidence is borrowed from slots. The appeal is put as anticipation, "the suspense of watching a coin teeter on the edge" (https://highstakewins.com/articles/coin-pusher-games-las-vegas-analysis/, weak). The near-miss effect is the usual mechanism; Wikipedia notes supporting studies and one Cambridge University Press study that "found no evidence of the near-miss effect" (https://en.wikipedia.org/wiki/Near-miss_effect). Variable-ratio reinforcement and the illusion of control are the other two named (https://www.palm-fun.com/article/coin-pusher-arcade-machine-guide.html, vendor); the 1988 FBI bulletin makes the illusion-of-control case from the regulator's side (https://www.ojp.gov/ncjrs/virtual-library/abstracts/penny-falls-friend-or-foe). Wizard of Odds' "primed machine" is the player's version: a heap visibly leaning over the edge. Spectating counts too: a 2025 review of a pusher video game is titled "Fun To Watch, But Not Much Of A Game" (https://kotaku.com/raccooin-review-balatro-like-coin-pusher-is-it-good-steam-pc-2000683914), and a newsletter notes many viral pusher videos are staged (https://coinbooks.org/v25/esylum_v25n34a30.html). For the sim: slow creep (4.5 s), coins that hang on the lip for a stroke or two, a visible heap slope, sound on every spill.

## 7. Home-built and hobby pushers

- **Martin's Coin Pusher V1.2** (3D printed): 130 x 175 x 190 mm, coins up to 30 mm, TT 5 V 59 RPM gearmotor with a shaft gear riding rails, four 625ZZ bearings (https://makerworld.com/en/models/1292594-martin-s-coin-pusher-v1-2).
- **RobbertDIY laser-cut pusher**: "a 12v 20RPM transmission motor for the movement of the shuttle" (https://www.thingiverse.com/thing:6437619).
- **Instructables "Coin Pusher"** (balsa, continuous-rotation servo, 5 V): stroke set by the crank offset on the servo horn (https://www.instructables.com/Coin-pusher/); a Make: MDF-and-perspex build used the same template (https://makezine.com/article/craft/diy-penny-pusher-taunts-you-into-gi/).
- **Retro Built Games kit** (Ryan Bates): laser-cut birch and acrylic, bring your own Arduino and motor; Bates' build uses a motor shield and "monitors a tilt sensor to detect if someone tries to cheat" (https://hackster.io/news/have-you-ever-wanted-an-arcade-style-coin-pusher-game-then-this-diy-kit-is-for-you-bd3501775a4a, https://blog.arduino.cc/?p=14960).
- **madmodder penny pusher** (wood, PC power supply): notes commercial heaps "up to two inches" thick (https://www.madmodder.net/index.php/topic,8817.0.html).
- **K'Nex pusher**: one excerpt reported "around two seconds was deemed appropriate for each direction's movement" and a stroke "just large enough to avoid too many overlapping coins" (https://www.instructables.com/KNex-Coin-Pusher-2); a second search could not find that text, so unconfirmed.
- **Arduino forum threads** gave no dimensions (https://forum.arduino.cc/t/diy-coin-pusher-with-arduino/1406658, https://forum.arduino.cc/t/newbie-project-coin-pusher/74555).
- **Software sims**: FCTX runs a kinematic sine-wave pusher at 60 Hz with pusher-top friction 0.85, medal friction 0.50, restitution 0.05, mass 1.0 (https://github.com/futurecortexlabs/FCTX-Web-Medal-Pusher); a Unity course project notes the pusher "slows at the ends of its travel" (https://perso.esiee.fr/~buzerl/sphinx_UNITY_1/90_project/project.html); a Godot developer tweaked "mass, simulation rate, bounciness, and friction" most and found scaling the scene changes the feel (https://forum.godotengine.org/t/how-do-i-make-the-collision-detection-more-precise-jolt-physics-coin-pusher-game/38671).

No hobby consensus on stroke or period; both motor speeds found (20 and 59 RPM) are faster than our 13 RPM-equivalent crank.

## 8. What this means for a game sim

Starting geometry per player station. Quarter: 24.26 mm diameter, 1.75 mm thick (US Mint specification, page not opened this session: https://www.usmint.gov/learn/coin-and-medal-programs/coin-specifications).

| Parameter | Recommended | Basis |
|---|---|---|
| Plate stroke | 5.0 cm | measured |
| Cycle period | 4.5 s, sinusoidal | measured; sine from the eccentric-arm drive and the sims |
| Tier step | 2.5–5 cm | owner's "inch or two"; estimate |
| Gap under back wall | ≈ 0.4–0.6 cm (one coin plus margin) | estimate |
| Lower field depth, plate face at full retraction to lip | 6–8 coin rows, ≈ 15–20 cm | estimate from priming counts and the 31 in cabinet depth |
| Field width per station | ≈ 30–40 cm | estimate from the 23.5 in single-player cabinet |
| Side-hole width, each side | ≈ 5% of width (10% total) | Wong's 10%-of-width estimate |
| Lip height | 0 to 1 coin thickness, adjustable | hinged-lip patents; ours is screw-set |
| Resting heap | 1–3 layers, deeper near the plate | madmodder "two inches"; Coastal 600+ per section |
| Drop point | plate's exposed top, movable left-right | Silver Falls slider; Crompton "via an upper surface" |
| Tilt | alarm, chute to house, 3 s | measured; Coastal uses 10 s |
| House take at neutral lip | 10–15% | Wizard of Odds 11.1%; easy.vegas 10–33% |
| Coin friction / restitution | ≈ 0.5 / ≈ 0.05 | FCTX sim values; tune by feel |

Measured: stroke, period, lip adjustability, side holes, tilt time. Sourced but rough: house take, heap depth, priming count. Guessed: tier step, wall gap, field depth and width, side-hole width.

## Where the sources differ from the owner's description

1. **The mechanism matches.** Wikipedia, the JP patent and Crompton's patent describe the owner's cycle exactly: plate out, coin lands on it, plate retracts under a fixed wall that sweeps the coins down, plate face pushes the heap to the edge.
2. **Timing advice points the other way, for a different layout.** Most guides say drop when the shelf is "in" or "fully pulled back," describing one-tier tabletops. In a hooded two-tier machine that is the owner's "while it is out." One sim found timing barely matters. Make the window a mild bonus, not a hard skill gate.
3. **The description omits the side holes and the lip,** which every source and our teardown treat as the economic core.
4. **The Silver Falls coin entry is a moving slider with a stop button** per two dealer pages; the owner's description does not mention it. Check the teardown video for whether COIN COMET's entry moves.
5. **"An inch or two lower" has no outside confirmation.** No patent or manual gives the tier step; madmodder's "two inches" is the pile, not the step. Measure it from the video.
6. **Fill level matters more than the description implies.** Operators prime each section with hundreds of coins. Start the sim primed.

## Applied in the build (workstream PUSHER, Nov 3, 2026)

What the rebuilt `play/pusher/sim.js` took from this note and from Steven's description (the numbers are
in `design/storefronts/pocket-change.md`, "COIN COMET plays like a pusher"):

- **The cycle is Steven's and Wikipedia's:** a fixed back wall at the back of the top tier, the deck sliding
  out from under it; the chute lands the coin 1.5 cm in front of the wall, so a coin dropped while the deck
  is out falls into the gap behind the deck's heap and the wall shoves that heap forward when the deck comes
  back in. The page cues the open gap (section 3's "land behind the heap, in open space").
- **A short lower field** (9 rows of quarters from the deck's face to the lip, section 8's 6–8) and a small
  step between the tiers (3 cm, Steven's "an inch or two") in place of the Nov 1 build's 14 rows and 7.5 cm.
- **No side holes** (Steven's call; section 4's skill-pusher patent shows machines built that way). The blue
  art ramps are side guides in the sim; the soak counts a coin past a side wall as a failure and found none.
- **Primed fill** (section 1's Coastal manuals: operators hand-fill a field before it pays): three layers on
  both tiers at high quality.
- **Stroke 6 cm, period 3 s** against the teardown's 50 mm and 4.5 s: play values. A 2° forward tilt of the
  whole field (not in any source; a feel number) is what makes the rigid-body heap creep instead of hoard.
- **Not applied:** the Silver Falls' skill-stop button (section 1); the house take through side holes
  (section 5): with walls the long-run return in coins tends to 100 %, and the house's margin is the drop's
  price against the tickets a coin pays (ECON's knob).
- **The open question from section 3** (do timing guides apply?): the soak's `phase` option drops every coin
  with the gap open or closed; the result is in the design note's "Timing matters" line.
