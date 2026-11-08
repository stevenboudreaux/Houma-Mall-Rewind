extends MultiMeshInstance3D
## Workstream FOOD3D (Nov 8 2026; design/godot-blender-pipeline.md "FOOD3D"): many copies of one Blender piece
## (cookies on the cookie case's trays, corn dogs in the warmer, cups of nuggets, the mall's trash cans), placed
## by the wing build (tools/stores/food3d/kit.gd multi(), tools/build_mall.gd trash cans).
## The build runs headless on Godot's dummy renderer, which does not keep a MultiMesh's instance transforms, so
## a MultiMesh built there saves every copy at the origin. This node saves the piece and the transforms as plain
## properties instead and builds its MultiMesh when it enters the tree.

## The piece to repeat (a mesh from a kit .glb, embedded in the scene).
@export var piece: Mesh
## One transform per copy, in this node's parent space.
@export var xforms: Array[Transform3D] = []

func _ready() -> void:
	if piece == null or xforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = piece
	mm.instance_count = xforms.size()
	for i in xforms.size():
		mm.set_instance_transform(i, xforms[i])
	multimesh = mm
