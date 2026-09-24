class_name SurvivalHUD
extends Control

## Small always-on panel for the info HealthUI/ToolUI don't already show:
## hunger, thirst, and the current in-game time. Deliberately minimal -
## no bars/icons yet, just numbers, per "keep it functional and minimal".
@onready var _hunger_label: Label = $Panel/HungerLabel
@onready var _thirst_label: Label = $Panel/ThirstLabel
@onready var _time_label: Label = $Panel/TimeLabel

func set_survival(survival: PlayerSurvival) -> void:
	survival.hunger_changed.connect(_on_hunger_changed)
	survival.thirst_changed.connect(_on_thirst_changed)
	_on_hunger_changed(survival.hunger, survival.max_hunger)
	_on_thirst_changed(survival.thirst, survival.max_thirst)

func _ready() -> void:
	TimeManager.minute_changed.connect(_on_minute_changed)
	_on_minute_changed(TimeManager.day, TimeManager.hour, TimeManager.minute)

func _on_hunger_changed(current: float, max_value: float) -> void:
	_hunger_label.text = "Hunger: %d / %d" % [roundi(current), roundi(max_value)]

func _on_thirst_changed(current: float, max_value: float) -> void:
	_thirst_label.text = "Thirst: %d / %d" % [roundi(current), roundi(max_value)]

func _on_minute_changed(day: int, hour: int, minute: int) -> void:
	_time_label.text = "Day %d  %02d:%02d" % [day, hour, minute]
