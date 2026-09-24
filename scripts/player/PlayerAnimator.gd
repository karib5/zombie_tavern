class_name PlayerAnimator
extends AnimatedSprite2D

## Purely visual: watches the player's existing velocity and the existing
## Hurtbox/Health signals to pick which animation to show. Never reads or
## writes anything that affects movement, damage, or timing - Player.gd,
## PlayerAttack.gd and PlayerDeath.gd remain the authority on all of that.
## This node keeps the name "Visual" so the existing by-convention lookups
## in Hurtbox.gd (hit-flash) and PlayerDeath.gd (death dim) keep working
## unchanged.

enum Direction { DOWN, UP, LEFT, RIGHT }

const DIRECTION_NAMES := {
	Direction.DOWN: "down",
	Direction.UP: "up",
	Direction.LEFT: "left",
	Direction.RIGHT: "right",
}

@onready var _player: CharacterBody2D = get_parent()
@onready var _hurtbox: Hurtbox = _player.get_node("Hurtbox")

var _last_direction: Direction = Direction.DOWN
var _is_attacking: bool = false
var _is_hurt: bool = false
var _is_dead: bool = false

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	animation_finished.connect(_on_animation_finished)
	_hurtbox.damaged.connect(_on_damaged)
	play(_anim_name("idle"))

func _process(_delta: float) -> void:
	if _is_dead or _is_attacking or _is_hurt:
		return
	_update_movement_animation()

func _update_movement_animation() -> void:
	var move_velocity: Vector2 = _player.velocity
	if move_velocity.length() > 1.0:
		_last_direction = _direction_from_vector(move_velocity)
		_play_if_different(_anim_name("walk"))
	else:
		_play_if_different(_anim_name("idle"))

func _direction_from_vector(v: Vector2) -> Direction:
	if absf(v.x) > absf(v.y):
		return Direction.RIGHT if v.x > 0.0 else Direction.LEFT
	return Direction.DOWN if v.y > 0.0 else Direction.UP

func _anim_name(category: String) -> String:
	return "%s_%s" % [category, DIRECTION_NAMES[_last_direction]]

func _play_if_different(anim_name: String) -> void:
	if animation != anim_name:
		play(anim_name)

## Called by PlayerAttack.gd when a swing starts. Purely cosmetic - the
## hitbox/damage/cooldown timing in PlayerAttack.gd is unaffected.
func play_attack() -> void:
	if _is_dead:
		return
	_is_attacking = true
	play(_anim_name("attack"))

## Called by PlayerDeath.gd the moment death logic begins.
func play_death() -> void:
	_is_dead = true
	_is_attacking = false
	_is_hurt = false
	play(_anim_name("death"))

## Called by PlayerDeath.gd once respawn completes.
func play_idle() -> void:
	_is_dead = false
	_is_attacking = false
	_is_hurt = false
	play(_anim_name("idle"))

func _on_damaged(_amount: float) -> void:
	if _is_dead:
		return
	_is_hurt = true
	play(_anim_name("hurt"))

func _on_animation_finished() -> void:
	if animation.begins_with("attack_"):
		_is_attacking = false
	elif animation.begins_with("hurt_"):
		_is_hurt = false
	# death_* animations intentionally hold on their last frame until
	# play_idle() is called after respawn.
