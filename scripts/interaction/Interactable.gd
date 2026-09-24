class_name Interactable
extends Area2D

## Text shown in the interaction prompt (e.g. "Interact", "Open", "Cook").
@export var prompt_text: String = "Interact"

## Whether this object can currently be interacted with. Override in
## subclasses that can become temporarily or permanently unusable (e.g.
## depleted, consumed, disabled) so InteractionController stops offering
## it the moment it stops being valid - even before the player physically
## leaves range or the object is fully removed from the scene.
func is_available() -> bool:
	return true

## Override in subclasses to define what happens when the player interacts.
func interact(_player: Node) -> void:
	pass
