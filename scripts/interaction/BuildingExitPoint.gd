class_name BuildingExitPoint
extends Interactable

func _ready() -> void:
	prompt_text = "Exit"

func interact(_player: Node) -> void:
	BuildingManager.exit_building()
