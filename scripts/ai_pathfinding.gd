extends Node

func get_desired_direction(enemy: CharacterBody3D, player_history: Array) -> Vector3:
	if player_history.size() > 0:
		var delayed_position: Vector3 = player_history[0]
		enemy.navigation_agent_3d.target_position = delayed_position
		var next_path_position: Vector3 = enemy.navigation_agent_3d.get_next_path_position()
		var target_direction: Vector3 = (next_path_position - enemy.global_position).normalized()
		return target_direction
	return Vector3.ZERO
