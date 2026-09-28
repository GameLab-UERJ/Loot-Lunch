extends Node2D
class_name RandomEvent


@export var event_interval: float = 8.0
@export var first_event_delay: float = 3.0
@export var automatic_events: bool = true

var _event_timer: Timer


func _ready() -> void:
	_event_timer = Timer.new()
	_event_timer.wait_time = first_event_delay
	_event_timer.one_shot = true
	_event_timer.timeout.connect(_on_first_event_timeout)
	add_child(_event_timer)
	if automatic_events:
		_event_timer.start()


func trigger_random_event() -> void:
	if _can_trigger_event():
		_activate_event()


func _can_trigger_event() -> bool:
	return true


func _activate_event() -> void:
	push_warning("RandomEvent '%s' não implementa _activate_event()." % name)


func _on_first_event_timeout() -> void:
	trigger_random_event()
	_event_timer.wait_time = event_interval
	_event_timer.one_shot = false
	_event_timer.start()
