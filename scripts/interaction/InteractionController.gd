class_name InteractionController
extends Area2D

## How far away (in pixels) the player can detect interactables.
@export var interaction_range: float = 48.0

## Emitted whenever the closest available interactable changes,
## including to/from null. The prompt UI listens for this.
signal interactable_changed(interactable: Interactable)

var _nearby_interactables: Array[Interactable] = []
var _current_interactable: Interactable = null

@onready var _collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	(_collision_shape.shape as CircleShape2D).radius = interaction_range
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(_delta: float) -> void:
	if _current_interactable and Input.is_action_just_pressed("interact"):
		_current_interactable.interact(get_parent())

func _on_area_entered(area: Area2D) -> void:
	var interactable := area as Interactable
	if interactable == null:
		return
	_nearby_interactables.append(interactable)
	_update_current_interactable()

func _on_area_exited(area: Area2D) -> void:
	var interactable := area as Interactable
	if interactable == null:
		return
	_nearby_interactables.erase(interactable)
	_update_current_interactable()

func _update_current_interactable() -> void:
	var closest: Interactable = null
	var closest_distance := INF
	for interactable in _nearby_interactables:
		var distance := global_position.distance_to(interactable.global_position)
		if distance < closest_distance:
			closest = interactable
			closest_distance = distance

	if closest != _current_interactable:
		_current_interactable = closest
		interactable_changed.emit(_current_interactable)
