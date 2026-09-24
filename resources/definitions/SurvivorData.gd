class_name SurvivorData
extends Resource

@export var survivor_name: String = "Survivor"
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
