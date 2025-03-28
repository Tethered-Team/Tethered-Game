extends CharacterBody3D
class_name Player

@onready var movement = $Movement
@onready var dash = $Dash
@onready var stats = $Stats
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var tree_root: AnimationNodeStateMachine = $AnimationTree.get("tree_root")
@onready var attack_node: AnimationNodeAnimation = tree_root.get_node("Attack")
@onready var playback = animation_tree.get("parameters/playback")
@onready var camera
@onready var animation_player: AnimationPlayer = $AnimationPlayer
#@onready var weapon: Node3D = $Weapon
@onready var weapon_component = $WeaponComponent as WeaponComponent
@onready var model: Skeleton3D = $Model.get_child(0).get_node("Skeleton3D")
@export var use_mouse_vector: bool = true


var input_vector:Vector2 = Vector2.ZERO
var move_vector: Vector3 = Vector3.ZERO
var to_mouse_vector: Vector3 = Vector3.ZERO
var dash_vector: Vector3 = Vector3.ZERO

var attack_vector: Vector3 = Vector3.ZERO
var exact_target: Node3D = null
var cone_target: Node3D = null
var closest_target: Node3D = null
var attack_target: Node3D = null  # Used as the final target for attack direction


var is_grounded: bool
var is_dashing: bool
var is_running: bool
var lungeTriggered: bool = false



#region Movement and Dash Exports

# Backing variable for movement speed.
var _move_speed: float = 5.0
@export var move_speed: float = 5.0:
	get:
		return movement.speed if movement != null else _move_speed
	set(value):
		_move_speed = value
		if movement != null:
			movement.speed = value

# Backing variable for rotation speed.
var _rotation_speed: float = 10.0
@export var rotation_speed: float = 10.0:
	get:
		return movement.rotation_speed if movement != null else _rotation_speed
	set(value):
		_rotation_speed = value
		if movement != null:
			movement.rotation_speed = value

# Backing variable for dash speed.
var _dash_speed: float = 25.0
@export var dash_speed: float = 25.0:
	get:
		return dash.dash_speed if dash != null else _dash_speed
	set(value):
		_dash_speed = value
		if dash != null:
			dash.dash_speed = value

# Backing variable for dash duration.
var _dash_duration: float = 0.1
@export var dash_duration: float = 0.1:
	get:
		return dash.dash_duration if dash != null else _dash_duration
	set(value):
		_dash_duration = value
		if dash != null:
			dash.dash_duration = value

# Backing variable for dash cooldown.
var _dash_cooldown: float = 0.5
@export var dash_cooldown: float = 0.5:
	get:
		return dash.dash_cooldown if dash != null else _dash_cooldown
	set(value):
		_dash_cooldown = value
		if dash != null:
			dash.dash_cooldown = value

#endregion


func _ready() -> void:

	GlobalReferences.player = self

	"""Initialize the player, resolve required nodes, and set initial movement values."""
	print(movement)
	
	camera = GlobalReferences.main_camera
	if camera == null:
		camera = get_viewport().get_camera_3d()


	# Set initial values for movement and dash.
	set_initial_values()

func _physics_process(delta):
	# """Process the per-frame physics: update input, movement, dash state, and rotation."""

	InputHandler.execute_commands(self)
	
	update_attack_direction()


	if weapon_component.is_attacking:

		# Only trigger the lunge values once per attack.
		if not lungeTriggered:
			movement.apply_rotation(self, attack_vector)
			lungeTriggered = true
			# Start the lunge with custom parameters.
			var lunge_distance = weapon_component.current_attack.lunge_distance
			if attack_target:
				var enemy_distance = global_transform.origin.distance_to(attack_target.global_transform.origin) - 0.5
				if enemy_distance < lunge_distance:
					lunge_distance = enemy_distance

			movement.handle_lunge(self, delta, lunge_distance, 0.1)

		else:
			# Continue the active lunge without re-applying custom parameters.
			movement.handle_lunge(self, delta)
	else:
		# Reset the lunge trigger when not attacking.
		lungeTriggered = false
		update_movement_vectors()

		is_grounded = is_on_floor()
		player_dash(delta)
		if not is_dashing or is_running:
			handle_normal_movement(delta)

			
	move_and_slide()
	draw_debug_vectors()

func player_dash(delta: float) -> void:
	dash.handle_dash(self, delta, dash_vector)
	is_dashing = dash.is_dashing
	is_running = dash.is_running

func handle_normal_movement(delta: float) -> void:
	movement.apply_smooth_rotation(self, move_vector, delta)
	movement.apply_player_movement(self, move_vector, delta)

## Function: set_initial_values [br]
## Purpose: Apply initial speed and duration values to the movement and dash components.[br]
## Parameters: None. [br]
## Returns: void.
func set_initial_values() -> void:
	"""Apply the backing variables to the movement and dash components, setting initial speeds and durations."""
	# Set initial values for movement and dash.
	move_speed = _move_speed
	rotation_speed = _rotation_speed
	dash_speed = _dash_speed
	dash_duration = _dash_duration
	dash_cooldown = _dash_cooldown


## - Function: update_movement_vectors
## Purpose: Update movement vectors using current input and (if enabled) mouse position.
## Parameters: None.
## Returns: void.
func update_movement_vectors() -> void:
	move_vector = InputHandler.get_movement_vector()
	to_mouse_vector = InputHandler.get_mouse_direction(self).normalized()

	if InputHandler.is_control_kbm() and use_mouse_vector:
	
		if is_running and not is_dashing and move_vector.length() > 0.01:
			dash_vector = move_vector.normalized()
		else:
			dash_vector = to_mouse_vector
	else:
		dash_vector = move_vector.normalized()
		print("Dash vector is move vector: ", dash_vector)

func draw_debug_vectors() -> void:
	# Draw debug vectors for movement and rotation.

	# Draw the movement vector - Red
	DebugDraw3D.draw_line(global_transform.origin, global_transform.origin + move_vector*5, Color(1, 0, 0))

	# Draw the direction to the mouse cursor - Green
	DebugDraw3D.draw_line(global_transform.origin, global_transform.origin + to_mouse_vector*5, Color(0, 1, 0))

	# Draw the dash vector - Yellow
	DebugDraw3D.draw_line(global_transform.origin, global_transform.origin + dash_vector* 5, Color(1, 1, 0))

	# Draw the forward vector - White
	DebugDraw3D.draw_line(global_transform.origin, global_transform.origin - global_transform.basis.z * 3, Color(1, 1, 1))

	if cone_target:
		DebugDraw3D.draw_line(global_transform.origin, cone_target.global_transform.origin, Color(1, 0, 1))

	if closest_target:
		DebugDraw3D.draw_line(global_transform.origin, closest_target.global_transform.origin, Color(0, 1, 1))
		
	if attack_target:
		DebugDraw3D.draw_line(global_transform.origin, attack_target.global_transform.origin, Color(1, 0, 1))

			

## Function: _print_animation_tree_parameters
## Purpose: Print the AnimationTree parameters for debugging purposes.
## Parameters: None.
## Returns: void.
func _print_animation_tree_parameters() -> void:
	"""Print the current AnimationTree parameters for debugging."""
	print("AnimationTree parameters: ", animation_tree.get("parameters"))


func _on_check_button_toggled(toggled_on: bool) -> void:
	use_mouse_vector = toggled_on


func update_attack_direction() -> void:
	# Reset the attack vector and clear previous target data.
	attack_vector = Vector3.ZERO
	cone_target = null
	exact_target = null
	closest_target = null
	attack_target = null

	# If using keyboard/mouse input and mouse-based targeting is enabled:
	if InputHandler.is_control_kbm() and use_mouse_vector:
		# Get the precise target under the mouse cursor.
		exact_target = Targeting.get_target_at_mouse_position(self)
		# Get a target in a cone from the mouse direction (accounts for peripheral targets).
		cone_target = Targeting.get_target_in_mouse_direction(self, 5.0, 30.0)
		
		# Outcome 1: Only an exact target is found.
		if (exact_target and not cone_target):
			# Choose the exact target.
			attack_target = exact_target
		# Outcome 2: Both targets are found, so choose the one that is closer.
		elif (exact_target and cone_target
			and global_transform.origin.distance_squared_to(exact_target.global_transform.origin) > global_transform.origin.distance_squared_to(cone_target.global_transform.origin)):
			# Choose the cone target if it is closer.
			attack_target = cone_target
		# Outcome 3: Only one of them is present or conditions don’t favor cone target.
		else:
			# Default to the exact target.
			attack_target = exact_target

		# Outcome: Set attack_vector toward the chosen target, or fallback on the current mouse direction.
		if attack_target:
			attack_vector = (attack_target.global_transform.origin - global_transform.origin).normalized()
		else:
			attack_vector = InputHandler.get_mouse_direction(self).normalized()
	else:
		# When not in mouse-based targeting mode:
		#
		# Step 1: Prioritize targets that lie very close to the player's forward direction.
		# We search within a narrow cone (15°) from the player's forward.
		var forward_cone_target = Targeting.get_closest_target_in_cone(global_transform.origin, global_transform.basis.z, 5.0, 15.0)
		
		# Outcome 1: If a target is found within the narrow cone, use it.
		if forward_cone_target:
			attack_target = forward_cone_target
		else:
			# Outcome 2: Otherwise, perform a wider search for any nearby target.
			closest_target = Targeting.get_target_near_position(global_transform.origin, 10.0)
			if closest_target:
				var candidate_vec = (closest_target.global_transform.origin - global_transform.origin).normalized()
				# Only accept the candidate if it lies within 45° of the player's forward direction.
				if global_transform.basis.z.dot(candidate_vec) >= cos(deg_to_rad(45)):
					attack_target = closest_target
				else:
					attack_target = null
					
		# Outcome: Set the attack vector toward the chosen target or default to the player's forward direction.
		if attack_target:
			attack_vector = (attack_target.global_transform.origin - global_transform.origin).normalized()
		else:
			attack_vector = global_transform.basis.z
