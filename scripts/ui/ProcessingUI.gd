class_name ProcessingUI
extends Control

## One shared UI for every ProcessingStation (Workbench, Furnace, ...) -
## Main.gd connects every station's `opened` signal to this, the same way
## CookingUI is shared across every CookingStation.
var _inventory: Inventory
var _station: ProcessingStation

@onready var _title_label: Label = $Panel/TitleLabel
@onready var _recipe_list: VBoxContainer = $Panel/RecipeList

func _ready() -> void:
	visible = false

func set_inventory(inventory: Inventory) -> void:
	if _inventory and _inventory.inventory_changed.is_connected(_refresh):
		_inventory.inventory_changed.disconnect(_refresh)
	_inventory = inventory
	_inventory.inventory_changed.connect(_refresh)

func open(station: ProcessingStation) -> void:
	if _station and _station.processing_finished.is_connected(_on_processing_finished):
		_station.processing_finished.disconnect(_on_processing_finished)

	_station = station
	_station.processing_finished.connect(_on_processing_finished)

	_title_label.text = station.station_name()
	visible = true
	_refresh()

func close() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()

func _on_processing_finished(_recipe: RecipeData) -> void:
	_refresh()

func _refresh() -> void:
	for child in _recipe_list.get_children():
		child.queue_free()

	if _station == null:
		return

	for recipe in _station.recipes:
		if recipe == null:
			continue
		_recipe_list.add_child(_build_recipe_row(recipe))

func _build_recipe_row(recipe: RecipeData) -> Control:
	var row := VBoxContainer.new()

	var title := Label.new()
	title.text = recipe.recipe_name
	row.add_child(title)

	var ingredient_parts: Array[String] = []
	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item == null:
			continue
		var have := _inventory.get_item_count(ingredient.item) if _inventory else 0
		ingredient_parts.append("%s %d/%d" % [ingredient.item.display_name, have, ingredient.quantity])
	var ingredients_label := Label.new()
	ingredients_label.text = "Needs: %s" % ", ".join(ingredient_parts)
	row.add_child(ingredients_label)

	var output_label := Label.new()
	if recipe.output_item:
		output_label.text = "Makes: %s x%d  (%.0fs)" % [
			recipe.output_item.display_name, recipe.output_quantity, recipe.cook_time_seconds]
	row.add_child(output_label)

	var process_button := Button.new()
	var can_process_now := _station.can_process_recipe(recipe, _inventory)
	process_button.text = "Processing..." if _station.is_processing else "Process"
	process_button.disabled = not can_process_now
	process_button.pressed.connect(_on_process_pressed.bind(recipe))
	row.add_child(process_button)

	return row

func _on_process_pressed(recipe: RecipeData) -> void:
	if _station.start_processing(recipe, _inventory):
		_refresh()
