extends CharacterBody3D

@onready var animation_tree = $AnimationTree
@onready var state_machine = animation_tree.get("parameters/playback")  # Get the AnimationTree state machine

var player
var player_position_history: Array[Vector3] = []
var has_started_moving: bool = false  # Ensures tracking starts only after Idle state

enum SPAWN_POSES {FLOOR, FLOOR_LONG, STANDING, IDLE, GROUND, SPAWN_AIR, RESURRECT}
@export var SPAWN_POSE: SPAWN_POSES = SPAWN_POSES.FLOOR  
@export var play_spawn: bool = false
@export var spawn_delay: float = 2.0


@export var gravity: float = 9.8
var gravity_current: float = 0.0
@export var speed: float = 2.0

@export var delay_steps: int = 20  # Delay before the enemy reacts to the player

var movement_vector = Vector3.ZERO
var is_grounded

func _ready():
	player = get_tree().get_first_node_in_group("Player")
	animation_tree.active = true  # Ensure AnimationTree is active

func spawn():
	print("Spawn triggered!")
	play_spawn = true  # Set flag (if needed)
	
	# **Force transition to Idle after spawn animation**
	await get_tree().create_timer(spawn_delay).timeout  # Wait for spawn animation duration
	has_started_moving = true

func _physics_process(delta):
	is_grounded = is_on_floor()
	if is_grounded:
		gravity_current = 0
	else:
		gravity_current -= gravity * delta

	if has_started_moving:
		player_position_history.append(player.global_position)

			# Keep history limited to delay_steps
		if player_position_history.size() > delay_steps:
			player_position_history.pop_front()

		# Move towards the older position (delayed tracking)
		if player_position_history.size() >= delay_steps:
			var delayed_position = player_position_history[0]  # Oldest stored position

			# Calculate direction towards the delayed position
			var direction = (delayed_position - global_position).normalized()
			velocity = direction * speed

			print(velocity, direction)
			
			# Make the enemy look toward its movement direction
			if velocity.length() > 0:
				look_at(global_position - velocity, Vector3.UP)
				


	move_and_slide()
