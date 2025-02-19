extends Node3D

@export var hand_socket_path: NodePath
@export var back_socket_path: NodePath
@export var shield_socket_path: NodePath

@onready var hand_socket: Node3D = get_node(hand_socket_path)
@onready var back_socket: Node3D = get_node(back_socket_path)
@onready var shield_socket: Node3D = get_node(shield_socket_path)

var equipped_weapon: Node3D = null

func equip_weapon(weapon_scene: PackedScene, weapon_type: String):
	if equipped_weapon:
		equipped_weapon.queue_free()  # Remove the old weapon

	# Instance the new weapon
	equipped_weapon = weapon_scene.instantiate()
	
	# Attach to the correct socket based on weapon type
	var target_socket = get_socket_for_weapon(weapon_type)
	if target_socket:
		target_socket.add_child(equipped_weapon)
		equipped_weapon.global_transform = target_socket.global_transform
	else:
		print("⚠️ No valid socket found for weapon type:", weapon_type)

	print("Equipped:", equipped_weapon.name, "to", target_socket.name if target_socket else "None")

func get_socket_for_weapon(weapon_type: String) -> Node3D:
	match weapon_type:
		"sword", "dagger", "axe": return hand_socket
		"bow", "rifle": return back_socket
		"shield": return shield_socket
	return null
