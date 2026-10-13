extends Node
class_name CustomerDirector
## DIRETOR DE CLIENTES da fase: decide quando chega cliente, monta o cliente com tudo
## que ele precisa e cuida da saída dele.
##
## Ao chegar, cada cliente ganha (por código, sem mexer na cena do cliente):
##   pedido.tscn  -> OrderComponent: o pedido só aparece com o chef a `order_reveal_distance`
##   entrega.tscn -> OrderPaymentComponent: recebe o espetinho e paga
##   PatienceAbilityTrigger -> solta as magias 1, 2 e 3 conforme a barra de paciência cai
##
## Atendido (certo ou errado) -> vai embora contente. Paciência acabou -> vai embora bravo.
## Os números (ritmo, paciência, limites das magias...) vêm do LevelData.
##
## Os clientes ficam soltos na fase, ANTES de `insert_before` na árvore (como na cena de
## teste): as magias nascem no mesmo pai e ficam embaixo dos itens e do chef.


signal customer_arrived(customer: Customer)
signal customer_served(customer: Customer, correct: bool, amount: int)
signal customer_lost(customer: Customer)


@export var level_data: LevelData
@export var queue: QueueManager
@export var spawn_point: Node2D
## Onde os clientes entram na árvore. Vazio = o pai deste nó (a fase).
@export var customers_parent: Node
## Os clientes entram logo antes deste nó (ex.: ItensNoChao), para ficarem embaixo dele.
@export var insert_before: Node
@export var order_scene: PackedScene
@export var delivery_scene: PackedScene

@export_group("Orientação")
## Para onde fica a "frente" do cliente (o lado da cozinha). Clientes ABAIXO do balcão
## olham para CIMA: as invocações (demoninho, pato...) nascem desse lado.
@export var customers_front: Vector2 = Vector2.UP

@export_group("Debug")
@export var debug_print: bool = false


var served_count: int = 0
var correct_count: int = 0
var lost_count: int = 0

var _running: bool = false
var _time_to_next: float = 0.0


func _ready() -> void:
	if customers_parent == null:
		customers_parent = get_parent()
	if queue and level_data:
		queue.max_queue_size = level_data.max_customers


# --- Controle ------------------------------------------------------------------

## Começa a mandar clientes (o primeiro chega depois de `first_spawn_delay`).
func start() -> void:
	if queue and level_data:
		queue.max_queue_size = level_data.max_customers
	_running = true
	_time_to_next = level_data.first_spawn_delay if level_data else 1.0


## Para de mandar clientes novos (quem está na fila continua).
func stop() -> void:
	_running = false


func is_running() -> bool:
	return _running


## Todos os clientes vão embora (fim do turno). Não conta como cliente perdido.
func dismiss_all() -> void:
	for customer in get_customers():
		_leave(customer, Color(1, 1, 1, 1))


## Clientes no restaurante (sem contar quem já está indo embora).
func get_customers() -> Array[Customer]:
	var found: Array[Customer] = []
	if customers_parent == null:
		return found
	for child in customers_parent.get_children():
		if child is Customer and not child.is_queued_for_deletion() and not child.has_meta(&"leaving"):
			found.append(child)
	return found


func _process(delta: float) -> void:
	if not _running or level_data == null:
		return
	_time_to_next -= delta
	if _time_to_next > 0.0:
		return
	# Fila cheia: tenta de novo daqui a pouco, sem perder a vez.
	_time_to_next = level_data.roll_spawn_interval() if spawn_next() else 1.0


# --- Chegada -------------------------------------------------------------------

## Chama um cliente agora. Retorna null se a fila estiver cheia.
func spawn_next() -> Customer:
	if level_data == null or queue == null or queue.is_full():
		return null
	var scene: PackedScene = _pick_scene()
	if scene == null:
		return null
	return _spawn(scene)


## Sorteia quem vem, dando preferência a quem ainda não está na fila.
func _pick_scene() -> PackedScene:
	var all: Array[PackedScene] = []
	var absent: Array[PackedScene] = []
	for scene in level_data.customer_scenes:
		if scene == null:
			continue
		all.append(scene)
		if not _is_present(scene):
			absent.append(scene)
	if not absent.is_empty():
		return absent.pick_random()
	return all.pick_random() if not all.is_empty() else null


func _spawn(scene: PackedScene) -> Customer:
	var customer := scene.instantiate() as Customer
	if customer == null:
		push_warning("CustomerDirector: '%s' não tem Customer na raiz." % scene.resource_path)
		return null
	customer.patience_time = level_data.patience_time
	customer.set_meta(&"scene_path", scene.resource_path)

	if order_scene:
		var order := order_scene.instantiate() as OrderComponent
		order.show_only_when_near = true
		order.reveal_distance = level_data.order_reveal_distance
		customer.add_child(order)
	if delivery_scene:
		customer.add_child(delivery_scene.instantiate())

	var trigger := PatienceAbilityTrigger.new()
	trigger.name = "GatilhoMagias"
	trigger.thresholds = level_data.ability_thresholds.duplicate()
	customer.add_child(trigger)

	customers_parent.add_child(customer)
	if insert_before and insert_before.get_parent() == customers_parent:
		customers_parent.move_child(customer, insert_before.get_index())
	customer.global_position = spawn_point.global_position if spawn_point else Vector2.ZERO
	_face_summons(customer)

	customer.customer_gave_up.connect(_on_gave_up.bind(customer))
	var payment := _find_child_of_type(customer, OrderPaymentComponent) as OrderPaymentComponent
	if payment:
		payment.order_paid.connect(_on_order_paid.bind(customer))

	queue.enqueue(customer)
	customer_arrived.emit(customer)
	if debug_print:
		print("[Diretor] %s chegou" % customer.name)
	return customer


## As invocações nascem "na frente" do cliente. A cena do cliente assume a cozinha
## embaixo dele; aqui a cozinha fica do lado de `customers_front`.
func _face_summons(customer: Customer) -> void:
	var caster := customer.get_node_or_null("Habilidades") as CustomerAbilityCaster
	if caster == null or is_zero_approx(customers_front.y):
		return
	for ability in caster.get_abilities():
		var summon := ability as SummonAbility
		if summon:
			summon.spawn_offset.y = absf(summon.spawn_offset.y) * signf(customers_front.y)


## Já tem um desses no restaurante (inclusive indo embora)?
func _is_present(scene: PackedScene) -> bool:
	for child in customers_parent.get_children():
		if child is Customer and not child.is_queued_for_deletion() \
				and child.get_meta(&"scene_path", "") == scene.resource_path:
			return true
	return false


# --- Saída ---------------------------------------------------------------------

func _on_order_paid(correct: bool, amount: int, _deliverer: Node, customer: Customer) -> void:
	served_count += 1
	if correct:
		correct_count += 1
	customer_served.emit(customer, correct, amount)
	_leave(customer, Color(0.6, 1.0, 0.6))


func _on_gave_up(customer: Customer) -> void:
	lost_count += 1
	customer_lost.emit(customer)
	_leave(customer, Color.RED)


func _leave(customer: Customer, flash: Color) -> void:
	if not is_instance_valid(customer) or customer.has_meta(&"leaving"):
		return
	customer.set_meta(&"leaving", true)
	var patience: PatienceComponent = customer.get_node_or_null("PatienceComponent")
	if patience:
		patience.pause()
	var trigger: PatienceAbilityTrigger = customer.get_node_or_null("GatilhoMagias")
	if trigger:
		trigger.stop()
	var caster: CustomerAbilityCaster = customer.get_node_or_null("Habilidades")
	if caster:
		caster.interrupt_all()
	var order := _find_child_of_type(customer, OrderComponent) as OrderComponent
	if order:
		order.clear_order()
	if queue:
		queue.remove_customer(customer)
	var tween: Tween = customer.create_tween()
	tween.tween_property(customer, "modulate", flash, 0.15)
	tween.tween_property(customer, "modulate:a", 0.0, 0.5)
	tween.tween_callback(customer.queue_free)


func _find_child_of_type(node: Node, type: Variant) -> Node:
	for child in node.get_children():
		if is_instance_of(child, type):
			return child
	return null
