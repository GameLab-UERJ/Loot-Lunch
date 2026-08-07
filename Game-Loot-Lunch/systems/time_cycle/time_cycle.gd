extends Node


signal day_started
signal night_started


enum TimeState {
	DAY,
	NIGHT,
}


@export var cycle_duration: float = 10.0


var current_state: TimeState = TimeState.DAY

var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()

	_timer.wait_time = cycle_duration
	_timer.one_shot = false
	_timer.autostart = false

	_timer.timeout.connect(_on_timeout)

	add_child(_timer)

	_timer.start()


func change_state(new_state: TimeState) -> void:
	if current_state == new_state:
		return

	current_state = new_state

	match current_state:
		TimeState.DAY:
			day_started.emit()

		TimeState.NIGHT:
			night_started.emit()


func is_day() -> bool:
	return current_state == TimeState.DAY


func is_night() -> bool:
	return current_state == TimeState.NIGHT


func get_time_remaining() -> float:
	if _timer:
		return _timer.time_left
	return 0.0


func set_time_remaining(time: float) -> void:
	if _timer:
		_timer.stop()
		_timer.start(time)


func _on_timeout() -> void:
	match current_state:
		TimeState.DAY:
			change_state(TimeState.NIGHT)

		TimeState.NIGHT:
			change_state(TimeState.DAY)
