class_name TavernTable
extends Interactable

@onready var _serving_slots: Array[FoodServingSlot] = [$ServingSlot1, $ServingSlot2]

func _ready() -> void:
	add_to_group("tavern_tables")
	_update_prompt()

## Single interact key, so this prioritizes the most useful action for
## the current state: serve if the player is carrying food and there's
## room, otherwise let them take back whatever is already on the table.
func interact(player: Node) -> void:
	var inventory := player.get_node("Inventory") as Inventory
	if inventory == null:
		return

	if has_empty_slot() and _find_servable_food(inventory) != null:
		_serve_food(inventory)
	elif has_available_food():
		_take_food(inventory)
	else:
		print("Nothing to serve and nothing available to take.")

	_update_prompt()

func has_empty_slot() -> bool:
	for slot in _serving_slots:
		if not slot.is_occupied():
			return true
	return false

## --- Minimal food-facing API for a future survivor system (Phase 11).
## No AI calls these yet; they only need to exist and behave correctly. ---

func has_available_food() -> bool:
	for slot in _serving_slots:
		if slot.is_occupied():
			return true
	return false

func get_available_food() -> Array[ItemData]:
	var foods: Array[ItemData] = []
	for slot in _serving_slots:
		if slot.is_occupied():
			foods.append(slot.food_item)
	return foods

## Removes and returns one available serving (null if none available).
## Updates the table's own state/prompt; does not touch any inventory.
func consume_food() -> ItemData:
	for slot in _serving_slots:
		if slot.is_occupied():
			var item := slot.take_food()
			_update_prompt()
			return item
	return null

# --- Internal ---

func _find_servable_food(inventory: Inventory) -> ItemData:
	for slot in inventory.slots:
		if slot != null and slot.item != null and slot.item.category == ItemData.ItemCategory.FOOD:
			return slot.item
	return null

func _find_empty_slot() -> FoodServingSlot:
	for slot in _serving_slots:
		if not slot.is_occupied():
			return slot
	return null

func _serve_food(inventory: Inventory) -> void:
	var food := _find_servable_food(inventory)
	if food == null:
		return
	var empty_slot := _find_empty_slot()
	if empty_slot == null:
		return
	if not inventory.remove_item(food, 1):
		return
	empty_slot.place_food(food)
	print("Served %s" % food.display_name)

func _take_food(inventory: Inventory) -> void:
	var occupied_slot: FoodServingSlot = null
	for slot in _serving_slots:
		if slot.is_occupied():
			occupied_slot = slot
			break
	if occupied_slot == null:
		return

	var food := occupied_slot.food_item
	var leftover := inventory.add_item(food, 1)
	if leftover > 0:
		# No room in the inventory - leave the food safely on the table
		# rather than losing it.
		return

	occupied_slot.take_food()
	print("Took %s from the table" % food.display_name)

func _update_prompt() -> void:
	prompt_text = "Serve Food" if has_empty_slot() else "Food Available"
