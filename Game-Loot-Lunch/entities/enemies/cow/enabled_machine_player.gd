@tool
extends StateMachinePlayer


@onready var cow_monster : CowMonster = get_parent().get_parent()
@onready var idle_timer: Timer = $IdleTimer


func _on_transited(from: Variant, to: Variant) -> void:
	print("Enabled: ", from, " --> ", to)
	match to:
		"Idle":
			idle_timer.start(randf_range(1.0,3.0))


func _on_updated(_state: Variant, _delta: Variant) -> void:
	pass


func _on_idle_timer_timeout() -> void:
	set_trigger("idle_time_has_passed")
