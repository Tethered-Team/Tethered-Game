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
		var target_direction = move_vector.normalized()
		var target_basis = Basis.looking_at(-target_direction, Vector3.UP)
		character.global_transform.basis = character.global_transform.basis.slerp(target_basis, delta * rot_speed)

func apply_rotation(character: CharacterBody3D, move_vector: Vector3):
	if move_vector.length() > 0.01 or character.is_dashing:
		character.look_at(character.global_position - Vector3(move_vector.x, 0, move_vector.z), Vector3.UP)

func apply_movement(character: CharacterBody3D, move_vector: Vector3, delta: float, is_grounded: bool):
	if is_grounded:
		gravity_current = 0
	else:
		gravity_current -= gravity * delta
	if move_vector.length() > 0.01:
		character.velocity.x = move_vector.x * speed
		character.velocity.z = move_vector.z * speed
	else:
		character.velocity.x = 0
		character.velocity.z = 0
	character.velocity.y = gravity_current

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
