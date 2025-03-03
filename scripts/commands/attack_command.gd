extends Command
class_name AttackCommand

func execute(actor):
	if actor.weapon_component:
		actor.weapon_component.attack()
