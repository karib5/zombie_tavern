class_name SearchUI
extends Control

const LOOT_PICKUP_SCENE: PackedScene = preload("res://scenes/loot/LootPickup.tscn")

var _inventory: Inventory
var _container: SearchableContainer

@onready var _title_label: Label = $Panel/TitleLabel
@onready var _entry_list: VBoxContainer = $Panel/EntryList

func _ready() -> void:
	visible = false

func set_inventory(inventory: Inventory) -> void:
	_inventory = inventory

func open(container: SearchableContainer) -> void:
	_container = container
	_title_label.text = container.container_name
	visible = true
	_refresh()

func close() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	for child in _entry_list.get_children():
		child.queue_free()

	if _container == null:
		return

	if _container.loot_table.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Empty."
		_entry_list.add_child(empty_label)
		return

	for i in _container.loot_table.size():
		_entry_list.add_child(_build_entry_row(i))

func _build_entry_row(index: int) -> Control:
	var entry := _container.loot_table[index]
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = "%s x%d" % [entry.item.display_name, entry.quantity] if entry.item else "?"
	row.add_child(label)

	var take_button := Button.new()
	take_button.text = "Take"
	take_button.pressed.connect(_on_take_pressed.bind(index))
	row.add_child(take_button)

	return row

func _on_take_pressed(index: int) -> void:
	if _container == null or index < 0 or index >= _container.loot_table.size():
		return
	var item := _container.loot_table[index].item
	var quantity := _container.loot_table[index].quantity

	var taken := _container.take_entry(index)
	if taken == null or item == null:
		return

	var leftover := _inventory.add_item(item, quantity)
	if leftover > 0:
		_spawn_leftover_pickup(item, leftover)

	_refresh()

func _spawn_leftover_pickup(item: ItemData, quantity: int) -> void:
	var entry := LootEntry.new()
	entry.item = item
	entry.quantity = quantity
	var pickup := WorldManager.spawn_entity(LOOT_PICKUP_SCENE, _container.global_position) as LootPickup
	pickup.loot_table = [entry]
