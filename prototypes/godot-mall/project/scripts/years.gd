## The two years as the player reads them (ws/items, Steven Nov 4 2026; design/godot-2026-year.md "The years'
## names"): the 1995 mall is shown as "1990s" (the rule is the decade now: virtual pets stay), 2026 as "2026".
## Internal ids, scene names, storage keys and URLs keep 1995 (wing1.tscn, ?year=, mall-state-1995 ...).
## Every menu, prompt, card and the directory say Years.label(year), never the number.
extends RefCounted

const LABELS := {1995: "1990s", 2026: "2026"}

## The player-facing name of year y (1995 -> "1990s"); another year is shown as its number.
static func label(y) -> String:
	var n := int(str(y)) if str(y).is_valid_int() else 0
	return str(LABELS.get(n, str(y)))

## The other of the two years (1995 <-> 2026).
static func other(y) -> int:
	return 2026 if int(y) != 2026 else 1995
