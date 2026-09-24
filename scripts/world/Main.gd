extends Node

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")

@onready var world_root: Node2D = $WorldRoot

func _ready() -> void:
	WorldManager.register_current_map(world_root)
	_spawn_player()

func _spawn_player() -> void:
	var spawn_point := WorldManager.get_spawn_point("PlayerSpawnPoint")
	var spawn_position := spawn_point.global_position if spawn_point else Vector2.ZERO
	var player := WorldManager.spawn_entity(PLAYER_SCENE, spawn_position)
	GameManager.player = player
