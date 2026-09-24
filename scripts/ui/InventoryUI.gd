class_name InventoryUI
extends Control

@export var toggle_action: String = "toggle_inventory"

var _inventory: Inventory
var _survival: PlayerSurvival

@onready var _weight_label: Label = $Panel/WeightLabel
@onready var _slot_list: VBoxContainer = $Panel/SlotList

func _ready() -> void:
	visible = false

func set_inventory(inventory: Inventory) -> void:
	if _inventory and _inventory.inventory_changed.is_connected(_refresh):
		_inventory.inventory_changed.disconnect(_refresh)
	_inventory = inventory
	_inventory.inventory_changed.connect(_refresh)
	_refresh()

func set_survival(survival: PlayerSurvival) -> void:
	_survival = survival

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

	_weight_label.text = "Weight: %.1f / %.1f" % [_inventory.get_total_weight(), _inventory.max_carry_weight]

	for slot in _inventory.slots:
		if slot == null:
			continue
		_slot_list.add_child(_build_slot_row(slot))

func _build_slot_row(slot: InventorySlot) -> Control:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = "%s  x%d%s" % [slot.item.display_name, slot.quantity, _freshness_suffix(slot)]
	row.add_child(label)

	if slot.item.is_consumable and _survival != null:
		var button := Button.new()
		button.text = "Drink" if slot.item.thirst_restore > slot.item.hunger_restore else "Eat"
		button.pressed.connect(_on_consume_pressed.bind(slot.item))
		row.add_child(button)

	return row

func _freshness_suffix(slot: InventorySlot) -> String:
	var freshness := slot.item.get_freshness(slot.acquired_at_minutes, TimeManager.get_total_minutes())
	match freshness:
		ItemData.Freshness.AGING:
			return "  (aging)"
		ItemData.Freshness.SPOILED:
			return "  (spoiled)"
		_:
			return ""

func _on_consume_pressed(item: ItemData) -> void:
	if _survival == null:
		return
	if _survival.consume(item):
		_inventory.remove_item(item, 1)
