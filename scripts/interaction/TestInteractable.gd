extends Interactable

@export var item_to_give: ItemData
@export var item_quantity: int = 1
@export var default_color: Color = Color(0.8, 0.7, 0.2)
@export var activated_color: Color = Color(0.2, 0.8, 0.3)

@onready var _visual: Polygon2D = $Visual

var _activated: bool = false

func _ready() -> void:
	prompt_text = "Interact"
	_visual.color = default_color

func interact(player: Node) -> void:
	_activated = not _activated
	_visual.color = activated_color if _activated else default_color

	if item_to_give == null:
		return

	var inventory := player.get_node("Inventory") as Inventory
	if inventory == null:
		return

	var leftover := inventory.add_item(item_to_give, item_quantity)
	if leftover > 0:
		print("Inventory full: could not add %d x %s" % [leftover, item_to_give.display_name])
	else:
		print("Added %d x %s to inventory" % [item_quantity, item_to_give.display_name])
