class_name PlayerTools
extends Node

## Tracks which tool (if any) the player currently has equipped, and lets
## them cycle through the distinct tool-holding inventory slots. Cycling
## is per-slot (not per-ToolData) so two copies of the same tool (e.g. two
## Axes) are tracked - and can wear down - independently.
signal equipped_tool_changed(tool: ToolData)
signal equipped_tool_durability_changed(current: float, max: float)

@export var cycle_action: String = "cycle_tool"

@onready var _inventory: Inventory = get_parent().get_node("Inventory")

var equipped_slot: InventorySlot = null

var equipped_tool: ToolData:
	get:
		return (equipped_slot.item as ToolData) if equipped_slot != null else null

func _ready() -> void:
	_inventory.inventory_changed.connect(_on_inventory_changed)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(cycle_action):
		_cycle_tool()

func has_tool(tool_type: ToolData.ToolType) -> bool:
	var tool := equipped_tool
	return tool != null and tool.tool_type == tool_type

## Tools with max_durability <= 0 don't use the durability system at all
## and are never considered broken.
func is_equipped_tool_broken() -> bool:
	var tool := equipped_tool
	if tool == null or tool.max_durability <= 0.0:
		return false
	return _durability_of(equipped_slot) <= 0.0

## Called by whatever interaction actually used the equipped tool (a
## ResourceNode gather, a FarmPlot till, ...) - decrements durability and
## returns whether the tool was usable. Callers should still gate on
## has_tool()/is_equipped_tool_broken() beforehand; this only moves state.
func use_equipped_tool() -> bool:
	var tool := equipped_tool
	if tool == null or equipped_slot == null:
		return false
	if tool.max_durability <= 0.0:
		return true

	var current := _durability_of(equipped_slot)
	if current <= 0.0:
		return false

	current = maxf(current - tool.durability_loss_per_use, 0.0)
	equipped_slot.tool_durability = current
	equipped_tool_durability_changed.emit(current, tool.max_durability)
	return true

func _durability_of(slot: InventorySlot) -> float:
	var tool := slot.item as ToolData
	if tool == null:
		return 0.0
	if slot.tool_durability < 0.0:
		slot.tool_durability = tool.max_durability
	return slot.tool_durability

func _cycle_tool() -> void:
	var tool_slots := _tool_slots()
	if tool_slots.is_empty():
		_set_equipped(null)
		return

	var current_index := tool_slots.find(equipped_slot)
	var next_index := (current_index + 1) % tool_slots.size()
	_set_equipped(tool_slots[next_index])

## Keeps the equipped tool usable the moment it's crafted/picked up without
## requiring a manual cycle, and clears it if it's no longer held.
func _on_inventory_changed() -> void:
	var tool_slots := _tool_slots()
	if equipped_slot != null and not tool_slots.has(equipped_slot):
		_set_equipped(tool_slots[0] if not tool_slots.is_empty() else null)
	elif equipped_slot == null and not tool_slots.is_empty():
		_set_equipped(tool_slots[0])

## Used by SaveManager to restore the equipped tool after
## Inventory.apply_save_data() rebuilds `slots` with fresh InventorySlot
## instances (equipped_slot can't just be serialized directly - it's an
## object reference, not data).
func get_equipped_slot_index() -> int:
	return _inventory.slots.find(equipped_slot)

func equip_slot_index(index: int) -> void:
	if index >= 0 and index < _inventory.slots.size() and _inventory.slots[index] != null:
		_set_equipped(_inventory.slots[index])
	else:
		_set_equipped(null)

func _tool_slots() -> Array[InventorySlot]:
	var result: Array[InventorySlot] = []
	for slot in _inventory.slots:
		if slot != null and slot.item is ToolData:
			result.append(slot)
	return result

func _set_equipped(slot: InventorySlot) -> void:
	if slot == equipped_slot:
		return
	equipped_slot = slot
	equipped_tool_changed.emit(equipped_tool)
