class_name FishingSpot
extends Interactable

## A reusable "this water supports fishing" marker - the pond gets one
## instance of this scene; a future river/lake/ocean would just be another
## instance with its own fish_table, with no new script needed.
@export var fish_table: Array[LootEntry] = []
@export var fishing_time_seconds: float = 3.0

const LOOT_PICKUP_SCENE: PackedScene = preload("res://scenes/loot/LootPickup.tscn")

var is_fishing: bool = false

@onready var _fishing_timer: Timer = $FishingTimer

var _fishing_player: Node = null

func _ready() -> void:
	prompt_text = "Fish (needs Fishing Rod)"
	_fishing_timer.one_shot = true
	_fishing_timer.timeout.connect(_on_fishing_timer_timeout)

func interact(player: Node) -> void:
	if is_fishing or fish_table.is_empty():
		return
	var tools := player.get_node_or_null("PlayerTools") as PlayerTools
	if tools == null or not tools.has_tool(ToolData.ToolType.FISHING_ROD):
		print("Need a Fishing Rod to fish here")
		return

	is_fishing = true
	_fishing_player = player
	prompt_text = "Fishing..."
	_fishing_timer.start(fishing_time_seconds)

func _on_fishing_timer_timeout() -> void:
	is_fishing = false
	prompt_text = "Fish (needs Fishing Rod)"

	var player := _fishing_player
	_fishing_player = null
	if player == null or not is_instance_valid(player):
		return

	var caught := fish_table[randi() % fish_table.size()]
	if caught == null or caught.item == null or caught.quantity <= 0:
		return

	var inventory := player.get_node_or_null("Inventory") as Inventory
	if inventory == null:
		return

	var leftover := inventory.add_item(caught.item, caught.quantity)
	var amount_caught := caught.quantity - leftover
	if amount_caught > 0:
		print("Caught %d %s" % [amount_caught, caught.item.display_name])
	if leftover > 0:
		_spawn_leftover_pickup(caught.item, leftover, player.global_position)

## Same overflow pattern as every other gather/craft/process source: keep
## what doesn't fit as a pickup rather than losing it.
func _spawn_leftover_pickup(item: ItemData, quantity: int, spawn_position: Vector2) -> void:
	var entry := LootEntry.new()
	entry.item = item
	entry.quantity = quantity
	var pickup := WorldManager.spawn_entity(LOOT_PICKUP_SCENE, spawn_position) as LootPickup
	pickup.loot_table = [entry]
