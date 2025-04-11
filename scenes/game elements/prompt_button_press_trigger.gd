extends Area3D

@export var prompt: Node3D
@export var object_checking_for_prompt: Node3D


func _ready() -> void:
	
	monitoring = false

	if prompt == null:
		print("Prompt node is not assigned.")
	else:
		prompt.visible = false

	GlobalEvents.connect("event_arena_end", Callable(self, "set_trigger_active"))

	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Player") and body is CharacterBody3D:
		print("Player entered the trigger area.")
		show_prompt(true)
	else:
		print("Non-player entity entered the trigger area.")


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("Player") and body is CharacterBody3D:
		print("Player exited the trigger area.")
		show_prompt(false)
	else:
		print("Non-player entity exited the trigger area.")
	

func show_prompt(state: bool) -> void:
	# Show the prompt to the player
	print("Showing prompt to player.")
	prompt.visible = state

	if object_checking_for_prompt:
		if state:
			InputHandler.connect("confirm_pressed", Callable(object_checking_for_prompt, "_on_confirm_pressed"))

		else:
			InputHandler.disconnect("confirm_pressed", Callable(object_checking_for_prompt, "_on_confirm_pressed"))

func set_trigger_active() -> void:
	monitoring = true
