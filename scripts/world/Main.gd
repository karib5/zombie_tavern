extends Node

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")

@onready var world_root: Node2D = $WorldRoot
@onready var interaction_prompt: InteractionPrompt = $UILayer/InteractionPrompt
@onready var inventory_ui: InventoryUI = $UILayer/InventoryUI
@onready var health_ui: HealthUI = $UILayer/HealthUI
@onready var cooking_ui: CookingUI = $UILayer/CookingUI
@onready var crafting_ui: CraftingUI = $UILayer/CraftingUI
@onready var processing_ui: ProcessingUI = $UILayer/ProcessingUI
@onready var search_ui: SearchUI = $UILayer/SearchUI
@onready var storage_ui: StorageUI = $UILayer/StorageUI
@onready var tool_ui: ToolUI = $UILayer/ToolUI
@onready var survival_hud: SurvivalHUD = $UILayer/SurvivalHUD
@onready var attack_event_ui: AttackEventUI = $UILayer/AttackEventUI

func _ready() -> void:
	WorldManager.register_current_map(world_root)
	_spawn_player()

## Debug save triggers for this phase (no save menu yet) - F5 save, F9
## load, F12 new game. SaveManager itself has no idea Main.tscn exists;
## this is just where the keybinding happens to live.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		SaveManager.save_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("load_game"):
		SaveManager.load_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("new_game"):
		SaveManager.new_game()
		get_viewport().set_input_as_handled()

func _spawn_player() -> void:
	var spawn_point := WorldManager.get_spawn_point("PlayerSpawnPoint")
	var spawn_position := spawn_point.global_position if spawn_point else Vector2.ZERO
	var player := WorldManager.spawn_entity(PLAYER_SCENE, spawn_position)
	GameManager.player = player

	var interaction_controller := player.get_node("InteractionArea") as InteractionController
	interaction_controller.interactable_changed.connect(interaction_prompt.set_interactable)

	var inventory := player.get_node("Inventory") as Inventory
	inventory_ui.set_inventory(inventory)

	var survival := player.get_node("PlayerSurvival") as PlayerSurvival
	inventory_ui.set_survival(survival)
	survival_hud.set_survival(survival)

	var health := player.get_node("Health") as Health
	health_ui.set_health(health)

	cooking_ui.set_inventory(inventory)
	for station in get_tree().get_nodes_in_group("cooking_stations"):
		(station as CookingStation).opened.connect(cooking_ui.open)

	crafting_ui.setup(player, inventory)

	processing_ui.set_inventory(inventory)
	for station in get_tree().get_nodes_in_group("processing_stations"):
		(station as ProcessingStation).opened.connect(processing_ui.open)

	search_ui.set_inventory(inventory)
	for container in get_tree().get_nodes_in_group("searchable_containers"):
		(container as SearchableContainer).opened.connect(search_ui.open)

	storage_ui.set_inventory(inventory)
	for container in get_tree().get_nodes_in_group("storage_containers"):
		(container as StorageContainer).opened.connect(storage_ui.open)

	var tools := player.get_node("PlayerTools") as PlayerTools
	tool_ui.set_tools(tools)

	var attack_events := get_tree().get_nodes_in_group("tavern_attack_events")
	if attack_events.size() > 0:
		attack_event_ui.set_attack_event(attack_events[0] as TavernAttackEvent)
