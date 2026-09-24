extends Node

## Root node of the currently active map's world content.
var current_map_root: Node2D = null

## Simple registries future systems (horde checks, AI queries) can use.
var active_zombies: Array[Node] = []
var active_animals: Array[Node] = []
var active_survivors: Array[Node] = []

var _spawn_points: Dictionary = {}

func register_current_map(map_root: Node2D) -> void:
	current_map_root = map_root
	_spawn_points.clear()
	for node in map_root.find_children("*", "Marker2D", true, false):
		if node.name.ends_with("SpawnPoint"):
			_spawn_points[String(node.name)] = node

func get_spawn_point(spawn_name: String) -> Marker2D:
	return _spawn_points.get(spawn_name)

## Pooling-ready spawn seam: instances directly for now, swappable
## for a real pool later without touching any call sites.
func spawn_entity(scene: PackedScene, spawn_position: Vector2, parent: Node = null) -> Node:
	var instance := scene.instantiate()
	var target_parent: Node = parent if parent else current_map_root
	target_parent.add_child(instance)
	(instance as Node2D).global_position = spawn_position
	return instance

func despawn_entity(instance: Node) -> void:
	instance.queue_free()
