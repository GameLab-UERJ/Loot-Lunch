extends CustomerDirector
class_name CustomerWaveDirector
## DIRETOR de uma ONDA de clientes vindo de VÁRIOS LADOS (fase 1-1 em diante).
##
## É o CustomerDirector de sempre (monta pedido, entrega e magias do mesmo jeito),
## com três diferenças:
##   - várias filas (`lanes`): cada cliente vai para um lado sorteado que tenha lugar;
##   - número FIXO de clientes (`total_customers`): quando todos forem atendidos,
##     emite `wave_finished`;
##   - `stay_until_served`: o cliente NÃO desiste. Quando a paciência acaba, ele fica
##     furioso, a barra recomeça (um pouco menor) e ele volta a lançar as magias.
##
## Os números vêm do StopwatchLevelData quando ele é o `level_data` (senão, dos exports).


## Todos os clientes da fase foram atendidos.
signal wave_finished
## A paciência de um cliente acabou e ele recomeçou a barra, mais bravo.
signal customer_furious(customer: Customer, times: int)


## Filas (CustomerLane) de onde os clientes podem chegar.
@export var lanes: Array[NodePath] = []
@export var total_customers: int = 20
@export_range(1, 32) var max_simultaneous: int = 12
@export var stay_until_served: bool = true
@export_range(0.2, 1.0) var furious_patience_scale: float = 0.8
@export var min_patience_time: float = 20.0


var spawned_count: int = 0
var furious_count: int = 0
var _lanes: Array[CustomerLane] = []
var _wave_done_emitted: bool = false


func _ready() -> void:
	super()
	for path in lanes:
		var lane := get_node_or_null(path) as CustomerLane
		if lane:
			_lanes.append(lane)
	var data := level_data as StopwatchLevelData
	if data:
		total_customers = data.total_customers
		max_simultaneous = data.max_simultaneous
		stay_until_served = data.customers_stay_until_served
		furious_patience_scale = data.furious_patience_scale
		min_patience_time = data.min_patience_time


func start() -> void:
	_running = true
	_time_to_next = level_data.first_spawn_delay if level_data else 1.0


func get_lanes() -> Array[CustomerLane]:
	return _lanes


## Clientes que ainda vão chegar.
func get_remaining_to_spawn() -> int:
	return maxi(total_customers - spawned_count, 0)


## Clientes que ainda faltam atender (os que vão chegar + os que estão esperando).
func get_remaining() -> int:
	return get_remaining_to_spawn() + get_customers().size()


func is_wave_done() -> bool:
	return spawned_count >= total_customers and get_customers().is_empty()


func spawn_next() -> Customer:
	if level_data == null or spawned_count >= total_customers:
		return null
	if get_customers().size() >= max_simultaneous:
		return null
	var lane: CustomerLane = _pick_lane()
	if lane == null:
		return null
	var scene: PackedScene = _pick_scene()
	if scene == null:
		return null
	queue = lane.queue
	spawn_point = lane.spawn_point
	customers_front = lane.front
	var customer: Customer = _spawn(scene)
	if customer:
		spawned_count += 1
		customer.set_meta(&"lane", lane)
		if spawned_count >= total_customers:
			stop()
	return customer


## Sorteia um lado com lugar, preferindo os mais vazios.
func _pick_lane() -> CustomerLane:
	var best: Array[CustomerLane] = []
	var best_count: int = 999
	for lane in _lanes:
		if not lane.has_space():
			continue
		var n: int = lane.count()
		if n < best_count:
			best_count = n
			best.clear()
		if n == best_count:
			best.append(lane)
	return best.pick_random() if not best.is_empty() else null


func _on_gave_up(customer: Customer) -> void:
	if not stay_until_served:
		super(customer)
		return
	furious_count += 1
	var times: int = int(customer.get_meta(&"furious", 0)) + 1
	customer.set_meta(&"furious", times)
	customer_furious.emit(customer, times)
	# O Customer muda para "leaving_angry" logo depois deste sinal: desfaz no próximo frame.
	_restart_patience.call_deferred(customer)


func _restart_patience(customer: Customer) -> void:
	if not is_instance_valid(customer) or customer.has_meta(&"leaving"):
		return
	customer.fsm.set_state(customer.fsm.states.waiting_in_queue)
	var patience: PatienceComponent = customer.get_node_or_null("PatienceComponent")
	if patience:
		patience.patience_time = maxf(patience.patience_time * furious_patience_scale, min_patience_time)
		patience.start()
	var trigger: PatienceAbilityTrigger = customer.get_node_or_null("GatilhoMagias")
	if trigger:
		trigger.reset()
	# Piscada vermelha: "ficou mais bravo".
	var tween: Tween = customer.create_tween()
	tween.tween_property(customer, "modulate", Color(1.0, 0.45, 0.4), 0.12)
	tween.tween_property(customer, "modulate", Color.WHITE, 0.3)


func _leave(customer: Customer, flash: Color) -> void:
	if not is_instance_valid(customer) or customer.has_meta(&"leaving"):
		return
	var lane := customer.get_meta(&"lane", null) as CustomerLane
	if lane:
		queue = lane.queue
	super(customer, flash)
	_check_done.call_deferred()


func _check_done() -> void:
	if not _wave_done_emitted and is_wave_done():
		_wave_done_emitted = true
		wave_finished.emit()
