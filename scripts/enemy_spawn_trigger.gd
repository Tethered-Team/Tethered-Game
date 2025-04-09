extends Area3D

@export var has_been_triggered: bool = false

@export var enemies: Array[Node3D]  # Manually assigned enemies
@export var enemy_parent: NodePath  # Path to a parent node containing multiple enemies
@export var enemy_group: String = "enemies"  # Group name for spawning all enemies in a group

@export var list: bool = true
@export var parent: bool = true
@export var group: bool = true


func _ready() -> void:
	# Connect the body_entered signal to the _on_body_entered function
	connect("body_entered", Callable(self, "_on_body_entered"))
	
	# Ensure the trigger is not already triggered
	if has_been_triggered:
		self.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	else:
		self.physics_interpolation_mode = Node3D.PHYSICS_INTERPOLATION_MODE_ON

func _on_body_entered(body):
	spawn_using_enemy_manager(body)
	print("Trigger entered:", body)
	
		
func enemies_by_list() -> void:
	# ✅ Spawn manually assigned enemies
	for enemy in enemies:
		initiate_spawn(enemy)

func enemies_by_parent() -> void:
	# ✅ Spawn all children from the specified parent node
	if enemy_parent and has_node(enemy_parent):  # Ensure the node exists
		var parent_node = get_node(enemy_parent)
		if parent_node:
			for enemy in parent_node.get_children():
				initiate_spawn(enemy)

func enemies_by_group() -> void:
	# ✅ Spawn all enemies in the specified group
	if enemy_group and enemy_group != "":
		for enemy in get_tree().get_nodes_in_group(enemy_group):
			initiate_spawn(enemy)

func initiate_spawn(enemy) -> void:
	if enemy and enemy.has_method("spawn"):
		enemy.spawn()
		print("Spawned from group:", enemy.name)

func _old_trigger_effect(body):
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

func spawn_using_enemy_manager(body):
	if not has_been_triggered:
		print("Trigger entered:", body)

		if body.is_in_group("Player") and body is CharacterBody3D:
			GlobalEvents.emit_signal("event_arena_start", body.global_transform.origin)
