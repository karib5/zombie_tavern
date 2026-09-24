class_name Inventory
extends Node

## Emitted whenever slot contents change (added, removed, stacked).
signal inventory_changed

@export var slot_capacity: int = 20

## Foundation only - not yet enforced anywhere (add_item never blocks on
## it). See get_total_weight()/is_overweight().
@export var max_carry_weight: float = 100.0

## Empty slots are represented as null.
var slots: Array[InventorySlot] = []

func _ready() -> void:
	slots.resize(slot_capacity)

## Adds up to `quantity` of `item`, filling existing stacks before empty
## slots. Returns the amount that didn't fit (0 if everything was added).
func add_item(item: ItemData, quantity: int = 1) -> int:
	var remaining := quantity

	for slot in slots:
		if remaining <= 0:
			break
		if slot != null and slot.item.item_id == item.item_id and slot.quantity < item.max_stack_size:
			var space := item.max_stack_size - slot.quantity
			var add_amount := mini(space, remaining)
			slot.quantity += add_amount
			remaining -= add_amount

	for i in slots.size():
		if remaining <= 0:
			break
		if slots[i] == null:
			var add_amount := mini(item.max_stack_size, remaining)
			var slot := InventorySlot.new(item, add_amount)
			slot.acquired_at_minutes = TimeManager.get_total_minutes()
			slots[i] = slot
			remaining -= add_amount

	if remaining < quantity:
		inventory_changed.emit()
	return remaining

## Removes up to `quantity` of `item`. Returns false (and removes nothing)
## if the inventory doesn't hold enough of it.
func remove_item(item: ItemData, quantity: int = 1) -> bool:
	if get_item_count(item) < quantity:
		return false

	var remaining := quantity
	for i in slots.size():
		if remaining <= 0:
			break
		var slot := slots[i]
		if slot != null and slot.item.item_id == item.item_id:
			var remove_amount := mini(slot.quantity, remaining)
			slot.quantity -= remove_amount
			remaining -= remove_amount
			if slot.quantity <= 0:
				slots[i] = null

	inventory_changed.emit()
	return true

func get_item_count(item: ItemData) -> int:
	var total := 0
	for slot in slots:
		if slot != null and slot.item.item_id == item.item_id:
			total += slot.quantity
	return total

func has_empty_slot() -> bool:
	for slot in slots:
		if slot == null:
			return true
	return false

func is_full() -> bool:
	return not has_empty_slot()

## Computed on demand (not cached/ticked) - cheap enough for a UI refresh
## or an occasional check, and always correct without every add_item/
## remove_item call site needing to maintain a running total.
func get_total_weight() -> float:
	var total := 0.0
	for slot in slots:
		if slot != null:
			total += slot.item.weight * slot.quantity
	return total

func is_overweight() -> bool:
	return get_total_weight() > max_carry_weight
