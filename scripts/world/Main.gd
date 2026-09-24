extends Node

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")

@onready var world_root: Node2D = $WorldRoot
@onready var interaction_prompt: InteractionPrompt = $UILayer/InteractionPrompt
@onready var inventory_ui: InventoryUI = $UILayer/InventoryUI
@onready var health_ui: HealthUI = $UILayer/HealthUI

func _ready() -> void:
	WorldManager.register_current_map(world_root)
	_spawn_player()

func _spawn_player() -> void:
	var spawn_point := WorldManager.get_spawn_point("PlayerSpawnPoint")
	var spawn_position := spawn_point.global_position if spawn_point else Vector2.ZERO
	var player := WorldManager.spawn_entity(PLAYER_SCENE, spawn_position)
	GameManager.player = player

	var interaction_controller := player.get_node("InteractionArea") as InteractionController
	interaction_controller.interactable_changed.connect(interaction_prompt.set_interactable)

	var inventory := player.get_node("Inventory") as Inventory
	inventory_ui.set_inventory(inventory)

	var health := player.get_node("Health") as Health
	health_ui.set_health(health)
