class_name HealthUI
extends Control

@onready var _label: Label = $Label

func set_health(health: Health) -> void:
	health.health_changed.connect(_on_health_changed)
	_on_health_changed(health.current_health, health.max_health)

func _on_health_changed(current_health: float, max_health: float) -> void:
	_label.text = "HP: %d / %d" % [current_health, max_health]
