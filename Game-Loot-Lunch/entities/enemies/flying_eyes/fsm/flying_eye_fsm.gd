extends FiniteStateMachine


func _init() -> void:
	_add_state("idle")
	_add_state("patrol")
	_add_state("chase")
	_add_state("hurt")
	_add_state("dead")
	
	
func _ready() -> void:
	await parent.ready
	set_state(states.idle)
	
	
func _state_logic(_delta: float) -> void:
	print(states.find_key(state))


func _get_transition() -> int:
	match state:
		states.idle:
			if parent.states_timer.is_stopped():
				return states.patrol
			
			if parent.alert:
				return states.chase
		states.patrol:
			if parent.alert:
				return states.chase
		states.chase:
			if parent.states_timer.is_stopped() and !parent.alert:
				return states.idle
		states.hurt:
			if not animation_player.is_playing():
				return states.chase
	return -1
	
	
func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.idle:
			parent.idle_state()
			animation_player.play("flying")
		states.patrol:
			animation_player.play("flying")
			if not parent.has_node("PatrolComponent"): return
			parent.patrol_component.enable()
		states.chase:
			animation_player.play("flying")
			if not parent.chase_component: return
			parent.chase_component.enable()
		states.hurt:
			animation_player.play("hurt")
		states.dead:
			parent.drop_component.drop_items()
			animation_player.play("dead")


func _exit_state(state_exited: int) -> void:
	match state_exited:
		states.patrol:
			if not parent.patrol_component: return
			parent.patrol_component.disable()
		states.chase:
			if not parent.chase_component: return
			parent.chase_component.disable()
