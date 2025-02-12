extends Node3D

		


func _on_body_entered(body):
	get_tree().reload_current_scene()
