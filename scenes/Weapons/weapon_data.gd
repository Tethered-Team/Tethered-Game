extends Resource
class_name WeaponData

@export var name: String = "Weapon"
@export var damage: int = 10
@export var attack_speed: float = 1.0
@export var effect: String = ""  # e.g., "fire", "shock", "bleed"

# ✅ Define separate combo sequences for different attack types
@export var light_combo: Array[String] = ["attack_0", "attack_1", "attack_2"]  # Animation names
@export var heavy_combo: Array[String] = ["heavy_attack_0", "heavy_attack_1"]
@export var special_combo: Array[String] = ["special_0"]

# ✅ Allow upgrades to modify combos
func modify_combo(attack_type: String, new_combo: Array[String]):
	match attack_type:
		"light": light_combo = new_combo
		"heavy": heavy_combo = new_combo
		"special": special_combo = new_combo
