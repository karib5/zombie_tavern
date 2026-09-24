extends Node

@onready var world_root: Node2D = $WorldRoot

func _ready() -> void:
	WorldManager.register_current_map(world_root)
