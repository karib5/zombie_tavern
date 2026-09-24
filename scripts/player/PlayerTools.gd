class_name PlayerTools
extends Node

## Tracks which tool (if any) the player currently has equipped, and lets
## them cycle through the distinct tool items sitting in their inventory.
## Purely a selection layer on top of the existing Inventory - equipping a
## tool never removes it from inventory or duplicates its data.
signal equipped_tool_changed(tool: ToolData)

@export var cycle_action: String = "cycle_tool"

@onready var _inventory: Inventory = get_parent().get_node("Inventory")

var equipped_tool: ToolData = null

func _ready() -> void:
	_inventory.inventory_changed.connect(_on_inventory_changed)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(cycle_action):
		_cycle_tool()

func has_tool(tool_type: ToolData.ToolType) -> bool:
	return equipped_tool != null and equipped_tool.tool_type == tool_type

func _cycle_tool() -> void:
	var tools := _available_tools()
	if tools.is_empty():
		_set_equipped(null)
		return

	var current_index := tools.find(equipped_tool)
	var next_index := (current_index + 1) % tools.size()
	_set_equipped(tools[next_index])

## Keeps the equipped tool usable the moment it's crafted/picked up without
## requiring a manual cycle, and clears it if it's no longer held.
func _on_inventory_changed() -> void:
	var tools := _available_tools()
	if equipped_tool != null and not tools.has(equipped_tool):
		_set_equipped(tools[0] if not tools.is_empty() else null)
	elif equipped_tool == null and not tools.is_empty():
		_set_equipped(tools[0])

func _available_tools() -> Array[ToolData]:
	var result: Array[ToolData] = []
	for slot in _inventory.slots:
		if slot == null:
			continue
		var tool := slot.item as ToolData
		if tool != null and not result.has(tool):
			result.append(tool)
	return result

func _set_equipped(tool: ToolData) -> void:
	if tool == equipped_tool:
		return
	equipped_tool = tool
	equipped_tool_changed.emit(equipped_tool)
