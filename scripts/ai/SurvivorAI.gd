class_name SurvivorAI
extends CharacterBody2D

enum State { IDLE, WANDER, FLEE, DEAD }

## Identity/config data for this survivor. Fields are copied onto this
## instance in _ready() (health, speeds, wander/detection radii), the same
## way a planted CropData's fields are read by FarmPlot - the resource
## itself never changes at runtime.
@export var survivor_data: SurvivorData

## How often (seconds) the AI re-evaluates danger/state - not every frame.
## Movement itself still updates every physics frame; only the more
## expensive decision-making is throttled.
@export var ai_update_interval: float = 0.2

## How often (seconds) a new idle/wander leg is picked while undisturbed.
@export var behavior_retarget_interval: float = 3.0

var state: State = State.IDLE

@onready var _health: Health = $Health
@onready var _visual: CanvasItem = $Visual
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var _detection_area: Area2D = $DetectionArea
@onready var _decision_timer: Timer = $DecisionTimer
@onready var _behavior_timer: Timer = $BehaviorTimer

var _move_speed: float = 50.0
var _flee_speed: float = 130.0
var _wander_radius: float = 60.0

## Center point wandering is bounded around - the survivor's spawn point,
## not the whole map.
var wander_center: Vector2
var _wander_target: Vector2
var _flee_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	wander_center = global_position
	_wander_target = global_position

	if survivor_data != null:
		if survivor_data.max_health > 0.0:
			_health.max_health = survivor_data.max_health
		_move_speed = survivor_data.move_speed
		_flee_speed = survivor_data.flee_speed
		_wander_radius = survivor_data.wander_radius
		var detection_shape := (_detection_area.get_node("CollisionShape2D") as CollisionShape2D).shape as CircleShape2D
		if detection_shape != null:
			detection_shape.radius = survivor_data.detection_radius

	_health.died.connect(_on_died)

	_decision_timer.wait_time = ai_update_interval
	_decision_timer.timeout.connect(_update_state)
	_decision_timer.start()

	_behavior_timer.wait_time = behavior_retarget_interval
	_behavior_timer.timeout.connect(_pick_idle_or_wander)
	_behavior_timer.start()
	_pick_idle_or_wander()

	WorldManager.active_survivors.append(self)

func _physics_process(_delta: float) -> void:
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
		State.WANDER:
			if global_position.distance_to(_wander_target) > 4.0:
				velocity = global_position.direction_to(_wander_target) * _move_speed
				move_and_slide()
			else:
				velocity = Vector2.ZERO
		State.FLEE:
			velocity = _flee_direction * _flee_speed
			move_and_slide()
		State.DEAD:
			velocity = Vector2.ZERO

func _update_state() -> void:
	if state == State.DEAD:
		return

	var danger := _find_nearest_danger()

	if danger != null:
		state = State.FLEE
		_flee_direction = (global_position - danger.global_position).normalized()
	elif state == State.FLEE:
		# Danger has cleared - settle back into idle/wander rather than
		# freezing in place.
		_pick_idle_or_wander()

## Nearest living zombie currently inside DetectionArea, or null. Reuses
## the existing "enemies" collision layer (mask=4) rather than a new
## danger-tagging system.
func _find_nearest_danger() -> Node2D:
	var nearest: Node2D = null
	var nearest_distance := INF
	for body in _detection_area.get_overlapping_bodies():
		if not is_instance_valid(body):
			continue
		var zombie := body as ZombieAI
		if zombie == null or zombie.state == ZombieAI.State.DEAD:
			continue
		var distance := global_position.distance_to(zombie.global_position)
		if distance < nearest_distance:
			nearest = zombie
			nearest_distance = distance
	return nearest

func _pick_idle_or_wander() -> void:
	if state == State.DEAD or state == State.FLEE:
		return
	if randf() < 0.5:
		state = State.IDLE
	else:
		state = State.WANDER
		var offset := Vector2(randf_range(-_wander_radius, _wander_radius), randf_range(-_wander_radius, _wander_radius))
		_wander_target = wander_center + offset

func _on_died() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	# Death can be triggered synchronously from within a Hitbox's
	# area_entered (a physics query-flush context), so collision/area
	# state changes must be deferred rather than applied directly here.
	_collision_shape.set_deferred("disabled", true)
	_hurtbox_shape.set_deferred("disabled", true)
	_detection_area.set_deferred("monitoring", false)
	_decision_timer.stop()
	_behavior_timer.stop()
	set_physics_process(false)
	_visual.modulate = Color(0.4, 0.4, 0.4, 1.0)
	WorldManager.active_survivors.erase(self)
