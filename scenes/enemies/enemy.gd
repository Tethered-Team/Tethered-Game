extends CharacterBody3D
class_name Enemy

@export var enemy_data: EnemySpawnData

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
var is_in_hit_reaction: bool = false

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
		
	spawn()


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

	# Start physics process
	set_process(true)


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
		
		if not is_in_hit_reaction:
			if global_transform.origin.distance_to(delayed_position) > min_distance_to_target:
				# **Move forward relative to facing direction**
				movement.apply_ai_movement(self, target_direction, delta, seperation_distance, minimum_speed, 1/angle_toward_player * speed)
			else:
				velocity.x = 0
				velocity.z = 0

			# **Rotate smoothly toward movement direction**
			movement.apply_smooth_rotation(self, target_direction, delta, 1/angle_toward_player * turn_speed)
		else:
				velocity.x = 0
				velocity.z = 0


	

func die():
	GlobalEvents.emit_signal("event_enemy_killed", self)

	# Set state
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

	despawn()

# ✅ **Drop Loot on Death**
func death_drop_loot():
	# Drop loot items
	pass

func apply_damage(damage: float) -> void:
	# Always update health regardless of current state.
	health.damage(damage)
	
	# If not already in hit reaction, trigger it.
	if not is_in_hit_reaction:
		is_in_hit_reaction = true
		state_machine.travel("HitReaction")
		
		# Connect a one-shot signal to know when the hit reaction completes.
		animation_tree.connect("animation_finished", Callable(self, "_on_hit_reaction_finished"), CONNECT_ONE_SHOT)

func _on_hit_reaction_finished(_anim_name: String) -> void:
	is_in_hit_reaction = false

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

func reset():
	# Reset health
	health.reset()
	# Reset position
	global_transform.origin = Vector3.ZERO
	# Reset state
	is_alive = false
	is_seeking_player = false
	is_in_hit_reaction = false
	# Reset collider
	collider_state(false)
	# Reset movement
	velocity = Vector3.ZERO
	# Reset animation
	state_machine.travel("Movement")
	# Reset player history
	player_position_history.clear()
	# Reset navigation agent
	navigation_agent_3d.target_position = Vector3.ZERO
	# Reset AI state
	is_grounded = false
	# Reset AI movement
	movement.reset(self)

	# Reset Physics Process
	set_process(false)

func despawn():

	## Effect - Dissolve?
	## Effect - Fade out?
	## Effect - Particle effect?
	## Effect - Animation?
	

	## Wait for effect to finish
	await get_tree().create_timer(10).timeout

	GlobalEvents.emit_signal("event_enemy_despawn", self)

	
