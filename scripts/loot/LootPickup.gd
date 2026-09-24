class_name LootPickup
extends Interactable

## Reusable, multi-entry loot list so future sources can drop several
## item types from one pickup without any changes to this script.
@export var loot_table: Array[LootEntry] = []

func _ready() -> void:
	prompt_text = "Collect Loot"

func is_available() -> bool:
	return not loot_table.is_empty()

func interact(player: Node) -> void:
	var inventory := player.get_node("Inventory") as Inventory
	if inventory == null:
		return

	var remaining: Array[LootEntry] = []
	for entry in loot_table:
		if entry == null or entry.item == null or entry.quantity <= 0:
			continue

		var leftover := inventory.add_item(entry.item, entry.quantity)
		var collected := entry.quantity - leftover
		if collected > 0:
			print("Collected %d %s" % [collected, entry.item.display_name])

		if leftover > 0:
			var remaining_entry := LootEntry.new()
			remaining_entry.item = entry.item
			remaining_entry.quantity = leftover
			remaining.append(remaining_entry)

	loot_table = remaining
	if loot_table.is_empty():
		queue_free()
