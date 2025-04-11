extends Node

# List of enemies currently registered as available targets.

func get_target_near_position(origin: Vector3, radius: float = 5.0) -> Node3D:
	var target: Node3D = null
	var radius_sq = radius * radius
	for enemy in GlobalReferences.enemy_manager.active_enemies:
		var enemy_pos = enemy.global_transform.origin
		var distance_sq = enemy_pos.distance_squared_to(origin)
		if distance_sq < radius_sq:
			if target == null:
				target = enemy
			elif distance_sq < target.global_transform.origin.distance_squared_to(origin):
				target = enemy
	return target

func get_closest_target(from_position: Vector3) -> Node3D:
	return get_target_near_position(from_position, INF)

func get_target_at_mouse_position(origin: Node3D = GlobalReferences.player) -> Node3D:
	var mouse_pos = InputHandler.get_mouse_position(origin)
	return get_target_near_position(mouse_pos)

func get_closest_target_in_cone(from_position: Vector3, direction: Vector3, max_distance: float = 5.0, cone_angle: float = 30.0) -> Node3D:
	var closest: Node3D = null
	var min_distance = INF
	var norm_direction = direction.normalized()
	var cos_threshold = cos(deg_to_rad(cone_angle))  # cone_angle is in degrees
	for enemy in GlobalReferences.enemy_manager.active_enemies:
		var to_enemy = (enemy.global_transform.origin - from_position).normalized()
		if norm_direction.dot(to_enemy) >= cos_threshold:
			var d_sq = enemy.global_transform.origin.distance_squared_to(from_position)
			# Check if within max_distance.
			if d_sq > max_distance * max_distance:
				continue
			# Compare squared distances.
			if d_sq < min_distance * min_distance:
				min_distance = d_sq
				closest = enemy
	return closest

func get_target_in_mouse_direction(origin: Node3D = GlobalReferences.player, distance: float = 5.0, cone_angle: float = 30.0) -> Node3D:

	var from_position = origin.global_transform.origin
	var direction = InputHandler.get_mouse_direction(origin)

	return get_closest_target_in_cone(from_position, direction, distance, cone_angle)
