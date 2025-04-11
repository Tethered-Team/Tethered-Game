extends Enemy
class_name ChargerEnemy

# --- Exported Charge Attack Settings ---
@export var charge_distance: float = 7.0           # Distance at which the enemy will trigger its charge.
@export var charge_duration: float = 4.0           # Duration the enemy spends in the charge phase.
@export var telegraph_duration: float = 0.5        # Duration the enemy telegraphs the upcoming charge.
@export var pause_after_charge: float = 0.5        # Brief pause after the charge.
@export var charge_cooldown: float = 7.0           # Cooldown period before a new charge can begin.


var is_stunned: bool = false  # Flag to check if the enemy is stunned.

# --- Local Charge Attack States ---
enum ChargeAttackState {
	NONE,
	TELEGRAPH,
	CHARGING,
	COOLDOWN
}

var charge_state: ChargeAttackState = ChargeAttackState.NONE
var is_executing_charge: bool = false

func _physics_process(delta: float) -> void:
	# Let the base enemy states (SPAWNING, HIT_REACTION, DEATH) override any attack logic.
	match current_state:
		BaseState.SPAWNING, BaseState.HIT_REACTION, BaseState.DEATH:
			# Do not execute charging if enemy is not in a normal state.
			pass
		_:
			# When the enemy is moving, check if the player is within charge range.
			if current_state == BaseState.MOVING:
				if charge_state == ChargeAttackState.NONE and player and global_position.distance_to(player.global_position) <= attack_range:
					if is_on_navmesh() and navigation_agent_3d.get_current_navigation_path().size() <= 2:
						charge_attack()
					else:
						# Continue normal movement toward the player.
						move_towards_player(delta)
				else:
					# Continue normal movement toward the player.
					move_towards_player(delta)
	if is_stunned:
		# If the enemy is stunned, stop all movement and animations.
		velocity = Vector3.ZERO
		return
	
	if current_state != BaseState.DEATH:
		# Apply standard physics movement.
		move_and_slide()

# --- Charge Attack Coroutine ---
func charge_attack() -> void:
	if is_executing_charge:
		return  # Prevent overlapping charge attacks.
	is_executing_charge = true
	# Set the base enemy state to ATTACKING.
	current_state = BaseState.ATTACKING
	charge_state = ChargeAttackState.TELEGRAPH
	
	velocity = Vector3.ZERO  # Reset velocity to prevent sliding during charge.
	# Play telegraphing animation.
	state_machine.travel("attack_telegraph")
	
	# Wait the telegraph duration.
	var current_telegraph_duration = telegraph_duration
	while current_telegraph_duration > 0:
		if current_state == BaseState.DEATH or current_state == BaseState.HIT_REACTION:
			attack_cooldown()
			return  # Exit if the enemy is stunned during telegraph.
		var delta = get_physics_process_delta_time()
		movement.apply_smooth_rotation(self, player.global_position - global_position, delta, turn_speed)
		current_telegraph_duration -= delta
		await get_tree().physics_frame


	
	# Begin the charge phase.
	charge_state = ChargeAttackState.CHARGING
	state_machine.travel("attack")
	# Disable dash pass-through collision (simulate entering charge mode).
	set_collision_layer_value(GlobalReferences.DASH_PASSABLE_LAYER_INDEX, false)
	
	# Enable continuous collision detection (CCD) for fast charge movement
	
	
	# Calculate the direction toward the player.
	var to_player: Vector3 = (player.global_position - global_position).normalized()
	movement.apply_rotation(self, to_player)
	# Execute the charge movement (lunge).

	var delta = get_physics_process_delta_time()

	movement.handle_lunge(self, delta, charge_distance, charge_duration)
	
	# Wait for the duration of the charge plus a short pause.
	var current_charge_duration = charge_duration
	
	while current_charge_duration > 0:
		if not is_on_navmesh():
			print("Not on navmesh, stopping charge.")
			velocity = Vector3.ZERO  # Stop the charge if not on the navmesh.
			break
		# Continue the lunge movement.
		delta = get_physics_process_delta_time()
		current_charge_duration -= delta
		# Apply the lunge movement.
		movement.handle_lunge(self, delta)
		await get_tree().physics_frame
	

	state_machine.travel("after_attack")  # Return to a default movement animation.
	
	# Reset the collision layer back to normal.
	set_collision_layer_value(GlobalReferences.DASH_PASSABLE_LAYER_INDEX, true)

	# Wait for the duration of the charge plus a short pause.
	var current_after_charge_duration = pause_after_charge
	
	while current_after_charge_duration > 0:
		# Continue the lunge movement.
		if current_state == BaseState.DEATH or current_state == BaseState.HIT_REACTION:
			attack_cooldown()
			return  # Exit if the enemy is stunned during telegraph.
		delta = get_physics_process_delta_time()
		current_after_charge_duration -= delta
		
		await get_tree().physics_frame


	state_machine.travel("Movement")

	attack_cooldown()


# --- Reset Charge Attack State ---
func reset_charge_attack() -> void:
	is_executing_charge = false
	charge_state = ChargeAttackState.NONE


func attack_cooldown() -> void:
	# Enter cooldown phase.
	charge_state = ChargeAttackState.COOLDOWN
	
	current_state = BaseState.MOVING  # Resume regular movement.

	# Wait for the cooldown duration.
	await get_tree().create_timer(charge_cooldown).timeout
	
	# Reset the charge attack.
	reset_charge_attack()
