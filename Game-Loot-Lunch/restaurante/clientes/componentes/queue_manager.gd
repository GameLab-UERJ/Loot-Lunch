@tool
class_name QueueManager
extends Node2D

## Gerencia a fila física de clientes: calcula os waypoints/slots a partir
## de um ponto de entrada (EntryPoint) e um vetor de direção configurável,
## e controla a quantidade máxima de clientes aguardando.
##
## O vetor "queue_direction" define para onde a fila cresce, permitindo
## filas esquerda->direita, direita->esquerda, cima->baixo ou baixo->cima
## apenas trocando o valor no Inspector (ex: Vector2.LEFT, Vector2.RIGHT,
## Vector2.UP, Vector2.DOWN).

signal customer_added(customer: Node, slot_index: int)
signal customer_removed(customer: Node)
signal queue_full
signal queue_available

@export var max_queue_size: int = 3
@export var slot_spacing: float = 40.0

@export var queue_direction: Vector2 = Vector2.LEFT:
	set(value):
		queue_direction = value.normalized() if value != Vector2.ZERO else Vector2.LEFT
		if is_inside_tree():
			queue_redraw()

@export var debug_draw: bool = true:
	set(value):
		debug_draw = value
		if is_inside_tree():
			queue_redraw()

@onready var entry_point: Marker2D = $EntryPoint

var _queue: Array[Node] = []


func _ready() -> void:
	queue_direction = queue_direction.normalized()


func is_full() -> bool:
	return _queue.size() >= max_queue_size


func has_space() -> bool:
	return not is_full()


func current_size() -> int:
	return _queue.size()


func get_slot_global_position(index: int) -> Vector2:
	return entry_point.global_position + queue_direction * slot_spacing * index


func enqueue(customer: Node) -> bool:
	if is_full():
		return false

	if not (customer is Node2D):
		push_warning("QueueManager: o cliente precisa ser um Node2D para ser posicionado na fila.")
		return false

	_queue.append(customer)
	var slot_index: int = _queue.size() - 1
	_move_customer_to_slot(customer, slot_index)
	customer_added.emit(customer, slot_index)

	if is_full():
		queue_full.emit()

	return true


## Remove e retorna o cliente da frente da fila (ex: quando o pedido foi
## entregue/atendido no balcão) e reorganiza os demais.
func dequeue_front() -> Node:
	if _queue.is_empty():
		return null

	var was_full: bool = is_full()
	var front: Node = _queue.pop_front()
	customer_removed.emit(front)
	_reflow_queue()

	if was_full and not is_full():
		queue_available.emit()

	return front


## Remove um cliente específico de qualquer posição da fila (ex: cliente
## desistiu) e reorganiza os demais.
func remove_customer(customer: Node) -> bool:
	var idx: int = _queue.find(customer)
	if idx == -1:
		return false

	var was_full: bool = is_full()
	_queue.remove_at(idx)
	customer_removed.emit(customer)
	_reflow_queue()

	if was_full and not is_full():
		queue_available.emit()

	return true


func _reflow_queue() -> void:
	for i in _queue.size():
		_move_customer_to_slot(_queue[i], i)


func _move_customer_to_slot(customer: Node, index: int) -> void:
	var target: Vector2 = get_slot_global_position(index)

	# Se o cliente for um "Customer" (customer.gd), ele já sabe cuidar da
	# FSM (estado "Walking"/"WaitingInQueue") junto com o movimento.
	if customer.has_method("walk_to_queue_slot"):
		customer.walk_to_queue_slot(target)
		return

	# Fallback genérico: qualquer outro Node2D sem customer.gd.
	var mover: QueueMovementComponent = customer.get_node_or_null("QueueMovementComponent")

	if mover == null:
		mover = QueueMovementComponent.new()
		mover.name = "QueueMovementComponent"
		customer.add_child(mover)

	mover.move_to(target)


func _draw() -> void:
	if not debug_draw or entry_point == null:
		return

	var local_entry: Vector2 = entry_point.position

	for i in max_queue_size:
		var slot_local: Vector2 = local_entry + queue_direction * slot_spacing * i
		draw_circle(slot_local, 6.0, Color(0.2, 0.8, 1.0, 0.6))

	var last_index: int = max_queue_size - 1 if max_queue_size > 1 else 1
	var arrow_end: Vector2 = local_entry + queue_direction * slot_spacing * last_index
	draw_line(local_entry, arrow_end, Color(1.0, 0.6, 0.1), 2.0)
