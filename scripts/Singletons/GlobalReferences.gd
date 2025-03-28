extends Node

# References to key game nodes.
var player: Player = null
var enemy_manager: Node = null
var main_camera: Camera3D = null
var camera_controller: Node3D = null


func get_player() -> Player:
	return player 

func set_player(new_player: Player) -> void:
	player = new_player


func get_enemy_manager() -> Node:
	return enemy_manager

func set_enemy_manager(new_enemy_manager: Node) -> void:
	enemy_manager = new_enemy_manager

func get_camera() -> Camera3D:
	return main_camera 

func set_camera(new_camera: Camera3D) -> void:
	main_camera = new_camera
	camera_controller = new_camera.get_parent()
