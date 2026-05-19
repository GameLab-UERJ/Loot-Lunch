extends Node


enum TimeState {
	DAY,
	NIGHT,
}


var current_state: TimeState = TimeState.DAY


func change_state(new_state: TimeState) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	print("Time state changed to: %s" % TimeState.keys()[current_state])
