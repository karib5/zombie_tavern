class_name AnimalAI
extends CharacterBody2D

enum State { WANDER, FLEE, DEAD }

## Used to build the carcass's interaction prompt, e.g. "Butcher Rabbit".
@export var animal_name: String = "Animal"

@export var move_speed: float = 40.0
@export var flee_speed: float = 140.0
@export var detection_range: float = 150.0

## How far away the player must be before the animal stops fleeing and
## returns to wandering. Kept larger than detection_range so the animal
## doesn't flicker back and forth right at the detection boundary.
@export var flee_distance: float = 260.0

## How far from its spawn point the animal wanders.
@export var wander_radius: float = 100.0

## How often (seconds) the AI re-evaluates danger/state - not every frame.
## Movement itself still updates every physics frame; only the more
## expensive decision-making is throttled.
@export var ai_update_interval: float = 0.2

## How often (seconds) a new wander destination is picked while undisturbed.
@export var wander_retarget_interval: float = 3.0

@export var meat_item: ItemData
@export var meat_quantity: int = 2

const CARCASS_SCENE: PackedScene = preload("res://scenes/loot/Carcass.tscn")

var state: State = State.WANDER

@onready var _health: Health = $Health
@onready var _visual: CanvasItem = $Visual
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var _decision_timer: Timer = $DecisionTimer
@onready var _wander_timer: Timer = $WanderTimer

var _anchor_position: Vector2
var _wander_target: Vector2
var _flee_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	_anchor_position = global_position
	_wander_target = global_position

	_health.died.connect(_on_died)

	_decision_timer.wait_time = ai_update_interval
	_decision_timer.timeout.connect(_update_state)
	_decision_timer.start()

	_wander_timer.wait_time = wander_retarget_interval
	_wander_timer.timeout.connect(_pick_wander_target)
	_wander_timer.start()
	_pick_wander_target()

	WorldManager.active_animals.append(self)

func _physics_process(_delta: float) -> void:
	match state:
		State.WANDER:
			if global_position.distance_to(_wander_target) > 4.0:
				velocity = global_position.direction_to(_wander_target) * move_speed
				move_and_slide()
			else:
				velocity = Vector2.ZERO
		State.FLEE:
			velocity = _flee_direction * flee_speed
			move_and_slide()
		State.DEAD:
			velocity = Vector2.ZERO

func _update_state() -> void:
	if state == State.DEAD:
		return

	var player: Node2D = GameManager.player
	if player == null:
		return

	var distance := global_position.distance_to(player.global_position)

	if state == State.FLEE:
		if distance >= flee_distance:
			state = State.WANDER
			_pick_wander_target()
		else:
			_flee_direction = (global_position - player.global_position).normalized()
	elif distance <= detection_range:
		state = State.FLEE
		_flee_direction = (global_position - player.global_position).normalized()

func _pick_wander_target() -> void:
	if state != State.WANDER:
		return
	var offset := Vector2(randf_range(-wander_radius, wander_radius), randf_range(-wander_radius, wander_radius))
	_wander_target = _anchor_position + offset

func _on_died() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	# Death can be triggered synchronously from within a Hitbox's
	# area_entered (a physics query-flush context), so collision shape
	# changes must be deferred rather than applied directly here.
	_collision_shape.set_deferred("disabled", true)
	_hurtbox_shape.set_deferred("disabled", true)
	_decision_timer.stop()
	_wander_timer.stop()
	set_physics_process(false)
	_visual.modulate = Color(0.5, 0.5, 0.5, 1.0)
	WorldManager.active_animals.erase(self)
	_spawn_carcass()

func _spawn_carcass() -> void:
	if meat_item == null or meat_quantity <= 0:
		return
	var entry := LootEntry.new()
	entry.item = meat_item
	entry.quantity = meat_quantity
	# Deferred: adding a new physics-enabled node to the tree while still
	# inside a physics query-flush (the same context _on_died() can be
	# called from) is rejected by the physics server, same as the
	# collision shape changes above.
	call_deferred("_do_spawn_carcass", entry)

func _do_spawn_carcass(entry: LootEntry) -> void:
	var carcass := WorldManager.spawn_entity(CARCASS_SCENE, global_position) as Carcass
	carcass.setup(animal_name, [entry])
