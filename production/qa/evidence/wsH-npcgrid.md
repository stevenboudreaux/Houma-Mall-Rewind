# wsH: shopper path grid, old vs new build (Nov 1, 2026)

`scripts/npcs.gd` `_build_grid()`, native Godot 4.7.2 headless on the 4-core cloud box
(`godot --headless --path . res://wing<n>.tscn --quit-after 5`), with a temporary checksum print of the
grid's three outputs (open cells, wall distances, hall cells), removed afterwards.

| Wing | Old: obstacles / BFS / A* (ms) | Old grid+places (ms) | New grid+places (ms) | open cells | hash(open) | hash(wdist) | hall cells | hash(hall) |
|---|---|---|---|---|---|---|---|---|
| 1 | 506 / 125 / 14 | 848 | 70 | 4963 | 2562696766 | 3790302480 | 2627 | 3773934939 |
| 2 | — | 558 | 92 | 3820 | 347800936 | 3415602033 | 2141 | 2015778467 |

The hashes are the same before and after for both wings: the shoppers walk exactly the same grid.
(Old Wing 1 breakdown from a timed run; in the SwiftShader browser run the old grid took 1.4-1.5 s.)
