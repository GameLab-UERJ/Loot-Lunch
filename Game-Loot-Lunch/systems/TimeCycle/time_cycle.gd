extends Node


signal day_started
signal night_started


enum TimeState {
	DAY,
	NIGHT,
}


@export var cycle_duration: float = 10.0


var current_state: TimeState = TimeState.DAY

var _timer: float = 0.0


func _process(delta: float) -> void:
	_timer += delta

	if _timer < cycle_duration:
		return

	_timer = 0.0

	match current_state:
		TimeState.DAY:
			change_state(TimeState.NIGHT)

		TimeState.NIGHT:
			change_state(TimeState.DAY)


func change_state(new_state: TimeState) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	match current_state:
		TimeState.DAY:
			day_started.emit()

		TimeState.NIGHT:
			night_started.emit()
