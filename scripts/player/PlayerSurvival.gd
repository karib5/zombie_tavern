class_name PlayerSurvival
extends Node

## Hunger/thirst live here, separate from Health - Health remains the
## sole authority on damage/death (see Health.gd); this component only
## calls Health.apply_damage() for the very simple "starving/dehydrated"
## trickle, mirroring how PlayerAnimator listens to Health without
## controlling it.
signal hunger_changed(current: float, max: float)
signal thirst_changed(current: float, max: float)

@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0

## Gentle by design - a full day (24 real-time minutes at the default
## TimeManager rate) only costs a small fraction of either stat, so
## exploring never feels rushed.
@export var hunger_depletion_per_minute: float = 0.05
@export var thirst_depletion_per_minute: float = 0.08

## Very small, and only applied once both hit zero - the "simple final
## stage" the design calls for, not a punishing survival timer.
@export var starving_damage_per_minute: float = 1.0

var hunger: float
var thirst: float

@onready var _health: Health = get_parent().get_node("Health")

func _ready() -> void:
	hunger = max_hunger
	thirst = max_thirst
	TimeManager.minute_changed.connect(_on_minute_changed)

func _on_minute_changed(_day: int, _hour: int, _minute: int) -> void:
	hunger = maxf(hunger - hunger_depletion_per_minute, 0.0)
	thirst = maxf(thirst - thirst_depletion_per_minute, 0.0)
	hunger_changed.emit(hunger, max_hunger)
	thirst_changed.emit(thirst, max_thirst)

	if (hunger <= 0.0 or thirst <= 0.0) and not _health.is_dead:
		_health.apply_damage(starving_damage_per_minute)

## Restores a specific saved hunger/thirst pair - used by SaveManager on
## load, bypassing consume()'s is_consumable gate.
func load_state(p_hunger: float, p_thirst: float) -> void:
	hunger = clampf(p_hunger, 0.0, max_hunger)
	thirst = clampf(p_thirst, 0.0, max_thirst)
	hunger_changed.emit(hunger, max_hunger)
	thirst_changed.emit(thirst, max_thirst)

## Returns false (no-op) if the item can't actually be consumed.
func consume(item: ItemData) -> bool:
	if item == null or not item.is_consumable:
		return false
	hunger = clampf(hunger + item.hunger_restore, 0.0, max_hunger)
	thirst = clampf(thirst + item.thirst_restore, 0.0, max_thirst)
	hunger_changed.emit(hunger, max_hunger)
	thirst_changed.emit(thirst, max_thirst)
	return true
