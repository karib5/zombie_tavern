class_name SearchableContainer
extends Interactable

## A one-time loot container (chest/barrel/crate/...) - reuses LootEntry
## exactly like LootPickup/carcasses/ResourceNode overflow do. Once
## emptied it stays empty; nothing here ever respawns loot, which is the
## deliberate distinction from ResourceNode's natural-resource respawn.
@export var container_name: String = "Container"
@export var loot_table: Array[LootEntry] = []

signal opened(container: SearchableContainer)

var is_searched: bool = false

func _ready() -> void:
	add_to_group("searchable_containers")
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
