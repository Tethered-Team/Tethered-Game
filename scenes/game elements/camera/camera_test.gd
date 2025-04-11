extends Camera3D

# Target property with a setter to update the target node

var _target_node: Node3D
var _distance: float = 40.0
var _angle_horizontal: float = 45.0
var _angle_vertical: float = 30.0
var _custom_size: float = 1.0
var left_margin: float = 0.2
var right_margin: float = 0.2
var top_margin: float = 0.2
var bottom_margin: float = 0.2

# Store the fixed camera offset vector - calculated once when angles change
var _fixed_offset: Vector3 = Vector3.ZERO
var _fixed_rotation: Basis = Basis.IDENTITY

# Add these variables to track the target's last screen position
var _last_target_screen_pos = Vector2.ZERO
var _drag_horizontal_offset: float = 0.0
var _drag_vertical_offset: float = 0.0

@export var target: Node3D:
	set(value):
		_target_node = value
		update_camera_transform()
	get:
		return _target_node

@export_category("Camera Settings")
@export var distance: float = 40.0:
	set(value):
		_distance = value
		update_camera_transform()
	get:
		return _distance

@export var angle_horizontal: float = 45.0:
	set(value):
		_angle_horizontal = value
		update_camera_transform()
	get:
		return _angle_horizontal

@export var angle_vertical: float = 30.0:
	set(value):
		_angle_vertical = value
		update_camera_transform()
	get:
		return _angle_vertical

@export_range(0.1, 50.0, 1) var custom_size: float = 1.0:
	set(value):
		_custom_size = value
		update_camera_transform()
	get:
		return _custom_size

@export_category("Drag Margins")
@export var drag_horizontal_enabled: bool = false
@export var drag_vertical_enabled: bool = false

@export var drag_left_margin: float = 0.2:
	set(value):
		left_margin = clamp(value, 0.0, 1.0)
	get:
		return left_margin
		
@export var drag_right_margin: float = 0.2:
	set(value):
		right_margin = clamp(value, 0.0, 1.0)
	get:
		return right_margin
		
@export var drag_top_margin: float = 0.2:
	set(value):
		top_margin = clamp(value, 0.0, 1.0)
	get:
		return top_margin
		
@export var drag_bottom_margin: float = 0.2:
	set(value):
		bottom_margin = clamp(value, 0.0, 1.0)
	get:
		return bottom_margin

@export var drag_horizontal_offset: float = 0.0:
	set(value):
		_drag_horizontal_offset = clamp(value, -1.0, 1.0)
	get:
		return _drag_horizontal_offset
		
@export var drag_vertical_offset: float = 0.0:
	set(value):
		_drag_vertical_offset = clamp(value, -1.0, 1.0)
	get:
		return _drag_vertical_offset

@export_category("Position Smoothing")
@export var position_smoothing: bool = true
@export var position_smoothing_speed: float = 2.0

@export_category("Editor")
@export var draw_drag_margin: bool = true
@export var debug_draw_colors: Color = Color(1, 0, 0)

func _ready() -> void:
	if _target_node == null:
		push_warning("No target node set for the camera.")
		return

	# Initialize the camera transform
	update_camera_transform()

func update_camera_transform() -> void:
	if not is_inside_tree() or _target_node == null:
		return

	# Calculate the fixed offset vector based on spherical coordinates
	var rad_h = deg_to_rad(angle_horizontal)
	var rad_v = deg_to_rad(angle_vertical)
	_fixed_offset = Vector3(
		distance * sin(rad_h) * cos(rad_v),
		distance * sin(rad_v),
		distance * cos(rad_h) * cos(rad_v)
	)
	
	# Calculate and store the fixed rotation
	var target_pos = _target_node.global_transform.origin
	var camera_pos = target_pos + _fixed_offset
	var temp_transform = global_transform
	temp_transform.origin = camera_pos
	temp_transform = temp_transform.looking_at(target_pos, Vector3.UP)
	_fixed_rotation = temp_transform.basis
	
	# Apply transform and size
	global_transform.origin = camera_pos
	global_transform.basis = _fixed_rotation
	
	if _custom_size > 0.001:
		size = _custom_size
		
	if Engine.is_editor_hint():
		# Update the camera's size in the editor
		look_at(target_pos, Vector3.UP)
		

func draw_drag_margin_lines() -> void:
	if not Engine.is_editor_hint() or not draw_drag_margin:
		return
		
	# Get camera's basis vectors to draw lines in camera space
	var cam_basis = global_transform.basis
	var cam_pos = global_transform.origin
	
	# Calculate the view frustum at some distance (e.g., 10 units in front)
	var view_distance = 10.0
	var height = 2.0 * view_distance * tan(deg_to_rad(fov * 0.5))
	var width = height * get_viewport().size.x / get_viewport().size.y
	
	# Calculate corners with margins
	var left = -width / 2 - left_margin
	var right = width / 2 + right_margin  
	var top = height / 2 + top_margin
	var bottom = -height / 2 - bottom_margin
	
	# Calculate world space positions
	var forward = -cam_basis.z.normalized() * view_distance
	var top_left = cam_pos + forward + cam_basis.x * left + cam_basis.y * top
	var top_right = cam_pos + forward + cam_basis.x * right + cam_basis.y * top
	var bottom_left = cam_pos + forward + cam_basis.x * left + cam_basis.y * bottom
	var bottom_right = cam_pos + forward + cam_basis.x * right + cam_basis.y * bottom
	
	# Draw the rectangle using DebugDraw
	DebugDraw3D.draw_line(top_left, top_right, debug_draw_colors)
	DebugDraw3D.draw_line(top_right, bottom_right, debug_draw_colors)
	DebugDraw3D.draw_line(bottom_right, bottom_left, debug_draw_colors)
	DebugDraw3D.draw_line(bottom_left, top_left, debug_draw_colors)

func apply_drag_margins(target_screen_pos: Vector2) -> Vector2:
	var drag_direction = Vector2.ZERO
	
	#print("Target screen pos: ", target_screen_pos)
	
	# Horizontal drag
	if drag_horizontal_enabled:
		if target_screen_pos.x > 0.5 + right_margin * 0.5:
			drag_direction.x = 1
		elif target_screen_pos.x < 0.5 - left_margin * 0.5:
			drag_direction.x = -1
	# Vertical drag
	if drag_vertical_enabled:
		if target_screen_pos.y < 0.5 + top_margin * 0.5:
			drag_direction.y = 1
		elif target_screen_pos.y > 0.5 + bottom_margin * 0.5:
			drag_direction.y = -1
			
	print("Target screen pos: ", target_screen_pos, " ---- Final drag direction: ", drag_direction)
	return drag_direction
	

func _physics_process(delta: float) -> void:
	if not is_inside_tree() or _target_node == null:
		return
		
	# Get target's screen position (normalized 0-1)
	var viewport = get_viewport()
	if viewport == null:
		return
		
	var target_screen_pos = unproject_position(_target_node.global_transform.origin)
	target_screen_pos = Vector2(
		target_screen_pos.x / viewport.size.x,
		target_screen_pos.y / viewport.size.y
	)
	
	var margin_drag = apply_drag_margins(target_screen_pos)

	var new_raw_camera_pos = to_local(_target_node.global_transform.origin + _fixed_offset)

	var new_camera_pos = Vector3.ZERO
	
	
	
	
	
