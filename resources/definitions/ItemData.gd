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

## Whether this item can be eaten/drunk via the inventory. Items with
## hunger_restore/thirst_restore but is_consumable = false (e.g. Dirty
## Water) exist in the world but can't be consumed directly - they need
## to be processed first (e.g. boiled into Clean Water).
@export var is_consumable: bool = false

## How much hunger this restores when eaten. Only meaningful for
## consumable items; non-food items leave this at 0.
@export var hunger_restore: float = 0.0

## How much thirst this restores when drunk. Only meaningful for
## consumable items; non-drink items leave this at 0.
@export var thirst_restore: float = 0.0

## In-game minutes (TimeManager.get_total_minutes()) before a perishable
## item's freshness moves from Fresh -> Aging -> Spoiled. 0 means this
## item never spoils (the default, so non-food items need no changes).
@export var spoil_minutes: float = 0.0

## Carried weight per single unit of this item. Inventory sums
## item.weight * slot.quantity for its total weight - see
## Inventory.get_total_weight().
@export var weight: float = 1.0

enum Freshness { NOT_PERISHABLE, FRESH, AGING, SPOILED }

## Computed on demand from two in-game-minute timestamps (see
## TimeManager.get_total_minutes()) rather than ticked per-frame or even
## per-minute - a stack's freshness only actually needs evaluating when
## something looks at it (inventory UI refresh, an eat attempt, etc).
func get_freshness(acquired_at_minutes: float, current_minutes: float) -> Freshness:
	if spoil_minutes <= 0.0:
		return Freshness.NOT_PERISHABLE
	var age := current_minutes - acquired_at_minutes
	if age >= spoil_minutes:
		return Freshness.SPOILED
	if age >= spoil_minutes * 0.5:
		return Freshness.AGING
	return Freshness.FRESH
