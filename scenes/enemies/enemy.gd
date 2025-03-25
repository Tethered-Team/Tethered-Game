extends CharacterBody3D

@onready var animation_tree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var health: Node = $Health
@onready var movement: Node = $Movement 

var player
var player_position_history: Array[Vector3] = []
var is_seeking_player: bool = false  # Ensures tracking starts only after spawn animation
var is_alive

# Spawn-related settings
enum SPAWN_POSES {FLOOR, FLOOR_LONG, STANDING, IDLE, GROUND, SPAWN_AIR, RESURRECT}
@export var SPAWN_POSE: SPAWN_POSES = SPAWN_POSES.FLOOR  
@export var play_spawn: bool = false
@export var spawn_delay: float = 1.0  # Time before AI starts moving

# Movement settings
@export var speed: float = 2.0
@export var turn_speed: float = 2
var angle_toward_player: float = 1

@export_category("AI Navigation")
@export var delay_steps: int = 20  # Delay in frames before reacting to player\]
@export var min_distance_to_target: float = 4
@export var seperation_distance: float = 2
@export var minimum_speed: float = 1

var is_grounded

# ✅ **Initialization**
func _ready():
	player = get_tree().get_first_node_in_group("Player")
	animation_tree.active = true  # Ensure AnimationTree is running
		
	collider_state(false)

# ✅ **Spawning Logic**
func spawn():
	print("Spawn triggered!")
	await get_tree().create_timer(1).timeout
	
	play_spawn = true  # Set flag (if needed)
	collider_state(true)
	is_alive = true

	# Wait for the spawn animation to finish before starting movement
	await get_tree().create_timer(spawn_delay).timeout  
	is_seeking_player = true  # AI can now start following the player
	#print("Has started moving: ", self.name)

# ✅ **Physics Update**
func _physics_process(delta):

	if is_seeking_player:
		update_player_history()
		move_towards_player(delta)

	move_and_slide()


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

		navigation_agent_3d.target_position = delayed_position
		
		# **Determine movement direction**
		var target_direction = (navigation_agent_3d.get_next_path_position() - global_position).normalized()
		
		if global_transform.origin.distance_to(delayed_position) > min_distance_to_target:
			# **Move forward relative to facing direction**
			movement.apply_ai_movement(self, target_direction, delta, seperation_distance, minimum_speed, 1/angle_toward_player * speed)
		else:
			velocity.x = 0
			velocity.z = 0

		# **Rotate smoothly toward movement direction**
		movement.apply_smooth_rotation(self, target_direction, delta, 1/angle_toward_player * turn_speed)



	

func die():
	is_alive = false
	# Play death animation
	state_machine.travel("Death")
	print("Current animation state: ", state_machine.get_current_node())
	# Disable AI logic
	is_seeking_player = false
	
	# Disable collision
	collider_state(false)

	# Drop loot
	death_drop_loot()

	# Destroy enemy after animation

# ✅ **Drop Loot on Death**
func death_drop_loot():
	# Drop loot items
	pass

func apply_damage(damage: float):
	# Apply damage to the enemy
	health.damage(damage)

func collider_state(state: bool):
	if state:
		call_deferred("enable_collider_deferred")
	else:
		call_deferred("disable_collider_deferred")

func disable_collider_deferred():
	collider.disabled = true
	self.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	velocity = Vector3.ZERO

func enable_collider_deferred():
	collider.disabled = false
	self.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON
