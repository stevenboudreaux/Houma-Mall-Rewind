## Preview helper: the games, inc. machines in a row (tools/qa/preview.sh res://tools/stores/games_inc/machines/gallery.gd
## <out> "<cams>" '{"set": 0}' lit). Not used by the build.

const MK = "res://tools/stores/games_inc/machines/"
const SETS = [
	[["claw", {"color": 0}], ["claw", {"color": 1}], ["claw", {"color": 2}], ["claw", {"color": 3}], ["claw", {"color": 4}], ["claw", {"color": 5}], ["merch", {"style": "white"}], ["merch", {"style": "yellow"}], ["merch", {"style": "push"}], ["merch", {"style": "purple"}]],
	[["pusher", {"style": 0}], ["pusher", {"style": 1}], ["dice", {}], ["gunbig", {}], ["racer", {"kind": "twin"}]],
	[["upright", {"style": "nerf"}], ["deal", {}], ["hoop", {}], ["ptower", {"style": 1}], ["ptower", {"style": 0}], ["upright", {"style": "mascot"}], ["upright", {"style": "crossy"}]],
	[["dome", {"style": 0}], ["dome", {"style": 1}], ["wheel", {}], ["dome", {"style": "arch"}], ["hockey", {"style": 0}], ["hockey", {"style": 1}]],
	[["alley", {"style": "alley"}], ["alley", {"style": "alley"}], ["alley", {"style": "eyes"}], ["alley", {"style": "quik"}], ["upright", {"style": "music"}], ["racer", {"kind": "bikes"}]],
	[["counter", {"kind": "case", "led": "#ff4fa8"}], ["counter", {"kind": "counter", "length": 2.0}], ["counter", {"kind": "kiosk"}], ["counter", {"kind": "prizewall", "length": 4.0, "sign_at": 0.0, "tvs": [1.5]}]],
]

static func preview(b, g, o, f, opts = {}):
	var row = SETS[int(opts.get("set", 0))]
	var tot = 0.0
	for it in row:
		tot += load(MK + it[0] + ".gd").footprint(it[1]).x + 0.3
	var x = -tot * 0.5
	for it in row:
		var M = load(MK + it[0] + ".gd")
		var w = M.footprint(it[1]).x
		M.build(b, g, Vector3(x + w * 0.5, 0, 0), Vector3.FORWARD, it[1])
		x += w + 0.3
