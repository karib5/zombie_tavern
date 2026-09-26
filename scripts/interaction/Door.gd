class_name Door
extends Interactable

## The interior scene this door leads into (e.g. Tavern.tscn). Pressing
## the interact key while in range hands off to BuildingManager instead
## of doing anything itself - Door only owns the visual open/close.
@export var interior_scene: PackedScene
@export var interior_spawn_point: String = "PlayerSpawnPoint"

## Local-space offset DoorSprite animates to while the player is in
## ProximityArea, e.g. Vector2(0, -18) to slide the door leaf up and
## out of the archway. Tune to taste once the real door texture is in.
@export var open_offset: Vector2 = Vector2(0, -18)
@export var open_speed: float = 8.0

@onready var _sprite: Sprite2D = $DoorSprite
@onready var _proximity: Area2D = $ProximityArea

var _closed_position: Vector2
var _target_position: Vector2

func _ready() -> void:
	prompt_text = "Enter"
	_closed_position = _sprite.position
	_target_position = _closed_position
	_proximity.body_entered.connect(_on_proximity_body_entered)
	_proximity.body_exited.connect(_on_proximity_body_exited)

func _process(delta: float) -> void:
	_sprite.position = _sprite.position.lerp(_target_position, min(open_speed * delta, 1.0))

func _on_proximity_body_entered(body: Node) -> void:
	if body == GameManager.player:
		_target_position = _closed_position + open_offset

func _on_proximity_body_exited(body: Node) -> void:
	if body == GameManager.player:
		_target_position = _closed_position

func interact(_player: Node) -> void:
	BuildingManager.enter_building(interior_scene, interior_spawn_point)
