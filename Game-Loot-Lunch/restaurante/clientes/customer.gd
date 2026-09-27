class_name Customer
extends Character

## Script base para os clientes do restaurante (Johnny, Mandy, Patolino, ...).
## Substitui o "character.gd" genérico como script raiz destas cenas.
##
## A troca idle/move da FSM já acontece sozinha (baseada na velocity, igual
## ao FSM do player). Este script só liga o QueueMovementComponent e avisa
## a FSM quando o cliente TERMINA de andar até o slot da fila, pra entrar
## em "waiting_in_queue" (em vez de só cair de volta em "idle").
##
## Quando a paciência se esgota, o cliente entra em "leaving_angry" e emite
## o sinal customer_gave_up para que o spawner/fila cuide da remoção.

signal customer_gave_up

@export var patience_time: float = 15.0

@onready var fsm: CustomerFiniteStateMachine = $FiniteStateMachine

var _queue_mover: QueueMovementComponent
var _patience: PatienceComponent


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


func _ensure_patience() -> void:
	if _patience != null:
		return

	_patience = get_node_or_null("PatienceComponent")
	if _patience == null:
		_patience = PatienceComponent.new()
		_patience.name = "PatienceComponent"
		_patience.position = Vector2(0.0, -36.0)
		add_child(_patience)

	_patience.patience_time = patience_time

	if not _patience.patience_expired.is_connected(_on_patience_expired):
		_patience.patience_expired.connect(_on_patience_expired)


func _on_queue_mover_arrived(_target_position: Vector2) -> void:
	fsm.set_state(fsm.states.waiting_in_queue)
	_ensure_patience()
	if not _patience.is_running():
		_patience.start()


func _on_patience_expired() -> void:
	customer_gave_up.emit()
	fsm.set_state(fsm.states.leaving_angry)
