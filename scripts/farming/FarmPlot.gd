class_name FarmPlot
extends Interactable

enum State { UNTILLED, EMPTY, GROWING, MATURE }

## Crop types this plot accepts a seed for. A future plot (or a future
## crop type) just needs a new CropData .tres added here - no script
## changes required.
@export var available_crops: Array[CropData] = []

## When true, the plot starts as untilled ground and needs a Hoe
## interaction before it can be planted. Defaults to false so existing
## ready-to-plant plots are unaffected.
@export var requires_hoe_to_prepare: bool = false

const LOOT_PICKUP_SCENE: PackedScene = preload("res://scenes/loot/LootPickup.tscn")

var state: State = State.EMPTY
var planted_crop: CropData = null

@onready var _crop_visual: Polygon2D = $CropVisual
@onready var _stage1_timer: Timer = $Stage1Timer
@onready var _stage2_timer: Timer = $Stage2Timer
@onready var _mature_timer: Timer = $MatureTimer

func _ready() -> void:
	_stage1_timer.one_shot = true
	_stage2_timer.one_shot = true
	_mature_timer.one_shot = true
	_stage1_timer.timeout.connect(_on_stage1_timeout)
	_stage2_timer.timeout.connect(_on_stage2_timeout)
	_mature_timer.timeout.connect(_on_mature_timeout)
	state = State.UNTILLED if requires_hoe_to_prepare else State.EMPTY
	_update_state_visuals()

func interact(player: Node) -> void:
	match state:
		State.UNTILLED:
			_try_till(player)
		State.EMPTY:
			_try_plant(player)
		State.MATURE:
			_try_harvest(player)
		State.GROWING:
			pass  # nothing to do yet; the prompt just says "Growing..."

## Reuses the same PlayerTools/ToolData check ResourceNode uses, rather
## than a bespoke "has hoe" lookup local to farming.
func _try_till(player: Node) -> void:
	var tools := player.get_node_or_null("PlayerTools") as PlayerTools
	if tools == null or not tools.has_tool(ToolData.ToolType.HOE):
		return
	state = State.EMPTY
	_update_state_visuals()

func _try_plant(player: Node) -> void:
	var inventory := player.get_node("Inventory") as Inventory
	if inventory == null:
		return

	var crop := _find_plantable_crop(inventory)
	if crop == null:
		return  # no compatible seed on hand - silently do nothing, like a
				 # resource node that can't currently be gathered from
	if not inventory.remove_item(crop.seed_item, 1):
		return

	planted_crop = crop
	state = State.GROWING

	# Three fixed timers (1/3, 2/3, full duration) rather than per-frame
	# polling - each fires once, so an idle/growing plot costs nothing
	# beyond three dormant Timer nodes. A future watering mechanic could
	# hook in here by adjusting these wait_times (e.g. shortening them)
	# without changing the state machine itself.
	_stage1_timer.start(maxf(crop.growth_duration_seconds / 3.0, 0.01))
	_stage2_timer.start(maxf(crop.growth_duration_seconds * 2.0 / 3.0, 0.02))
	_mature_timer.start(maxf(crop.growth_duration_seconds, 0.03))

	_update_state_visuals()

func _find_plantable_crop(inventory: Inventory) -> CropData:
	for crop in available_crops:
		if crop != null and crop.seed_item != null and inventory.get_item_count(crop.seed_item) > 0:
			return crop
	return null

func _try_harvest(player: Node) -> void:
	var inventory := player.get_node("Inventory") as Inventory
	var crop := planted_crop

	if crop != null and crop.harvest_item != null and inventory != null:
		var leftover := inventory.add_item(crop.harvest_item, crop.harvest_quantity)
		if leftover > 0:
			_spawn_leftover_pickup(crop.harvest_item, leftover)
		print("Harvested %d %s" % [crop.harvest_quantity - leftover, crop.harvest_item.display_name])

	_reset_to_empty()

## Tilled soil stays tilled after a harvest - only the very first planting
## needs the Hoe.
func _reset_to_empty() -> void:
	state = State.EMPTY
	planted_crop = null
	_stage1_timer.stop()
	_stage2_timer.stop()
	_mature_timer.stop()
	_update_state_visuals()

func _on_stage1_timeout() -> void:
	if state == State.GROWING:
		_crop_visual.scale = Vector2(0.6, 0.6)

func _on_stage2_timeout() -> void:
	if state == State.GROWING:
		_crop_visual.scale = Vector2(0.85, 0.85)

func _on_mature_timeout() -> void:
	if state != State.GROWING:
		return
	state = State.MATURE
	_update_state_visuals()

func _update_state_visuals() -> void:
	match state:
		State.UNTILLED:
			_crop_visual.visible = false
			prompt_text = "Till Soil (Hoe)"
		State.EMPTY:
			_crop_visual.visible = false
			prompt_text = _empty_prompt_text()
		State.GROWING:
			_crop_visual.visible = true
			_crop_visual.scale = Vector2(0.3, 0.3)
			_crop_visual.color = Color(0.35, 0.55, 0.25, 1)
			prompt_text = "Growing..."
		State.MATURE:
			_crop_visual.visible = true
			_crop_visual.scale = Vector2(1.0, 1.0)
			_crop_visual.color = Color(0.45, 0.8, 0.2, 1)
			prompt_text = "Harvest"

func _empty_prompt_text() -> String:
	if available_crops.size() > 0 and available_crops[0] != null and available_crops[0].seed_item != null:
		return "Plant %s" % available_crops[0].seed_item.display_name
	return "Plant Seed"

## Same pattern as ResourceNode/CookingStation: if the inventory can't
## hold the full harvest, the remainder is preserved as a LootPickup
## rather than deleted.
func _spawn_leftover_pickup(item: ItemData, quantity: int) -> void:
	var entry := LootEntry.new()
	entry.item = item
	entry.quantity = quantity
	var pickup := WorldManager.spawn_entity(LOOT_PICKUP_SCENE, global_position) as LootPickup
	pickup.loot_table = [entry]
