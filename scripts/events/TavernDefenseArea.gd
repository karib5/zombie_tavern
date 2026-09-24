class_name TavernDefenseArea
extends Area2D

## Emitted whenever a zombie's body enters this area. Any system can
## listen (not just the attack event) - e.g. a future alarm or building-
## damage system - without this area needing to know who's listening.
signal zombie_entered(zombie: Node2D)

func _ready() -> void:
	add_to_group("tavern_defense_areas")
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is ZombieAI:
		zombie_entered.emit(body)
