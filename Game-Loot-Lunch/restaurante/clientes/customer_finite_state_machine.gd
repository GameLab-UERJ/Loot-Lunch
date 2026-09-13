class_name CustomerFiniteStateMachine
extends FiniteStateMachine

## FSM básica dos clientes, no mesmo padrão do FSM do player.
##
## Estados:
##   idle             -> parado
##   move             -> andando até um ponto (ex: slot da fila)
##   waiting_in_queue -> parado, aguardando ser atendido no balcão
##
## idle <-> move é automático (baseado na velocity, igual ao player).
## waiting_in_queue é setado manualmente pelo Customer quando o cliente
## termina de andar até o slot (ver customer.gd).
##
## Só existe animação "idle" até agora, então todo estado toca "idle" -
## troque o nome dentro de _enter_state quando tiver animações próprias
## de andar/esperar.

func _init() -> void:
	_add_state("idle")
	_add_state("move")
	_add_state("waiting_in_queue")


func _ready() -> void:
	set_state(states.idle)


func _get_transition() -> int:
	match state:
		states.idle:
			if parent.velocity.length() > 10:
				return states.move
		states.move:
			if parent.velocity.length() < 10:
				return states.idle
	return -1


func _enter_state(_previous_state: int, new_state: int) -> void:
	match new_state:
		states.idle:
			animation_player.play("idle")
		states.move:
			animation_player.play("idle")  # trocar quando tiver animação de andar
		states.waiting_in_queue:
			animation_player.play("idle")  # trocar quando tiver animação de espera
