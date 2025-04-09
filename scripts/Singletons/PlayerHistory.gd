extends Node

@export var max_history: int = 20
var position_history: Array[Vector3] = []
var player: Player = null

func _ready() -> void:
	# Initialize the player reference from GlobalReferences
	player = GlobalReferences.player

func _physics_process(_delta: float) -> void:
	var player_position = GlobalReferences.player.global_transform.origin
	position_history.append(player_position)
	if position_history.size() > max_history:
		position_history.pop_front()


func get_player_position_slowest() -> Vector3:
	if position_history.size() > 0:
		return position_history[0]
	return Vector3.ZERO

func get_player_position_midd() -> Vector3:
	if position_history.size() > 0:
		@warning_ignore("integer_division")
		return position_history[position_history.size() / 2]
	return Vector3.ZERO

func get_player_position_fastest() -> Vector3:
	if position_history.size() > 0:
		return position_history[position_history.size() - 1]
	return Vector3.ZERO

func get_player_position_at_index(index: int) -> Vector3:
	if index >= 0 and index < position_history.size():
		return position_history[index]
	return Vector3.ZERO

func get_player_position_history() -> Array[Vector3]:
	return position_history

func get_player_position_history_size() -> int:
	return position_history.size()

func clear_player_position_history() -> void:
	position_history.clear()

