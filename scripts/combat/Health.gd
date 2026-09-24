class_name Health
extends Node

## Emitted whenever current_health changes (damage or reset).
signal health_changed(current_health: float, max_health: float)

## Emitted once, the moment current_health first reaches zero.
signal died

@export var max_health: float = 100.0

var current_health: float
var is_dead: bool = false

func _ready() -> void:
	current_health = max_health

func apply_damage(amount: float) -> void:
	if is_dead or amount <= 0.0:
		return
	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(current_health, max_health)
	if current_health <= 0.0:
		is_dead = true
		died.emit()

## Fully restores health and clears death state (used for player respawn).
func reset() -> void:
	current_health = max_health
	is_dead = false
	health_changed.emit(current_health, max_health)

## Restores a specific saved health value without going through
## apply_damage()/reset() - used by SaveManager on load. Deliberately does
## not emit `died`, even if dead=true, so loading doesn't re-trigger a
## fresh death/respawn sequence; callers that need that (SurvivorAI) call
## their own death handling explicitly afterward.
func load_state(current: float, dead: bool) -> void:
	current_health = current
	is_dead = dead
	health_changed.emit(current_health, max_health)
