# Coin pusher reference: "What's inside a coin pusher, how it works" (Silver Falls, ClawD00d)

Files: `video.mp4` (16:44, 640×360, 30 fps — cut your own frames with ffmpeg where 1 fps isn't enough),
`frames/tNNNN.jpg` (1 fps; frame tNNNN = second NNNN−1), `sheet_0..5.jpg` (contact sheets, 4 s apart, labelled),
`transcript.txt` (offline Whisper small.en, 25 s chunks: `[ Ns]` = seconds; misheard words noted below).

Misheard: "loot chute" = the payout chute; "skill stop" as said; "Tarzan Lanier" = (his own lamp, irrelevant);
"heal-out token" = an arcade token; "super duper" = (a cover).

## The machine
A **Silver Falls** single-player quarter pusher (made in Taiwan), two tiers, glass front, a back-lit translite
marquee (changeable insert), side lights with switches inside.

## Mechanics, with times
- **Coin entry (332–450 s):** a chrome coin mechanism that **slides left/right** along a slot in the top panel
  (330–345 s) — the player aims where the coin drops. **Quarters only**: a bigger token won't go in (404–420 s);
  a penny or a dime goes in but is **lost** to the cash box (425–450 s, 548 s). Coins fall onto the upper tier.
- **Skill stop (350 s, 775 s):** a setting, on/off ("right now it has a skill stop, I have it off"); buttons inside.
  Treat as an option, default off.
- **Two tiers (20–24 s, 360–404 s, 596–612 s):** the back **pusher deck moves back and forth** under a fixed
  back wall, shoving coins forward off its front onto the **lower fixed shelf**; the shelf's heap is pushed toward
  the **front drop edge**.
- **Motor (600–660 s, 848–912 s):** "just a motor underneath; it goes in circles and pushes it back and forth" — a
  gear motor with a crank arm, running continuously, fairly loud. Measure the stroke period and length from the
  video at 30 fps where the deck is visible moving (try 176–200 s, 360–404 s, 596–612 s).
- **The lip (250–300 s):** an **adjustable lip/ridge at the front edge** (Phillips screws, up/down): coins look
  about to fall and slide back — the house's main control on payout. He lowered it.
- **Side holes / inserts (200–250 s, 300 s):** gaps at both sides of the shelf; coins pushed into them fall to the
  **house bucket** ("this is how they make money… all of this is their profit"). Every arcade pusher has them.
- **Payout ("loot") chute (50–75 s):** coins over the front edge fall into a chute behind a finger guard into the
  player's cup ("grab your loot down here", 375 s).
- **Tilt (100–200 s, 675–700 s):** a hanging weight completes a circuit when the cabinet is shaken → an **alarm for
  3 s** and a **flipper gate** in the chute swings over so falling coins go to the **house** instead of the cup
  (a loud clunk). Fail-safe: with the power off the gate rests on the house side.
- **Power and the rest (500–900 s):** PC-style PSU (5 V/12 V), power strip, fan; lights on two outlets, motor on one.
- **Payout examples:** 370–380 s: a few quarters dropped, one falls into the cup ("we got a quarter!").

## What Pocket Change has
In the mall it's **COIN COMET** (`tools/stores/pocket_change/pusher.gd`): Steven's 1995 Pocket Change machine
was a 3-player pusher played from both sides (like Crompton's Silver Skis) → 6 positions, each with the same
two-tier mechanics. Use the Silver Falls mechanics, COIN COMET's look.
