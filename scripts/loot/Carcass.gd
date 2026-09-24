class_name Carcass
extends LootPickup

## Used to build the interaction prompt, e.g. "Butcher Rabbit". Set this
## directly (editor placement) or via setup() (dynamic spawning) - either
## way _rebuild_prompt() keeps prompt_text in sync with it.
@export var animal_name: String = "Animal"

func _ready() -> void:
	_rebuild_prompt()

## The intended way to configure a freshly spawned carcass: sets the
## animal name and its loot table together so the prompt is always built
## from the final values, regardless of spawn/configuration ordering.
func setup(p_animal_name: String, entries: Array[LootEntry]) -> void:
	animal_name = p_animal_name
	loot_table = entries
	_rebuild_prompt()

func _rebuild_prompt() -> void:
	prompt_text = "Butcher %s" % animal_name
