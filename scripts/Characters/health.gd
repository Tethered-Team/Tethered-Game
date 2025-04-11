
extends Node

var parent = null

@export var max_health: float = 100.0
@export var current_health: float = 100.0
var is_alive: bool = true

## Function: _ready
## Purpose: Initialize the health component.
## Parameters: None.
## Returns: void.
func _ready():
	"""Initialize the health component."""
	parent = get_parent()

	reset()

## Function: take_damage
## Purpose: Apply damage to the character's health.
## Parameters:
##   damage (float): The amount of damage to apply.
##   attacker (Node): The attacker that caused the damage.  
## Returns: void.
func damage(amount: float) -> void:
	"""Apply damage to the character's health."""
	if not is_alive:
		return

	current_health -= amount
	if current_health <= 0:
		die()
		

func heal(amount: float) -> void:
	"""Heal the character by the specified amount."""
	current_health = min(current_health + amount, max_health)

func reset() -> void:
	current_health = max_health

func die():
	is_alive = false
	print("Character has died!")
	
	if parent.has_method("die"):
		parent.call_deferred("die")

func is_dead() -> bool:
	"""Check if the character is dead."""
	return not is_alive
