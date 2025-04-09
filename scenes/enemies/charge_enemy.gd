extends Enemy



# This enemy charges at the player when within a certain distance.
# It has a cooldown period after each charge.
# The enemy can also be stunned, which interrupts its charge.

@export_category("Charge Attack")
@export var charge_distance: float = 7.0  # Distance within which the enemy will charge at the player.
@export var charge_duration: float = 4.0  # Speed of the charge attack.
@export var pause_after_charge: float = 0.5  # Pause duration after the charge attack.
@export var charge_cooldown: float = 7.0  # Cooldown time after a charge attack.
@export var telegraph_duration: float = 0.5  # Duration of the telegraph before the charge.


var is_stunned: bool = false  # Flag to indicate if the enemy is stunned.
var is_attacking: bool = false  # Flag to indicate if the enemy is currently charging.
var charge_triggered: bool = false  # Flag to indicate if the charge has been triggered.
var can_attack: bool = true  # Flag to indicate if the enemy can attack.
var charge_duration_timer: Timer  # Timer for the cooldown period after a charge attack.
var stun_timer: Timer  # Timer for the stun duration.
var attack_telegraph_timer: Timer  # Timer for the telegraph duration before the charge.

func _ready() -> void:

	call_deferred("deferred_get_player")

	GlobalEvents.connect("event_arena_wave_spawn", Callable(self, "spawn"), CONNECT_ONE_SHOT)

	# Initialize the cooldown timer.
	charge_duration_timer = Timer.new()
	charge_duration_timer.wait_time = charge_duration + pause_after_charge
	charge_duration_timer.one_shot = true
	charge_duration_timer.timeout.connect(_attack_finished)
	add_child(charge_duration_timer)

	attack_telegraph_timer = Timer.new()
	attack_telegraph_timer.wait_time = telegraph_duration
	attack_telegraph_timer.one_shot = true
	attack_telegraph_timer.timeout.connect(_on_attack_telegraph_timeout)
	add_child(attack_telegraph_timer)

	# Set the initial state of the enemy.
	is_stunned = false
	is_attacking = false
	charge_triggered = false  # Flag to indicate if the charge has been triggered.

func _physics_process(delta: float) -> void:

	if can_move() and not is_stunned:
		# Check if the player is within charge distance.
		if player != null:
			
			

			if can_attack and global_position.distance_to(player.global_position) < attack_range:
				# Start the charge attack.
				if not is_attacking and not charge_triggered:
					charge_triggered = true  # Set the charge triggered flag.
					start_attack()
				else:
					continue_attack(delta)  # Call the parent class method to continue the charge.
			
			else:
				move_towards_player(delta)  # Call the parent class method to move towards the player.
			
	move_and_slide()


func start_attack() -> void:
	# Start the charge attack if not already charging.
	if not is_attacking:
		is_attacking = true
		# Play the charge animation (if any).

		attack_telegraph_timer.start()  # Start the telegraph timer. 
		set_collision_layer_value(GlobalReferences.DASH_PASSABLE_LAYER_INDEX, false)  # Enable the dash passable layer for the charge.
	
		state_machine.travel("attack_telegraph")  # Play the telegraph animation.



func _on_cooldown_timeout() -> void:
	# Reset the cooldown state and allow the enemy to charge again.
	is_attacking = false
	state_machine.travel("Movement")  # Play idle animation after cooldown.


func _on_attack_telegraph_timeout() -> void:
	var delta = get_physics_process_delta_time()
	var to_player = player.global_position - global_position
	state_machine.travel("attack")
	# Ensure you have stored the appropriate charge direction (e.g., as a member variable)
	movement.apply_rotation(self, to_player.normalized())
	movement.handle_lunge(self, delta, charge_distance, charge_duration)
	is_attacking = true

	charge_duration_timer.start()  # Start the cooldown timer after the charge attack.

func continue_attack(delta: float) -> void:
	# Continue the charge attack if already charging.
	if is_attacking:
		# Call the parent class method to continue the charge.
		movement.handle_lunge(self, delta)
		# Check if the charge duration has ended.

func _attack_finished() -> void:
	# Reset the attack state and allow the enemy to charge again.
	is_attacking = false
	charge_triggered = false  # Reset the charge trigger flag.
	state_machine.travel("Movement")  # Play idle animation after cooldown.

	set_collision_layer_value(GlobalReferences.DASH_PASSABLE_LAYER_INDEX, true)  # Disable the dash passable layer after the charge.

	await get_tree().create_timer(charge_cooldown).timeout  # Wait for the pause duration.
	charge_triggered = false  # Allow the enemy to charge again.