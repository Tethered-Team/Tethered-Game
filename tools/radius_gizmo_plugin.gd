# extends EditorNode3DGizmoPlugin

# func _init():
# 	set_gizmo_name("RadiusGizmo")

# func _has_gizmo(node):
# 	return node is RadiusVisualizer

# func _redraw(gizmo):
# 	var node = gizmo.get_node()
# 	var radius = node.radius

# 	var lines = PackedVector3Array()
# 	var steps = 64
# 	for i in steps:
# 		var angle = TAU * i / steps
# 		var next_angle = TAU * (i + 1) / steps
# 		lines.append(Vector3(cos(angle) * radius, 0, sin(angle) * radius))
# 		lines.append(Vector3(cos(next_angle) * radius, 0, sin(next_angle) * radius))
# 	gizmo.add_lines(lines, get_material("main", gizmo))
