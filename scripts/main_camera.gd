extends Node3D

@export var target: NodePath

# Camera settings
@export var distance: float = 40.0
@export var angle_horizontal: float = 45.0 # yaw
@export var angle_vertical: float = 30.0  # pitch

@export var limit_horizontal: float = 10.0
@export var limit_vertical: float = 10.0
@export var horizontal_offset: float = 2.0
@export var vertical_offset: float = 1.0

@export var smooth_speed: float = 2.0
@export var reset_pause_delay: float = 0.5           # seconds to wait before resetting
@export var opposite_lerp_multiplier: float = 2       # multiplier for faster lerp when reversing
@export var reset_speed: float = 1.0

var _target_node: Node3D
var _camera: Camera3D
var _input_handler: Node

var rad_h = deg_to_rad(angle_horizontal)
var rad_v = deg_to_rad(angle_vertical)
var current_offset: Vector2 = Vector2.ZERO
var reset_timer: float = 0.0

func _ready():
	# Initialize target node.
	if target:
		_target_node = get_node(target)
	else:
		push_warning("No target set for the camera.")
	
	# Get Camera3D child.
	_camera = $Camera3D
	if _camera == null:
		push_warning("No Camera3D child found.")
	
	# Get InputHandler from root.
	if has_node("/root/InputHandler"):
		_input_handler = get_node("/root/InputHandler")
	else:
		push_warning("No InputHandler found.")
	
	# Set initial camera position and orientation.
	if _target_node:
		var offset = get_spherical_offset()
		var desired_position = _target_node.global_transform.origin + offset
		global_transform.origin = desired_position
		look_at(_target_node.global_transform.origin, Vector3.UP)

func _physics_process(delta: float) -> void:
	if _target_node and _camera and _input_handler:
		update_current_offset(delta)
		apply_camera_offset()
		
		var offset = get_spherical_offset()
		var desired_position = _target_node.global_transform.origin + offset
		global_transform.origin = desired_position

# Returns the camera offset using spherical coordinates.
func get_spherical_offset() -> Vector3:
	return Vector3(
		distance * cos(rad_v) * sin(rad_h), # X component
		distance * sin(rad_v),              # Y component (height)
		distance * cos(rad_v) * cos(rad_h)    # Z component
	)

# Update accumulated offset based on the movement vector.
func update_current_offset(delta: float) -> void:
	var movement_vector = _input_handler.get_input_vector()
	
	if movement_vector.length() > 0:
		# Reset timer if movement occurs.
		reset_timer = 0.0
		
		# Compute the desired target offsets based on input.
		var target_offset = Vector2(movement_vector.x * limit_horizontal, -movement_vector.y * limit_vertical)
		
		 # Calculate the angle difference between current offset and input direction
		var current_angle = 0
		var target_angle = 0
		
		if current_offset.length() > 0.01:
			current_angle = current_offset.angle()
		
		if target_offset.length() > 0.01:
			target_angle = target_offset.angle()
		
		var angle_diff = abs(wrapf(target_angle - current_angle, -PI, PI))
		
		# Calculate adaptive smoothing - faster when direction differs more
		var adaptive_smooth = smooth_speed/8
		if angle_diff > 0.1:
			# Scale smoothing speed based on angle difference (0 to PI)
			adaptive_smooth = opposite_lerp_multiplier * angle_diff / PI
		
		# Apply adaptive smoothing
		current_offset = current_offset.lerp(target_offset, adaptive_smooth * delta)
		
		# Clamp the accumulated offset.
		current_offset.x = clamp(current_offset.x, -limit_horizontal, limit_horizontal)
		current_offset.y = clamp(current_offset.y, -limit_vertical, limit_vertical)
	else:
		# Increase the pause timer; only start resetting after delay.
		reset_timer += delta
		if reset_timer > reset_pause_delay:
			current_offset = current_offset.lerp(Vector2.ZERO, reset_speed * delta)
			
# Apply the accumulated current_offset to the Camera3D's transform.
func apply_camera_offset() -> void:
	var cam_transform = _camera.transform
	cam_transform.origin.x = current_offset.x
	cam_transform.origin.y = current_offset.y
	_camera.transform = cam_transform
