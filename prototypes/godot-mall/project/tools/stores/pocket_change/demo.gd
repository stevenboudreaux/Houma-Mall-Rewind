## A minimal prop module showing the Pocket Change prop contract
## (tools/stores/pocket_change/README.md): a plain box cabinet with a lit
## marquee, a screen and a control panel. Not placed in the store; the real
## machines follow this pattern.
##   tools/qa/preview.sh demo /home/claude/houma-mall-rewind/.scratch/preview/demo "0,1.5,2.5,0,-8;1.8,1.4,1.8,40,-10"

const W = 0.66   # width (along the player's right)
const D = 0.80   # depth (along f, away from the player)
const H = 1.85

## Footprint (width, depth) in metres, for the store's layout.
static func footprint(_opts = {}):
	return Vector2(W, D)

## The machine's frame: local x = player's right, y = up, z = into the machine (along f).
static func X(o, f):
	return Transform3D(Basis(f.cross(Vector3.UP), Vector3.UP, f), o)

## Builds one machine. The player stands at `o` (floor, centre of the machine's front
## edge) facing `f` (horizontal unit vector); the machine fills x in [-W/2, W/2], z in [0, D].
static func build(b, g, o, f, opts = {}):
	var xf = X(o, f)
	var r = f.cross(Vector3.UP)
	# cabinet body (static: it is lightmapped)
	b.box(g, "pc_demo_body", Vector3(0, H * 0.5, D * 0.5), Vector3(W, H, D), xf)
	# the screen: an explicit-UV quad 1 cm proud of the front, so the whole picture shows once
	var s0 = xf * Vector3(-0.25, 1.15, -0.01)
	var s1 = xf * Vector3(0.25, 1.15, -0.01)
	var s2 = xf * Vector3(0.25, 1.55, -0.01)
	var s3 = xf * Vector3(-0.25, 1.55, -0.01)
	b.quad(g, "pc_demo_screen", [s0, s1, s2, s3], -f, [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)])
	# small parts (buttons) are dynamic: they need no lightmap texels
	b.cur_color = Color("#d02020")
	for i in 3:
		b.cyl(g, "vcolor", xf * Vector3(-0.1 + 0.1 * i, 0.95, -0.12), 0.018, 0.018, 0.015, 10, true, false, true)
	b.cur_color = Color.WHITE
	# obstacle for the walk grid: an axis-aligned rect around the footprint
	var c0 = xf * Vector3(-W * 0.5, 0, 0)
	var c1 = xf * Vector3(W * 0.5, 0, D)
	b.obst(["rect", min(c0.x, c1.x), min(c0.z, c1.z), max(c0.x, c1.x), max(c0.z, c1.z)])

## Material "pc_demo_<key>": fill m and return true, or return false for an unknown key.
static func fill_mat(m, key, b):
	match key:
		"body":
			m.albedo_color = Color("#22222a"); m.roughness = 0.6
		"screen":
			m.albedo_color = Color.BLACK
			m.emission_enabled = true; m.emission = Color("#3a8cff"); m.emission_energy_multiplier = 1.5
			m.set_meta("e_day", 1.5); m.set_meta("e_night", 1.5)
		_:
			return false
	return true
