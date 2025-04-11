extends CharacterBody3D
class_name Enemy

# --- Define the core states for all enemies ---
enum BaseState {
	SPAWNING,
	IDLE,
	MOVING,
	AVOIDING,
	ATTACKING,    # Generic attack state that specialized enemies can override.
	HIT_REACTION,
	DEATH
}

# The current state of the enemy.
var current_state: BaseState = BaseState.SPAWNING

# --- Enemy Properties ---
var id: int = 0
var weight: int = 1
var spawn_radius: float = 1.0
var can_summon: bool = false
var tags: Array[String] = []

# Nodes and other onready variables.
@onready var animation_tree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree.get("parameters/playback")
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var collider: CollisionShape3D = $CollisionShape3D
@onready var health: Node = $Health
@onready var movement: Node = $Movement 

var player
var is_seeking_player: bool = false  # Begins tracking only after spawn animation.
var is_alive: bool = false
var is_in_hit_reaction: bool = false

# --- Spawn-related Settings ---
enum SPAWN_POSES {FLOOR, FLOOR_LONG, STANDING, IDLE, GROUND, SPAWN_AIR, RESURRECT}
@export var SPAWN_POSE: SPAWN_POSES = SPAWN_POSES.FLOOR  
@export var play_spawn: bool = false
@export var spawn_delay: float = 1.0  # Time before AI starts moving.

# --- Movement Settings ---
@export var speed: float = 2.0
@export var turn_speed: float = 2
var angle_toward_player: float = 1

@export_category("AI Navigation")
@export var attack_range: float = 5.0
@export var delay_steps: int = 20  # Delay in frames before reacting to player.
@export var min_distance_to_target: float = 4
@export var seperation_distance: float = 2
@export var minimum_speed: float = 1

var is_grounded
var navmesh_map: RID


# --- Initialization ---
func _ready() -> void:

	navmesh_map = navigation_agent_3d.get_navigation_map()
	
	animation_tree.active = true  # Start the animation tree.
	deferred_get_player()
	spawn()  # Start the spawning logic.

# --- Physics Process using the State Machine ---
func _physics_process(delta: float) -> void:
	match current_state:
		BaseState.SPAWNING:
			# Typically handled in spawn(). Nothing to update.
			pass
		BaseState.IDLE:
			# Transition to MOVING if a player exists.
			if player:
				current_state = BaseState.MOVING
		BaseState.MOVING:
			if is_seeking_player:
				move_towards_player(delta)
		BaseState.ATTACKING:
			# (Reserved for specialized attack logic in this base state or override in subclass)
			pass
		BaseState.HIT_REACTION:
			# Freeze movement; animation is playing.
			pass
		BaseState.DEATH:
			# Dead state: usually animations and effects play; no further processing.
			pass

	# Ensure character physics (e.g., collisions, sliding) are processed.
	move_and_slide()

# --- Spawning Logic ---
func spawn() -> void:
	print("Spawn triggered!")
	current_state = BaseState.SPAWNING
	# Simulate a brief spawn effect.
	await get_tree().create_timer(1).timeout
	
	play_spawn = true
	collider_state(true)
	is_alive = true
	
	# Wait for spawn animation to finish.
	await get_tree().create_timer(spawn_delay).timeout  
	is_seeking_player = true  
	# Transition to IDLE (or directly to MOVING if desired).
	current_state = BaseState.MOVING
	set_process(true)

# --- Movement & Rotation ---
func move_towards_player(delta: float) -> void:
	# This example uses a delayed tracking pattern.
	if PlayerHistory.get_player_position_history_size() >= 0:
		var delayed_position = PlayerHistory.get_player_position_at_index(delay_steps - 1)
		navigation_agent_3d.target_position = delayed_position
		
		# Calculate movement direction.
		var target_direction = (navigation_agent_3d.get_next_path_position() - global_position).normalized()
		#print("Target direction: ", target_direction)

		if not is_in_hit_reaction:
			if global_transform.origin.distance_to(delayed_position) > min_distance_to_target:
				# Move toward the target position.
				movement.apply_ai_movement(self, target_direction, delta, seperation_distance, minimum_speed, (1 / angle_toward_player) * speed)
			else:
				velocity.x = 0
				velocity.z = 0
			# Rotate toward the movement direction.
			movement.apply_smooth_rotation(self, target_direction, delta, (1 / angle_toward_player) * turn_speed)
		else:
			velocity.x = 0
			velocity.z = 0


#func avoid_player(delta: float) -> void:
	

func can_move() -> bool:
	return is_alive and not is_in_hit_reaction and is_seeking_player

# --- Damage, Hit Reaction, and Death ---
func apply_damage(damage: float, source: Node3D = player) -> void:
	health.damage(damage)

	if health.is_dead():
		return

	
	if not is_in_hit_reaction:
		is_in_hit_reaction = true
		current_state = BaseState.HIT_REACTION
		state_machine.travel("HitReaction")
		# Use a one-shot connection to know when the hit reaction is finished.
		if not animation_tree.is_connected("animation_finished", Callable(self, "_on_hit_reaction_finished")):
			# Connect the signal to handle the end of the hit reaction.
			animation_tree.connect("animation_finished", Callable(self, "_on_hit_reaction_finished"), CONNECT_ONE_SHOT)
		else:
			animation_tree.disconnect("animation_finished", Callable(self, "_on_hit_reaction_finished"))
			animation_tree.connect("animation_finished", Callable(self, "_on_hit_reaction_finished"), CONNECT_ONE_SHOT)
	if source is Player:

		var knockback_time = 0.1

		while knockback_time > 0:
			knockback_time -= get_physics_process_delta_time()
			await get_tree().physics_frame
			# Apply knockback effect.
			if current_state != BaseState.HIT_REACTION or knockback_time <= 0:
				var knockback_direction = (global_transform.origin - player.global_transform.origin).normalized()
				global_transform.origin = global_transform.origin.lerp(global_transform.origin + knockback_direction, 0.5)
				
				return  # Exit if the enemy is stunned during telegraph.
		# If the enemy is dead, trigger the death sequence.


func _on_hit_reaction_finished(_anim_name: String) -> void:
	is_in_hit_reaction = false
	if is_alive:
		current_state = BaseState.MOVING

func die() -> void:
	GlobalEvents.emit_signal("event_enemy_killed", self)
	is_alive = false
	current_state = BaseState.DEATH
	state_machine.travel("Death")
	print("Current animation state: ", state_machine.get_current_node())

	# Disable collider to prevent further interactions.
	collider_state(false)
	is_seeking_player = false
	collider_state(false)
	death_drop_loot()
	despawn()

func death_drop_loot() -> void:
	# Implement loot drop logic.
	pass

# --- Collider Management ---
func collider_state(state: bool) -> void:
	if state:
		call_deferred("enable_collider_deferred")
	else:
		call_deferred("disable_collider_deferred")

func disable_collider_deferred() -> void:
	set_collision_layer_value(GlobalReferences.DASH_PASSABLE_LAYER_INDEX, false)
	
	self.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	velocity = Vector3.ZERO

func enable_collider_deferred() -> void:
	set_collision_layer_value(GlobalReferences.DASH_PASSABLE_LAYER_INDEX, false)
	self.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_ON

# --- Reset, Despawn, and Other Helpers ---
func reset() -> void:
	health.reset()
	global_transform.origin = Vector3.ZERO
	is_alive = false
	is_seeking_player = false
	is_in_hit_reaction = false
	collider_state(false)
	velocity = Vector3.ZERO
	state_machine.travel("Movement")
	navigation_agent_3d.target_position = Vector3.ZERO
	is_grounded = false
	movement.reset(self)
	set_process(false)

func despawn() -> void:
	await get_tree().create_timer(5).timeout
	print("Despawn triggered!")
	GlobalEvents.emit_signal("event_enemy_despawn", self)

func deferred_get_player() -> void:
	player = GlobalReferences.get_player()


func is_on_navmesh() -> bool:
	# Check if the enemy is on the navmesh.
	var tolerance: float = .5
	var closest_point: Vector3 = NavigationServer3D.map_get_closest_point(navmesh_map, global_transform.origin)
	DebugDraw3D.draw_sphere(closest_point, 0.1, Color(1, 0, 0), 0.5)
	return global_position.distance_to(closest_point) < tolerance
