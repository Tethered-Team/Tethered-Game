extends CharacterBody3D

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")

var player
var player_position_history: Array[Vector3] = []
var has_started_moving: bool = false  # Ensures tracking starts only after spawn animation

# Spawn-related settings
enum SPAWN_POSES {FLOOR, FLOOR_LONG, STANDING, IDLE, GROUND, SPAWN_AIR, RESURRECT}
@export var SPAWN_POSE: SPAWN_POSES = SPAWN_POSES.FLOOR  
@export var play_spawn: bool = false
@export var spawn_delay: float = 1.0  # Time before AI starts moving

# Movement settings
@export var gravity: float = 9.8
var gravity_current: float = 0.0
@export var speed: float = 2.0
@export var turn_speed: float = 10.0

# AI behavior settings
@export var delay_steps: int = 20  # Delay in frames before reacting to player

var is_grounded

# ✅ **Initialization**
func _ready():
	player = get_tree().get_first_node_in_group("Player")
	animation_tree.active = true  # Ensure AnimationTree is running

# ✅ **Spawning Logic**
func spawn():
	print("Spawn triggered!")
	await get_tree().create_timer(1).timeout
	
	play_spawn = true  # Set flag (if needed)
	
	# Wait for the spawn animation to finish before starting movement
	await get_tree().create_timer(spawn_delay).timeout  
	has_started_moving = true  # AI can now start following the player
	#print("Has started moving: ", self.name)

# ✅ **Physics Update**
func _physics_process(delta):
	handle_gravity(delta)

	if has_started_moving:
		update_player_history()
		move_towards_player(delta)

	move_and_slide()

# ✅ **Gravity Handling**
func handle_gravity(delta):
	is_grounded = is_on_floor()
	if is_grounded:
		gravity_current = 0
	else:
		gravity_current -= gravity * delta

# ✅ **Update Player Position History**
func update_player_history():
	player_position_history.append(player.global_position)

	# Limit history size to avoid excessive memory usage
	if player_position_history.size() > delay_steps:
		player_position_history.pop_front()

# ✅ **Enemy Movement & Rotation**
func move_towards_player(delta):
	# Move towards an older position of the player (delayed tracking)
	if player_position_history.size() >= delay_steps:
		var delayed_position = player_position_history[0]  # Oldest stored position

		# **Determine movement direction**
		var target_direction = (delayed_position - global_position).normalized()

		# **Rotate smoothly toward movement direction**
		rotate_toward_target(target_direction, delta)

		# **Move forward relative to facing direction**
		velocity = global_transform.basis.z * speed
		#print(velocity, Vector2(velocity.x, velocity.z).normalized().length())

# ✅ **Smooth Rotation Toward Target**
func rotate_toward_target(target_direction: Vector3, delta: float):
	var target_basis = Basis().looking_at(-target_direction, Vector3.UP)  # Flip direction
	global_transform.basis = global_transform.basis.slerp(target_basis, delta * turn_speed)
