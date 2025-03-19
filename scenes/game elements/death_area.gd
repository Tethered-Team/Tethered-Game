extends Node3D


func _on_body_entered(body):
	if body is CharacterBody3D:
		print("Player entered death area. Reloading scene...")
		call_deferred("reload_scene")

func reload_scene():
	get_tree().reload_current_scene()
