extends Interactable

@export var default_color: Color = Color(0.8, 0.7, 0.2)
@export var activated_color: Color = Color(0.2, 0.8, 0.3)

@onready var _visual: Polygon2D = $Visual

var _activated: bool = false

func _ready() -> void:
	prompt_text = "Interact"
	_visual.color = default_color

func interact(_player: Node) -> void:
	_activated = not _activated
	_visual.color = activated_color if _activated else default_color
	print("Test interactable triggered. Activated: %s" % _activated)
