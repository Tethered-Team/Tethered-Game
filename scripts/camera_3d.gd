extends Camera3D

# The target node to follow (e.g., the player)
@export var target: NodePath

# Offset from the target (adjust for isometric view)
@export var offset: Vector3 = Vector3(10, 15, 10)

# Smoothness of the camera movement (lower values = smoother)
@export var smooth_speed: float = 10.0

# Reference to the target node
var _target_node: Node3D

func _ready():
	# Ensure the target is set and valid
	if target:
		_target_node = get_node(target)
	else:
		push_warning("No target set for the camera.")

func _process(delta):
	if _target_node:
		# Calculate the desired position for the camera
		var desired_position = _target_node.global_transform.origin + offset

		# Smoothly interpolate the camera's position
		global_transform.origin = global_transform.origin.lerp(desired_position, smooth_speed * delta)

		# Make the camera look at the target
		look_at(_target_node.global_transform.origin, Vector3.UP)
