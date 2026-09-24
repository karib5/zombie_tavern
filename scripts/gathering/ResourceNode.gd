class_name ResourceNode
extends Interactable

## Display name used to build the interaction prompt (e.g. "Gather Wood")
## and shown in gather feedback messages.
@export var resource_name: String = "Resource"

## Item granted to the player's inventory when gathered.
@export var reward_item: ItemData

## Amount restored to the node when it respawns; also its starting amount.
@export var max_amount: int = 10

## Amount attempted per successful interaction. Actual amount gathered is
## capped by whatever remains on the node and by available inventory space.
@export var amount_per_gather: int = 2

## Seconds the node stays depleted before it respawns.
@export var respawn_time_seconds: float = 10.0

## Current remaining amount and depletion state. Changed only through
## gathering and respawning below.
var current_amount: int
var is_depleted: bool = false

@onready var _visual: Node2D = $Visual
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _respawn_timer: Timer = $RespawnTimer

func _ready() -> void:
	current_amount = max_amount
	prompt_text = "Gather %s" % resource_name
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	_update_visual_state()

func interact(player: Node) -> void:
	if is_depleted:
		return
	_gather(player)

func _gather(player: Node) -> void:
	if reward_item == null:
		return

	var inventory := player.get_node("Inventory") as Inventory
	if inventory == null:
		return

	var amount_to_attempt := mini(amount_per_gather, current_amount)
	var leftover := inventory.add_item(reward_item, amount_to_attempt)
	var amount_gathered := amount_to_attempt - leftover

	if amount_gathered <= 0:
		print("Inventory full: could not gather %s" % resource_name)
		return

	current_amount -= amount_gathered
	print("Gathered %d %s" % [amount_gathered, reward_item.display_name])

	if current_amount <= 0:
		_deplete()

func _deplete() -> void:
	current_amount = 0
	is_depleted = true
	_collision_shape.disabled = true
	_update_visual_state()
	_respawn_timer.start(respawn_time_seconds)

func _on_respawn_timer_timeout() -> void:
	current_amount = max_amount
	is_depleted = false
	_collision_shape.disabled = false
	_update_visual_state()

func _update_visual_state() -> void:
	_visual.visible = not is_depleted
