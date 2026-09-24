class_name RecipeData
extends Resource

## Cooking recipes (used by CookingStation) leave this at the default
## GENERAL value; CraftingUI groups its own recipes by this category.
enum Category { GENERAL, TOOLS, PROCESSING, BUILDING }

@export var recipe_name: String = ""
@export var category: Category = Category.GENERAL

## Reuses LootEntry (item + quantity) for the ingredient list - a recipe
## ingredient is structurally identical to a loot entry, so this avoids a
## duplicate "item + quantity" Resource type.
@export var ingredients: Array[LootEntry] = []

@export var output_item: ItemData
@export var output_quantity: int = 1
@export var cook_time_seconds: float = 3.0

## Optional future gate: a named crafting station (e.g. "forge") the
## player must be near to craft this recipe. Not yet enforced by
## CraftingUI - reserved so a station requirement can be added later
## without changing the resource format.
@export var requires_station: bool = false
@export var station_name: String = ""
