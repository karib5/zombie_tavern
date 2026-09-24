extends Node

## Lightweight day/hour/minute clock. elapsed_seconds/is_night are kept
## for existing callers; is_night is now derived from hour instead of
## being a standalone flag.
var elapsed_seconds: float = 0.0
var is_night: bool = false

## How many real seconds make up one in-game minute. At the default,
## a full 24h day takes 24 real minutes - slow enough that hunger/thirst/
## spoilage never feel rushed.
@export var seconds_per_game_minute: float = 1.0

var day: int = 1
var hour: int = 8
var minute: int = 0

## Emitted once per in-game minute that passes - the single event other
## systems (PlayerSurvival, day/night visuals) hook into instead of each
## running their own per-frame polling.
signal minute_changed(day: int, hour: int, minute: int)

var _minute_accumulator: float = 0.0

func _process(delta: float) -> void:
	elapsed_seconds += delta
	_minute_accumulator += delta
	while _minute_accumulator >= seconds_per_game_minute:
		_minute_accumulator -= seconds_per_game_minute
		_advance_minute()

func _advance_minute() -> void:
	minute += 1
	if minute >= 60:
		minute = 0
		hour += 1
		if hour >= 24:
			hour = 0
			day += 1
	is_night = hour < 6 or hour >= 20
	minute_changed.emit(day, hour, minute)

## A single monotonically increasing counter, handy for age/freshness
## comparisons (ItemData.get_freshness, InventorySlot.acquired_at_minutes)
## without callers needing to reason about day/hour/minute rollover.
func get_total_minutes() -> int:
	return day * 24 * 60 + hour * 60 + minute

func get_time_string() -> String:
	return "Day %d  %02d:%02d" % [day, hour, minute]
