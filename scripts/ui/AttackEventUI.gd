class_name AttackEventUI
extends Control

@onready var _label: Label = $Label

var _attack_event: TavernAttackEvent = null

func set_attack_event(attack_event: TavernAttackEvent) -> void:
	_attack_event = attack_event
	_attack_event.state_changed.connect(_refresh)
	_attack_event.stats_changed.connect(_refresh)
	_refresh()

func _refresh(_arg = null) -> void:
	if _attack_event == null:
		_label.text = ""
		return

	match _attack_event.state:
		TavernAttackEvent.State.INACTIVE:
			_label.text = ""
		TavernAttackEvent.State.WARNING:
			_label.text = "Zombie attack incoming!"
		TavernAttackEvent.State.ACTIVE:
			_label.text = "Attack: ACTIVE\nSpawned: %d\nKilled: %d\nBreached: %d" % [
				_attack_event.zombies_spawned,
				_attack_event.zombies_killed,
				_attack_event.zombies_breached,
			]
		TavernAttackEvent.State.COMPLETE:
			_label.text = "Attack cleared!"
