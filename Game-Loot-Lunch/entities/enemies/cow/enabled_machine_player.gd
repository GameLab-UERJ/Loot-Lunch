@tool
extends StateMachinePlayer


func _on_transited(from: Variant, to: Variant) -> void:
	print("Enabled: ", from, " --> ", to)


func _on_updated(state: Variant, _delta: Variant) -> void:
	print("enabled current: ", state)
