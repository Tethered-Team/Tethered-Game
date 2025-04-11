extends Node

enum INPUT_SCHEMES {KBM, GAMEPAD, TOUCH}
var INPUT_SCHEME_NAMES: Array[String] = ["Keyboard & Mouse", "Gamepad", "Touch"]
var current_input_scheme: INPUT_SCHEMES = INPUT_SCHEMES.KBM

#signals
signal control_set_changed(control_set: String)
signal confirm_pressed

# Stores buffered inputs with expiration time
var input_buffer: Dictionary = {}
@export var buffer_time: float = 0.2  # Buffer duration (200ms)

var input_vector: Vector2 = Vector2.ZERO
var dash_pressed: bool = false
var dash_held: bool = false
var dash_released: bool = false

var aim_direction: Vector3 = Vector3.ZERO  # Aim direction (Mouse/Gamepad)
var aim_angle: float = 0.0  # Right stick angle
# Command queue
var command_queue: Array[Command] = []

# Register command objects
var attack_command: AttackCommand = AttackCommand.new()
#var dash_command: Command = DashCommand.new()

var camera: Camera3D = null

func set_camera(cam: Camera3D):
	camera = cam

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	emit_signal("control_set_changed", current_input_scheme)
	camera = get_viewport().get_camera_3d()
	
func handle_confirm_input():
	"""Handle confirm button press."""
	print("Confirm button pressed")
	emit_signal("confirm_pressed")

		


## Function: is_control_kbm
## Purpose: Check if the current input scheme is Keyboard & Mouse.
## Parameters: None.
## Returns: bool.
func is_control_kbm() -> bool:
	"""Return true if the current input scheme is Keyboard & Mouse."""
	return current_input_scheme == INPUT_SCHEMES.KBM

## Function: _input
## Purpose: Process input events by updating input scheme, reading movement/dash/aim inputs, and queuing commands.
## Parameters:
##   event (InputEvent): The input event to process.
## Returns: void.
func _input(event: InputEvent):
	"""Process an input event, update input scheme, movement input, dash and aiming, then queue commands."""
	# **Detect input scheme dynamically**
	if event is InputEventKey or event is InputEventMouseMotion or event is InputEventMouseButton:
		switch_input_scheme(INPUT_SCHEMES.KBM)
	elif event is InputEventJoypadMotion and abs(event.axis_value) > 0.2 or event is InputEventJoypadButton:
		switch_input_scheme(INPUT_SCHEMES.GAMEPAD)
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		switch_input_scheme(INPUT_SCHEMES.TOUCH)
	
	if Input.is_action_just_pressed("confirm"):
		handle_confirm_input()


	# **Handle movement input**
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# **Handle dash input**
	update_dash_input()

	# **Update aiming direction**
	update_aim_direction()
	
	# Handle attack and dash inputs
	process_commands()
	
	

## Function: update_dash_input
## Purpose: Update the dash input states and buffer dash action if pressed.
## Parameters: None.
## Returns: void.
func update_dash_input():
	"""Update dash input states and buffer dash input if just pressed."""
	dash_pressed = Input.is_action_just_pressed("dash")
	dash_held = Input.is_action_pressed("dash")
	dash_released = Input.is_action_just_released("dash")

	if dash_pressed:
		buffer_input("dash")  # Buffer the dash input for responsiveness

## Function: is_dash_pressed
## Purpose: Check if the dash action was pressed (or buffered).
## Parameters: None.
## Returns: bool.
func is_dash_pressed() -> bool:
	"""Return true if dash was pressed (or buffered)."""
	return dash_pressed or get_buffered_input("dash")

## Function: is_dash_held
## Purpose: Check if the dash button is currently held.
## Parameters: None.
## Returns: bool.
func is_dash_held() -> bool:
	"""Return true if dash is currently held down."""
	return dash_held

## Function: is_dash_released
## Purpose: Check if the dash button was just released.
## Parameters: None.
## Returns: bool.
func is_dash_released() -> bool:
	"""Return true if dash was just released."""
	return dash_released

## Function: process_commands
## Purpose: Buffer attack/dash commands and append them to the command queue.
## Parameters: None.
## Returns: void.
func process_commands():
	"""Buffer attack commands and append dash command to the queue."""
	if Input.is_action_just_pressed("attack_light"):
		buffer_input("attack_light")
	if Input.is_action_just_pressed("attack_heavy"):
		buffer_input("attack_heavy")
	if Input.is_action_just_pressed("dash"):
		buffer_input("dash")

	# Add commands to queue if buffered
	if get_buffered_input("attack_light"):
		# Create a new attack command for a light attack
		var cmd = AttackCommand.new()
		cmd.attack_type = "light"
		command_queue.append(cmd)
	elif get_buffered_input("attack_heavy"):
		# Create a new attack command for a heavy attack
		var cmd = AttackCommand.new()
		cmd.attack_type = "heavy"
		command_queue.append(cmd)
	

	# if get_buffered_input("dash"):
	# 	command_queue.append(dash_command)

## Function: execute_commands
## Purpose: Execute every queued command with the provided actor, then clear the queue.
## Parameters:
##   actor (Node): The actor for which to execute commands.
## Returns: void.
func execute_commands(actor):
	"""Execute every command in the queue using the provided actor and then clear the queue."""
	for command in command_queue:
		command.execute(actor)
	command_queue.clear()  # Clear after execution

## Function: buffer_input
## Purpose: Buffer a given input action with an expiration timestamp.
## Parameters:
##   action (String): The action to buffer.
## Returns: void.
func buffer_input(action: String):
	"""Store an input action in the buffer with an expiration timestamp."""
	input_buffer[action] = Time.get_ticks_msec() + int(buffer_time * 1000)

## Function: get_buffered_input
## Purpose: Retrieve a buffered action if still valid, then remove it.
## Parameters:
##   action (String): The action to check.
## Returns: bool.
func get_buffered_input(action: String) -> bool:
	"""Return true if the action is still buffered and remove it from the buffer."""
	var current_time = Time.get_ticks_msec()
	if action in input_buffer and input_buffer[action] > current_time:
		input_buffer.erase(action)  # Remove after use
		return true
	return false

## Function: clear_buffer
## Purpose: Clear all buffered input actions.
## Parameters: None.
## Returns: void.
func clear_buffer():
	"""Clear all buffered inputs."""
	input_buffer.clear()

## Function: switch_input_scheme
## Purpose: Change the current input scheme if the new scheme differs.
## Parameters:
##   new_scheme (INPUT_SCHEMES): The new input scheme.
## Returns: void.
func switch_input_scheme(new_scheme: INPUT_SCHEMES):
	"""Switch to a new input scheme if it differs from the current one."""
	if current_input_scheme != new_scheme:
		current_input_scheme = new_scheme
		print("Switched to:", get_input_scheme_name(new_scheme))
		emit_signal("control_set_changed", current_input_scheme)

## Function: get_input_scheme_name
## Purpose: Return a string representing the current input scheme.
## Parameters:
##   scheme (INPUT_SCHEMES): The input scheme to represent.
## Returns: String.
func get_input_scheme_name(scheme: INPUT_SCHEMES) -> String:
	"""Return a string representation of the given input scheme."""
	match scheme:
		INPUT_SCHEMES.KBM: return "Keyboard & Mouse"
		INPUT_SCHEMES.GAMEPAD: return "Gamepad"
		INPUT_SCHEMES.TOUCH: return "Touch"
	return "Unknown"

## Function: get_movement_vector
## Purpose: Compute a 3D movement vector from the 2D input vector and the camera's yaw.
## Parameters: None.
## Returns: Vector3.
func get_movement_vector() -> Vector3:
	# Get the active camera.
	if not camera:
		camera = GlobalReferences.get_camera()
		if not camera:
			return Vector3.ZERO
	# Get the camera’s Y rotation (yaw)
	var camera_yaw = camera.global_transform.basis.get_euler().y
	# Forward in raw input is initially -Z.
	var movement_vector = Vector3(input_vector.x, 0, input_vector.y).rotated(Vector3.UP, camera_yaw)
	return movement_vector
	
## Function: get_input_vector
## Purpose: Return the raw 2D input vector.
## Parameters: None.
## Returns: Vector2.
func get_input_vector() -> Vector2:
	"""Return the 2D raw input vector."""
	return input_vector

## Function: get_mouse_direction
## Purpose: Cast a ray from the mouse position and return the intersection point in world space.
## Parameters:
##   origin (Node3D): The origin node from which to cast the ray.
## Returns: Vector3.
func get_mouse_direction(origin: Node3D) -> Vector3:
	return get_mouse_position(origin) - origin.global_transform.origin
## Function: get_mouse_position
## Purpose: Return the current mouse position in world space.
## Parameters:
##   origin (Node3D): The origin node from which to cast the ray.
## Returns: Vector3.
func get_mouse_position(origin: Node3D) -> Vector3:
	# Get the active camera.
	
	# Get the current mouse position.
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	
	# Calculate the target y value using the origin's global position.
	var target_y = origin.global_transform.origin.y
	
	# Avoid division by zero if the ray is nearly horizontal.
	if abs(ray_direction.y) < 0.001:
		return Vector3.ZERO
	
	# Calculate the intersection scale factor.
	var t = (target_y - ray_origin.y) / ray_direction.y
	
	# If t is negative, the intersection is behind the camera.
	if t < 0:
		return Vector3.ZERO
	
	# Return the global intersection point on the plane at target_y.
	return ray_origin + ray_direction * t


## Function: update_aim_direction
## Purpose: Update the aim direction using mouse or gamepad input.
## Parameters: None.
## Returns: void.
func update_aim_direction():
	"""Update the aim_direction based on either mouse or gamepad input."""
	pass

## Function: get_aim_angle
## Purpose: Return the current aim angle (from e.g. a right stick).
## Parameters: None.
## Returns: float.
func get_aim_angle() -> float:
	"""Return the current aim angle (e.g. right stick angle)."""
	return aim_angle

## Function: get_aim_direction
## Purpose: Return the normalized aim direction.
## Parameters: None.
## Returns: Vector3.
func get_aim_direction() -> Vector3:
	"""Return the normalized aim direction."""
	return aim_direction
