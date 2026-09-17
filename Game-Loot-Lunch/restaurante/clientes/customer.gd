class_name Customer
extends Character

## Script base para os clientes do restaurante (Johnny, Mandy, Patolino, ...).
## Substitui o "character.gd" genérico como script raiz destas cenas.
##
## A troca idle/move da FSM já acontece sozinha (baseada na velocity, igual
## ao FSM do player). Este script só liga o QueueMovementComponent e avisa
## a FSM quando o cliente TERMINA de andar até o slot da fila, pra entrar
## em "waiting_in_queue" (em vez de só cair de volta em "idle").

@onready var fsm: CustomerFiniteStateMachine = $FiniteStateMachine

var _queue_mover: QueueMovementComponent


## Chamado pelo QueueManager para mandar o cliente andar até um slot da
## fila (ou qualquer outro ponto, ex: posição de atendimento no balcão).
func walk_to_queue_slot(target_position: Vector2) -> void:
	_ensure_queue_mover()
	_queue_mover.move_to(target_position)


func _ensure_queue_mover() -> void:
	if _queue_mover != null:
		return

	_queue_mover = get_node_or_null("QueueMovementComponent")
	if _queue_mover == null:
		_queue_mover = QueueMovementComponent.new()
		_queue_mover.name = "QueueMovementComponent"
		add_child(_queue_mover)

	if not _queue_mover.arrived_at_target.is_connected(_on_queue_mover_arrived):
		_queue_mover.arrived_at_target.connect(_on_queue_mover_arrived)


func _on_queue_mover_arrived(_target_position: Vector2) -> void:
	fsm.set_state(fsm.states.waiting_in_queue)
