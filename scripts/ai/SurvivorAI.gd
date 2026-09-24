class_name SurvivorAI
extends CharacterBody2D

enum State { IDLE, WANDER, FLEE, EAT, DEAD }

## Identity/config data for this survivor. Fields are copied onto this
## instance in _ready() (health, speeds, wander/detection radii, hunger),
## the same way a planted CropData's fields are read by FarmPlot - the
## resource itself never changes at runtime.
@export var survivor_data: SurvivorData

## How often (seconds) the AI re-evaluates danger/hunger/state - not every
## frame. Movement itself still updates every physics frame; only the more
## expensive decision-making (including any food search) is throttled.
@export var ai_update_interval: float = 0.2

## How often (seconds) a new idle/wander leg is picked while undisturbed.
@export var behavior_retarget_interval: float = 3.0

## How close (pixels) the survivor must be to a table before eating starts.
@export var eating_range: float = 30.0

var state: State = State.IDLE

## Current hunger, 0..max_hunger. Decays every physics frame (a plain
## float subtraction - cheap) and is restored on eating.
var hunger: float = 100.0

@onready var _health: Health = $Health
@onready var _visual: CanvasItem = $Visual
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var _detection_area: Area2D = $DetectionArea
@onready var _decision_timer: Timer = $DecisionTimer
@onready var _behavior_timer: Timer = $BehaviorTimer
@onready var _eat_timer: Timer = $EatTimer
@onready var _hunger_label: Label = get_node_or_null("HungerLabel")

var _move_speed: float = 50.0
var _flee_speed: float = 130.0
var _wander_radius: float = 60.0

var _max_hunger: float = 100.0
var _hunger_decay_per_second: float = 0.5
var _hungry_threshold: float = 40.0
var _critical_hunger_threshold: float = 15.0
var _eating_duration_seconds: float = 2.0

## Center point wandering is bounded around - the survivor's spawn point,
## not the whole map.
var wander_center: Vector2
var _wander_target: Vector2
var _flee_direction: Vector2 = Vector2.ZERO

## The table currently being approached/eaten from, or null when not
## seeking food. Non-null takes priority over the idle/wander cycle.
var _target_table: TavernTable = null
var _pending_hunger_restore: float = 0.0

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

		_max_hunger = survivor_data.max_hunger
		_hunger_decay_per_second = survivor_data.hunger_decay_per_second
		_hungry_threshold = survivor_data.hungry_threshold
		_critical_hunger_threshold = survivor_data.critical_hunger_threshold
		_eating_duration_seconds = survivor_data.eating_duration_seconds
		hunger = clampf(survivor_data.starting_hunger, 0.0, _max_hunger)
	else:
		hunger = _max_hunger

	_update_hunger_label()

	_health.died.connect(_on_died)

	_decision_timer.wait_time = ai_update_interval
	_decision_timer.timeout.connect(_update_state)
	_decision_timer.start()

	_behavior_timer.wait_time = behavior_retarget_interval
	_behavior_timer.timeout.connect(_pick_idle_or_wander)
	_behavior_timer.start()
	_pick_idle_or_wander()

	_eat_timer.one_shot = true
	_eat_timer.timeout.connect(_on_eat_timer_timeout)

	WorldManager.active_survivors.append(self)

func _physics_process(delta: float) -> void:
	if state != State.DEAD:
		hunger = maxf(hunger - _hunger_decay_per_second * delta, 0.0)

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
		State.EAT:
			velocity = Vector2.ZERO
		State.DEAD:
			velocity = Vector2.ZERO

func _update_state() -> void:
	if state == State.DEAD:
		return

	_update_hunger_label()

	var danger := _find_nearest_danger()
	if danger != null:
		if state == State.EAT:
			_stop_eating()
		state = State.FLEE
		_flee_direction = (global_position - danger.global_position).normalized()
		return

	if state == State.EAT:
		return  # the EatTimer drives the return to normal behavior

	# Danger has cleared - re-evaluate hunger/wander from a neutral state
	# instead of calling _pick_idle_or_wander() directly, which would no-op
	# (and leave state stuck at FLEE) while food-seeking is active.
	var was_fleeing := state == State.FLEE
	if was_fleeing:
		state = State.IDLE

	_update_hunger_behavior()

	if was_fleeing and _target_table == null:
		_pick_idle_or_wander()

## Below the hungry threshold, seeks out a TavernTable with available food
## instead of the normal idle/wander cycle. Reuses WANDER's move-toward-
## target movement rather than adding a separate "seeking" state.
func _update_hunger_behavior() -> void:
	if hunger > _hungry_threshold:
		_target_table = null
		return

	var target_is_stale := _target_table == null or not is_instance_valid(_target_table) \
		or not _target_table.has_available_food()

	# At critical hunger, re-check every decision tick (not just when the
	# current target goes stale) so the survivor prioritizes food more
	# strongly, e.g. switching to a closer table that just opened up.
	if target_is_stale or hunger <= _critical_hunger_threshold:
		_target_table = _find_table_with_food()

	if _target_table == null:
		return  # no food available anywhere right now - keep existing behavior

	state = State.WANDER
	_wander_target = _target_table.global_position

	if global_position.distance_to(_target_table.global_position) <= eating_range:
		_start_eating(_target_table)

## Nearest TavernTable (from the existing "tavern_tables" group) that
## currently has food available, or null. Only called from the throttled
## decision tick, never every frame.
func _find_table_with_food() -> TavernTable:
	var nearest: TavernTable = null
	var nearest_distance := INF
	for node in get_tree().get_nodes_in_group("tavern_tables"):
		var table := node as TavernTable
		if table == null or not table.has_available_food():
			continue
		var distance := global_position.distance_to(table.global_position)
		if distance < nearest_distance:
			nearest = table
			nearest_distance = distance
	return nearest

func _start_eating(table: TavernTable) -> void:
	var food := table.consume_food()
	if food == null:
		# Someone else took the last serving first - fall back to normal
		# behavior and try again on a later tick.
		_target_table = null
		_pick_idle_or_wander()
		return

	_pending_hunger_restore = food.hunger_restore
	state = State.EAT
	velocity = Vector2.ZERO
	_visual.modulate = Color(1.0, 0.9, 0.4, 1.0)
	_eat_timer.start(_eating_duration_seconds)

func _on_eat_timer_timeout() -> void:
	_apply_pending_hunger_restore()
	_visual.modulate = Color.WHITE
	_target_table = null
	# _pick_idle_or_wander() no-ops while state == EAT, so leave EAT first -
	# otherwise the survivor would stay frozen here after every meal.
	state = State.IDLE
	_pick_idle_or_wander()

func _stop_eating() -> void:
	_eat_timer.stop()
	_apply_pending_hunger_restore()
	_visual.modulate = Color.WHITE
	_target_table = null

func _apply_pending_hunger_restore() -> void:
	hunger = minf(hunger + _pending_hunger_restore, _max_hunger)
	_pending_hunger_restore = 0.0
	_update_hunger_label()

func _update_hunger_label() -> void:
	if _hunger_label != null:
		_hunger_label.text = "Hunger: %d" % int(hunger)

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
	if state == State.DEAD or state == State.FLEE or state == State.EAT or _target_table != null:
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
	_eat_timer.stop()
	_target_table = null
	set_physics_process(false)
	_visual.modulate = Color(0.4, 0.4, 0.4, 1.0)
	WorldManager.active_survivors.erase(self)
