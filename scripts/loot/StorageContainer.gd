class_name StorageContainer
extends Interactable

## Groundwork for future tavern/settlement storage. Holds an ordinary
## Inventory child node - reusing Inventory.gd exactly rather than
## inventing a second "container of items" data structure.
@export var container_name: String = "Chest"

@export var save_id: String = ""
@export var world_region: String = "prototype"

signal opened(container: StorageContainer)

@onready var storage: Inventory = $Storage

func _ready() -> void:
	add_to_group("storage_containers")
	add_to_group("saveable")
	prompt_text = "Open %s" % container_name

func interact(_player: Node) -> void:
	opened.emit(self)

func get_save_key() -> String:
	return "%s/%s" % [world_region, save_id if save_id != "" else name]

## Delegates straight to Inventory's own serialization - no second
## "container of items" format to keep in sync.
func get_save_data() -> Dictionary:
	return {"storage": storage.to_save_data()}

func apply_save_data(data: Dictionary) -> void:
	storage.apply_save_data(data.get("storage", []))
