class_name InventoryUI
extends Control

@export var toggle_action: String = "toggle_inventory"

var _inventory: Inventory

@onready var _slot_list: VBoxContainer = $Panel/SlotList

func _ready() -> void:
	visible = false

func set_inventory(inventory: Inventory) -> void:
	if _inventory and _inventory.inventory_changed.is_connected(_refresh):
		_inventory.inventory_changed.disconnect(_refresh)
	_inventory = inventory
	_inventory.inventory_changed.connect(_refresh)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		visible = not visible
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	for child in _slot_list.get_children():
		child.queue_free()

	if _inventory == null:
		return

	for slot in _inventory.slots:
		if slot == null:
			continue
		var label := Label.new()
		label.text = "%s  x%d" % [slot.item.display_name, slot.quantity]
		_slot_list.add_child(label)
