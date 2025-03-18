extends Node

var current_weapon: Weapon = null

## Function: equip_weapon
## Purpose: Set the specified weapon as the currently active weapon.
## Parameters:
##   new_weapon (Weapon): The weapon to equip.
## Returns: void.
func equip_weapon(new_weapon: Weapon):
	"""Set the provided weapon as the current active weapon."""
	current_weapon = new_weapon

## Function: attack
## Purpose: Execute the current weapon's attack function.
## Parameters: None.
## Returns: void.
func attack():
	"""Execute the current weapon's attack function."""
	if current_weapon:
		current_weapon.attack()

## Function: apply_damage_upgrade
## Purpose: Increase the damage value of the current weapon by a specified amount.
## Parameters:
##   amount (float): The amount by which to upgrade the weapon's damage.
## Returns: void.
func apply_damage_upgrade(amount: float):
	"""Increase the current weapon’s damage by the specified amount."""
	if current_weapon:
		current_weapon.modified_damage += amount
		print("Upgraded damage:", current_weapon.modified_damage)

## Function: apply_special_upgrade
## Purpose: Apply a special effect upgrade (fire, lightning, or poison) to the current weapon.
## Parameters:
##   upgrade_type (String): The type of special upgrade to apply.
## Returns: void.
func apply_special_upgrade(upgrade_type: String):
	"""Apply a special effect upgrade (fire, lightning, or poison) to the current weapon."""
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
