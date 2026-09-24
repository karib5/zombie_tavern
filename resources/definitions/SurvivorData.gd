class_name SurvivorData
extends Resource

## Kept intentionally minimal for Phase 11C - only what guarding needs.
## New roles (farmer, cook, hunter, ...) can be appended later without
## touching existing values, since Godot enums are ordinal.
enum Role { NONE, GUARD }

@export var survivor_name: String = "Survivor"
@export var role: Role = Role.NONE
@export var max_health: float = 60.0
@export var move_speed: float = 50.0
@export var flee_speed: float = 130.0
@export var detection_radius: float = 150.0
@export var wander_radius: float = 60.0

@export var max_hunger: float = 100.0
@export var starting_hunger: float = 100.0
@export var hunger_decay_per_second: float = 0.5
@export var hungry_threshold: float = 40.0
@export var critical_hunger_threshold: float = 15.0
@export var eating_duration_seconds: float = 2.0

## Only meaningful for role == GUARD.
@export var attack_damage: float = 15.0
@export var attack_range: float = 32.0
@export var attack_cooldown: float = 1.0
