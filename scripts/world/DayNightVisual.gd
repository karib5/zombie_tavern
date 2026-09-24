class_name DayNightVisual
extends CanvasModulate

## Extremely lightweight day/night tint: a single color, updated once per
## in-game minute off TimeManager's signal (never per-frame), lerped
## between a day and night color with a short dawn/dusk blend. Being a
## CanvasModulate, this only affects the 2D world layer - the UI's
## separate CanvasLayer is untouched, so the HUD stays readable at night.
@export var day_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var night_color: Color = Color(0.25, 0.28, 0.45, 1.0)

func _ready() -> void:
	TimeManager.minute_changed.connect(_on_minute_changed)
	_on_minute_changed(TimeManager.day, TimeManager.hour, TimeManager.minute)

func _on_minute_changed(_day: int, hour: int, minute: int) -> void:
	var t := hour + minute / 60.0
	var night_amount := _night_amount(t)
	color = day_color.lerp(night_color, night_amount)

## Piecewise blend: full night before 5am/after 9pm, a 2-hour dawn/dusk
## transition on either side, full day the rest of the time.
func _night_amount(t: float) -> float:
	if t < 5.0 or t >= 21.0:
		return 1.0
	if t < 7.0:
		return 1.0 - (t - 5.0) / 2.0
	if t < 19.0:
		return 0.0
	return (t - 19.0) / 2.0
