extends FiniteStateMachine
class_name ChefFSM


func _init() -> void:
	_add_state("idle")
	_add_state("move")
	_add_state("dash")
	_add_state("hurt")
	_add_state("dead")


func _ready() -> void:
	set_state(states.idle)


## Estados em que o chef pode andar, interagir, pegar/largar e dar dash.
func is_free() -> bool:
	return active and (state == states.idle or state == states.move)


func _state_logic(_delta: float) -> void:
	if state == states.idle or state == states.move:
		if not parent.can_control:
			return

		parent.input_component.get_input()


func _get_transition() -> int:
	match state:
		states.idle:
			if parent.velocity.length() > 10:
				return states.move
		states.move:
			if parent.velocity.length() < 10:
				return states.idle
		states.dash:
			if not parent.dash_component.is_dashing:
				return states.idle
		states.hurt:
			if not animation_player.is_playing():
				return states.idle
	return -1


func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.idle:
			animation_player.play("idle")
		states.move:
			animation_player.play("move")
		states.dash:
			animation_player.play("dash" if animation_player.has_animation("dash") else "move")
		states.hurt:
			animation_player.play("hurt")
		states.dead:
			animation_player.play("dead")


func _exit_state(state_exited: int) -> void:
	if state_exited == states.dash:
		parent.dash_component.cancel()
