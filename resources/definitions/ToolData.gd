class_name ToolData
extends ItemData

## A tool is just an ItemData with equip-relevant stats attached, so tool
## items live in the inventory exactly like any other item - no separate
## "tool" bookkeeping is needed anywhere else in the game.
enum ToolType { NONE, AXE, PICKAXE, HOE, HAMMER, FISHING_ROD, SHOVEL, BUCKET }

@export var tool_type: ToolType = ToolType.NONE

## Multiplies the amount gathered per interaction when this tool matches a
## ResourceNode's required_tool_type. Purely a yield modifier for now.
@export var effectiveness: float = 1.0

## Reserved for future tool-specific interactions (e.g. a longer swing
## range than the base InteractionController range, or attack-style use).
@export var interaction_range: float = 48.0

## Reserved for future rate-limiting of tool use (e.g. a swing animation
## lock). Not yet enforced by any system.
@export var use_cooldown_seconds: float = 0.3

## 0 or less means this tool doesn't use the durability system at all
## (always usable). Current durability is tracked per-inventory-slot (see
## InventorySlot.tool_durability), not here, since this Resource is
## shared by every copy of the item - see PlayerTools for how it's used.
@export var max_durability: float = 100.0
@export var durability_loss_per_use: float = 1.0
