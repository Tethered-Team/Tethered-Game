@tool
extends Node3D

@export_node_path("Node3D") var target_spawn_point_path: NodePath
@onready var mesh_instance: MeshInstance3D = null

func _ready():
	_update_visual()

func _notification(what):
	if what == NOTIFICATION_ENTER_TREE or what == NOTIFICATION_READY:
		_update_visual()

func _process(_delta):
	if Engine.is_editor_hint():
		_update_visual()

func _update_visual():
	var target = get_node_or_null(target_spawn_point_path)
	if target == null:
		return

	# Try to access a 'spawn_radius' property from the target node
	if not target.has_method("spawn_radius"):
		return

	var radius = target.spawn_radius

	if mesh_instance == null:
		mesh_instance = MeshInstance3D.new()
		mesh_instance.name = "RadiusMesh"
		mesh_instance.visible = true
		mesh_instance.visible_in_game = false
		mesh_instance.editor_only = true
		add_child(mesh_instance)

	var sphere = SphereMesh.new()
	sphere.radius = radius
	sphere.height = 0.1
	sphere.radial_segments = 32
	sphere.rings = 16

	# Optional: Transparent Material
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0, 0, 0.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	sphere.material = mat

	mesh_instance.mesh = sphere
