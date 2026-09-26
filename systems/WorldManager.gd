extends Node

## Root node of the currently active map's world content.
var current_map_root: Node2D = null

## The exterior map itself (e.g. PrototypeMap), as opposed to sibling
## overlay nodes under current_map_root like DayNightVisual - the node
## BuildingManager hides/freezes while the player is inside a building.
## Defaults to current_map_root itself if no exterior_map is given, so
## existing register_current_map(world_root) call sites keep working.
var current_exterior_map: Node = null

## Simple registries future systems (horde checks, AI queries) can use.
var active_zombies: Array[Node] = []
var active_animals: Array[Node] = []
var active_survivors: Array[Node] = []

var _spawn_points: Dictionary = {}

func register_current_map(map_root: Node2D, exterior_map: Node = null) -> void:
	current_map_root = map_root
	current_exterior_map = exterior_map if exterior_map else map_root
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

## ============================================================
## World regions
## ============================================================
## The current PrototypeMap is one scene subdivided into logical regions
## (see data/regions/*.tres) purely by world-position bounds - this is a
## test of the architecture, not a rewrite of the map. A future large
## hand-designed world would register many more WorldRegionData
## instances the exact same way.

signal region_changed(new_region_id: String, old_region_id: String)
signal region_activated(region_id: String)
signal region_deactivated(region_id: String)

const REGION_CHECK_INTERVAL_SECONDS := 0.5

## "" until the first check resolves a region (or if the player is
## somehow outside every registered region's bounds).
var current_region_id: String = ""

var _regions: Dictionary = {}  # region_id -> WorldRegionData
var _active_region_ids: Dictionary = {}  # region_id -> bool
var _region_snapshots: Dictionary = {}  # region_id -> {save_key: save_data}

var _region_check_timer: Timer

func _ready() -> void:
	# Throttled polling instead of a per-frame check or a physics Area2D
	# per region - simplest reliable approach for "which of a handful of
	# rectangles am I in", and cheap enough that 0.5s latency on the
	# region_changed signal is a non-issue.
	_region_check_timer = Timer.new()
	_region_check_timer.wait_time = REGION_CHECK_INTERVAL_SECONDS
	_region_check_timer.autostart = true
	_region_check_timer.timeout.connect(_check_current_region)
	add_child(_region_check_timer)

func register_region(data: WorldRegionData) -> void:
	if data == null or data.region_id == "":
		return
	_regions[data.region_id] = data
	if not _active_region_ids.has(data.region_id):
		_active_region_ids[data.region_id] = true

func get_region(region_id: String) -> WorldRegionData:
	return _regions.get(region_id)

func get_all_regions() -> Array[WorldRegionData]:
	var result: Array[WorldRegionData] = []
	for region_id in _regions:
		result.append(_regions[region_id])
	return result

## Linear scan over registered regions - fine for a handful of regions,
## and only ever called from the throttled timer or on demand, never
## per-frame. A future world with many regions would swap this for a
## spatial lookup (grid/quadtree) without changing any call site.
func get_region_at_position(world_position: Vector2) -> WorldRegionData:
	for region_id in _regions:
		var region: WorldRegionData = _regions[region_id]
		if region.contains_point(world_position):
			return region
	return null

func is_region_active(region_id: String) -> bool:
	return _active_region_ids.get(region_id, true)

## Exposed for tests/manual triggers that don't want to wait up to
## REGION_CHECK_INTERVAL_SECONDS for the timer.
func force_region_check() -> void:
	_check_current_region()

func _check_current_region() -> void:
	var player: Node2D = GameManager.player
	if player == null:
		return
	var region := get_region_at_position(player.global_position)
	var new_id := region.region_id if region != null else ""
	if new_id != current_region_id:
		var old_id := current_region_id
		current_region_id = new_id
		region_changed.emit(new_id, old_id)

## ============================================================
## Region activation/deactivation
## ============================================================
## Deliberately NOT real streaming (no nodes are added/removed from the
## tree) - Phase 19 only establishes the hook. Deactivating a region
## snapshots every "saveable" object whose save key belongs to it (via
## the exact get_save_data()/apply_save_data() contract SaveManager
## already uses) and marks the region inactive; activating it restores
## that snapshot. This is intentionally a clean seam a real streaming/
## simulation-LOD system can be swapped in behind later, e.g. by also
## despawning/respawning nodes or throttling AI update rates per region.

func deactivate_region(region_id: String) -> void:
	if not is_region_active(region_id):
		return
	var snapshot := {}
	for node in get_tree().get_nodes_in_group("saveable"):
		if not (node.has_method("get_save_key") and node.has_method("get_save_data")):
			continue
		var key: String = node.get_save_key()
		if key.begins_with(region_id + "/"):
			snapshot[key] = node.get_save_data()
	_region_snapshots[region_id] = snapshot
	_active_region_ids[region_id] = false
	region_deactivated.emit(region_id)

func activate_region(region_id: String) -> void:
	if is_region_active(region_id):
		return
	var snapshot: Dictionary = _region_snapshots.get(region_id, {})
	for node in get_tree().get_nodes_in_group("saveable"):
		if not (node.has_method("get_save_key") and node.has_method("apply_save_data")):
			continue
		var key: String = node.get_save_key()
		if snapshot.has(key):
			node.apply_save_data(snapshot[key])
	_active_region_ids[region_id] = true
	region_activated.emit(region_id)
