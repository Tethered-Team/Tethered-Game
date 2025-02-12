extends CharacterBody3D

@export var speed: float = 5.0
@export var dash_speed: float = 25  # Speed during dash
@export var run_speed: float = 10.0
@export var dash_duration: float = 0.1  # Duration of the dash
@export var dash_cooldown: float = 1.0  # Cooldown time between dashes
var is_dashing: bool = false  # Track if currently dashing
var is_running: bool = false # Track if currently running
var dash_timer: float = 0.0  # Timer for dash duration
var dash_cooldown_timer: float = 0.0

var movement_vector = Vector3.ZERO
var dash_vector

@export var rotation_speed: float = 5.0
@export var camera_node_path: NodePath
@onready var animation_tree = $AnimationTree




func _ready():
	pass

func _process(delta: float) -> void:

	get_movement_vector()

	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0: #Press dash when cooldown is over
		is_dashing = true
		dash_timer = dash_duration
		velocity = movement_vector * dash_speed  # Apply dash speed
		dash_vector = velocity
	elif Input.is_action_pressed("dash"): # holding dash
		if is_dashing:
			velocity = dash_vector
			if dash_timer > 0: #dash is still going
				dash_timer = clampf(dash_timer - delta, 0, dash_duration)
			elif dash_timer <= 0: # dash is out of time
				is_dashing = false
				is_running = true
				dash_cooldown_timer = dash_cooldown
		else: # dash is held to run when dash cooldown is going
			velocity = movement_vector * run_speed
			dash_cooldown_timer = clampf(dash_cooldown_timer - delta, 0, dash_cooldown)
	elif Input.is_action_just_released("dash") and is_dashing: # when dash button is released
		is_dashing = false
		is_running = false
		velocity = movement_vector * speed
		dash_cooldown_timer = clampf(dash_cooldown_timer - delta, 0, dash_cooldown)
	else:
		dash_cooldown_timer = clampf(dash_cooldown_timer - delta, 0, dash_cooldown)
		is_dashing = false
		is_running = false
		velocity = movement_vector * speed
		
	
	move_and_slide()


func get_movement_vector():

	movement_vector = Vector3.ZERO

	if Input.is_action_pressed("up"):
		movement_vector.x += 1  # Adjusted for isometric view
	if Input.is_action_pressed("down"):
		movement_vector.x -= 1  # Adjusted for isometric view
	if Input.is_action_pressed("left"):
		movement_vector.z -= 1  # Adjusted for isometric view
	if Input.is_action_pressed("right"):
		movement_vector.z += 1  # Adjusted for isometric view
	movement_vector = movement_vector.normalized()
	movement_vector = Vector3(-movement_vector.x, movement_vector.y, -movement_vector.z)
	
	movement_vector = movement_vector.rotated(Vector3(0, 1, 0), deg_to_rad(-45))

	if movement_vector.length() > 0:
		look_at(global_position - movement_vector, Vector3.UP) 
	
