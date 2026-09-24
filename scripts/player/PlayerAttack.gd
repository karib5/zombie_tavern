class_name PlayerAttack
extends Node

@export var attack_action: String = "attack"
@export var attack_range: float = 40.0
@export var cooldown_seconds: float = 0.5
@export var attack_active_seconds: float = 0.15

@onready var _hitbox: Hitbox = get_parent().get_node("AttackHitbox")
@onready var _hitbox_shape: CollisionShape2D = _hitbox.get_node("CollisionShape2D")
@onready var _hitbox_visual: CanvasItem = _hitbox.get_node("FlashVisual")
@onready var _cooldown_timer: Timer = $CooldownTimer
@onready var _active_timer: Timer = $ActiveTimer

var _can_attack: bool = true

func _ready() -> void:
	(_hitbox_shape.shape as CircleShape2D).radius = attack_range
	_hitbox_shape.disabled = true
	_hitbox_visual.visible = false
	_cooldown_timer.one_shot = true
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)
	_active_timer.one_shot = true
	_active_timer.timeout.connect(_end_attack)

func _process(_delta: float) -> void:
	if _can_attack and Input.is_action_just_pressed(attack_action):
		_start_attack()

func _start_attack() -> void:
	_can_attack = false
	_hitbox.reset_hit_targets()
	_hitbox_shape.disabled = false
	_hitbox_visual.visible = true
	_active_timer.start(attack_active_seconds)
	_cooldown_timer.start(cooldown_seconds)

func _end_attack() -> void:
	_hitbox_shape.disabled = true
	_hitbox_visual.visible = false

func _on_cooldown_timeout() -> void:
	_can_attack = true
