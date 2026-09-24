class_name ItemData
extends Resource

enum ItemCategory {
	MATERIAL,
	FOOD,
	TOOL,
	WEAPON,
}

@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var category: ItemCategory = ItemCategory.MATERIAL
@export var icon: Texture2D
@export var max_stack_size: int = 10

## How much hunger this restores when eaten. Only meaningful for
## category == FOOD; non-food items leave this at 0.
@export var hunger_restore: float = 0.0
