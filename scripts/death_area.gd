extends Node3D


func _on_body_entered(body) -> void:
	if body is CharacterBody3D:
		print("Player entered death area. Reloading scene...")
		call_deferred("reload_scene")

func reload_scene() -> void:
	get_tree().reload_current_scene()
