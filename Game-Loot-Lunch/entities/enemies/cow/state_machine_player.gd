@tool
extends StateMachinePlayer


@onready var cow_monster : CowMonster = get_parent()
@onready var enabled_machine_player: StateMachinePlayer = $EnabledMachinePlayer


func _on_transited(_from: Variant, to: Variant) -> void:
	match to:
		"Enabled":
			enabled_machine_player.active = true
		"Disabled":
			enabled_machine_player.active = false
		"Dead":
			enabled_machine_player.active = false
			


func _on_updated(_state: Variant, _delta: Variant) -> void:
	pass
