@tool
extends StateMachinePlayer


@onready var enabled_machine_player: StateMachinePlayer = $EnabledMachinePlayer


func _on_transited(from: Variant, to: Variant) -> void:
	print("Base: ", from, " --> ", to)
	match to:
		"Enabled":
			enabled_machine_player.active = true
		"Disabled":
			enabled_machine_player.active = false
		"Dead":
			enabled_machine_player.active = false
			


func _on_updated(state: Variant, _delta: Variant) -> void:
	print("Base current: ", state)
