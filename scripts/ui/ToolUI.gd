class_name ToolUI
extends Control

@onready var _label: Label = $Label

func set_tools(tools: PlayerTools) -> void:
	tools.equipped_tool_changed.connect(_on_equipped_tool_changed)
	_on_equipped_tool_changed(tools.equipped_tool)

func _on_equipped_tool_changed(tool: ToolData) -> void:
	_label.text = "Tool: %s" % tool.display_name if tool else "Tool: (none)"
