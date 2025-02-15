extends Node

enum INPUT_SCHEMES {KBM, GAMEPAD, TOUCH}
var current_input_scheme: INPUT_SCHEMES = INPUT_SCHEMES.KBM

# Stores buffered inputs with expiration time
var input_buffer: Dictionary = {}
@export var buffer_time: float = 0.2  # Buffer duration (200ms)


var movement_vector: Vector2 = Vector2.ZERO
var is_dashing: bool = false
var aim_direction: Vector3 = Vector3.ZERO  # Aim direction (Mouse/Gamepad)
var aim_angle: float = 0.0  # Right stick angle

func _input(event):
	# **Detect input scheme dynamically**
	if event is InputEventKey or event is InputEventMouseMotion or event is InputEventMouseButton:
		switch_input_scheme(INPUT_SCHEMES.KBM)
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		switch_input_scheme(INPUT_SCHEMES.GAMEPAD)
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		switch_input_scheme(INPUT_SCHEMES.TOUCH)

	# **Handle movement input**
	movement_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	# **Handle dash input**
	is_dashing = Input.is_action_pressed("dash")

	# **Update aiming direction**
	update_aim_direction()


func buffer_input(action: String):
	"""Stores an input action in the buffer with an expiration timestamp."""
	input_buffer[action] = Time.get_ticks_msec() + int(buffer_time * 1000)


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
func get_movement_vector() -> Vector2:
	return movement_vector

# ✅ **Check if the Player is Dashing**
func is_player_dashing() -> bool:
	return is_dashing

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
	# **Gamepad Right Stick Input**
	var right_stick = Vector2(
		Input.get_action_strength("aim_right") - Input.get_action_strength("aim_left"),
		Input.get_action_strength("aim_down") - Input.get_action_strength("aim_up")
	)

	if right_stick.length() > 0.1:  # Deadzone check
		aim_angle = rad_to_deg(right_stick.angle())  # Convert to degrees
		aim_direction = Vector3(right_stick.x, 0, right_stick.y).normalized()
	else:
		aim_angle = 0.0
		aim_direction = Vector3.ZERO

# ✅ **Get Right Stick Aim Angle**
func get_aim_angle() -> float:
	return aim_angle

# ✅ **Get Right Stick Aim Direction (Normalized)**
func get_aim_direction() -> Vector3:
	return aim_direction
