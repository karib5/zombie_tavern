class_name WaterSource
extends Interactable

## Reusable "this is a water source" marker - a pond, river, or well all
## just become another instance of this scene with different data, the
## same pattern FishingSpot uses for "this water is fishable". A single
## body of water can (and at the pond, does) carry both a WaterSource and
## a FishingSpot as separate sibling nodes.
@export var water_type: String = "Pond"

## Whether output_item can be drunk directly (a clean well) or needs
## further processing first (a pond's water comes out dirty).
@export var is_drinkable: bool = false

## Whether the player can collect from this source at all right now.
@export var is_collectible: bool = true

## Informational only, for future water-source listings/UI - fishing
## itself is handled entirely by a separate FishingSpot instance.
@export var is_fishable: bool = false

## The container consumed to collect one unit of output_item.
@export var container_item: ItemData
@export var output_item: ItemData

const LOOT_PICKUP_SCENE: PackedScene = preload("res://scenes/loot/LootPickup.tscn")

func _ready() -> void:
	prompt_text = "Collect Water" if is_collectible else water_type

func interact(player: Node) -> void:
	if not is_collectible or container_item == null or output_item == null:
		return

	var inventory := player.get_node_or_null("Inventory") as Inventory
	if inventory == null:
		return

	if not inventory.remove_item(container_item, 1):
		print("Need a %s to collect water" % container_item.display_name)
		return

	var leftover := inventory.add_item(output_item, 1)
	if leftover > 0:
		_spawn_leftover_pickup(output_item, leftover, player.global_position)
	else:
		print("Collected %s" % output_item.display_name)

func _spawn_leftover_pickup(item: ItemData, quantity: int, spawn_position: Vector2) -> void:
	var entry := LootEntry.new()
	entry.item = item
	entry.quantity = quantity
	var pickup := WorldManager.spawn_entity(LOOT_PICKUP_SCENE, spawn_position) as LootPickup
	pickup.loot_table = [entry]
