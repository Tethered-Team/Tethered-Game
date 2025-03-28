@tool
extends Resource
class_name WeaponData

@export var name: String = "Weapon"

@export var light_combo: Array[AttackData] = []
@export var heavy_combo: Array[AttackData] = []
@export var special_combo: Array[AttackData] = []
@export var dash_attack: AttackData

@export var base_damage: float = 10

@export var weapon_model: PackedScene   # Weapon model resource.

@export var attachment_bone: String = "hand"  # Bone name

# The actual transform used at runtime.
@export var attachment_transform: Transform3D = Transform3D.IDENTITY:
	get:
		return _attachment_transform
	set(value):
		_attachment_transform = value
		attachment_euler = value.basis.get_euler()

# Additional property to edit using Euler angles.
@export var attachment_euler: Vector3 = Vector3.ZERO:
	get:
		return _attachment_euler
	set(value):
		_attachment_euler = value
		_attachment_transform = Transform3D(Basis.from_euler(value), _attachment_transform.origin)

var _attachment_transform: Transform3D = Transform3D.IDENTITY
var _attachment_euler: Vector3 = Vector3.ZERO

## Function: _init
## Purpose: Initialize the WeaponData resource by setting attachment Euler angles from the transform.
## Parameters: None.
## Returns: void.
func _init() -> void:
	# Initialize attachment_euler from attachment_transform.
	attachment_euler = attachment_transform.basis.get_euler()

## Function: modify_combo
## Purpose: Modify the attack combo sequence for the given attack type.
## Parameters:
##   attack_type (String): The type of attack ("light", "heavy", or "special").
##   new_combo (Array[AttackData]): An array of new attack data for the combo.
## Returns: void.
func modify_combo(attack_type: String, new_combo: Array[AttackData]) -> void:
	"""Modify the combo sequence for the specified attack type with a new combo array."""
	match attack_type:
		"light": light_combo = new_combo
		"heavy": heavy_combo = new_combo
		"special": special_combo = new_combo
