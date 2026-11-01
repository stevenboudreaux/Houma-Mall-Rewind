# wsH: load phases and frame times, live (Demo 46) vs this branch (Nov 1, 2026)

`tools/qa/frametimes.py`, headless Chromium 153 on SwiftShader (CPU rendering, 4-core cloud box), 480x270, packs served from localhost (download time ~0). Times in ms from navigation start. "setup" = `npcs: grid` printed (wing set up; with the warm-up, after it); "control" = first frame after setup with the card gone. Desktop pack runs keep the desktop pack although SwiftShader lacks BPTC (`--noflip`; Godot then decodes the BPTC lightmap on the CPU). 2026 wings have no shopper node: control = card lifted.

## Frame times, first 30 s after control (mobile pack, 2 runs each)

| Run | Wing | control s | frames in 30 s | median ms | p95 ms | max ms | frames > 3x median | frames > 500 ms | ms above median (sum) |
|---|---|---|---|---|---|---|---|---|---|
| live #1 | 1 | 12.3 | 19 | 973.3 | 16103.2 | 16103.2 | 1 | 12 | 17242.0 |
| live #2 | 1 | 9.1 | 17 | 933.8 | 13513.1 | 13513.1 | 2 | 10 | 19394.0 |
| new-nowarm #1 | 1 | 11.0 | 19 | 975.1 | 13141.4 | 13141.4 | 2 | 12 | 17742.0 |
| new-nowarm #2 | 1 | 8.2 | 20 | 901.0 | 11432.4 | 11432.4 | 2 | 12 | 17228.0 |
| new-warm #1 | 1 | 27.7 | 26 | 950.2 | 1992.5 | 2121 | 0 | 21 | 5718.0 |
| new-warm #2 | 1 | 24.0 | 26 | 979.1 | 1689.9 | 2127.8 | 0 | 22 | 3886.0 |
| live #1 | 2 | 18.4 | 13 | 278.4 | 23902.9 | 23902.9 | 3 | 4 | 27071.0 |
| live #2 | 2 | 13.6 | 14 | 176.9 | 23697.3 | 23697.3 | 4 | 4 | 27746.0 |
| new-nowarm #1 | 2 | 17.9 | 14 | 204.8 | 23267.6 | 23267.6 | 4 | 4 | 26824.0 |
| new-nowarm #2 | 2 | 20.3 | 18 | 271.1 | 13365.9 | 13365.9 | 8 | 8 | 23801.0 |
| new-warm #1 | 2 | 43.4 | 20 | 1462.4 | 3359.7 | 3359.7 | 0 | 13 | 8739.0 |
| new-warm #2 | 2 | 35.2 | 19 | 1562.5 | 4756.9 | 4756.9 | 1 | 14 | 7449.0 |

## Load phases, one run each (3 s after control)

| Wing | Pack | Build | wasm ms | pack ms | scene + setup ms (npcs line) | card lifted ms | control ms |
|---|---|---|---|---|---|---|---|
| 1 | mobile | live | 530 | 768 | 5244 | 11934 | 11935 |
| 1 | mobile | new | 539 | 795 | 24904 | 25061 | 25064 |
| 1 | desktop | live | 462 | 854 | 4577 | 11298 | 11299 |
| 1 | desktop | new | 613 | 842 | 27585 | 27804 | 27812 |
| 2 | mobile | live | 651 | 929 | 5221 | 18478 | 18479 |
| 2 | mobile | new | 520 | 765 | 42200 | 44448 | 44451 |
| 2 | desktop | live | 574 | 785 | 4849 | 17858 | 17859 |
| 2 | desktop | new | 548 | 796 | 40190 | 42228 | 42233 |
| 3 | mobile | live | 575 | 685 | 10221 | 12156 | 12158 |
| 3 | mobile | new | 567 | 595 | 2315 | 4277 | 4280 |
| 3 | desktop | live | 558 | 659 | 10512 | 12176 | 12177 |
| 3 | desktop | new | 610 | 713 | 2451 | 4095 | 4098 |
| 1y26 | mobile | live | 523 | 692 | 5657 | 5657 | 5657 |
| 1y26 | mobile | new | 579 | 697 | 5615 | 5615 | 5615 |
| 1y26 | desktop | live | 448 | 632 | 5685 | 5685 | 5685 |
| 1y26 | desktop | new | 538 | 655 | 5498 | 5498 | 5498 |
| 2y26 | mobile | live | 568 | 727 | 13964 | 13964 | 13964 |
| 2y26 | mobile | new | 551 | 735 | 14429 | 14429 | 14429 |
| 2y26 | desktop | live | 657 | 756 | 13647 | 13647 | 13647 |
| 2y26 | desktop | new | 595 | 830 | 14354 | 14354 | 14354 |

## Game log lines (load: / npc_warmup / npcs:)

- live-w1m-ft: npcs: grid 402x402, 4963 open cells, 16 stores, 23 windows, 24 benches, 11 crowd skins, 2 pairs
- live-w1m-ft: npcs: grid 402x402, 4963 open cells, 16 stores, 23 windows, 24 benches, 11 crowd skins, 2 pairs
- live-w2m-ft: npcs: 5 of 42 cabinets have players; npcs: grid 402x402, 3820 open cells, 17 stores, 23 windows, 12 benches, 6 crowd skins, 2 pairs
- live-w2m-ft: npcs: 5 of 42 cabinets have players; npcs: grid 402x402, 3820 open cells, 17 stores, 23 windows, 12 benches, 6 crowd skins, 2 pairs
- new-w1m-nowarm-ft: load: npcs grid+places 189 ms; load: npcs roles spawned 279 ms after _ready; npcs: grid 402x402, 4963 open cells, 16 stores, 23 windows, 24 benches, 11 crowd skins, 2 pairs
- new-w1m-nowarm-ft: load: npcs grid+places 189 ms; load: npcs roles spawned 301 ms after _ready; npcs: grid 402x402, 4963 open cells, 16 stores, 23 windows, 24 benches, 11 crowd skins, 2 pairs
- new-w1m-warm-ft: load: npcs grid+places 197 ms; npc_warmup: 19 skins + anims in 23867 ms (load 127, bodies 7081, draw 16659); load: npcs roles spawned 24093 ms after _ready; npcs: grid 402x402, 4963 open cells, 16 stores, 23 windows, 24 benches, 11 crowd skins, 2 pairs
- new-w1m-warm-ft: load: npcs grid+places 226 ms; npc_warmup: 19 skins + anims in 19955 ms (load 164, bodies 4332, draw 15459); load: npcs roles spawned 20197 ms after _ready; npcs: grid 402x402, 4963 open cells, 16 stores, 23 windows, 24 benches, 11 crowd skins, 2 pairs
- new-w2m-nowarm-ft: load: npcs grid+places 201 ms; npcs: 5 of 42 cabinets have players; load: npcs roles spawned 264 ms after _ready; npcs: grid 402x402, 3820 open cells, 17 stores, 23 windows, 12 benches, 6 crowd skins, 2 pairs
- new-w2m-nowarm-ft: load: npcs grid+places 193 ms; npcs: 5 of 42 cabinets have players; load: npcs roles spawned 251 ms after _ready; npcs: grid 402x402, 3820 open cells, 17 stores, 23 windows, 12 benches, 6 crowd skins, 2 pairs
- new-w2m-warm-ft: load: npcs grid+places 189 ms; npc_warmup: 19 skins + anims in 36953 ms (load 282, bodies 12753, draw 23918); npcs: 5 of 42 cabinets have players; load: npcs roles spawned 37174 ms after _ready; npcs: grid 402x402, 3820 open cells, 17 stores, 23 windows, 12 benches, 6 crowd skins, 2 pairs
- new-w2m-warm-ft: load: npcs grid+places 187 ms; npc_warmup: 19 skins + anims in 30721 ms (load 303, bodies 15714, draw 14704); npcs: 5 of 42 cabinets have players; load: npcs roles spawned 30945 ms after _ready; npcs: grid 402x402, 3820 open cells, 17 stores, 23 windows, 12 benches, 6 crowd skins, 2 pairs
- final-w1-mobile (final export): control 26055 ms; load: npcs grid+places 183 ms; npc_warmup: 19 skins + anims in 22304 ms (load 124, bodies 6810, draw 15370); load: npcs roles spawned 22505 ms after _ready; npcs: grid 402x402, 4963 open cells, 16 stores, 23 windows, 24 benches, 11 crowd skins, 2 pairs
- final-w3-mobile (final export): control 4249 ms; npcs: grid 0x0, no shopper skins in this pack

## Native (Godot 4.7.2 headless, same box)

- Wing 1 scene start to `npcs: grid`: ~1.1-1.2 s; grid+places old 848 ms, new 70-105 ms (wsH-npcgrid.md).
- Decoding Wing 1's textures (`ResourceLoader.load`, cache off): 152 WebP-lossless 442 ms, 51 ETC2 13 ms.
