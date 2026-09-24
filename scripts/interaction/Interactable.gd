class_name Interactable
extends Area2D

## Text shown in the interaction prompt (e.g. "Interact", "Open", "Cook").
@export var prompt_text: String = "Interact"

## Override in subclasses to define what happens when the player interacts.
func interact(_player: Node) -> void:
	pass
