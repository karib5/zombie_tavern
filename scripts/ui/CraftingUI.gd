class_name CraftingUI
extends Control

## Unlike ProcessingUI/CookingUI (opened by walking up to a specific
## station), this is toggled from anywhere, the same way InventoryUI is -
## it now works as a recipe reference ("what needs a Workbench/Furnace?")
## rather than a place recipes actually get crafted. Anything with
## requires_station = true can only actually be made at that station's
## ProcessingUI/CookingUI.
@export var toggle_action: String = "toggle_crafting"

## The initial recipe set, assigned directly in the scene - small and
## data-driven, with no filesystem scanning needed.
@export var recipes: Array[RecipeData] = []

const LOOT_PICKUP_SCENE: PackedScene = preload("res://scenes/loot/LootPickup.tscn")

var _inventory: Inventory
var _player: Node2D

@onready var _recipe_list: VBoxContainer = $Panel/RecipeList

func _ready() -> void:
	visible = false

func setup(player: Node2D, inventory: Inventory) -> void:
	_player = player
	if _inventory and _inventory.inventory_changed.is_connected(_refresh):
		_inventory.inventory_changed.disconnect(_refresh)
	_inventory = inventory
	_inventory.inventory_changed.connect(_refresh)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		visible = not visible
		if visible:
			_refresh()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		visible = false
		get_viewport().set_input_as_handled()

func can_craft(recipe: RecipeData) -> bool:
	if recipe == null or _inventory == null or recipe.requires_station:
		return false
	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item == null or ingredient.quantity <= 0:
			continue
		if _inventory.get_item_count(ingredient.item) < ingredient.quantity:
			return false
	return true

func _refresh() -> void:
	for child in _recipe_list.get_children():
		child.queue_free()

	if _inventory == null:
		return

	var current_category := -1
	for recipe in recipes:
		if recipe == null:
			continue
		if int(recipe.category) != current_category:
			current_category = int(recipe.category)
			_recipe_list.add_child(_build_category_label(recipe.category))
		_recipe_list.add_child(_build_recipe_row(recipe))

func _build_category_label(category: RecipeData.Category) -> Label:
	var label := Label.new()
	label.text = RecipeData.Category.keys()[category]
	return label

func _build_recipe_row(recipe: RecipeData) -> Control:
	var row := VBoxContainer.new()

	var title := Label.new()
	title.text = recipe.recipe_name
	row.add_child(title)

	var ingredient_parts: Array[String] = []
	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item == null:
			continue
		var have := _inventory.get_item_count(ingredient.item)
		ingredient_parts.append("%s %d/%d" % [ingredient.item.display_name, have, ingredient.quantity])
	var ingredients_label := Label.new()
	ingredients_label.text = "Needs: %s" % ", ".join(ingredient_parts)
	row.add_child(ingredients_label)

	var output_label := Label.new()
	if recipe.output_item:
		output_label.text = "Makes: %s x%d" % [recipe.output_item.display_name, recipe.output_quantity]
	row.add_child(output_label)

	if recipe.requires_station:
		var station_label := Label.new()
		station_label.text = "Requires: %s" % recipe.station_name
		row.add_child(station_label)

	var craft_button := Button.new()
	craft_button.text = ("Requires %s" % recipe.station_name) if recipe.requires_station else "Craft"
	craft_button.disabled = not can_craft(recipe)
	craft_button.pressed.connect(_on_craft_pressed.bind(recipe))
	row.add_child(craft_button)

	return row

func _on_craft_pressed(recipe: RecipeData) -> void:
	if not can_craft(recipe):
		return

	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item == null or ingredient.quantity <= 0:
			continue
		_inventory.remove_item(ingredient.item, ingredient.quantity)

	if recipe.output_item != null and recipe.output_quantity > 0:
		var leftover := _inventory.add_item(recipe.output_item, recipe.output_quantity)
		if leftover > 0:
			_spawn_leftover_pickup(recipe.output_item, leftover)

	_refresh()

## Same pattern as CookingStation/ResourceNode/FarmPlot: preserve output
## that doesn't fit rather than deleting it.
func _spawn_leftover_pickup(item: ItemData, quantity: int) -> void:
	if _player == null:
		return
	var entry := LootEntry.new()
	entry.item = item
	entry.quantity = quantity
	var pickup := WorldManager.spawn_entity(LOOT_PICKUP_SCENE, _player.global_position) as LootPickup
	pickup.loot_table = [entry]
