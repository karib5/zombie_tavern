class_name StorageUI
extends Control

var _player_inventory: Inventory
var _container: StorageContainer

@onready var _title_label: Label = $Panel/TitleLabel
@onready var _player_list: VBoxContainer = $Panel/HBox/PlayerColumn/PlayerList
@onready var _storage_list: VBoxContainer = $Panel/HBox/StorageColumn/StorageList

func _ready() -> void:
	visible = false

func set_inventory(inventory: Inventory) -> void:
	if _player_inventory and _player_inventory.inventory_changed.is_connected(_refresh):
		_player_inventory.inventory_changed.disconnect(_refresh)
	_player_inventory = inventory
	_player_inventory.inventory_changed.connect(_refresh)

func open(container: StorageContainer) -> void:
	if _container and _container.storage.inventory_changed.is_connected(_refresh):
		_container.storage.inventory_changed.disconnect(_refresh)
	_container = container
	_container.storage.inventory_changed.connect(_refresh)

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
	for child in _player_list.get_children():
		child.queue_free()
	for child in _storage_list.get_children():
		child.queue_free()

	if _container == null:
		return

	for slot in _player_inventory.slots:
		if slot == null:
			continue
		_player_list.add_child(_build_row(slot, _on_store_pressed))

	for slot in _container.storage.slots:
		if slot == null:
			continue
		_storage_list.add_child(_build_row(slot, _on_take_pressed))

func _build_row(slot: InventorySlot, on_pressed: Callable) -> Control:
	var row := HBoxContainer.new()

	var label := Label.new()
	label.text = "%s x%d" % [slot.item.display_name, slot.quantity]
	row.add_child(label)

	var button := Button.new()
	button.text = "Move"
	button.pressed.connect(on_pressed.bind(slot.item))
	row.add_child(button)

	return row

## Moves one unit at a time - simple, and naturally self-limiting since a
## full destination just leaves the remainder where it was. No explicit
## _refresh() call needed here: both Inventory's add_item/remove_item
## emit inventory_changed, which this UI is already connected to.
func _on_store_pressed(item: ItemData) -> void:
	if not _player_inventory.remove_item(item, 1):
		return
	var leftover := _container.storage.add_item(item, 1)
	if leftover > 0:
		_player_inventory.add_item(item, leftover)

func _on_take_pressed(item: ItemData) -> void:
	if not _container.storage.remove_item(item, 1):
		return
	var leftover := _player_inventory.add_item(item, 1)
	if leftover > 0:
		_container.storage.add_item(item, leftover)
