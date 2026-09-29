class_name CustomerSpawner
extends Node2D

## Gera clientes aleatórios em intervalos configuráveis (Timer) e os envia
## para a fila gerenciada por um QueueManager. Se a fila estiver cheia, o
## spawner simplesmente não gera ninguém e tenta de novo no próximo ciclo.
##
## Quando um cliente desiste (paciência esgotada), o spawner remove-o da
## fila e emite o sinal customer_lost para que outros sistemas apliquem
## penalidades (ex: perda de pontos, reputação).

signal customer_lost

@export var customer_scenes: Array[PackedScene] = []
@export var min_spawn_interval: float = 3.0
@export var max_spawn_interval: float = 7.0

## Caminho até o node QueueManager na cena (arraste o node no Inspector
## usando o botão de seleção do campo, ou digite o caminho relativo).
@export var queue_manager_path: NodePath

## Opcional: node onde os clientes instanciados serão adicionados.
## Se vazio, usa a cena atual (get_tree().current_scene).
@export var customers_container: Node

@onready var spawn_timer: Timer = $SpawnTimer
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var queue_manager: QueueManager = get_node_or_null(queue_manager_path) as QueueManager


func _ready() -> void:
	if queue_manager == null:
		push_warning("CustomerSpawner: nenhum QueueManager atribuído em 'Queue Manager Path'.")

	if customer_scenes.is_empty():
		push_warning("CustomerSpawner: nenhuma cena de cliente configurada em 'customer_scenes'.")

	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_schedule_next_spawn()


func _schedule_next_spawn() -> void:
	spawn_timer.wait_time = randf_range(min_spawn_interval, max_spawn_interval)
	spawn_timer.start()


func _on_spawn_timer_timeout() -> void:
	_try_spawn_customer()
	_schedule_next_spawn()


func _try_spawn_customer() -> void:
	if queue_manager == null or customer_scenes.is_empty():
		return

	if queue_manager.is_full():
		# Fila cheia: não gera cliente agora, tenta novamente no próximo timer.
		return

	var scene: PackedScene = customer_scenes[randi() % customer_scenes.size()]
	var customer: Node = scene.instantiate()

	var container: Node = customers_container if customers_container != null else get_tree().current_scene
	container.add_child(customer)

	if customer is Node2D:
		customer.global_position = spawn_point.global_position

	if customer is Customer:
		customer.customer_gave_up.connect(_on_customer_gave_up.bind(customer))

	queue_manager.enqueue(customer)


func _on_customer_gave_up(customer: Node) -> void:
	if queue_manager:
		queue_manager.remove_customer(customer)

	customer_lost.emit()

	# Feedback visual: pisca vermelho e some
	if customer is Node2D:
		var tween: Tween = create_tween()
		tween.tween_property(customer, "modulate", Color.RED, 0.15)
		tween.tween_property(customer, "modulate:a", 0.0, 0.4)
		tween.tween_callback(customer.queue_free)
