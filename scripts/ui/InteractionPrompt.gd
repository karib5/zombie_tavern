class_name InteractionPrompt
extends Control

@onready var _label: Label = $PromptLabel

func set_interactable(interactable: Interactable) -> void:
	if interactable:
		_label.text = "E  %s" % interactable.prompt_text
		_label.visible = true
	else:
		_label.visible = false
