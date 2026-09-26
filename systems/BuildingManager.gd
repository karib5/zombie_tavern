extends Node

## Moves the player between the exterior world and a building's interior.
##
## The interior is instanced as a SIBLING of WorldManager.current_exterior_map
## (both under current_map_root, Main's WorldRoot) - never as a child of
## the exterior itself, since a CanvasItem's visibility is inherited and
## hiding the exterior would hide an interior nested inside it too.
## Hiding the exterior and setting its process_mode to DISABLED freezes
## its entities/timers/physics while the player is inside, exactly like
## WorldManager's region activate/deactivate, and needs no full scene
## reload - the player's Camera2D, Inventory and every autoload keep
## working untouched.
##
## Saveable furniture inside a building (StorageContainer, TavernTable,
## etc.) is only reset to its scene defaults on each entry - it is not
## re-applied from the last save automatically, since SaveManager only
## re-applies data on a full load_game(). That's a separate gap from
## this door/entry feature and would need its own fix if it matters.

var _interior_root: Node = null
var _exterior_map: Node = null
var _exterior_return_position: Vector2 = Vector2.ZERO

func is_inside_building() -> bool:
	return _interior_root != null

func enter_building(interior_scene: PackedScene, spawn_marker_name: String = "PlayerSpawnPoint") -> void:
	if interior_scene == null or _interior_root != null:
		return
	var player: Node2D = GameManager.player
	var map_root := WorldManager.current_map_root
	if player == null or map_root == null:
		return

	_exterior_map = WorldManager.current_exterior_map
	_exterior_return_position = player.global_position

	_interior_root = interior_scene.instantiate()
	map_root.add_child(_interior_root)

	if _exterior_map:
		_exterior_map.visible = false
		_exterior_map.process_mode = Node.PROCESS_MODE_DISABLED

	var spawn := _interior_root.find_children(spawn_marker_name, "Marker2D", true, false)
	player.global_position = (spawn[0] as Marker2D).global_position if not spawn.is_empty() else Vector2.ZERO

func exit_building() -> void:
	if _interior_root == null:
		return
	var player: Node2D = GameManager.player

	_interior_root.queue_free()
	_interior_root = null

	if _exterior_map:
		_exterior_map.visible = true
		_exterior_map.process_mode = Node.PROCESS_MODE_INHERIT
		_exterior_map = null

	if player:
		player.global_position = _exterior_return_position
