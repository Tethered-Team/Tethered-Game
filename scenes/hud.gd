extends CanvasLayer

@onready var player: CharacterBody3D = $"../Player"



@onready var debug_current_control_set_text: RichTextLabel = $Control/DebugCurrentControlSetText


func _ready() -> void:
	"""Initialize the HUD."""
	#health_bar = $HealthBar
	#health_label = $HealthLabel

	# Connect to the player's health component
	#player.connect("health_changed", self, "_on_health_changed")
	#player.connect("control_set_changed", self, "_on_control_set_changed")
	InputHandler.connect("control_set_changed", Callable(self, "_on_control_set_changed"))


func _on_control_set_changed(scheme: InputHandler.INPUT_SCHEMES) -> void:
	"""Update the HUD based on the current control set."""
	debug_current_control_set_text.text = InputHandler.INPUT_SCHEME_NAMES[scheme]
