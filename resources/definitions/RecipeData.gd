class_name RecipeData
extends Resource

@export var recipe_name: String = ""

## Reuses LootEntry (item + quantity) for the ingredient list - a recipe
## ingredient is structurally identical to a loot entry, so this avoids a
## duplicate "item + quantity" Resource type.
@export var ingredients: Array[LootEntry] = []

@export var output_item: ItemData
@export var output_quantity: int = 1
@export var cook_time_seconds: float = 3.0
