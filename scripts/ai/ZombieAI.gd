class_name ZombieAI
extends CharacterBody2D

enum State { IDLE, CHASE, ATTACK, DEAD }

@export var move_speed: float = 90.0
@export var detection_range: float = 220.0
@export var attack_range: float = 40.0
@export var attack_damage: float = 10.0
@export var attack_cooldown: float = 1.2

## How often (seconds) the AI re-evaluates state/target - not every frame.
## Movement itself still updates every physics frame while chasing; only
## the more expensive decision-making is throttled.
@export var ai_update_interval: float = 0.2

## Simple single-item loot config for this phase; LootPickup itself
## supports a full multi-entry table for future zombie types.
@export var loot_item: ItemData
@export var loot_quantity: int = 2

const LOOT_PICKUP_SCENE: PackedScene = preload("res://scenes/loot/LootPickup.tscn")

var state: State = State.IDLE

@onready var _health: Health = $Health
@onready var _visual: CanvasItem = $Visual
@onready var _collision_shape: CollisionShape2D = $CollisionShape2D
@onready var _hurtbox_shape: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var _decision_timer: Timer = $DecisionTimer
@onready var _attack_cooldown_timer: Timer = $AttackCooldownTimer

var _target: Node2D = null
var _can_attack: bool = true

func _ready() -> void:
	_health.died.connect(_on_died)

	_decision_timer.wait_time = ai_update_interval
	_decision_timer.timeout.connect(_update_state)
	_decision_timer.start()

	_attack_cooldown_timer.one_shot = true
	_attack_cooldown_timer.timeout.connect(_on_attack_cooldown_timeout)

	WorldManager.active_zombies.append(self)

func _physics_process(_delta: float) -> void:
	if state == State.CHASE and _target != null:
		velocity = global_position.direction_to(_target.global_position) * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func _update_state() -> void:
	if state == State.DEAD:
		return

	var player: Node2D = GameManager.player
	if player == null:
		state = State.IDLE
		_target = null
		return

	var distance := global_position.distance_to(player.global_position)

	if distance <= attack_range:
		state = State.ATTACK
		_target = player
		_try_attack(player)
	elif distance <= detection_range:
		state = State.CHASE
		_target = player
	else:
		state = State.IDLE
		_target = null

func _try_attack(player: Node2D) -> void:
	if not _can_attack:
		return
	var hurtbox := player.get_node_or_null("Hurtbox") as Hurtbox
	if hurtbox == null:
		return
	hurtbox.take_hit(attack_damage)
	_can_attack = false
	_attack_cooldown_timer.start(attack_cooldown)

func _on_attack_cooldown_timeout() -> void:
	_can_attack = true

func _on_died() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	_collision_shape.disabled = true
	_hurtbox_shape.disabled = true
	_decision_timer.stop()
	_visual.modulate = Color(0.25, 0.25, 0.25, 1.0)
	WorldManager.active_zombies.erase(self)
	_drop_loot()

func _drop_loot() -> void:
	if loot_item == null or loot_quantity <= 0:
		return
	var entry := LootEntry.new()
	entry.item = loot_item
	entry.quantity = loot_quantity
	var pickup := WorldManager.spawn_entity(LOOT_PICKUP_SCENE, global_position) as LootPickup
	pickup.loot_table = [entry]
