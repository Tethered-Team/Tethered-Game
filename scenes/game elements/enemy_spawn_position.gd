@tool
extends Node3D

@export var spawn_radius: float = 5.0:
	set(value):
		spawn_radius = value
		_update_visualizer()

@export var show_radius_visualizer: bool = false:
	set(value):
		show_radius_visualizer = value
		_update_visualizer()

func _ready():
	if Engine.is_editor_hint():
		# Remove any existing duplicated visualizers
		for child in get_children():
			if child.name == "RadiusVisualizer":
				child.queue_free()
	else:
		var existing = get_node_or_null("RadiusVisualizer")
		if existing:
			existing.queue_free()

	

func _update_visualizer():
	if not Engine.is_editor_hint():
		return

	var existing = get_node_or_null("RadiusVisualizer")
	if show_radius_visualizer:
		if existing == null:
			var visualizer = MeshInstance3D.new()
			visualizer.name = "RadiusVisualizer"
			visualizer.visible = true
			add_child(visualizer)
			visualizer.owner = null  # Prevents it from being saved/duplicated with the scene.

			var sphere := SphereMesh.new()
			sphere.radius = spawn_radius
			sphere.height = 0.1
			sphere.radial_segments = 32
			sphere.rings = 16

			var mat := StandardMaterial3D.new()
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.albedo_color = Color(1, 0, 0, 0.2)
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.flags_transparent = true
			sphere.material = mat

			visualizer.mesh = sphere
		else:
			if existing.mesh is SphereMesh:
				existing.mesh.radius = spawn_radius
	else:
		if existing:
			existing.queue_free()

func can_spawn_size(size: float) -> bool:
	return size <= spawn_radius

func get_valid_position(radius: float) -> Vector3:
	return deferred_valid_position(radius)


func deferred_valid_position(radius: float) -> Vector3:
	var attempts = 10
	var world = get_world_3d()
	if world == null:
		push_error("World is null in get_valid_position()")
		return Vector3.ZERO
	var space_state = world.direct_space_state
	if space_state == null:
		push_error("Direct space state is null in get_valid_position()")
		return Vector3.ZERO
	while attempts > 0:
		# Generate a random position within the given radius.
		var random_dir = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
		if random_dir == Vector3.ZERO:
			random_dir = Vector3(1, 0, 0)
		random_dir = random_dir.normalized()
		var random_pos = global_transform.origin + random_dir * randf_range(0, radius)
		
		# Create a new point query parameter
		var query = PhysicsPointQueryParameters3D.new()
		query.position = random_pos
		var result = space_state.intersect_point(query)
		if result.size() == 0:
			return random_pos
		attempts -= 1
	return Vector3.ZERO
