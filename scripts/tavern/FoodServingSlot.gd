class_name FoodServingSlot
extends Node2D

## The food currently placed here, or null if empty. Set only through
## place_food()/take_food() below so the visual always stays in sync.
var food_item: ItemData = null

@onready var _visual: Polygon2D = $FoodVisual

func _ready() -> void:
	_update_visual()

func is_occupied() -> bool:
	return food_item != null

func place_food(item: ItemData) -> void:
	food_item = item
	_update_visual()

## Clears this slot and returns whatever was on it (null if it was empty).
func take_food() -> ItemData:
	var item := food_item
	food_item = null
	_update_visual()
	return item

func _update_visual() -> void:
	_visual.visible = food_item != null
