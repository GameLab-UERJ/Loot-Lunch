extends FiniteStateMachine

func _init() -> void:
	_add_state("idle")
	_add_state("hurt")
	_add_state("patrol")
	_add_state("alerted")
	_add_state("attacking")
	_add_state("Dead")
	
	
func _ready() -> void:
	set_state(states.idle)
	
	
func _state_logic(_delta: float) -> void:
	if state == states.chase:
		parent.chase()
		parent.move()
		
		
func _get_transition() -> int:
	match state:
		states.hurt:
			if not animation_player.is_playing():
				return states.chase
	return -1
	
	
func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.idle:
			animation_player.play("idle")
		states.idle:
			animation_player.play("hurt")
		states.patrol:
			animation_player.play("patrol")
		states.alerted:
			animation_player.play("alerted")
		states.attacking:
			animation_player.play("attacking")
		states.dead:
			animation_player.play("dead")
