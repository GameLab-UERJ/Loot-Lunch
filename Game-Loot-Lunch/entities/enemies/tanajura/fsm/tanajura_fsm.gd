extends FiniteStateMachine


func _init() -> void:
	_add_state("idle")
	_add_state("hidden")
	_add_state("alert")
	_add_state("chase")
	_add_state("hurt")
	_add_state("dead")


func _ready() -> void:
	await parent.ready
	set_state(states.idle)


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
		states.alert:
			if parent.states_timer.is_stopped():
				if !parent.targets.size() > 0:
					return states.idle
				else:
					return states.chase
		states.hurt:
			if parent.tween and !parent.tween.is_running():
				return states.chase
	return -1


func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.idle:
			parent.idle_state()
			
			if !_previous_state == states.alert:
				parent.hidden_move()
				animation_player.play("digging_up")
				await animation_player.animation_finished
			
			animation_player.play("idle_left")
		states.alert:
			parent.alert_state()
			
			if !_previous_state == states.idle:
				animation_player.play("digging_up")
				await animation_player.animation_finished
				
			animation_player.play("alert")
		states.hidden:
			animation_player.play("digging_down")
		states.chase:
			animation_player.play("walk_left")
		states.hurt:
			parent.damage_taken_animation()
		states.dead:
			parent.item_drop_component.drop_item()
			parent.formigueiro.creature_counter -= 1
			animation_player.play("dead_left")
