class_name Hurtbox
extends Area2D

## Emitted whenever this hurtbox actually takes a hit (for visual feedback).
signal damaged(amount: float)

@export var flash_color: Color = Color(1.0, 0.3, 0.3, 1.0)
@export var flash_duration: float = 0.15

## The owning entity's Health, resolved by convention (sibling node named
## "Health"), so any entity using Hurtbox just needs a Health child of the
## same name - no manual wiring required.
@onready var _health: Health = get_parent().get_node("Health")

func take_hit(amount: float) -> void:
	if _health == null or _health.is_dead:
		return
	_health.apply_damage(amount)
	damaged.emit(amount)
	_flash()

func _flash() -> void:
	var visual := get_parent().get_node_or_null("Visual") as CanvasItem
	if visual == null:
		return
	visual.modulate = flash_color
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, flash_duration)
