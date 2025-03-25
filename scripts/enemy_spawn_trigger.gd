extends Area3D

@export var has_been_triggered: bool = false

@export var enemies: Array[Node3D]  # Manually assigned enemies
@export var enemy_parent: NodePath  # Path to a parent node containing multiple enemies
@export var enemy_group: String = "enemies"  # Group name for spawning all enemies in a group

@export var list: bool = true
@export var parent: bool = true
@export var group: bool = true

func _on_body_entered(body):
	
	if not has_been_triggered:
		print("Trigger entered:", body)

		if body.is_in_group("Player") and body is CharacterBody3D:
			if list:
				enemies_by_list()
				
			if parent:
				enemies_by_list()
				
			if group:
				enemies_by_group()
		
		has_been_triggered = true
		self.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		
func enemies_by_list():
	# ✅ Spawn manually assigned enemies
	for enemy in enemies:
		initiate_spawn(enemy)

func enemies_by_parent():
	# ✅ Spawn all children from the specified parent node
	if enemy_parent and has_node(enemy_parent):  # Ensure the node exists
		var parent_node = get_node(enemy_parent)
		if parent_node:
			for enemy in parent_node.get_children():
				initiate_spawn(enemy)

func enemies_by_group():
	# ✅ Spawn all enemies in the specified group
	if enemy_group and enemy_group != "":
		for enemy in get_tree().get_nodes_in_group(enemy_group):
			initiate_spawn(enemy)

func initiate_spawn(enemy):
	if enemy and enemy.has_method("spawn"):
		enemy.spawn()
		print("Spawned from group:", enemy.name)
