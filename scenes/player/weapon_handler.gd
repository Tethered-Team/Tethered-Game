extends Node

var current_weapon: Weapon = null

func equip_weapon(new_weapon: Weapon):
	"""Set the currently active weapon."""
	current_weapon = new_weapon

func attack():
	"""Execute the assigned attack function."""
	if current_weapon:
		current_weapon.attack()

func apply_damage_upgrade(amount: float):
	"""Increase the weapon's damage."""
	if current_weapon:
		current_weapon.modified_damage += amount
		print("Upgraded damage:", current_weapon.modified_damage)

func apply_special_upgrade(upgrade_type: String):
	"""Apply a special effect to the weapon."""
	if current_weapon:
		match upgrade_type:
			"fire":
				current_weapon.special_effect = func():
					print("🔥 Fire effect applied on hit!")
			"lightning":
				current_weapon.special_effect = func():
					print("⚡ Lightning strikes on hit!")
			"poison":
				current_weapon.special_effect = func():
					print("☠️ Poison applied on hit!")
		print("Special effect applied:", upgrade_type)
