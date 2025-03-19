extends CharacterBody3D

@onready var movement = $Movement
@onready var dash = $Dash
<<<<<<<< HEAD:scenes/player/player.gd
@onready var weapon_componenet = $WeaponComponent
========
>>>>>>>> nick:scripts/player.gd
@onready var stats = $Stats
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var tree_root: AnimationNodeStateMachine = $AnimationTree.get("tree_root")
@onready var attack_node: AnimationNodeAnimation = tree_root.get_node("Attack")
@onready var playback = animation_tree.get("parameters/playback")
@onready var camera
@onready var animation_player: AnimationPlayer = $AnimationPlayer
#@onready var weapon: Node3D = $Weapon
@onready var weapon_component: WeaponComponent = $WeaponComponent as WeaponComponent
@onready var model: Skeleton3D = $Model.get_child(0).get_node("Skeleton3D")
@export var use_mouse_vector: bool = true


var input_vector:Vector2 = Vector2.ZERO
var move_vector: Vector3 = Vector3.ZERO
var to_mouse_vector: Vector3 = Vector3.ZERO
var last_move_vector: Vector3 = Vector3.ZERO  # New variable to store the last non-zero move vector
var dash_vector: Vector3 = Vector3.ZERO
var attack_vector: Vector3 = Vector3.ZERO
var near_enemy: Node3D = null
var closest_enemy: Node3D = null
var distance_to_enemy: float = 0.0
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
	"""Initialize the player, resolve required nodes, and set initial movement values."""
	print(movement)
	camera = get_viewport().get_camera_3d()


	# Set initial values for movement and dash.
	set_initial_values()

func _physics_process(delta):
	# """Process the per-frame physics: update input, movement, dash state, and rotation."""

	InputHandler.execute_commands(self)
	

<<<<<<<< HEAD:scenes/player/player.gd

	

	# Handle dash input
	dash.handle_dash(self, delta)
	
	movement.apply_smooth_rotation(self, move_vector, delta)
========

	if weapon_component.is_attacking:
		movement.apply_rotation(self, attack_vector)
		# Only trigger the lunge values once per attack.
		if not lungeTriggered:
			lungeTriggered = true
			# Start the lunge with custom parameters.
			if near_enemy:
				movement.handle_lunge(self, delta, (global_position.distance_to(near_enemy.global_transform.origin) * .8), 0.1)
			else:
				# Continue the active lunge without re-applying custom parameters.
				movement.handle_lunge(self, delta, 2.0, 0.1)
		else:
			# Continue the active lunge without re-applying custom parameters.
			movement.handle_lunge(self, delta)
	else:
		# Reset the lunge trigger when not attacking.
		lungeTriggered = false
		update_movement_vectors()
>>>>>>>> nick:scripts/player.gd

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
	movement.apply_movement(self, move_vector, delta, is_grounded)

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

	if use_mouse_vector:
	
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

	# Draw the last non-zero move vector - Blue
	DebugDraw3D.draw_line(global_transform.origin, global_transform.origin + last_move_vector*5, Color(0, 0, 1), 2)

	# Draw the dash vector - Yellow
	DebugDraw3D.draw_line(global_transform.origin, global_transform.origin + dash_vector* 5, Color(1, 1, 0))

	# Draw the forward vector - White
	DebugDraw3D.draw_line(global_transform.origin, global_transform.origin - global_transform.basis.z * 3, Color(1, 1, 1))

	if near_enemy:
		DebugDraw3D.draw_line(global_transform.origin, near_enemy.global_transform.origin, Color(1, 0, 1))

	if closest_enemy:
		DebugDraw3D.draw_line(global_transform.origin, closest_enemy.global_transform.origin, Color(0, 1, 1))
	

			

## Function: _print_animation_tree_parameters
## Purpose: Print the AnimationTree parameters for debugging purposes.
## Parameters: None.
## Returns: void.
func _print_animation_tree_parameters() -> void:
	"""Print the current AnimationTree parameters for debugging."""
	print("AnimationTree parameters: ", animation_tree.get("parameters"))


func _on_check_button_toggled(toggled_on: bool) -> void:
	use_mouse_vector = toggled_on


func get_closest_enemy(max_range: float, max_angle_deg: float, close_override: float = 0.5, perfect_angle_threshold: float = 5.0) -> void:
	var overall_closest: Node3D = null
	var overall_closest_dist: float = INF
	
	var in_angle_closest: Node3D = null
	var in_angle_closest_dist: float = INF
	
	# For extra priority if the angle is almost perfect.
	var perfect_candidate: Node3D = null
	var perfect_candidate_angle: float = INF
	
	# Iterate through all enemies.
	for enemy in get_tree().get_nodes_in_group("Enemies"):
		if enemy is Node3D:
			var d = global_transform.origin.distance_to(enemy.global_transform.origin)
			print("Enemy:", enemy.name, "distance:", d, "max_range:", max_range)
			if d <= max_range:
				# Update overall closest enemy.
				if d < overall_closest_dist:
					overall_closest = enemy
					overall_closest_dist = d
				
				# Check for override distance first.
				if d <= close_override:
					in_angle_closest = enemy
					in_angle_closest_dist = d
				else:
					# Otherwise check angle.
					var to_enemy = (enemy.global_transform.origin - global_transform.origin).normalized()
					var base_vector = dash_vector.normalized()
					var angle_deg = rad_to_deg(acos(clamp(base_vector.dot(to_enemy), -1.0, 1.0)))
					
					# If the enemy's angle is nearly perfect, update perfect_candidate.
					if angle_deg < perfect_angle_threshold and angle_deg < perfect_candidate_angle:
						perfect_candidate = enemy
						perfect_candidate_angle = angle_deg
					
					# Update the in-angle candidate if within the allowed angle and closer.
					if angle_deg <= max_angle_deg and d < in_angle_closest_dist:
						in_angle_closest = enemy
						in_angle_closest_dist = d
	
	# Decide which enemy to use.
	if perfect_candidate:
		near_enemy = perfect_candidate
	elif in_angle_closest:
		near_enemy = in_angle_closest
	else:
		near_enemy = overall_closest
	
	if near_enemy:
		attack_vector = (near_enemy.global_transform.origin - global_transform.origin).normalized()
		distance_to_enemy = global_transform.origin.distance_to(near_enemy.global_transform.origin)
	else:
		attack_vector = dash_vector
		distance_to_enemy = 0.0

# Helper function for sorting.
func sort_by_distance(a, b):
	if a["dist"] < b["dist"]:
		return -1
	elif a["dist"] > b["dist"]:
		return 1
	else:
		return 0
