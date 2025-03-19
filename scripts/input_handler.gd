extends Node

enum INPUT_SCHEMES {KBM, GAMEPAD, TOUCH}
var current_input_scheme: INPUT_SCHEMES = INPUT_SCHEMES.KBM

# Stores buffered inputs with expiration time
var input_buffer: Dictionary = {}
@export var buffer_time: float = 0.2  # Buffer duration (200ms)

var input_vector: Vector2 = Vector2.ZERO
var dash_pressed: bool = false
var dash_held: bool = false
var dash_released: bool = false
var attack_pressed: bool = false

var aim_direction: Vector3 = Vector3.ZERO  # Aim direction (Mouse/Gamepad)
var aim_angle: float = 0.0  # Right stick angle
# Command queue
var command_queue: Array[Command] = []

# Register command objects
var attack_command: Command = AttackCommand.new()
var dash_command: Command = DashCommand.new()

func _input(event):
	# **Detect input scheme dynamically**
	if event is InputEventKey or event is InputEventMouseMotion or event is InputEventMouseButton:
		switch_input_scheme(INPUT_SCHEMES.KBM)
	elif (event is InputEventJoypadMotion and Input.get_vector("move_left", "move_right", "move_up", "move_down").length() > .05) or event is InputEventJoypadButton:
		switch_input_scheme(INPUT_SCHEMES.GAMEPAD)
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		switch_input_scheme(INPUT_SCHEMES.TOUCH)

	# **Handle movement input**
	input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# **Handle dash input**
	update_dash_input()

	# **Update aiming direction**
	update_aim_direction()
	
	# Handle attack and dash inputs
	process_commands()

# ✅ **Detect Dash Input Properly**
func update_dash_input():
	dash_pressed = Input.is_action_just_pressed("dash")
	dash_held = Input.is_action_pressed("dash")
	dash_released = Input.is_action_just_released("dash")

	if dash_pressed:
		buffer_input("dash")  # Buffer the dash input for responsiveness

# ✅ **Get Dash Input Status for Dash System**
func is_dash_pressed() -> bool:
	return dash_pressed or get_buffered_input("dash")

func is_dash_held() -> bool:
	return dash_held

func is_dash_released() -> bool:
	return dash_released

# ✅ **Command Processing**
func process_commands():
	if Input.is_action_just_pressed("attack_light"):
		buffer_input("attack_light")
	if Input.is_action_just_pressed("attack_heavy"):
		buffer_input("attack_heavy")
	if Input.is_action_just_pressed("dash"):
		buffer_input("dash")

	# Add commands to queue if buffered
	if get_buffered_input("attack"):
		command_queue.append(attack_command)
	if get_buffered_input("dash"):
		command_queue.append(dash_command)

func execute_commands(actor):
	"""Execute all queued commands."""
	for command in command_queue:
		command.execute(actor)
	command_queue.clear()  # Clear after execution

# ✅ **Buffer Input**
func buffer_input(action: String):
	"""Stores an input action in the buffer with an expiration timestamp."""
	input_buffer[action] = Time.get_ticks_msec() + int(buffer_time * 1000)

# ✅ **Retrieve Buffered Input if Still Valid**
func get_buffered_input(action: String) -> bool:
	"""Checks if the action is buffered and removes it if expired."""
	var current_time = Time.get_ticks_msec()
	if action in input_buffer and input_buffer[action] > current_time:
		input_buffer.erase(action)  # Remove after use
		return true
	return false

func clear_buffer():
	"""Clears all buffered inputs."""
	input_buffer.clear()

# ✅ **Switch Input Scheme Dynamically**
func switch_input_scheme(new_scheme: INPUT_SCHEMES):
	if current_input_scheme != new_scheme:
		current_input_scheme = new_scheme
		print("Switched to:", get_input_scheme_name(new_scheme))

func get_input_scheme_name(scheme: INPUT_SCHEMES) -> String:
	match scheme:
		INPUT_SCHEMES.KBM: return "Keyboard & Mouse"
		INPUT_SCHEMES.GAMEPAD: return "Gamepad"
		INPUT_SCHEMES.TOUCH: return "Touch"
	return "Unknown"

# ✅ **Get Movement Vector**
func get_movement_vector() -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return Vector3.ZERO

	# Get camera's Y rotation (Yaw)
	var camera_yaw = camera.global_transform.basis.get_euler().y

	# Convert input into a movement vector (forward is initially -Z)
	var movement_vector = Vector3(input_vector.x, 0, input_vector.y).rotated(Vector3.UP, camera_yaw)

	return movement_vector
	
func get_input_vector() -> Vector2:
	return input_vector

# ✅ **Get Direction to Mouse Pointer (3D)**
func get_mouse_direction(origin: Node3D) -> Vector3:
	var camera = get_viewport().get_camera_3d()
	if not camera:
		return Vector3.ZERO

	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)

	var space_state = origin.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000)
	var result = space_state.intersect_ray(query)

	if result:
		result.y = origin.global_position.y
		return result.position
	return Vector3.ZERO

# ✅ **Update Aiming Direction (Mouse or Right Stick)**
func update_aim_direction():
	pass

# ✅ **Get Right Stick Aim Angle**
func get_aim_angle() -> float:
	return aim_angle

# ✅ **Get Right Stick Aim Direction (Normalized)**
func get_aim_direction() -> Vector3:
	return aim_direction
