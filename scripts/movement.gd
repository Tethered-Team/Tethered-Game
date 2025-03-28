extends Node

# Movement exports & variables.
@export var speed: float = 5.0
@export var rotation_speed: float = 10.0
@export var gravity: float = 9.8
var gravity_current: float = 0.0

# Lunge exports & variables.
@export var default_lunge_distance: float = 2.0    # Default lunge distance.
@export var default_lunge_duration: float = 0.05      # Default duration in seconds to finish the lunge.
var is_lunging: bool = false                         # Whether a lunge is active.
var lunge_start_position: Vector3 = Vector3.ZERO     # Starting position when lunge begins.
var current_lunge_distance: float = 0.0              # Distance to travel for the current lunge.
var lunge_duration: float = 0.0                      # Total time to complete the lunge.
var lunge_elapsed: float = 0.0                       # Time elapsed since lunge started.
var lunge_direction: Vector3 = Vector3.ZERO          # Direction of the lunge.
var final_lunge_speed: float = 0.0                   # Calculated speed, = distance/duration.

#-----------------------------
# Movement Functions
#-----------------------------

func apply_smooth_rotation(character: CharacterBody3D, move_vector: Vector3, delta: float, rot_speed: float = rotation_speed):
	if move_vector.length() > 0.01 or character.is_dashing:
		# Flatten the move_vector so that y is zero.
		var flat_move = Vector3(move_vector.x, 0, move_vector.z)
		if flat_move.length() == 0:
			return
		var target_direction = flat_move.normalized()
		var target_basis = Basis.looking_at(-target_direction, Vector3.UP)
		character.global_transform.basis = character.global_transform.basis.slerp(target_basis, delta * rot_speed)

func apply_rotation(character: CharacterBody3D, move_vector: Vector3):
	if move_vector.length() > 0.01 or character.is_dashing:
		character.look_at(character.global_position - Vector3(move_vector.x, 0, move_vector.z), Vector3.UP)

# Common function to apply gravity and force the character to remain upright
func apply_common_movement(character: CharacterBody3D, delta: float, base_velocity: Vector3) -> void:
	# Gravity handling.
	if character.is_on_floor():
		gravity_current = 0
	else:
		gravity_current -= gravity * delta
	base_velocity.y = gravity_current
	
	# Apply the velocity.
	character.velocity = base_velocity
	
	# Force the character to remain upright.
	var current_transform = character.global_transform
	var current_euler = current_transform.basis.get_euler()
	current_euler.x = 0
	current_euler.z = 0
	current_transform.basis = Basis.from_euler(current_euler)
	character.global_transform = current_transform

# For the player: direct movement based on input.
func apply_player_movement(character: CharacterBody3D, input_vector: Vector3, delta: float, move_speed: float = speed) -> void:
	# Assume input_vector is already normalized and represents intended movement direction.
	var move_velocity = Vector3.ZERO
	if input_vector.length() > 0.01:
		move_velocity.x = input_vector.x * move_speed
		move_velocity.z = input_vector.z * move_speed
	# Call the common function to add gravity and enforce upright orientation.
	apply_common_movement(character, delta, move_velocity)

# For AI/enemy: movement based on AI target plus separation force.
func apply_ai_movement(character: CharacterBody3D, target_direction: Vector3, delta: float, separation_distance: float, minimum_speed: float, move_speed: float) -> void:
	var desired_velocity = Vector3.ZERO
	var neighbors = get_tree().get_nodes_in_group("Enemies")

	if target_direction.length() > 0.1:
		desired_velocity.x = target_direction.x * move_speed
		desired_velocity.z = target_direction.z * move_speed
	else:
		desired_velocity.x = 0
		desired_velocity.z = 0
	desired_velocity.y = gravity_current
	
	# Add separation force to avoid crowding.
	var separation_force = get_separation_force(character, neighbors, separation_distance)
	var final_velocity = desired_velocity + separation_force

	# If the final velocity is too small (i.e. forces cancel each other out), stop moving.

	if final_velocity.length() < minimum_speed:
		final_velocity = Vector3.ZERO
	
	apply_common_movement(character, delta, final_velocity)

#-----------------------------
# Lunge Functions
#-----------------------------
# handle_lunge() should be called each physics frame.
# If a lunge is not active, it starts one using the optional custom distance and duration.
# Otherwise, it continues the active lunge.
func handle_lunge(character: CharacterBody3D, delta: float, custom_distance: float = 0.0, custom_duration: float = 0.0) -> void:
	# End lunge if an invalid distance is provided.

	if not is_lunging:
		if custom_distance <= 0.01:
			end_lunge(character)
		else:
			start_lunge(character, custom_distance, custom_duration)
	else:
		continue_lunge(character, delta)

# Starts the lunge. If custom values are zero, defaults are used.
func start_lunge(character: CharacterBody3D, custom_distance: float = 0.0, custom_duration: float = 0.0) -> void:
	is_lunging = true
	lunge_start_position = character.global_transform.origin
	
	if custom_distance != 0.0:
		current_lunge_distance = custom_distance
	else:
		current_lunge_distance = default_lunge_distance
	
	if custom_duration != 0.0:
		lunge_duration = custom_duration
	else:
		lunge_duration = default_lunge_duration
	
	# Calculate speed so that the character covers the distance in the given duration.
	final_lunge_speed = current_lunge_distance / lunge_duration
	
	# Use the character's current forward direction.
	lunge_direction = character.global_transform.basis.z.normalized()
	
	# Immediately set velocity based on computed speed.
	character.velocity = lunge_direction * final_lunge_speed
	character.velocity.y = 0  # Force horizontal lunge.
	
	# Reset the elapsed timer.
	lunge_elapsed = 0.0
	
	#print("Lunge started. Direction:", lunge_direction, "Distance:", current_lunge_distance, "Duration:", lunge_duration, "Speed:", final_lunge_speed)

# Continues the lunge, incrementing time and applying computed velocity.
func continue_lunge(character: CharacterBody3D, delta: float) -> void:
	# Update the elapsed time.
	lunge_elapsed += delta
	
	# Continue applying constant velocity.
	character.velocity = lunge_direction * final_lunge_speed
	character.velocity.y = 0
	
	# If the elapsed time exceeds or meets the duration, finalize the lunge.
	if lunge_elapsed >= lunge_duration:
		# Snap the character to the exact target position.
		character.global_transform.origin = lunge_start_position + lunge_direction * current_lunge_distance
		end_lunge(character)

# Ends the lunge and resets its state.
func end_lunge(character: CharacterBody3D) -> void:
	is_lunging = false
	character.velocity = Vector3.ZERO
	#print("Lunge ended")
## Function: get_separation_force
## Purpose: Compute a separation force to avoid crowding with nearby characters.
## Algorithm: For each nearby character, compute a repulsive force inversely proportional to the distance.
##            Average the forces and scale by the desired separation distance.
## Parameters:
##   character (CharacterBody3D): The character to compute separation for.
##   neighbors (Array[Node]): An array of nearby characters to avoid.
##   desired_separation (float): The desired separation distance.
## Returns: Vector3.
func get_separation_force(character: CharacterBody3D, neighbors: Array[Node], desired_separation: float) -> Vector3:
	var force = Vector3.ZERO
	var count = 0
	# Loop through each neighbor to compute a repulsive force.
	for neighbor in neighbors:
		# Compute difference vector from neighbor to the current character.
		var diff = character.global_transform.origin - neighbor.global_transform.origin
		diff.y = 0  # Ignore vertical differences; consider horizontal separation only.
		var distance = diff.length()
		# If the neighbor is too close and not the same position:
		if distance < desired_separation and distance > 0:
			# Add a force inversely proportional to the distance (closer means more push).
			force += diff.normalized() / distance
			count += 1
	# If any neighbors contributed, average the forces.
	if count > 0:
		force /= count
	# Scale the averaged force by the desired separation to adjust overall strength.
	return force * desired_separation


## Function: reset
## Purpose: Reset the character's state and position.
## Parameters: None.
## Returns: void.
func reset(character: CharacterBody3D) -> void:
	# Reset the character's state.
	is_lunging = false
	gravity_current = 0.0
	character.velocity = Vector3.ZERO
	character.global_transform.origin = Vector3.ZERO
	character.global_transform.basis = Basis.IDENTITY
