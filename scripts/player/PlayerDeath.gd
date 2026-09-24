class_name PlayerDeath
extends Node

@export var respawn_delay_seconds: float = 2.0

@onready var _player: Node2D = get_parent()
@onready var _health: Health = _player.get_node("Health")
@onready var _visual: CanvasItem = _player.get_node("Visual")
@onready var _animator: PlayerAnimator = _player.get_node_or_null("Visual")
@onready var _player_attack: Node = _player.get_node("PlayerAttack")
@onready var _interaction_area: Node = _player.get_node("InteractionArea")

func _ready() -> void:
	_health.died.connect(_on_died)

func _on_died() -> void:
	print("Player died. Respawning in %.1f seconds..." % respawn_delay_seconds)

	# Stop movement, attacking, and interacting without touching those
	# systems' own scripts - just pause their processing while dead.
	_player.set_physics_process(false)
	_player_attack.set_process(false)
	_interaction_area.set_process(false)
	_visual.modulate = Color(0.3, 0.3, 0.3, 0.6)
	if _animator:
		_animator.play_death()

	await get_tree().create_timer(respawn_delay_seconds).timeout

	var spawn_point := WorldManager.get_spawn_point("PlayerSpawnPoint")
	if spawn_point:
		_player.global_position = spawn_point.global_position

	_health.reset()
	_visual.modulate = Color.WHITE
	_player.set_physics_process(true)
	_player_attack.set_process(true)
	_interaction_area.set_process(true)
	if _animator:
		_animator.play_idle()
