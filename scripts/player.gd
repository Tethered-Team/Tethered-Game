extends CharacterBody3D

@export var dodge_toward_mouse: bool = true

@export var gravity: float = 9.8  # Earth gravity
var gravity_current: float = 0.0
@export var speed: float = 5.0
@export var dash_speed: float = 25  # Speed during dash
@export var run_speed: float = 10.0
@export var dash_duration: float = 0.1  # Duration of the dash
@export var dash_cooldown: float = 1.0  # Cooldown time between dashes
var is_dashing: bool = false  # Track if currently dashing
var is_running: bool = false # Track if currently running
var dash_timer: float = 0.0  # Timer for dash duration
var dash_cooldown_timer: float = 0.0

var dash_start: Vector3


var movement_vector = Vector3.ZERO
var dash_vector: Vector3

var is_grounded: bool

@export var rotation_speed: float = 5.0
@export var camera_node_path: NodePath
@onready var animation_tree = $AnimationTree

enum INPUT_SCHEMES {KBM, GAMEPAD, TOUCH}
static var INPUT_SHCEME:INPUT_SCHEMES = INPUT_SCHEMES.GAMEPAD


func _ready():
	pass

func _physics_process(delta):
		is_grounded = is_on_floor()
		
		if is_grounded:
			gravity_current = 0
		else:
			gravity_current -= gravity * delta

func get_relative_mouse_position() -> Vector3:
	
	var camera = get_viewport().get_camera_3d()
	if camera:
		var mouse_pos = get_viewport().get_mouse_position()
		var ray_origin = camera.project_ray_origin(mouse_pos)
		var ray_direction = camera.project_ray_normal(mouse_pos)
		var space_state = get_world_3d().direct_space_state

		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * 1000)  # 1000 units long
		var result = space_state.intersect_ray(query)

		if result:
			result.y = global_position.y
			return result.position  # Return exact 3D hit point
		
	return Vector3.ZERO

func _process(delta: float) -> void:

	get_movement_vector()
	

	if Input.is_action_just_pressed("dash") and is_grounded and dash_cooldown_timer <= 0: #Press dash when cooldown is over
		is_dashing = true
		dash_timer = dash_duration
		dash_cooldown_timer = dash_cooldown
		if dodge_toward_mouse:
			velocity = global_position.direction_to(get_relative_mouse_position()) * dash_speed
		else:
			velocity = global_transform.basis.z.normalized() * dash_speed
		velocity.y = 0
		dash_vector = velocity
		dash_start = global_position
	elif Input.is_action_pressed("dash"): # holding dash
		if is_dashing:
			velocity = dash_vector
			velocity.y = 0
			if dash_timer > 0: #dash is still going
				dash_timer = clampf(dash_timer - delta, 0, dash_duration)
			elif dash_timer <= 0: # dash is out of time
				is_dashing = false
				is_running = true
				dash_cooldown_timer = dash_cooldown
				
				print("Dash length: ", Vector3(global_position - dash_start).length())
		else: # dash is held to run when dash cooldown is going
			velocity = movement_vector * run_speed
	elif Input.is_action_just_released("dash") and is_dashing: # when dash button is released
		is_dashing = false
		is_running = false
		velocity = movement_vector * speed
		print("Dash length: ", Vector3(global_position - dash_start).length())

	else:
		is_dashing = false
		is_running = false
		velocity = movement_vector * speed
		

	if velocity.normalized().length() > 0:
		look_at(global_position - velocity, Vector3.UP) 
	
	# print("Velocity Y: ", velocity.y, " Is on floor: ", is_on_floor())
	
	if not is_dashing:
		dash_cooldown_timer = clampf(dash_cooldown_timer - delta, 0, dash_cooldown)
		velocity.y = gravity_current
	else:
		gravity_current = 0
			
	#print("On Floor: ", is_grounded, " gravity: ", gravity_current, "is dashing: ", is_dashing)
	
	move_and_slide()

func get_movement_vector():

	movement_vector = Vector3(0, movement_vector.y, 0)

	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	#print(input_vector, "dash: ", Input.is_action_pressed("dash"))
	
	#if Input.is_action_pressed("move_up"):
		#movement_vector.x += 1  # Adjusted for isometric view
	#if Input.is_action_pressed("move_down"):
		#movement_vector.x -= 1  # Adjusted for isometric view
	#if Input.is_action_pressed("move_left"):
		#movement_vector.z -= 1  # Adjusted for isometric view
	#if Input.is_action_pressed("move_right"):
		#movement_vector.z += 1  # Adjusted for isometric view
	movement_vector = movement_vector.normalized()
	movement_vector = Vector3(-input_vector.x, movement_vector.y, -input_vector.y)
	
	movement_vector = movement_vector.rotated(Vector3(0, 1, 0), deg_to_rad(225))
