extends Node2D

## Cena de teste para o sistema de paciência do cliente.
## Mostra clientes entrando na fila com barras de paciência, e exibe
## informações de debug (estado, tempo restante, clientes perdidos).
##
## Controles:
##   Espaço  → gera um cliente manualmente
##   R       → reseta contadores

@onready var queue_manager: QueueManager = $QueueManager
@onready var customer_spawner: CustomerSpawner = $CustomerSpawner
@onready var label_info: Label = $CanvasLayer/VBoxContainer/LabelInfo
@onready var label_queue: Label = $CanvasLayer/VBoxContainer/LabelQueue
@onready var label_lost: Label = $CanvasLayer/VBoxContainer/LabelLost
@onready var label_controls: Label = $CanvasLayer/VBoxContainer/LabelControls

var _customers_lost: int = 0
var _customers_served: int = 0


func _ready() -> void:
	customer_spawner.customer_lost.connect(_on_customer_lost)
	label_controls.text = "[Espaço] Gerar cliente   [R] Resetar contadores"


func _process(_delta: float) -> void:
	_update_labels()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		_spawn_manual_customer()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		_customers_lost = 0
		_customers_served = 0


func _spawn_manual_customer() -> void:
	if customer_spawner.customer_scenes.is_empty():
		return
	if queue_manager.is_full():
		return

	var scene: PackedScene = customer_spawner.customer_scenes[
		randi() % customer_spawner.customer_scenes.size()
	]
	var customer: Node = scene.instantiate()
	add_child(customer)

	if customer is Node2D:
		customer.global_position = customer_spawner.get_node("SpawnPoint").global_position

	if customer is Customer:
		customer.customer_gave_up.connect(
			customer_spawner._on_customer_gave_up.bind(customer)
		)

	queue_manager.enqueue(customer)


func _on_customer_lost() -> void:
	_customers_lost += 1


func _update_labels() -> void:
	# Info geral
	label_info.text = "=== Teste de Paciência ==="

	# Estado da fila
	var queue_text: String = "Fila: %d/%d" % [
		queue_manager.current_size(), queue_manager.max_queue_size
	]

	# Detalhes por cliente na fila
	for i in queue_manager._queue.size():
		var customer: Node = queue_manager._queue[i]
		var patience_info: String = ""
		var state_info: String = ""

		if customer is Customer:
			# Info do PatienceComponent
			var patience: PatienceComponent = customer.get_node_or_null(
				"PatienceComponent"
			)
			if patience and patience.is_running():
				var ratio: float = patience.get_ratio()
				var time_left: float = patience.time_remaining
				patience_info = "  %.1fs (%.0f%%)" % [time_left, ratio * 100.0]
			elif patience and patience.time_remaining <= 0.0:
				patience_info = "  ESGOTOU!"
			else:
				patience_info = "  (aguardando)"

			# Info da FSM
			var fsm: CustomerFiniteStateMachine = customer.fsm
			for state_name: String in fsm.states:
				if fsm.states[state_name] == fsm.state:
					state_info = " [%s]" % state_name
					break

		queue_text += "\n  #%d: %s%s%s" % [
			i + 1, customer.name, state_info, patience_info
		]

	label_queue.text = queue_text

	# Contadores
	label_lost.text = "Clientes perdidos: %d" % _customers_lost
