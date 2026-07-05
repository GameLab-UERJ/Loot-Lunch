@tool
extends StateMachinePlayer


@onready var cow_monster : CowMonster = get_parent().get_parent()
@onready var idle_timer: Timer = $IdleTimer
@onready var alerted_timer: Timer = $AlertedTimer
@onready var attack_timer: Timer = $AttackTimer


func attack() -> void:
	set_trigger("attack_player")


func finish_attack() -> void:
	set_trigger("attack_player_finished")


func _on_transited(from: Variant, to: Variant) -> void:
	print(from, " --> ", to)
	match from:
		"Alerted":
			alerted_timer.stop()
	
	match to:
		"Idle":
			idle_timer.start(randf_range(1.0,3.0))
		"Alerted":
			alerted_timer.start(3)
		"Attacking":
			attack_timer.start(1)


func _on_idle_timer_timeout() -> void:
	set_trigger("idle_time_has_passed")
