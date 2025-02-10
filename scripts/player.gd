extends CharacterBody3D

@export var speed: float = 5.0
@export var dash_speed: float = 5.0  # Speed during dash
@export var dash_duration: float = 0.1  # Duration of the dash
@export var dash_cooldown: float = 1.0  # Cooldown time between dashes
var is_dashing: bool = false  # Track if currently dashing
var dash_timer: float = 0.0  # Timer for dash duration
@export var rotation_speed: float = 5.0
@export var camera_node_path: NodePath

func _ready():
	pass

func _process(delta: float) -> void:
	var input_vector = Vector3.ZERO

	if Input.is_action_pressed("up"):
		input_vector.x -= 1  # Adjusted for isometric view
	if Input.is_action_pressed("down"):
		input_vector.x += 1  # Adjusted for isometric view
	if Input.is_action_pressed("left"):
		input_vector.z += 1  # Adjusted for isometric view
	if Input.is_action_pressed("right"):
		input_vector.z -= 1  # Adjusted for isometric view

	input_vector = input_vector.normalized()
	
	# Get the camera node and its rotation
	var camera = get_node(camera_node_path)
	var camera_angle = camera.rotation.y

	# Adjust input vector based on camera angle
	var adjusted_input_vector = Vector3(
		input_vector.x * cos(camera_angle) - input_vector.z * sin(camera_angle),
		0,
		input_vector.x * sin(camera_angle) + input_vector.z * cos(camera_angle)
	)

	velocity = adjusted_input_vector * speed

	if velocity.length() > 0:
		var target_rotation = Vector3(0, atan2(velocity.x, velocity.z), 0)
		rotation = rotation.lerp(target_rotation, rotation_speed * delta)

	if is_dashing:
		if dash_timer <= 0: #dash duration
			is_dashing = false
			dash_timer = dash_cooldown
		if Input.is_action_pressed("ui_accept"): #dash input still held
			velocity *= dash_speed  # Apply dash speed
			dash_timer -= delta
		else:	#dash input released
			is_dashing = false
			dash_timer = dash_cooldown
	elif dash_timer > 0: #cooldown
		dash_timer -= delta
	elif Input.is_action_just_pressed("ui_accept") :  # Check for spacebar press
		is_dashing = true
		dash_timer = dash_duration
		velocity *= dash_speed  # Apply dash speed
	
	move_and_slide()
