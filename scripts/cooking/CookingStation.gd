class_name CookingStation
extends Interactable

@export var recipes: Array[RecipeData] = []

## Emitted when the player interacts with this station. Main.gd connects
## this to the one shared CookingUI, so any number of stations can reuse
## it without each needing its own reference to the UI.
signal opened(station: CookingStation)

signal cooking_started(recipe: RecipeData)
signal cooking_finished(recipe: RecipeData)

var is_cooking: bool = false

const LOOT_PICKUP_SCENE: PackedScene = preload("res://scenes/loot/LootPickup.tscn")

@onready var _cook_timer: Timer = $CookTimer

var _current_recipe: RecipeData = null
var _cooking_inventory: Inventory = null

func _ready() -> void:
	prompt_text = "Cook"
	add_to_group("cooking_stations")
	_cook_timer.one_shot = true
	_cook_timer.timeout.connect(_on_cook_timer_timeout)

func interact(_player: Node) -> void:
	opened.emit(self)

func can_cook(recipe: RecipeData, inventory: Inventory) -> bool:
	if is_cooking or recipe == null or inventory == null:
		return false
	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item == null or ingredient.quantity <= 0:
			continue
		if inventory.get_item_count(ingredient.item) < ingredient.quantity:
			return false
	return true

## Consumes the ingredients immediately and starts the cook timer. Returns
## false (doing nothing) if the station is already cooking or ingredients
## are insufficient, so this can never be started twice at once.
func start_cooking(recipe: RecipeData, inventory: Inventory) -> bool:
	if not can_cook(recipe, inventory):
		return false

	for ingredient in recipe.ingredients:
		if ingredient == null or ingredient.item == null or ingredient.quantity <= 0:
			continue
		inventory.remove_item(ingredient.item, ingredient.quantity)

	is_cooking = true
	_current_recipe = recipe
	_cooking_inventory = inventory
	cooking_started.emit(recipe)
	_cook_timer.start(recipe.cook_time_seconds)
	return true

func _on_cook_timer_timeout() -> void:
	var recipe := _current_recipe
	var inventory := _cooking_inventory
	is_cooking = false
	_current_recipe = null
	_cooking_inventory = null

	if recipe == null or recipe.output_item == null or recipe.output_quantity <= 0:
		cooking_finished.emit(recipe)
		return

	var leftover := recipe.output_quantity
	if inventory != null:
		leftover = inventory.add_item(recipe.output_item, recipe.output_quantity)

	if leftover > 0:
		_spawn_leftover_pickup(recipe.output_item, leftover)

	cooking_finished.emit(recipe)

## If the inventory couldn't hold the full output, the remainder is
## preserved as a LootPickup at the station - the same existing
## interaction/inventory architecture ResourceNode and animal carcasses
## already use for a full or partially-full inventory, rather than
## deleting it or inventing a new "pending output" concept here.
func _spawn_leftover_pickup(item: ItemData, quantity: int) -> void:
	var entry := LootEntry.new()
	entry.item = item
	entry.quantity = quantity
	var pickup := WorldManager.spawn_entity(LOOT_PICKUP_SCENE, global_position) as LootPickup
	pickup.loot_table = [entry]
