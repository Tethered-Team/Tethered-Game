extends Node3D

@export var weapon: WeaponData  # Assign in Inspector
@export var hitbox: Area3D  # Reference to the weapon's hitbox

var current_combo = []
var current_attack_type = "light"
var combo_step: int = 0
var can_attack: bool = true
var combo_timer: Timer

func _ready():
	combo_timer = Timer.new()
	combo_timer.one_shot = true
	combo_timer.wait_time = 0.5  # Time allowed for combo chaining
	combo_timer.timeout.connect(_reset_combo)
	add_child(combo_timer)

func attack(attack_type: String):
	if not can_attack or not weapon:
		return

	# Get the correct combo sequence for the attack type
	match attack_type:
		"light": current_combo = weapon.light_combo
		"heavy": current_combo = weapon.heavy_combo
		"special": current_combo = weapon.special_combo
		_: return  # Invalid attack type

	current_attack_type = attack_type

	if combo_step >= current_combo.size():
		combo_step = 0  # Restart combo if at the end

	var animation_name = current_combo[combo_step]
	if $AnimationPlayer.has_animation(animation_name):
		$AnimationPlayer.play(animation_name)

	can_attack = false

	# Enable hitbox briefly
	hitbox.monitoring = true
	await get_tree().create_timer(0.2).timeout
	hitbox.monitoring = false

	# Start combo buffer window
	combo_timer.start()

	# Start cooldown based on weapon attack speed
	await get_tree().create_timer(1.0 / weapon.attack_speed).timeout
	can_attack = true
	combo_step += 1  # Move to the next combo step

func _reset_combo():
	combo_step = 0  # Reset combo if no input received in time
