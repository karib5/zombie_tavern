extends Node

## Minimal placeholder: elapsed play time and a coarse night flag,
## just enough for later systems (e.g. the horde trigger in Phase 13)
## to query. No calendar/day-night cycle logic yet.
var elapsed_seconds: float = 0.0
var is_night: bool = false

func _process(delta: float) -> void:
	elapsed_seconds += delta
