extends Node3D
class_name WeaponComponent


@export var weapon: WeaponData  # Assigned via the Inspector.
@onready var parent: CharacterBody3D = get_parent()
@onready var animation_player: AnimationPlayer = parent.get_node("AnimationPlayer")
@onready var player_skeleton: Skeleton3D = $"../Model/Rig/Skeleton3D"   # Ensure this correctly points to the player's Skeleton3D.

var current_combo: Array[AttackData] = []
var current_attack_type: String = "light"
var combo_step: int = 0
var can_attack: bool = true
var combo_timer: Timer
@export var combo_timer_duration: float = 0.5
var attack_timer: Timer
var weapon_instance: Node3D = null
var is_attacking: bool = false

## Function: _ready
## Purpose: Initialize the weapon component, set up the combo timer, and attach the weapon model.
## Parameters: None.
## Returns: void.
func _ready():
	"""Initialize the combo timer and attach the weapon model to the player's skeleton."""
	combo_timer = Timer.new()
	combo_timer.one_shot = true
	combo_timer.wait_time = 0.5  # Time allowed for combo chaining
	combo_timer.timeout.connect(_reset_combo)
	add_child(combo_timer)

	# Load and attach the weapon model
	attach_weapon()

## Function: attack
## Purpose: Trigger an attack by selecting the appropriate combo and playing the associated animation; start timers.
## Parameters:
##   attack_type (String): The type of attack to trigger.
## Returns: void.
func attack(attack_type: String):
	print("attack command")
	if not can_attack or not weapon:
		return

	is_attacking = true  # Mark attack start

	# Choose the proper combo based on attack_type.
	match attack_type:
		"light": current_combo = weapon.light_combo
		"heavy": current_combo = weapon.heavy_combo
		"special": current_combo = weapon.special_combo
		_: return  # Invalid attack type

	var current_attack: AttackData = null

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
	start_attack_animation(current_attack)
		
	can_attack = false  # Prevent new attacks until window expires
	
	# Restart the combo reset timer.
		
	# Start the attack window timer.
	start_attack_timer(current_attack.start_attack_window_offset)
	
	parent.get_closest_enemy(current_attack.lunge_distance, current_attack.aim_assist_angle)

## Function: _reset_combo
## Purpose: Reset the combo step when the combo timer expires.
## Parameters: None.
## Returns: void.
func _reset_combo():
	"""Reset combo step to 0 when the combo timer expires."""
	combo_step = 0  # Reset combo if no input received in time
	print("Combo Reset!", combo_step)

## Function: attach_weapon
## Purpose: Attach the weapon model to the designated bone on the player's skeleton.
## Parameters: None.
## Returns: void.
func attach_weapon():
	"""Attach the weapon model to the specified bone on the player's skeleton."""
	if weapon.weapon_model and not weapon_instance:
		weapon_instance = weapon.weapon_model.instantiate()
		# Create a BoneAttachment3D to attach to the player's skeleton.
		var bone_attachment = BoneAttachment3D.new()
		bone_attachment.bone_name = weapon.attachment_bone  # Use the specified attachment bone.
		bone_attachment.transform = weapon.attachment_transform  # Set proper orientation / offset.
		bone_attachment.add_child(weapon_instance)
		player_skeleton.add_child(bone_attachment)
		
## Function: remove_weapon
## Purpose: Remove the attached weapon model from the player's skeleton.
## Parameters: None.
## Returns: void.
func remove_weapon():
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
	# Optionally, you might auto-increment the combo here,
	# but only if you want that behavior when no input is buffered.
	# Leaving it out gives you full control—increment on a new attack command.

## Function: start_attack_timer
## Purpose: Start or reset an attack timer for the duration of the attack window.
## Parameters:
##   duration (float): The duration (in seconds) for the attack timer.
## Returns: void.
func start_attack_timer(duration: float) -> void:
	"""Start (or reset) a timer with the given duration to govern the attack window."""
	# If the timer doesn't exist, create one.
	if attack_timer == null:
		attack_timer = Timer.new()
		attack_timer.one_shot = true
		add_child(attack_timer)
	else:
		# Stop the timer and disconnect previous connections.
		attack_timer.stop()
		attack_timer.timeout.disconnect(_on_attack_window_timeout)
		
	# Set the duration and connect the timeout signal.
	attack_timer.wait_time = duration
	attack_timer.timeout.connect(_on_attack_window_timeout)
	attack_timer.start()

## Function: start_attack_animation
## Purpose: Start the attack animation for the given attack data.
## Parameters:
##   current_attack (AttackData): The data for the current attack.
## Returns: void.
func start_attack_animation(current_attack: AttackData) -> void:
	# Set the new attack animation name on the attack_node.
	parent.attack_node.animation = current_attack.animation_name
	print("Attack Animation:", current_attack.animation_name)
	# Change into the attack state.
	parent.playback.travel("Attack")
	# Now play the animation (or seek to the desired offset).
	animation_player.play(current_attack.animation_name)
	animation_player.seek(current_attack.start_offset, true)
	
	# (Optional) Print out length for debugging.
	var attack_length = animation_player.get_animation(current_attack.animation_name).length
	print("Attack Animation Length:", attack_length)

	combo_timer.stop()
	combo_timer.wait_time = attack_length + combo_timer_duration
	combo_timer.start()
