extends Node

#region Signals

## Signal emitted when all enemy waves are completed.
signal arena_complete

#endregion

#region Exported Variables

@export var wave_weights: Array[int] = [5, 6, 7] ## Wave configuration: each integer represents the weight budget for that wave.
@export var enemy_data_pool: EnemyDataPool ## A Resource containing available enemy data, typically loaded from a .tres file.
@export var max_concurrent_enemies := 10 ## Maximum number of enemies allowed to exist concurrently.
@export var wave_delay: float = 3.0 ## Delay between waves (in seconds).
@export var default_pool_expand_count: int = 10 ## Default number of instances to preload per enemy type.
@export var min_spawn_distance_from_player: float = 5.0 ## Minimum distance from the player for enemy spawns.
@export var max_spawn_distance_from_player: float = 20.0 ## Maximum distance from the player for enemy spawns.

#endregion

#region Internal State

var current_wave: int = 0 ## The current wave index.
var active_enemies: Array[Node3D] = [] ## List of enemy nodes which have been spawned and are still active.
var spawn_points: Array[Node3D] = [] ## List of spawn point nodes available for enemy spawning.
var enemy_pool_storage: Dictionary = {} ## Dictionary used for pooling enemy instances. Key: enemy ID; Value: Array of inactive enemy nodes.
var player: Node3D = null ## Cached reference to the player node.

#endregion

#region Lifecycle

## Called when the node enters the scene tree. Initializes spawn points, preloads enemies, and connects events.
func _ready():
	GlobalReferences.set_enemy_manager(self)
	
	# Create an empty typed Array[Node3D]
	var typed_spawn_points: Array[Node3D] = []

	# Get the untyped array of nodes, then filter and cast to Node3D.
	for node in get_tree().get_nodes_in_group("SpawnPoints"):
		if node is Node3D:
			typed_spawn_points.append(node)
			
	spawn_points = typed_spawn_points
	
	player = get_tree().get_first_node_in_group("Player")
	preload_all_enemies()
	GlobalEvents.connect_once("event_arena_start", self, "start_arena")
	GlobalEvents.connect("event_enemy_killed", Callable(self, "_on_enemy_died"))
	GlobalEvents.connect("event_enemy_despawn", Callable(self, "_on_enemy_despawn"))

#endregion

#region Preloading

## Preloads enemy scenes and pre-instantiates a pool of enemies for faster spawning.
func preload_all_enemies():
	for config in enemy_data_pool.enemies:
		var scene = config.scene
		if scene == null:
			scene = ResourceLoader.load(config.scene.resource_path)
			config.scene = scene
		var key = config.id
		if not enemy_pool_storage.has(key):
			enemy_pool_storage[key] = []
			for i in range(default_pool_expand_count):
				var enemy = scene.instantiate()
				enemy.hide()
				enemy_pool_storage[key].append(enemy)

#endregion

#region Arena Control

## Starts the arena encounter by resetting state and spawning the first wave.
func start_arena(position: Vector3) -> void:
	await get_tree().create_timer(wave_delay).timeout
	current_wave = 0
	active_enemies.clear()
	spawn_next_wave()


## Spawns the next wave of enemies asynchronously.
func spawn_next_wave():
	if current_wave >= wave_weights.size():
		return
	var weight_budget = wave_weights[current_wave]
	var configs = pick_enemies_to_spawn(weight_budget, enemy_data_pool.enemies)
	
	print("Spawning wave %d with weight budget %d" % [current_wave, weight_budget])
	print("Selected enemies:", configs)
	if configs.size() == 0:
		print("No enemies selected for this wave.")
		return
	
	# Start an asynchronous routine to spawn one enemy per physics frame
	spawn_wave_async(configs)

	current_wave += 1



## Asynchronous routine that spawns one enemy per physics frame.
func spawn_wave_async(configs: Array):
	for config in configs:
		# Wait for the next physics frame before spawning the enemy.
		await get_tree().physics_frame
		spawn_enemy(config)

	GlobalEvents.emit_event("event_arena_wave_spawn")

#endregion

#region Enemy Spawning & Pooling

## Selects enemy configurations for spawning based on the available weight budget.
## @param weight_budget (int): Available weight points.
## @param enemy_pool (Array[EnemySpawnData]): Available enemy configurations.
## @returns Array[EnemySpawnData]
func pick_enemies_to_spawn(weight_budget: int, enemy_pool: Array[EnemySpawnData]) -> Array[EnemySpawnData]:
	var chosen: Array[EnemySpawnData] = []
	var remaining := weight_budget
	var sorted_pool = enemy_pool.duplicate()
	sorted_pool.sort_custom(func(a, b): return b.weight - a.weight)
	while remaining > 0:
		var valid = sorted_pool.filter(func(e): return e.weight <= remaining)
		if valid.is_empty():
			break
		var selected = valid.pick_random()
		remaining -= selected.weight
		chosen.append(selected)
		print("Selected enemy: %s, Remaining weight: %d" % [selected.id, remaining])
	return chosen

## Spawns an enemy instance at a valid spawn point while ensuring correct distance from the player.
## @param data (EnemySpawnData): Enemy spawn configuration.
func spawn_enemy(data: EnemySpawnData, debug_flag: bool = true) -> void:
	# Step 1: Select a valid spawn point based on the enemy's required spawn radius.
	var spawn_point = pick_valid_spawn_point(data.spawn_radius)
	# If no valid spawn point is found, exit early.
	if spawn_point == null:
		if debug_flag:
			push_error("No valid spawn point found for enemy ID: %s" % data.id)
		return
	
	# Step 2: Determine a valid spawn position within the specified spawn point.
	var position = spawn_point.get_valid_position(data.spawn_radius)
	# Exit if no valid position is determined or the position doesn't meet distance criteria.
	if position == null or not is_valid_spawn_distance(position):
		if debug_flag:
			push_error("Invalid spawn position for enemy ID: %s" % data.id)
			push_error("Position: %s, Distance from player: %f" % [position, position.distance_to(player.global_transform.origin)])
		return
	
	# Step 3: Retrieve an enemy instance from the pool associated with this enemy configuration.
	var enemy = get_enemy_from_pool(data)
	# If no enemy is available, expand the pool to create more instances.
	if enemy == null:
		expand_pool(data)
		enemy = get_enemy_from_pool(data)
		# If the pool expansion still doesn't yield an enemy, log an error and exit.
		if enemy == null:
			push_error("Failed to expand pool for enemy ID: %s" % data.id)
			return
	else:
		# If an enemy is successfully retrieved from the pool, ensure it's visible.
		enemy.show()
	
	# Remove the enemy from any current parent node before reparenting.
	if enemy.get_parent():
		enemy.get_parent().remove_child(enemy)
	
	# Step 4: Add the enemy instance to the current scene and set its position.
	get_tree().current_scene.add_child(enemy)
	enemy.global_transform.origin = position
	
	# Configure the enemy with the provided data, if applicable.
	if enemy.has_method("configure_from_data"):
		enemy.configure_from_data(data)
	
	# Track the enemy as active.
	active_enemies.append(enemy)

## Retrieves an enemy instance from the pool.
## @param data (EnemySpawnData): Enemy spawn configuration.
## @returns Node3D or null
func get_enemy_from_pool(data: EnemySpawnData) -> Node3D:
	var key = data.id
	if enemy_pool_storage.has(key) and enemy_pool_storage[key].size() > 0:
		return enemy_pool_storage[key].pop_back()
	return null

## Expands the enemy pool by instantiating additional hidden enemies.
## @param data (EnemySpawnData): Enemy spawn configuration.
## @param count (int): Number of instances to create.
func expand_pool(data: EnemySpawnData, count: int = default_pool_expand_count):
	var key = data.id
	if not enemy_pool_storage.has(key):
		enemy_pool_storage[key] = []
	for i in range(count):
		var enemy = data.scene.instantiate()
		enemy.hide()
		enemy_pool_storage[key].append(enemy)

## Returns an enemy to the pool when despawned.
## @param enemy (Node3D): The enemy instance to return.
func return_enemy_to_pool(enemy: Node3D) -> void:
	var key = enemy.enemy_id if enemy.has_method("enemy_id") else null
	if key == null:
		return
	if not enemy_pool_storage.has(key):
		enemy_pool_storage[key] = []
	enemy_pool_storage[key].append(enemy)
	enemy.hide()

## Picks a spawn point that can accommodate a minimum radius requirement.
## @param min_radius (float): Minimum spawn radius.
## @returns Node3D or null
func pick_valid_spawn_point(min_radius: float) -> Node3D:
	var candidates = spawn_points.filter(func(p): return p.can_spawn_size(min_radius))
	if candidates.is_empty():
		return null
	return candidates.pick_random()

## Checks if a spawn position is valid based on the distance to the player.
## @param position (Vector3): World position to check.
## @returns bool
func is_valid_spawn_distance(position: Vector3) -> bool:
	if player == null:
		return true
	var distance = player.global_transform.origin.distance_to(position)
	return distance >= min_spawn_distance_from_player and distance <= max_spawn_distance_from_player

#endregion

#region Enemy Death & Arena Clear

## Called when an enemy dies. Removes it from active enemies and checks arena status.
## @param enemy (Node3D): Enemy that died.
func _on_enemy_died(enemy):
	active_enemies.erase(enemy)
	check_arena_clear()

## Called when an enemy despawns. Returns it to the pool.
## @param enemy (Node3D): Enemy that despawned.
func _on_enemy_despawn(enemy):
	return_enemy_to_pool(enemy)

## Checks if all enemies are cleared and either spawns the next wave or emits arena_complete.
func check_arena_clear():
	if active_enemies.is_empty():
		if current_wave >= wave_weights.size():
			GlobalEvents.emit_event("event_arena_end")
		else:
			await get_tree().create_timer(wave_delay).timeout
			call_deferred("spawn_next_wave")

#endregion

#region Utility

## Finds and returns the closest enemy to a given position.
## @param from_position (Vector3): The reference position.
## @returns Node3D
func get_closest_enemy(from_position: Vector3) -> Node3D:
	var closest_enemy: Node3D = null
	var min_distance = INF
	for enemy in active_enemies:
		var d = enemy.global_transform.origin.distance_to(from_position)
		if d < min_distance:
			min_distance = d
			closest_enemy = enemy
	return closest_enemy

#endregion
