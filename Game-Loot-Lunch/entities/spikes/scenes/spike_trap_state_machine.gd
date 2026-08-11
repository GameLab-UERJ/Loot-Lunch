extends FiniteStateMachine


func _init() -> void:
	_add_state("idle")
	_add_state("attack")


func _ready() -> void:
	# Não precisa de AnimationPlayer, o AnimatedSprite2D cuida disso
	pass


func _state_logic(_delta: float) -> void:
	pass


func _get_transition() -> int:
	return -1


func _enter_state(_previous_state: int, new_state: int) -> void:
	# Não faz nada aqui, a animação é controlada pelo AnimatedSprite2D
	pass
