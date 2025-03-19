extends Node

@export var dodge_toward_mouse: bool = true
@export var dash_speed: float = 25.0
@export var run_speed: float = 10.0

@export var dash_duration: float = 0.1
@export var dash_cooldown: float = 1.0


@export var time_between_dashes: float = 0.25
@export var dash_max: int = 3


var is_dashing: bool = false
var is_running: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_between_timer: float = 0.0
var dash_count: int = dash_max
var dash_vector: Vector3

func handle_dash(character: CharacterBody3D, delta: float):
	# If already in dash state, update its timer/velocity.
	if is_dashing:
		continue_dash(character, delta)
		# When dash timer ends, transition into running if dash is still held.
		if dash_timer <= 0:
			if InputHandler.is_dash_held():
				start_running(character)
			else:
				end_dash(character)
		# Also end dash immediately if dash button is released before timer expires.
		elif InputHandler.is_dash_released():
			end_dash(character)
			
	# If already in running state, delegate handling to continue_running.
	elif is_running:
		continue_running(character)
			
	# If not in any dash state, check to start a dash.
	else:
		if InputHandler.is_dash_pressed() and character.is_on_floor() and dash_count > 0 and dash_between_timer <= 0:
			start_dash(character)
			
	# Update cooldown if neither dashing nor running.
	dash_cooldown_timer = clampf(dash_cooldown_timer - delta, 0, dash_cooldown)
	dash_between_timer = clampf(dash_between_timer - delta, 0, time_between_dashes)

	if dash_cooldown_timer == 0:
		dash_count = dash_max
		
	print("Dash pressed: ", InputHandler.is_dash_pressed(), " Dashing: ", is_dashing, " Running: ", is_running)

func start_dash(character: CharacterBody3D):
	is_dashing = true
	is_running = false
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown
	dash_count -= 1
	
	# Ignore "Dash Passable" obstacles but keep colliding with others.
	character.set_collision_mask_value(2, false)  # Ignore Layer 2 (Dash Passable)
	character.set_collision_mask_value(3, true)   # Keep colliding with Layer 3 (Dash Blocking)
	character.set_collision_mask_value(4, true)   # Keep colliding with Ground (Layer 4)

	# Set dash direction.
	if dodge_toward_mouse and InputHandler.current_input_scheme == InputHandler.INPUT_SCHEMES.KBM:
		character.velocity = character.global_position.direction_to(InputHandler.get_mouse_direction(character)) * dash_speed
	else:
		character.velocity = character.global_transform.basis.z.normalized() * dash_speed

	dash_vector = character.velocity
	print("Start Dash")

func continue_dash(character: CharacterBody3D, delta: float):
	if is_dashing:
		character.velocity = dash_vector
		# Optionally keep Y velocity zero during dash.
		character.velocity.y = 0
		dash_timer = clampf(dash_timer - delta, 0, dash_duration)
		#print("Continuing dash, timer: ", dash_timer)

func continue_running(character: CharacterBody3D):
	# Check if dash button is still held; otherwise, end running.
	if not InputHandler.is_dash_held():
		end_dash(character)
	else:
		# Continue running using the same dash direction.
		character.velocity = character.velocity.normalized() * run_speed

func start_running(character: CharacterBody3D):
	is_running = true
	is_dashing = false
	
	character.set_collision_mask_value(2, true)  # Re-enable Layer 2 (Dash Passable)
	character.set_collision_mask_value(3, true)  # Keep Layer 3 (Dash Blocking) active
	character.set_collision_mask_value(4, true)  # Keep Ground (Layer 4) active

	# Use the same dash direction when transitioning to running.
	character.velocity = dash_vector.normalized() * run_speed
	print("Start Running")

func end_dash(character: CharacterBody3D):
	is_dashing = false
	is_running = false
	dash_between_timer = time_between_dashes
	
	# Restore collision layers to normal.
	character.set_collision_mask_value(2, true)  # Re-enable Layer 2 (Dash Passable)
	character.set_collision_mask_value(3, true)  # Keep Layer 3 (Dash Blocking) active
	character.set_collision_mask_value(4, true)  # Keep Ground (Layer 4) active
	print("End Dash")
