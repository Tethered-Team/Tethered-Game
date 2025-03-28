extends Node3D
class_name WeaponComponent


@export var weapon: WeaponData  # Assigned via the Inspector.
@onready var parent: CharacterBody3D = get_parent()
@onready var animation_player: AnimationPlayer = parent.get_node("AnimationPlayer")
@onready var player_skeleton: Skeleton3D = $"../Model/Rig/Skeleton3D"   # Ensure this correctly points to the player's Skeleton3D.

var current_combo: Array[AttackData] = []
var current_attack_type: String = "light"
var current_attack: AttackData = null

var combo_step: int = 0
var can_attack: bool = true
var can_move: bool = true
var combo_timer: Timer
@export var combo_timer_duration: float = 0.5
var attack_timer: Timer
var weapon_instance: Node3D = null
var hitbox: Area3D = null
var is_attacking: bool = false


## Function: _ready
## Purpose: Initialize the weapon component, set up the combo timer, and attach the weapon model.
## Parameters: None.
## Returns: void.
func _ready() -> void:
	"""Initialize the combo timer and attach the weapon model to the player's skeleton."""
	combo_timer = Timer.new()
	combo_timer.one_shot = true
	combo_timer.wait_time = 0.5  # Time allowed for combo chaining
	combo_timer.timeout.connect(_reset_combo)
	add_child(combo_timer)

	# Load and attach the weapon model
	attach_weapon()

	# Create a persistent timer for the attack window.
	attack_timer = Timer.new()
	attack_timer.one_shot = true
	add_child(attack_timer)
	attack_timer.timeout.connect(Callable(self, "_on_attack_window_timeout"))

## Function: attack
## Purpose: Trigger an attack by selecting the appropriate combo and playing the associated animation; start timers.
## Parameters:
##   attack_type (String): The type of attack to trigger.
## Returns: void.
func attack(attack_type: String) -> void:
	print("attack command")
	if not can_attack or not weapon:
		return

	is_attacking = true  # Mark attack start
	can_attack = false    # Lock further combo unless reset by the combo timer.
	can_move = false      # Disable movement during the attack animation.

	# Choose the proper combo based on attack_type.
	match attack_type:
		"light": current_combo = weapon.light_combo
		"heavy": current_combo = weapon.heavy_combo
		"special": current_combo = weapon.special_combo
		_: return  # Invalid attack type

	if current_combo.size() != 0:
		current_attack_type = attack_type

		if combo_step >= current_combo.size() - 1:
			current_attack = current_combo[combo_step]
			combo_step = 0  # Reset chain
			print("Combo Complete!", combo_step)
		else:
			current_attack = current_combo[combo_step]
			combo_step += 1
	
	# First, exit the current attack state.
	parent.playback.travel("idle")
	# Optionally, force an immediate update (or wait one frame)
	# call_deferred("start_attack_animation", current_attack)

	# Then start the new attack animation.
	start_attack_animation()
		
	can_attack = false  # Prevent new attacks until window expires
	
	# Restart the combo reset timer.
		
	# Start the attack window timer.
	start_attack_timer(current_attack.start_attack_window_offset)
	


	# Optionally, also start a movement timer to re-enable movement earlier or when the attack animation ends.
	can_move = false
	# When attack starts, only connect if not already connected:
	if not animation_player.is_connected("animation_finished", Callable(self, "_on_movement_timer_timeout")):
		animation_player.connect("animation_finished", Callable(self, "_on_movement_timer_timeout"), CONNECT_ONE_SHOT)


## Function: _reset_combo
## Purpose: Reset the combo step when the combo timer expires.
## Parameters: None.
## Returns: void.
func _reset_combo() -> void:
	"""Reset combo step to 0 when the combo timer expires."""
	combo_step = 0  # Reset combo if no input received in time
	print("Combo Reset!", combo_step)
	# When no follow-up input is received in time,
	# you can leave can_attack as true (allowing the next attack) or false
	# depending on your design.
	can_attack = true

## Function: attach_weapon
## Purpose: Attach the weapon model to the designated bone on the player's skeleton.
## Parameters: None.
## Returns: void.
func attach_weapon() -> void:
	"""Attach the weapon model to the specified bone on the player's skeleton."""
	if weapon.weapon_model and not weapon_instance:
		weapon_instance = weapon.weapon_model.instantiate()
		# Create a BoneAttachment3D to attach to the player's skeleton.
		var bone_attachment: BoneAttachment3D = BoneAttachment3D.new()
		bone_attachment.bone_name = weapon.attachment_bone  # Use the specified attachment bone.
		bone_attachment.transform = weapon.attachment_transform  # Set proper orientation / offset.
		bone_attachment.add_child(weapon_instance)
		player_skeleton.add_child(bone_attachment)
		
		# Connect the hitbox signal if a hitbox exists.
		hitbox = weapon_instance.get_node("HitBox")
		if hitbox:
			hitbox.connect("body_entered", Callable(self, "_on_hitbox_body_entered"))
			hitbox.monitoring = false
		
## Function: remove_weapon
## Purpose: Remove the attached weapon model from the player's skeleton.
## Parameters: None.
## Returns: void.
func remove_weapon() -> void:
	"""Remove the attached weapon model from the player's skeleton."""
	if weapon_instance:
		weapon_instance.queue_free()
		weapon_instance = null

## Function: _on_attack_window_timeout
## Purpose: Handle the attack window timeout by resetting attack state and incrementing the combo step.
## Parameters: None.
## Returns: void.
func _on_attack_window_timeout() -> void:
	"""Callback function that resets the attack state and advances the combo step when the attack window ends."""
	# End the current attack state so that a new attack can be accepted.
	is_attacking = false
	can_attack = true

	#Disable the hitbox for the attack.
	hitbox.monitoring = false

	# Optionally, you might auto-increment the combo here,
	# but only if you want that behavior when no input is buffered.
	# Leaving it out gives you full control—increment on a new attack command.

## Function: start_attack_timer
## Purpose: Start or reset an attack timer for the duration of the attack window.
## Parameters:
##   duration (float): The duration (in seconds) for the attack timer.
## Returns: void.
func start_attack_timer(duration: float) -> void:
	"""Start a new one-shot timer for the attack window."""
	attack_timer.wait_time = duration
	# If it’s running, stop it first
	if attack_timer.is_stopped() == false:
		attack_timer.stop()
	attack_timer.start()

## Function: start_attack_animation
## Purpose: Start the attack animation for the given attack data.
## Parameters:
##   current_attack (AttackData): The data for the current attack.
## Returns: void.
func start_attack_animation() -> void:
	# Set the new attack animation name on the attack_node.
	parent.attack_node.animation = current_attack.animation_name
	print("Attack Animation:", current_attack.animation_name)
	# Change into the attack state.
	parent.playback.travel("Attack")
	
	# Configure and play the animation with no blend time so it starts smoothly.
	animation_player.speed_scale = current_attack.attack_speed_multiplier
	var start_offset: float = (current_attack.start_offset_percent * animation_player.get_animation(current_attack.animation_name).length)
	
	animation_player.play(current_attack.animation_name, 0.0, current_attack.attack_speed_multiplier, start_offset)

	# Enable the hitbox for the attack.
	hitbox.monitoring = true

	# (Optional) print out length for debugging.
	var attack_length: float = animation_player.get_animation(current_attack.animation_name).length
	print("Attack Animation Length:", attack_length)

	combo_timer.stop()
	combo_timer.wait_time = attack_length + combo_timer_duration
	combo_timer.start()

## Function: _on_hitbox_body_entered
## Purpose: Handle the event when a body enters the hitbox.
## Parameters:
##   body (Node): The body that entered the hitbox.
## Returns: void.
func _on_hitbox_body_entered(body: Node) -> void:

	if is_attacking:
		# Check if the collided body is an enemy and process the hit.
		if body.is_in_group("Enemies"):
			print("Hit enemy:", body.name)
			# Add your attack logic here (e.g., applying damage).
			body.apply_damage(calulate_damage())
			
			# Apply any special effects.

			

## Function: calulate_damage
## Purpose: Calculate the damage for the current attack based on the weapon's modified damage.
## Parameters: None.
## Returns: float.
func calulate_damage() -> float:
	"""Calculate the damage for the current attack based on the weapon's modified damage."""
	return weapon.base_damage + current_attack.per_attack_damage_modifier

# Called, for example, when the attack animation (or movement lock period) is over.
func _on_movement_timer_timeout(_anim_name: String) -> void:
	can_move = true
