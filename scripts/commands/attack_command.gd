extends Command
class_name AttackCommand

var attack_type: String = "light"  # or "heavy", set this when creating the command

func execute(actor):
    # Assumes actor has a weapon_component property.
    actor.weapon_component.attack(attack_type)