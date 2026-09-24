class_name InventorySlot
extends RefCounted

var item: ItemData
var quantity: int

## -1 means "unset" - PlayerTools lazily initializes this to
## item.max_durability the first time the tool in this slot is used, so a
## freshly-added tool doesn't need special-casing here.
var tool_durability: float = -1.0

## In-game minutes (TimeManager.get_total_minutes()) this stack was
## created. Only meaningful for items with spoil_minutes > 0 - see
## ItemData.get_freshness(). Stacking more of the same item onto an
## existing slot does not refresh this; the whole stack ages from when it
## was first created, which is a deliberate simplification rather than
## tracking per-unit freshness.
var acquired_at_minutes: float = 0.0

func _init(p_item: ItemData, p_quantity: int) -> void:
	item = p_item
	quantity = p_quantity
