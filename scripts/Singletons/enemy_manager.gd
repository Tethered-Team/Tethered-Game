extends Node

# ------------------------------------------------------------
# Signals
# ------------------------------------------------------------
## Signal emitted when the current arena (all waves) is complete.
signal arena_complete

# ------------------------------------------------------------
# Exported Variables & Configurations
# ------------------------------------------------------------
## Wave configuration: each integer represents the weight budget for that wave.
@export var wave_weights: Array[int] = [5, 6, 7]

## A Resource containing available enemy data, typically loaded from a .tres file.
@export var enemy_data_pool: EnemyDataPool # EnemyDataPool.tres

## Maximum number of enemies allowed to exist concurrently.
@export var max_concurrent_enemies := 10

## Delay between waves (in seconds).
@export var wave_delay: float = 3.0

# ------------------------------------------------------------
# Internal State Variables
# ------------------------------------------------------------
## Current wave index.
var current_wave := 0

## List of enemy nodes which have been spawned and are still active.
var active_enemies: Array[Node3D] = []

## List of spawn point nodes (populated in _ready()).
var spawn_points: Array[Node3D] = []

## Dictionary used for pooling enemy instances.
## Key: enemy scene resource path; Value: Array of inactive enemy nodes.
var enemy_pool_storage: Dictionary = {}

## Function: _ready
## Purpose: Initialize the enemy manager by gathering all spawn points.
## Parameters: None.
## Returns: void.
func _ready():

	GlobalReferences.enemy_manager = self

	# Get the nodes in group "enemy_spawn_points" (returns Array[Node])
	var raw_spawn_points = get_tree().get_nodes_in_group("SpawnPoints")
	# Clear and convert them to Node3D.
	spawn_points = []
	for node in raw_spawn_points:
		spawn_points.append(node as Node3D)

	# Connect the arena_complete signal to the start_arena function.
	GlobalEvents.connect_once("event_arena_start", self, "start_arena")
	GlobalEvents.connect("event_enemy_killed", Callable(self, "_on_enemy_died"))
	GlobalEvents.connect("event_enemy_despawn", Callable(self, "_on_enemy_despawn"))	

## Function: start_arena
## Purpose: Reset arena state and begin spawning waves starting from wave 0.
## Parameters: None.
## Returns: void.
func start_arena(position: Vector3) -> void:
	#print("Starting arena with player at position:", position)
	current_wave = 0
	active_enemies.clear()
	spawn_next_wave()

## Function: spawn_next_wave
## Purpose: Spawn the next wave of enemies based on the current wave's weight budget.
##          If more waves remain, wait for wave_delay seconds and then spawn the next wave.
## Parameters: None.
## Returns: void.
func spawn_next_wave():
	#print("Spawning wave:", current_wave)
	if current_wave >= wave_weights.size():
		return

	# Get the weight budget for the current wave.
	var weight_budget = wave_weights[current_wave]
	# Select enemy configurations from the pool based on the weight budget.
	# Assumes enemy_data_pool.enemies is an Array of enemy data (resources) with a "weight" property.
	var configs = pick_enemies_to_spawn(weight_budget, enemy_data_pool.enemies)
	#print("Selected enemies:", configs)	

	# For each enemy configuration selected, spawn an enemy.
	for config in configs:
		spawn_enemy(config)

	# Increment the wave index.
	current_wave += 1


## Function: pick_enemies_to_spawn
## Purpose: Select enemy configurations based on a weight budgeting system.
## Parameters:
##   weight_budget (int): The available weight for the current wave.
##   enemy_pool (Array[Resource]): Array of enemy data resources.
## Returns: Array[Resource] - The chosen enemy data resources from enemy_pool.
func pick_enemies_to_spawn(weight_budget: int, enemy_pool: Array[EnemySpawnData]) -> Array[EnemySpawnData]:
	var chosen : Array[EnemySpawnData] = []
	var remaining := weight_budget

	# Duplicate and sort the enemy pool in descending order by weight,
	# so higher weighted enemies are considered first.
	var sorted_pool = enemy_pool.duplicate()
	sorted_pool.sort_custom(func(a, b): return b.weight - a.weight)

	# While there is remaining budget, filter out all enemies that fit within the remaining budget.
	while remaining > 0:
		var valid = sorted_pool.filter(func(e): return e.weight <= remaining)
		if valid.is_empty():
			break
		# Pick a random enemy configuration from the valid set.
		var selected = valid.pick_random()
		remaining -= selected.weight
		chosen.append(selected)

	return chosen

## Function: spawn_enemy
## Purpose: Spawn an enemy using pooling. It selects an available spawn point,
##          retrieves or instantiates an enemy instance based on the provided enemy data,
##          and activates it.
## Parameters:
##   data (Resource): Enemy data resource containing properties (like spawn_radius) and a reference to the enemy scene.
## Returns: void.
func spawn_enemy(data):
	# Attempt to pick a valid spawn point for the enemy.
	var spawn_point = pick_valid_spawn_point(data.spawn_radius)
	#print("Spawn point:", spawn_point)
	if spawn_point == null:
		return

	# Retrieve a valid position from the spawn point, ensuring no overlap with obstacles.
	var position = spawn_point.get_valid_position(data.spawn_radius)
	if position == null:
		return

	# Attempt to retrieve an enemy instance from the pool.
	var enemy: Enemy = get_enemy_from_pool(data)
	if enemy == null:
		# No pooled instance available; instantiate a new enemy.
		enemy = data.scene.instantiate()
		# Store the enemy data on the instance for pooling later.
		enemy.enemy_data = data
	else:
		# An instance was found in the pool; ensure it is reactivated.
		enemy.show()


	# Remove enemy from its previous parent if necessary.
	if enemy.get_parent() != null:
		enemy.get_parent().remove_child(enemy)

	# Add the spawned enemy to the current scene and mark it as active.
	get_tree().current_scene.add_child(enemy)

	enemy.global_transform.origin = position


	active_enemies.append(enemy)
	

	# Set up a callback when the enemy "dies" so it can be returned to the pool.
	# (Assumes the enemy emits its own "died" signal instead of exiting the tree.)

## Function: get_enemy_from_pool
## Purpose: Retrieve an inactive enemy instance from the pool for the corresponding enemy type.
## Parameters:
##   data (Resource): Enemy data resource containing the scene reference.
## Returns: Node3D or null if none is available.
func get_enemy_from_pool(data: Resource) -> Node3D:
	var key = data.scene.resource_path  # Unique identifier for the enemy type.
	if enemy_pool_storage.has(key):
		var pool = enemy_pool_storage[key]
		if pool.size() > 0:
			return pool.pop_back()
	return null

## Function: return_enemy_to_pool
## Purpose: Hide an enemy instance and store it in the pool for later reuse.
## Parameters:
##   enemy (Node3D): The enemy instance to return.
##   data (Resource): The enemy data resource to determine the pool key.
## Returns: void.
func return_enemy_to_pool(enemy: Node3D, data: Resource) -> void:
	var key = data.scene.resource_path
	if not enemy_pool_storage.has(key):
		enemy_pool_storage[key] = []
	enemy_pool_storage[key].append(enemy)
	enemy.hide()

## Function: pick_valid_spawn_point
## Purpose: Return a random valid spawn point that can accommodate an enemy of at least min_radius.
## Parameters:
##   min_radius (float): The minimum required radius for a valid spawn point.
## Returns: Node3D or null.
func pick_valid_spawn_point(min_radius: float) -> Node3D:
	# Filter spawn points based on their ability to spawn an enemy of the given size.
	var candidates = spawn_points.filter(func(p): return p.can_spawn_size(min_radius))
	if candidates.is_empty():
		return null
	return candidates.pick_random()

## Function: _on_enemy_died
## Purpose: Handle an enemy's death by removing it from active enemies and returning it to the pool.
## Parameters:
##   enemy (Node3D): The enemy instance that died.
## Returns: void.
func _on_enemy_died(enemy):
	active_enemies.erase(enemy)
	check_arena_clear()

## Function: check_arena_clear
## Purpose: Determine if the arena is clear by verifying that all waves have been spawned
##          and there are no remaining active enemies, then emit the arena_complete signal.
## Parameters: None.
## Returns: void.
func check_arena_clear():
	#print("Checking arena clear...")
	#print("Active enemies:", active_enemies.size())
	if active_enemies.is_empty():
		if current_wave >= wave_weights.size():
			emit_signal("arena_complete")
		else:
			spawn_next_wave()

## Function: _on_enemy_despawn
## Purpose: Handle an enemy despawning event by removing it from active enemies.
## Parameters:
##   enemy (Node3D): The enemy instance that despawned.
## Returns: void.
func _on_enemy_despawn(enemy):
	return_enemy_to_pool(enemy, enemy.enemy_data)

## Function: get_closest_enemy
## Purpose: Find the closest enemy to a given position.
## Parameters:
##   from_position (Vector3): The position to measure distances from.
## Returns: Node3D - The closest enemy node.
func get_closest_enemy(from_position: Vector3) -> Node3D:
	var closest_enemy: Node3D = null
	var min_distance = INF
	for enemy in active_enemies:
		# Calculate the distance from the enemy's position to the given point.
		var d = enemy.global_transform.origin.distance_to(from_position)
		if d < min_distance:
			min_distance = d
			closest_enemy = enemy
	return closest_enemy
