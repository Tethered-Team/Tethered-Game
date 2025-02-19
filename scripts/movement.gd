extends Node

@export var speed: float = 5.0
@export var rotation_speed: float = 5.0
@export var gravity: float = 9.8

var gravity_current: float = 0.0


func apply_rotation(player: CharacterBody3D, move_vector: Vector3):
	if move_vector.length() > 0.01:
		player.look_at(player.global_position - player.velocity, Vector3.UP)

func apply_movement(player: CharacterBody3D, move_vector: Vector3, delta: float, is_grounded: bool):
	
	# Apply gravity
	if is_grounded:
		gravity_current = 0
	else:
		gravity_current -= gravity * delta

	# Move player
	if move_vector.length() > 0.01:
		player.velocity.x = move_vector.x * speed
		player.velocity.z = move_vector.z * speed
	else:
		player.velocity.x = 0
		player.velocity.z = 0

	# Apply gravity
	player.velocity.y = gravity_current
	#print("Move Vector: ", move_vector, " Velocity: ", player.velocity)
