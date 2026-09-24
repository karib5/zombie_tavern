class_name Hitbox
extends Area2D

## Damage applied to each Hurtbox this hitbox touches while active.
@export var damage: float = 20.0

## Tracks who's already been hit during the current activation window,
## so one swing can't hit the same target twice.
var _already_hit: Array[Hurtbox] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

## Call this when a new attack starts, before (re)enabling the hitbox.
func reset_hit_targets() -> void:
	_already_hit.clear()

func _on_area_entered(area: Area2D) -> void:
	var hurtbox := area as Hurtbox
	if hurtbox == null or hurtbox in _already_hit:
		return
	_already_hit.append(hurtbox)
	hurtbox.take_hit(damage)
