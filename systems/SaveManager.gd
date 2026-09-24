extends Node

## Coordinates saving/loading - it does not own gameplay state itself.
## Every persistable gameplay system (ResourceNode, FarmPlot,
## SearchableContainer, StorageContainer, SurvivorAI, Inventory,
## PlayerSurvival, Health, TimeManager) implements its own
## get_save_data()/apply_save_data(), and SaveManager just collects and
## distributes those dictionaries. World objects are found via the
## "saveable" group + WorldManager/GameManager, never via a hardcoded
## Main/PrototypeMap node path - so this works unchanged no matter which
## scene/region a saveable object actually lives in.

## v1: flat "world_objects" dict of {save_key: data}.
## v2: "regions" dict of {region_id: {"objects": {save_key: data}}} -
## the same per-object data, just grouped by region so a region's save
## data can eventually be loaded/saved independently of the rest of the
## world. v1 saves still load (see _regions_data_from_save()); every
## save written from here on is v2.
const SAVE_VERSION := 2
const OLDEST_LOADABLE_VERSION := 1
const SAVE_DIR := "user://saves"
const DEFAULT_SLOT := "default"

## How many in-game minutes between autosaves. Tunable, and deliberately
## measured in game-time (via TimeManager.minute_changed) rather than a
## real-time Timer, so autosave frequency doesn't depend on play speed.
@export var autosave_interval_minutes: float = 60.0

signal save_completed(slot: String)
signal load_completed(slot: String)
signal load_failed(slot: String, reason: String)

var _autosave_accumulator: float = 0.0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	TimeManager.minute_changed.connect(_on_minute_changed)

func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	_autosave_accumulator += 1.0
	if _autosave_accumulator >= autosave_interval_minutes:
		_autosave_accumulator = 0.0
		save_game("autosave")

func has_save(slot: String = DEFAULT_SLOT) -> bool:
	return FileAccess.file_exists(_save_path(slot))

func _save_path(slot: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, slot]

## Writes to a temporary file first and only replaces the real save file
## once that write has fully succeeded, so a crash/interruption mid-write
## can never corrupt (or half-overwrite) the last good save.
func save_game(slot: String = DEFAULT_SLOT) -> bool:
	var data := _collect_save_data()
	var json_text := JSON.stringify(data, "\t")

	var final_path := _save_path(slot)
	var tmp_path := final_path + ".tmp"

	var file := FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: could not open %s for writing" % tmp_path)
		return false
	file.store_string(json_text)
	file.close()

	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		push_error("SaveManager: could not open save directory %s" % SAVE_DIR)
		return false
	var err := dir.rename(tmp_path.get_file(), final_path.get_file())
	if err != OK:
		push_error("SaveManager: failed to finalize save at %s (error %d)" % [final_path, err])
		return false

	print("SaveManager: saved to %s" % final_path)
	save_completed.emit(slot)
	return true

## Returns false (and leaves the current game state untouched) if the
## save is missing, unreadable, or fails JSON/version validation - a
## corrupt or foreign save file is reported, never silently applied.
func load_game(slot: String = DEFAULT_SLOT) -> bool:
	var path := _save_path(slot)
	if not FileAccess.file_exists(path):
		push_warning("SaveManager: no save found at %s" % path)
		load_failed.emit(slot, "not_found")
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: could not open %s for reading" % path)
		load_failed.emit(slot, "unreadable")
		return false
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveManager: save file %s is corrupted (JSON parse error at line %d)" % [path, json.get_error_line()])
		load_failed.emit(slot, "corrupt")
		return false

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY or not data.has("version"):
		push_error("SaveManager: save file %s is missing version info" % path)
		load_failed.emit(slot, "missing_version")
		return false
	var file_version := int(data["version"])
	if file_version < OLDEST_LOADABLE_VERSION or file_version > SAVE_VERSION:
		push_error("SaveManager: save file %s is version %d, this build supports %d-%d" % [path, file_version, OLDEST_LOADABLE_VERSION, SAVE_VERSION])
		load_failed.emit(slot, "version_mismatch")
		return false

	_apply_save_data(data)
	print("SaveManager: loaded from %s" % path)
	load_completed.emit(slot)
	return true

## Resets time and reloads the current scene (Main.tscn), which
## reinstantiates the player/world/all resource nodes/containers/farms
## from their scene-file defaults - the same clean-slate every "New Game"
## should start from, without SaveManager having to hand-write reset
## logic for each gameplay system separately.
func new_game() -> void:
	delete_save(DEFAULT_SLOT)
	_autosave_accumulator = 0.0
	TimeManager.day = 1
	TimeManager.hour = 8
	TimeManager.minute = 0
	get_tree().reload_current_scene()

func delete_save(slot: String = DEFAULT_SLOT) -> void:
	var path := _save_path(slot)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _collect_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"time": TimeManager.get_save_data(),
		"player": _collect_player_data(),
		"regions": _collect_regions_data(),
	}

func _collect_player_data() -> Dictionary:
	var player := GameManager.player
	if player == null:
		return {}
	var health := player.get_node("Health") as Health
	var survival := player.get_node("PlayerSurvival") as PlayerSurvival
	var inventory := player.get_node("Inventory") as Inventory
	var tools := player.get_node("PlayerTools") as PlayerTools
	return {
		"position": {"x": player.global_position.x, "y": player.global_position.y},
		"health": health.current_health,
		"is_dead": health.is_dead,
		"hunger": survival.hunger,
		"thirst": survival.thirst,
		"inventory": inventory.to_save_data(),
		"equipped_slot_index": tools.get_equipped_slot_index(),
	}

## Every persistent world object (ResourceNode, FarmPlot,
## SearchableContainer, StorageContainer, SurvivorAI) adds itself to the
## "saveable" group in its own _ready() and implements
## get_save_key()/get_save_data() - discovered here purely by group
## membership, never by scene path. Each object's save key is
## "<world_region>/<id>" (see ResourceNode.get_save_key() etc.), so the
## region to file it under is just that key's first path segment - no
## separate region lookup needed, and this keeps working even for an
## object whose region isn't currently registered with WorldManager.
func _collect_regions_data() -> Dictionary:
	var regions := {}
	for node in get_tree().get_nodes_in_group("saveable"):
		if not (node.has_method("get_save_key") and node.has_method("get_save_data")):
			continue
		var key: String = node.get_save_key()
		var region_id := key.get_slice("/", 0)
		if not regions.has(region_id):
			regions[region_id] = {"objects": {}}
		regions[region_id]["objects"][key] = node.get_save_data()
	return regions

## v1 saves stored one flat {save_key: data} dict; v2 groups the same
## per-object data under {region_id: {"objects": {...}}}. Both shapes are
## flattened back to a single {save_key: data} dict here, so the apply
## loop below never needs to care which version it came from - the only
## place version matters is picking which section to read.
func _flatten_regions_data(data: Dictionary) -> Dictionary:
	var flat := {}
	var file_version := int(data.get("version", OLDEST_LOADABLE_VERSION))
	if file_version <= 1:
		flat = data.get("world_objects", {}).duplicate()
	else:
		var regions: Dictionary = data.get("regions", {})
		for region_id in regions:
			var objects: Dictionary = regions[region_id].get("objects", {})
			for key in objects:
				flat[key] = objects[key]
	return flat

func _apply_save_data(data: Dictionary) -> void:
	TimeManager.apply_save_data(data.get("time", {}))

	var flat_objects := _flatten_regions_data(data)
	for node in get_tree().get_nodes_in_group("saveable"):
		if not (node.has_method("get_save_key") and node.has_method("apply_save_data")):
			continue
		var key: String = node.get_save_key()
		if flat_objects.has(key):
			node.apply_save_data(flat_objects[key])

	_apply_player_data(data.get("player", {}))

func _apply_player_data(pdata: Dictionary) -> void:
	var player := GameManager.player
	if player == null or pdata.is_empty():
		return

	var pos: Dictionary = pdata.get("position", {})
	if pos.has("x"):
		player.global_position = Vector2(pos.get("x", player.global_position.x), pos.get("y", player.global_position.y))

	var health := player.get_node("Health") as Health
	health.load_state(pdata.get("health", health.max_health), pdata.get("is_dead", false))

	var survival := player.get_node("PlayerSurvival") as PlayerSurvival
	survival.load_state(pdata.get("hunger", survival.max_hunger), pdata.get("thirst", survival.max_thirst))

	var inventory := player.get_node("Inventory") as Inventory
	inventory.apply_save_data(pdata.get("inventory", []))

	var tools := player.get_node("PlayerTools") as PlayerTools
	tools.equip_slot_index(pdata.get("equipped_slot_index", -1))
