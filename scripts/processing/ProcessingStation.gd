class_name ProcessingStation
extends Interactable

## One reusable station script for Workbench, Furnace, and any future
## processing station - what a station can make is entirely defined by
## which RecipeData resources are assigned to its `recipes` array in the
## scene, not by station-specific code. station_type only affects the
## prompt/title text; CookingStation stays a separate, untouched system
## (cooking recipes keep using it, per the existing convention).
enum StationType { WORKBENCH, FURNACE }

@export var station_type: StationType = StationType.WORKBENCH
@export var recipes: Array[RecipeData] = []

signal opened(station: ProcessingStation)
signal processing_started(recipe: RecipeData)
signal processing_finished(recipe: RecipeData)

var is_processing: bool = false

const LOOT_PICKUP_SCENE: PackedScene = preload("res://scenes/loot/LootPickup.tscn")

@onready var _process_timer: Timer = $ProcessTimer

var _current_recipe: RecipeData = null
var _processing_inventory: Inventory = null

func _ready() -> void:
	prompt_text = "Open %s" % station_name()
	add_to_group("processing_stations")
	_process_timer.one_shot = true
	_process_timer.timeout.connect(_on_process_timer_timeout)

func station_name() -> String:
	return "Workbench" if station_type == StationType.WORKBENCH else "Furnace"

func interact(_player: Node) -> void:
	opened.emit(self)

func can_process_recipe(recipe: RecipeData, inventory: Inventory) -> bool:
	if is_processing or recipe == null or inventory == null:
		return false
	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item == null or ingredient.quantity <= 0:
			continue
		if inventory.get_item_count(ingredient.item) < ingredient.quantity:
			return false
	return true

## Consumes the ingredients immediately and starts the process timer -
## same "consume up front, one job at a time" behavior as CookingStation.
func start_processing(recipe: RecipeData, inventory: Inventory) -> bool:
	if not can_process_recipe(recipe, inventory):
		return false

	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item == null or ingredient.quantity <= 0:
			continue
		inventory.remove_item(ingredient.item, ingredient.quantity)

	is_processing = true
	_current_recipe = recipe
	_processing_inventory = inventory
	processing_started.emit(recipe)
	_process_timer.start(recipe.cook_time_seconds)
	return true

func _on_process_timer_timeout() -> void:
	var recipe := _current_recipe
	var inventory := _processing_inventory
	is_processing = false
	_current_recipe = null
	_processing_inventory = null

	if recipe == null or recipe.output_item == null or recipe.output_quantity <= 0:
		processing_finished.emit(recipe)
		return

	var leftover := recipe.output_quantity
	if inventory != null:
		leftover = inventory.add_item(recipe.output_item, recipe.output_quantity)

	if leftover > 0:
		_spawn_leftover_pickup(recipe.output_item, leftover)

	processing_finished.emit(recipe)

## Same overflow pattern as ResourceNode/CookingStation/FarmPlot/CraftingUI:
## preserve output that doesn't fit rather than deleting it.
func _spawn_leftover_pickup(item: ItemData, quantity: int) -> void:
	var entry := LootEntry.new()
	entry.item = item
	entry.quantity = quantity
	var pickup := WorldManager.spawn_entity(LOOT_PICKUP_SCENE, global_position) as LootPickup
	pickup.loot_table = [entry]
