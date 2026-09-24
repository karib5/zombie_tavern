class_name AttackEventTrigger
extends Interactable

## Debug/test trigger for Phase 12: reuses the existing Interactable +
## InteractionController pipeline (walk up, press E) instead of a new
## input action, so no project.godot changes are needed.
func _ready() -> void:
	prompt_text = "Trigger Zombie Attack"

func interact(_player: Node) -> void:
	var events := get_tree().get_nodes_in_group("tavern_attack_events")
	if events.size() > 0:
		(events[0] as TavernAttackEvent).start_attack()
