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

## NONE means gatherable by hand. Anything else requires the player to
## have that tool type equipped (see PlayerTools) - the same check runs
## for every resource node, so no per-scene tool logic is needed.
@export var required_tool_type: ToolData.ToolType = ToolData.ToolType.NONE

## True (the default) for natural resources - trees, bushes, wild plants -
## that regrow after respawn_time_seconds, matching every existing node's
## current behavior. Set false for finite resources (ore/clay deposits)
## that should stay depleted once exhausted, same spirit as a
## SearchableContainer staying empty once looted.
@export var respawns: bool = true

## Stable save identity: world_region + (save_id or node name). The node
## name is used as the fallback ID precisely because it's already unique
## per-parent and author-assigned (e.g. "Tree1", "OreRock2") - not a
## memory address, not scene-tree position.
@export var save_id: String = ""
@export var world_region: String = "prototype"

## Current remaining amount and depletion state. Changed only through
## gathering and respawning below.
var current_amount: int
var is_depleted: bool = false

## Real-world timestamp (Time.get_unix_time_from_system()) recorded when
## this node depleted - used only to resume the respawn countdown
## correctly across a save/load that spans the game being fully closed,
## when a Timer's own in-memory time_left can't survive. The live,
## running-game respawn behavior (the Timer itself) is unchanged.
var _depleted_at_unix: float = 0.0

@onready var _visual: Node2D = $Visual
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _respawn_timer: Timer = $RespawnTimer

func _ready() -> void:
	add_to_group("saveable")
	current_amount = max_amount
	prompt_text = "Gather %s" % resource_name
	_respawn_timer.one_shot = true
	_respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	_update_visual_state()

func get_save_key() -> String:
	return "%s/%s" % [world_region, save_id if save_id != "" else name]

func get_save_data() -> Dictionary:
	return {
		"current_amount": current_amount,
		"is_depleted": is_depleted,
		"depleted_at_unix": _depleted_at_unix,
	}

func apply_save_data(data: Dictionary) -> void:
	current_amount = data.get("current_amount", max_amount)
	is_depleted = data.get("is_depleted", false)
	_collision_shape.disabled = is_depleted
	_update_visual_state()
	_respawn_timer.stop()

	if not is_depleted or not respawns:
		return

	_depleted_at_unix = data.get("depleted_at_unix", Time.get_unix_time_from_system())
	var elapsed := Time.get_unix_time_from_system() - _depleted_at_unix
	if elapsed >= respawn_time_seconds:
		_on_respawn_timer_timeout()
	else:
		_respawn_timer.start(respawn_time_seconds - elapsed)

func is_available() -> bool:
	return not is_depleted

func interact(player: Node) -> void:
	if is_depleted:
		return
	if required_tool_type != ToolData.ToolType.NONE and not _has_usable_required_tool(player):
		print("Need a working %s to gather %s" % [ToolData.ToolType.keys()[required_tool_type], resource_name])
		return
	_gather(player)

func _has_usable_required_tool(player: Node) -> bool:
	var tools := player.get_node_or_null("PlayerTools") as PlayerTools
	return tools != null and tools.has_tool(required_tool_type) and not tools.is_equipped_tool_broken()

func _gather(player: Node) -> void:
	if reward_item == null:
		return

	var inventory := player.get_node("Inventory") as Inventory
	if inventory == null:
		return

	var amount_to_attempt := mini(_effective_amount_per_gather(player), current_amount)
	var leftover := inventory.add_item(reward_item, amount_to_attempt)
	var amount_gathered := amount_to_attempt - leftover

	if amount_gathered <= 0:
		print("Inventory full: could not gather %s" % resource_name)
		return

	current_amount -= amount_gathered
	print("Gathered %d %s" % [amount_gathered, reward_item.display_name])

	if required_tool_type != ToolData.ToolType.NONE:
		var tools := player.get_node_or_null("PlayerTools") as PlayerTools
		if tools != null:
			tools.use_equipped_tool()

	if current_amount <= 0:
		_deplete()

## Bare-hand nodes always yield the base amount; a matching tool scales it
## by that tool's effectiveness (a blunter tool is still usable, just
## slower to yield).
func _effective_amount_per_gather(player: Node) -> int:
	if required_tool_type == ToolData.ToolType.NONE:
		return amount_per_gather
	var tools := player.get_node_or_null("PlayerTools") as PlayerTools
	if tools == null or tools.equipped_tool == null:
		return amount_per_gather
	return maxi(1, roundi(amount_per_gather * tools.equipped_tool.effectiveness))

func _deplete() -> void:
	current_amount = 0
	is_depleted = true
	_depleted_at_unix = Time.get_unix_time_from_system()
	_collision_shape.disabled = true
	_update_visual_state()
	if respawns:
		_respawn_timer.start(respawn_time_seconds)

func _on_respawn_timer_timeout() -> void:
	current_amount = max_amount
	is_depleted = false
	_collision_shape.disabled = false
	_update_visual_state()

func _update_visual_state() -> void:
	_visual.visible = not is_depleted
