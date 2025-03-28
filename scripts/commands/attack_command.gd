extends Command
class_name AttackCommand

var attack_type: String = "light"  # or "heavy", set this when creating the command

func execute(actor: Node3D) -> void:
	var player = actor as Player
	if player:
		player.weapon_component.attack(attack_type)
	else:
		push_warning("Actor does not have a weapon_component.")
