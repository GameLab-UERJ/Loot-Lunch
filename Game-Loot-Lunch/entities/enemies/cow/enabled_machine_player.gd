@tool
extends StateMachinePlayer


@onready var cow_monster : CowMonster = get_parent().get_parent()
@onready var idle_timer: Timer = $IdleTimer
@onready var alerted_timer: Timer = $AlertedTimer
@onready var attack_timer: Timer = $AttackTimer


func attack() -> void:
	await get_tree().create_timer(0.5).timeout
	set_trigger("attack_player")


func finish_attack() -> void:
	set_trigger("attack_player_finished")


func patrol() -> void:
	set_trigger("idle_time_has_passed")


func finish_patrol() -> void:
	set_trigger("patrol_finished")


func _on_transited(from: Variant, to: Variant) -> void:
	print(from, " --> ", to)
	match from:
		"Alerted":
			alerted_timer.stop()
	
	match to:
		"Idle":
			idle_timer.start(randf_range(1.0,3.0))
		"Alerted":
			alerted_timer.start(2.5)
		"Attacking":
			attack_timer.start(1)
