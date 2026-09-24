class_name SearchableContainer
extends Interactable

## A one-time loot container (chest/barrel/crate/...) - reuses LootEntry
## exactly like LootPickup/carcasses/ResourceNode overflow do. Once
## emptied it stays empty; nothing here ever respawns loot, which is the
## deliberate distinction from ResourceNode's natural-resource respawn.
@export var container_name: String = "Container"
@export var loot_table: Array[LootEntry] = []

@export var save_id: String = ""
@export var world_region: String = "prototype"

signal opened(container: SearchableContainer)

var is_searched: bool = false

func _ready() -> void:
	add_to_group("searchable_containers")
	add_to_group("saveable")
	_update_prompt()

func get_save_key() -> String:
	return "%s/%s" % [world_region, save_id if save_id != "" else name]

## Saves the exact remaining loot table, not just is_searched - so a
## partially-searched container (some entries taken, some not) resumes
## exactly where it was, and an emptied one stays empty forever.
func get_save_data() -> Dictionary:
	var entries := []
	for entry in loot_table:
		if entry == null or entry.item == null:
			continue
		entries.append({"item_path": entry.item.resource_path, "quantity": entry.quantity})
	return {"is_searched": is_searched, "loot_table": entries}

func apply_save_data(data: Dictionary) -> void:
	is_searched = data.get("is_searched", false)
	loot_table.clear()
	for raw_entry in data.get("loot_table", []):
		var item_path: String = raw_entry.get("item_path", "")
		if item_path == "" or not ResourceLoader.exists(item_path):
			continue
		var entry := LootEntry.new()
		entry.item = load(item_path)
		entry.quantity = raw_entry.get("quantity", 1)
		loot_table.append(entry)
	_update_prompt()

func is_available() -> bool:
	return not is_searched

func interact(_player: Node) -> void:
	opened.emit(self)

## Called by SearchUI. Removes and returns the entry at `index` from the
## loot table; returns null if the index is no longer valid (e.g. two
## rapid clicks on the same row).
func take_entry(index: int) -> LootEntry:
	if index < 0 or index >= loot_table.size():
		return null
	var entry := loot_table[index]
	loot_table.remove_at(index)
	if loot_table.is_empty():
		is_searched = true
	_update_prompt()
	return entry

func _update_prompt() -> void:
	prompt_text = "Search %s" % container_name if not is_searched else "%s (Empty)" % container_name
