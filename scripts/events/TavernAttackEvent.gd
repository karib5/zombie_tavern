class_name TavernAttackEvent
extends Node

## Lightweight reusable attack-event state machine. Deliberately small -
## a single configurable wave, no progression/scaling system yet.
enum State { INACTIVE, WARNING, ACTIVE, COMPLETE }

## Emitted whenever `state` changes, so UI (or any future system) can react
## without polling every frame.
signal state_changed(new_state: State)

## Emitted whenever zombies_spawned/zombies_killed/zombies_breached change.
signal stats_changed

@export var zombie_count: int = 5
@export var warning_duration: float = 3.0
@export var complete_display_duration: float = 3.0

const ZOMBIE_SCENE: PackedScene = preload("res://scenes/zombies/Zombie.tscn")

## Attack spawn points are discovered through the existing WorldManager
## spawn-point registry, the same way Main.gd finds "PlayerSpawnPoint" - no
## separate wiring needed. WorldManager only registers Marker2D nodes whose
## name ends with the literal substring "SpawnPoint", so the index has to
## come before that suffix (e.g. "ZombieAttack1SpawnPoint"), not after.
const SPAWN_POINT_NAME_FORMAT: String = "ZombieAttack%dSpawnPoint"
const SPAWN_POINT_COUNT: int = 4

var state: State = State.INACTIVE
var zombies_spawned: int = 0
var zombies_killed: int = 0
var zombies_breached: int = 0

@onready var _warning_timer: Timer = $WarningTimer
@onready var _complete_timer: Timer = $CompleteTimer

var _defense_area: TavernDefenseArea = null

## This wave's own zombies, tracked separately from
## WorldManager.active_zombies (which also holds every other zombie on the
## map) so completion/breach tracking only concerns this attack.
var _wave_zombies: Array[ZombieAI] = []
var _breached_zombies: Array[ZombieAI] = []

func _ready() -> void:
	add_to_group("tavern_attack_events")

	var areas := get_tree().get_nodes_in_group("tavern_defense_areas")
	if areas.size() > 0:
		_defense_area = areas[0] as TavernDefenseArea
		_defense_area.zombie_entered.connect(_on_zombie_entered_defense_area)

	_warning_timer.one_shot = true
	_warning_timer.timeout.connect(_on_warning_timer_timeout)

	_complete_timer.one_shot = true
	_complete_timer.timeout.connect(_on_complete_timer_timeout)

## Starts a new attack. A no-op outside INACTIVE, so this can be called
## freely (e.g. from a debug trigger) without ever double-spawning a wave.
func start_attack() -> void:
	if state != State.INACTIVE:
		return

	zombies_spawned = 0
	zombies_killed = 0
	zombies_breached = 0
	_wave_zombies.clear()
	_breached_zombies.clear()

	state = State.WARNING
	state_changed.emit(state)
	EventBus.zombie_attack_started.emit()
	stats_changed.emit()

	_warning_timer.start(warning_duration)

func _on_warning_timer_timeout() -> void:
	state = State.ACTIVE
	state_changed.emit(state)
	_spawn_wave()

func _spawn_wave() -> void:
	for i in range(zombie_count):
		var spawn_point := WorldManager.get_spawn_point(SPAWN_POINT_NAME_FORMAT % ((i % SPAWN_POINT_COUNT) + 1))
		var spawn_position := spawn_point.global_position if spawn_point else Vector2.ZERO
		var zombie := WorldManager.spawn_entity(ZOMBIE_SCENE, spawn_position) as ZombieAI
		zombies_spawned += 1
		_wave_zombies.append(zombie)
		(zombie.get_node("Health") as Health).died.connect(_on_wave_zombie_died.bind(zombie))

	stats_changed.emit()
	_check_completion()  # covers the degenerate zombie_count == 0 case

func _on_wave_zombie_died(zombie: ZombieAI) -> void:
	zombies_killed += 1
	_wave_zombies.erase(zombie)
	stats_changed.emit()
	_check_completion()

func _on_zombie_entered_defense_area(body: Node2D) -> void:
	var zombie := body as ZombieAI
	if zombie == null or not _wave_zombies.has(zombie) or _breached_zombies.has(zombie):
		return
	_breached_zombies.append(zombie)
	zombies_breached += 1
	EventBus.zombie_breached_tavern.emit(zombie)
	stats_changed.emit()

func _check_completion() -> void:
	if state != State.ACTIVE:
		return
	if zombies_spawned > 0 and _wave_zombies.is_empty():
		state = State.COMPLETE
		state_changed.emit(state)
		EventBus.zombie_attack_completed.emit()
		stats_changed.emit()
		_complete_timer.start(complete_display_duration)

func _on_complete_timer_timeout() -> void:
	state = State.INACTIVE
	state_changed.emit(state)
	stats_changed.emit()
