class_name StorageContainer
extends Interactable

## Groundwork for future tavern/settlement storage. Holds an ordinary
## Inventory child node - reusing Inventory.gd exactly rather than
## inventing a second "container of items" data structure.
@export var container_name: String = "Chest"

signal opened(container: StorageContainer)

@onready var storage: Inventory = $Storage

func _ready() -> void:
	add_to_group("storage_containers")
	prompt_text = "Open %s" % container_name

func interact(_player: Node) -> void:
	opened.emit(self)
