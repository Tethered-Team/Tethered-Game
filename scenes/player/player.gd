extends CharacterBody3D

@onready var movement = $Movement
@onready var dash = $Dash
@onready var weapon_componenet = $WeaponComponent
@onready var stats = $Stats
@onready var animation_tree = $AnimationTree
@onready var playback = animation_tree.get("parameters/playback")
@onready var camera

var input_vector:Vector2 = Vector2.ZERO
var move_vector: Vector3 = Vector3.ZERO
var is_grounded: bool
var is_dashing: bool
var is_running: bool

func _ready() -> void:
	camera = get_viewport().get_camera_3d()

func _physics_process(delta):
	is_grounded = is_on_floor()

	# Get movement input from InputHandler
	move_vector = InputHandler.get_movement_vector()
	
	animation_tree.set("parameters/Walk/blend_position", move_vector.length())
	
	movement.apply_movement(self, move_vector, delta, is_grounded)


	

	# Handle dash input
	dash.handle_dash(self, delta)
	
	movement.apply_smooth_rotation(self, move_vector, delta)

	is_dashing = dash.is_dashing
	is_running = dash.is_running
	
	print(is_dashing, is_running)

	move_and_slide()

	#print("Velocity: ", velocity)
