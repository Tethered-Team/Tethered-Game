extends Resource
class_name EnemySpawnData

@export var scene: PackedScene
@export var weight: int = 1
@export var spawn_radius: float = 1.0
@export var can_summon: bool = false
@export var tags: Array[String] = []
