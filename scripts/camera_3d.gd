extends Camera3D

@export var target: NodePath

# Camera distance from the target
@export var distance: float = 10.0

# Camera angles
@export var angle_horizontal: float = 45.0 # Horizontal rotation (yaw)
@export var angle_vertical: float = 30.0  # Vertical rotation (pitch)

# Smoothness of camera movement
@export var smooth_speed: float = 10.0

var _target_node: Node3D

func _ready():
	if target:
		_target_node = get_node(target)
	else:
		push_warning("No target set for the camera.")

func _process(delta):
	if _target_node:
		# Convert angles from degrees to radians
		var rad_h = deg_to_rad(angle_horizontal)
		var rad_v = deg_to_rad(angle_vertical)
		
		# Calculate the camera offset using spherical coordinates
		var offset = Vector3(
			distance * cos(rad_v) * sin(rad_h), # X component
			distance * sin(rad_v),              # Y component (height)
			distance * cos(rad_v) * cos(rad_h)  # Z component
		)

		# Compute the desired position
		var desired_position = _target_node.global_transform.origin + offset

		# Smoothly interpolate the camera position
		global_transform.origin = global_transform.origin.lerp(desired_position, smooth_speed * delta)

		# Make the camera look at the target
		look_at(_target_node.global_transform.origin, Vector3.UP)
