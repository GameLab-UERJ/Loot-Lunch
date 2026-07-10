extends FiniteStateMachine


func _init() -> void:
	_add_state("idle")
	_add_state("hidden")
	_add_state("digging_up")
	_add_state("alert")
	_add_state("chase")
	_add_state("hurt")
	_add_state("dead")


func _ready() -> void:
	await parent.ready
	set_state(states.digging_up)


func _state_logic(_delta: float) -> void:
	if state == states.chase:
		parent.chase_component.enable()
	else:
		parent.chase_component.disable()


func _get_transition() -> int:
	match state:
		states.idle:
			if parent.states_timer.is_stopped():
				return states.hidden
				
			if parent.alert:
				return states.alert
		states.alert:
			if parent.states_timer.is_stopped():
				if !parent.alert:
					return states.idle
				else:
					return states.chase
		states.hidden:
			if parent.alert:
				return states.digging_up
			if parent.states_timer.is_stopped():
				return states.digging_up
		states.digging_up:
			if !animation_player.is_playing():
				if parent.alert:
					return states.alert
				else:
					return states.idle
		states.hurt:
			if parent.tween and !parent.tween.is_running():
				return states.chase
	return -1


func _enter_state(_previous_state: int, new_state: int) -> void:
	print(states.find_key(state))
	match new_state:
		states.idle:
			parent.idle_state()
			animation_player.play("idle_left")
		states.digging_up:
			animation_player.play("digging_up")
		states.alert:
			parent.alert_state()
			animation_player.play("alert")
		states.hidden:
			parent.hidden_state()
			animation_player.play("digging_down")
		states.chase:
			animation_player.play("walk_left")
		states.hurt:
			parent.damage_taken_animation()
		states.dead:
			parent.dead_state()
			animation_player.play("dead_left")


func _exit_state(state_exited: int) -> void:
	match state_exited:
		states.hidden:
			parent.hidden_move()
