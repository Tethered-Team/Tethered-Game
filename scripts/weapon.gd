extends Node3D

class_name Weapon

@export var attack_speed: float = 1.0
@export var attack_damage: int = 10

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func attack():
	if animation_player:
		animation_player.play("attack")  # Play weapon-specific animation
