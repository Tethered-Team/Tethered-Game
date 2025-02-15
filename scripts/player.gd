extends CharacterBody3D

@export var dodge_toward_mouse: bool = true
@export var is_aim_assist: bool = true
@export var aim_assist_angle: float = 17.0

# Movement Settings
@export var gravity: float = 9.8
var gravity_current: float = 0.0
@export var speed: float = 5.0
@export var run_speed: float = 10.0

# Dash Settings
@export var dash_speed: float = 25.0
@export var dash_duration: float = 0.1
@export var dash_cooldown: float = 1.0

var is_dashing: bool = false
var is_running: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_start: Vector3
var dash_vector: Vector3

# Rotation & Camera
@export var rotation_speed: float = 5.0
@export var camera_node_path: NodePath
@onready var animation_tree = $AnimationTree

# Input Handling
enum INPUT_SCHEMES {KBM, GAMEPAD, TOUCH}
static var INPUT_SCHEME: INPUT_SCHEMES = INPUT_SCHEMES.GAMEPAD

var movement_vector = Vector3.ZERO
var is_grounded: bool

# ✅ **Initialization**
func _ready():
	pass

# ✅ **Physics Update**
func _physics_process(delta):
	is_grounded = is_on_floor()

	get_movement_vector()
	apply_rotation()
	handle_dash(delta)
	apply_movement(delta)
	apply_gravity(delta)
	move_and_slide()

	#print("Movement Vector:", movement_vector, "Length:", movement_vector.length())


# ✅ **Gravity Handling**
func apply_gravity(delta):
	if is_grounded or is_dashing:
		gravity_current = 0
	else:
		gravity_current -= gravity * delta

func apply_rotation():
	if movement_vector.length() > 0.01:  # Avoid rotating when there's no movement
		look_at(global_position - movement_vector, Vector3.UP)

# ✅ **Dash Handling**
func handle_dash(delta):
	if Input.is_action_just_pressed("dash") and is_grounded and dash_cooldown_timer <= 0:
		start_dash()
	elif is_dashing:  # Continue Dash if active
		continue_dash(delta)
	elif Input.is_action_pressed("dash"):  # Holding dash to run
		start_running()
	elif Input.is_action_just_released("dash") or not is_dashing:  # End dash properly
		end_dash()
	else:
		normal_movement()

	# ✅ Cooldown management
	if not is_dashing:
		dash_cooldown_timer = clampf(dash_cooldown_timer - delta, 0, dash_cooldown)



# ✅ Start Dash: Ignore Dash Passable (Layer 2) but Keep Colliding with Dash Blocking (Layer 3)
func start_dash():
	print("Start Dash")
	
	is_dashing = true
	is_running = false  # Ensure it's not running
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

	# ✅ Ignore "Dash Passable" obstacles but keep colliding with "Dash Blocking"
	set_collision_mask_value(2, false)  # Ignore Layer 2 (Dash Passable)
	set_collision_mask_value(3, true)   # Keep colliding with Layer 3 (Dash Blocking)
	set_collision_mask_value(4, true)   # Keep colliding with Ground (Layer 4)

	# ✅ Set Dash Direction
	if dodge_toward_mouse and InputHandler.current_input_scheme == INPUT_SCHEMES.KBM:
		velocity = global_position.direction_to(get_aim_direction(false)) * dash_speed
	else:
		velocity = global_transform.basis.z.normalized() * dash_speed

	dash_vector = velocity
	dash_start = global_position


# ✅ End Dash: Restore Normal Collisions
func end_dash():
	print("End Dash")
	is_dashing = false
	is_running = false
	velocity = movement_vector * speed  # Transition back to normal movement

	# ✅ Ensure proper collision reset when dash ends
	set_collision_mask_value(2, true)  # Re-enable Layer 2 (Dash Passable)
	set_collision_mask_value(3, true)  # Keep Layer 3 (Dash Blocking) active
	set_collision_mask_value(4, true)  # Keep Ground (Layer 4) active


func start_running():
	print("Start Running")
	is_running = true
	is_dashing = false

	# ✅ Set proper layers for running (same as normal movement)
	set_collision_mask_value(2, true)  # Re-enable Layer 2 (Dash Passable)
	set_collision_mask_value(3, true)  # Keep Layer 3 (Dash Blocking) active
	set_collision_mask_value(4, true)  # Keep Ground (Layer 4) active

	velocity = movement_vector * run_speed


# ✅ **Continue Dash**
func continue_dash(delta):
	print("Still Dashing")
	if is_dashing:
		velocity = dash_vector
		velocity.y = 0

		# Reduce dash duration
		dash_timer = clampf(dash_timer - delta, 0, dash_duration)

		# ✅ End dash properly when timer runs out
		if dash_timer <= 0:
			end_dash()
	else:
		# ✅ If dash is held but cooldown is over, start running
		start_running()


# ✅ **Normal Movement**
func normal_movement():
	is_dashing = false
	is_running = false
	velocity = movement_vector * speed

# ✅ **Apply Movement & Rotation**
func apply_movement(delta):
	if is_dashing:
		gravity_current = 0
	else:
		velocity.y = gravity_current

# ✅ **Get Movement Vector**
func get_movement_vector():
	var move_input = InputHandler.get_movement_vector()
	movement_vector = Vector3(move_input.x, movement_vector.y, move_input.y).rotated(Vector3.UP, deg_to_rad(45))

# ✅ **Get Mouse Position in World Space**
func get_aim_direction(aim_assist: bool = is_aim_assist) -> Vector3:
	InputHandler.get_mouse_direction(self)
	
	
	return Vector3.ZERO
