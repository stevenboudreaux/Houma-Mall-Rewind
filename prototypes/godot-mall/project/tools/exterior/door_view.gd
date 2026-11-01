## The view out through the mall's exit doors (Workstream F, Nov 1 2026; design/godot-exterior.md
## "Looking out"). Until Nov 1 the inside wings showed a 12 m vestibule stand-in past each exit
## (build_mall.gd doors_out: a concrete floor, a canopy, sodium lights) and then nothing but sky.
## Now three pictures of the real lot, captured from the outside (wing 3) by
## tools/exterior/capture_doors.gd, close that box: a front picture 12 m out and one each side,
## like three faces of a cube round the doorway, so from the doors the lot is exactly where it is
## outside and close enough from anywhere in the hall. The box is the doorway's width and 12 m
## deep, the same as the vestibule floor it stands on. The vestibule floor and canopy stay (the
## picture starts at the floor's far edge), so the wing's lightmap does not change.
##
## The pictures: one atlas per inside wing, year and lighting, tex/standin/door_w<wing>_<mode>.png
## (2026: y26_door_w<wing>_day.png; the night is a copy), one row per door in exterior.json's order
## for that wing: [front | left | right], 384 px each. Each face is an off-axis camera from the
## doorway framed exactly on its quad (faces() below), so the picture lines up from the doors. They live with the stand-in pictures on the godot-build branch; captured with
## `tools/capture_standin.sh 3` (and `3 2026`) after the outside is baked.
## Drawn unshaded at twice the brightness, captured at half exposure with a linear tone curve, the
## same deal as the stand-in (build_mall.gd standin_mat), and in a dynamic mesh: not in the bake.
const UP = Vector3.UP
const D := 12.0            # the front picture this far out: the vestibule floor's far edge (doors_out)
const TOP := 14.0          # the pictures' top above the floor (the canopy hides the rest)
const EYE := 1.62          # the player's eye height (player.gd): where the cameras stand
const SLOT := 384          # each face's picture, square in the atlas
const ATLAS_W := 1152      # one row per door: [front | left | right]

## The doors of `wing` in exterior.json's order (the atlas rows).
static func wing_doors(wing: int) -> Array:
	if not FileAccess.file_exists("res://exterior.json"):
		return []
	var ex = JSON.parse_string(FileAccess.get_file_as_string("res://exterior.json"))
	var out := []
	for d in ex.get("doors", []):
		if int(d.get("wing", 0)) == wing:
			out.append(d)
	return out

static func atlas_size(wing: int) -> Vector2i:
	return Vector2i(ATLAS_W, max(1, wing_doors(wing).size()) * SLOT)

static func atlas_path(wing: int, year: int, mode: String) -> String:
	if year == 2026:
		return "res://tex/standin/y26_door_w%d_day.png" % wing
	return "res://tex/standin/door_w%d_%s.png" % [wing, mode]

## The box's faces for one door, as seen from the door's middle at eye height looking out: each is
## [plane corners p0 (bottom left as seen) .. p3, the camera's look direction, its distance to the
## plane, the plane's horizontal extent x0..x1 in the camera's right-hand coordinate, y0..y1 above
## the floor]. mid: the doorway's middle on the floor, out: outward, W: the doorway's width.
## Used by build() here and by capture_doors.gd (which frames each camera on its face).
static func faces(mid: Vector3, out: Vector3, W: float) -> Array:
	var t = UP.cross(out)            # the viewer's right, looking out
	var h = W * 0.5
	var c = mid + out * D
	return [
		# front: across the doorway's width at D
		[[c - t * h, c + t * h, c + t * h + UP * TOP, c - t * h + UP * TOP], out, D, -h, h],
		# left: the plane at -t * h, depth 0..D; facing it, the right hand points back to the doors
		[[mid - t * h + out * D, mid - t * h, mid - t * h + UP * TOP, mid - t * h + out * D + UP * TOP], -t, h, -D, 0.0],
		# right: the plane at +t * h; facing it, the right hand points out
		[[mid + t * h, mid + t * h + out * D, mid + t * h + out * D + UP * TOP, mid + t * h + UP * TOP], t, h, 0.0, D]]

## Called from build_mall.gd's doors_out: the three pictures past this exit. e: the layout edge
## (store), a/b: the hall edge (the glass), n: into the hall.
static func build(b, e, a: Vector3, bb: Vector3, n: Vector3):
	var doors = wing_doors(int(b.WING))
	var row := -1
	for i in doors.size():
		if str(doors[i].store) == str(e.store):
			row = i
	if row < 0:
		return
	var A = atlas_size(int(b.WING))
	var mname = "doorpic_w%d" % int(b.WING)
	var v0 = float(row * SLOT) / A.y; var v1 = float(row * SLOT + SLOT) / A.y
	var F = faces((a + bb) * 0.5, -n, a.distance_to(bb))
	b.force_dyn = true
	for k in 3:
		var p = F[k][0]
		var u0 = float(k * SLOT) / A.x; var u1 = float(k * SLOT + SLOT) / A.x
		b.quad("doorpic", mname, p, -F[k][1], [Vector2(u0, v1), Vector2(u1, v1), Vector2(u1, v0), Vector2(u0, v0)])
	b.force_dyn = false

## The material (build_mall.gd mat() hands "doorpic_w<n>" names here).
static func mat(b, name: String) -> StandardMaterial3D:
	var wing = name.substr(9).to_int()
	var year = int(b.YEAR)
	var m = StandardMaterial3D.new()
	m.resource_name = name
	var night = atlas_path(wing, year, "night")
	var day = atlas_path(wing, year, "day")
	if FileAccess.file_exists(night):
		m.albedo_texture = load(night)
	else:
		# not captured yet: a pale sky-and-lot grey until tools/capture_standin.sh 3 has run (the game
		# loads the pictures by path at start, time_of_day.gd, so no rebuild is needed after a capture)
		var im = Image.create(4, 4, false, Image.FORMAT_RGB8)
		im.fill(Color(0.42, 0.45, 0.48))
		m.albedo_texture = ImageTexture.create_from_image(im)
	if year == 2026:
		night = day
	m.set_meta("tex_night", night)
	m.set_meta("tex_day", day)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.353, 1.353, 1.353)   # sRGB 1.353 = linear 2.0, as standin_mat
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
