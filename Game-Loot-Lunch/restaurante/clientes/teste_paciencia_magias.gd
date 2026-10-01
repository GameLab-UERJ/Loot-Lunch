extends Node2D
## Cena de teste: PACIÊNCIA + MAGIAS + ENTREGA (na mão e por ARREMESSO).
##
## Os clientes chegam UM DE CADA VEZ (Johnny, depois Mandy, depois Patolino...), entram
## na fila e a barra de paciência começa a cair. Cada um tem um PatienceAbilityTrigger:
##
##   barra em 90% -> magia 1   |   50% -> magia 2   |   20% -> magia 3   |   0% -> vai embora bravo
##
## Entregue o pedido antes da barra acabar:
##   - na mão: chegue perto do cliente e aperte F;
##   - ARREMESSO: segure Q, mire com o mouse no cliente e solte (gasta 1 mana).
## Atendido, o cliente vai embora contente e o próximo da vez entra.
##
## No chão só tem espetinho PRONTO (no ponto e torrado). Quando acabarem, voltam sozinhos.
##
## Teclas extras: G repõe os espetinhos | H cura / revive | N chama o próximo cliente agora
##                M enche a mana


@export_group("Clientes")
## Ordem em que chegam (e voltam depois de irem embora).
@export var customer_scenes: Array[PackedScene] = []
@export var order_scene: PackedScene
@export var delivery_scene: PackedScene
## Segundos de paciência de cada cliente (a barra inteira).
@export var patience_time: float = 30.0
## Limites da barra que soltam as magias 1, 2 e 3.
@export var thresholds: Array[float] = [0.9, 0.5, 0.2]
## Segundos até o primeiro cliente aparecer.
@export var first_spawn_delay: float = 1.0
## Segundos entre um cliente e o próximo.
@export var spawn_interval: float = 7.0

@export_group("Espetinhos no chão")
@export var item_scene: PackedScene
## Só os prontos: no ponto e torrado.
@export var floor_items: Array[Resource] = []
@export var floor_spacing: float = 44.0
## Repõe sozinho quando o chão fica vazio.
@export var auto_restock: bool = true

@export_group("Teclas")
@export var restock_key: Key = KEY_G
@export var heal_key: Key = KEY_H
@export var next_customer_key: Key = KEY_N
@export var mana_key: Key = KEY_M


## Cliente -> o que aconteceu com ele (para o painel e para os testes).
var log_by_customer: Dictionary = {}
var spawned_order: Array[String] = []
## Tudo que aconteceu, em ordem ("Johnny: magia 1", "Mandy: atendido (certo)"...).
var events: Array[String] = []

var _next_index: int = 0
var _spawn_timer: float = 0.0
var _restock_pending: bool = false


@onready var chef: Chef = $Chef
@onready var queue: QueueManager = $Fila
@onready var spawn_point: Marker2D = $Entrada
## Os clientes ficam soltos na fase (como o chef): as magias deles nascem no mesmo lugar,
## e o raio do Johnny consegue ficar "no chão", embaixo do chef.
@onready var customers_root: Node2D = self
@onready var items_root: Node2D = $ItensNoChao
@onready var shelf: Marker2D = $Fileira
@onready var status_label: Label = get_node_or_null("Painel")


func _ready() -> void:
	randomize()
	_spawn_timer = spawn_interval - first_spawn_delay
	chef.health_changed.connect(func(current: int, maximum: int) -> void:
		print("[Chef] vida %d/%d" % [current, maximum]))
	restock()


func _process(delta: float) -> void:
	_spawn_timer += delta
	if _spawn_timer >= spawn_interval and spawn_next():
		_spawn_timer = 0.0
	if auto_restock and not _restock_pending and _floor_count() == 0 and not chef.hand_component.has_item():
		_restock_pending = true
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			_restock_pending = false
			if _floor_count() == 0:
				restock())
	_refresh_panel()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		restock_key:
			restock()
		heal_key:
			chef.heal_full()
		next_customer_key:
			if spawn_next():
				_spawn_timer = 0.0
		mana_key:
			if chef.mana:
				chef.mana.restore_full()
		_:
			return
	get_viewport().set_input_as_handled()


# --- Clientes ---------------------------------------------------------------

## Chama o próximo cliente da vez (pula quem já está no restaurante). false = fila cheia.
func spawn_next() -> Customer:
	if customer_scenes.is_empty() or queue.is_full():
		return null
	for attempt in customer_scenes.size():
		var index: int = (_next_index + attempt) % customer_scenes.size()
		var scene: PackedScene = customer_scenes[index]
		if scene == null or _is_present(scene):
			continue
		_next_index = (index + 1) % customer_scenes.size()
		return _spawn(scene)
	return null


## Clientes no restaurante (sem contar quem já está indo embora).
func get_customers() -> Array[Customer]:
	var found: Array[Customer] = []
	for child in customers_root.get_children():
		if child is Customer and not child.is_queued_for_deletion() and not child.has_meta(&"leaving"):
			found.append(child)
	return found


func _spawn(scene: PackedScene) -> Customer:
	var customer := scene.instantiate() as Customer
	if customer == null:
		return null
	customer.patience_time = patience_time
	customer.set_meta(&"scene_path", scene.resource_path)

	if order_scene:
		var order: OrderComponent = order_scene.instantiate()
		order.show_only_when_near = false
		customer.add_child(order)
	if delivery_scene:
		customer.add_child(delivery_scene.instantiate())

	var trigger := PatienceAbilityTrigger.new()
	trigger.name = "GatilhoMagias"
	trigger.thresholds = thresholds.duplicate()
	customer.add_child(trigger)

	customers_root.add_child(customer)
	customers_root.move_child(customer, items_root.get_index())  # embaixo dos itens e do chef
	customer.global_position = spawn_point.global_position
	var who: String = String(customer.name)
	log_by_customer[who] = {"magias": [], "status": "chegando", "paciencia": 1.0}
	spawned_order.append(who)
	print("[Cliente] %s chegou" % who)

	trigger.threshold_reached.connect(_on_threshold.bind(customer))
	trigger.ability_triggered.connect(_on_ability_triggered.bind(customer))
	customer.customer_gave_up.connect(_on_gave_up.bind(customer))
	var payment := _find_child_of_type(customer, OrderPaymentComponent) as OrderPaymentComponent
	if payment:
		payment.order_paid.connect(_on_order_paid.bind(customer))
	var order_component := _find_child_of_type(customer, OrderComponent) as OrderComponent
	if order_component and order_component.has_order():
		log_by_customer[who]["pedido"] = order_component.current_order.describe()

	queue.enqueue(customer)
	return customer


## Já tem um desses no restaurante (inclusive indo embora)?
func _is_present(scene: PackedScene) -> bool:
	for child in customers_root.get_children():
		if child is Customer and not child.is_queued_for_deletion() \
				and child.get_meta(&"scene_path", "") == scene.resource_path:
			return true
	return false


func _on_threshold(level: int, ratio: float, ok: bool, customer: Customer) -> void:
	print("[Paciência] %s em %d%% -> magia %d%s" % [customer.name, roundi(ratio * 100.0), level,
		"" if ok else " (ocupado, tenta de novo)"])


func _on_ability_triggered(level: int, customer: Customer) -> void:
	var entry: Dictionary = log_by_customer.get(String(customer.name), {})
	if entry.has("magias"):
		entry["magias"].append(level)
	events.append("%s: magia %d" % [customer.name, level])
	var caster: CustomerAbilityCaster = customer.get_node_or_null("Habilidades")
	var ability: CustomerAbility = caster.get_ability(mini(level, caster.get_abilities().size()) - 1) if caster else null
	print("[Magia] %s lançou a magia %d (%s)" % [customer.name, level, ability.name if ability else "?"])


func _on_order_paid(correct: bool, amount: int, _deliverer: Node, customer: Customer) -> void:
	print("[Entrega] %s: %s +%d" % [customer.name, "CERTO" if correct else "ERRADO", amount])
	_set_status(customer, "atendido (%s)" % ("certo" if correct else "errado"))
	_leave(customer, Color(0.6, 1.0, 0.6))


func _on_gave_up(customer: Customer) -> void:
	print("[Cliente] %s desistiu (paciência acabou)" % customer.name)
	_set_status(customer, "desistiu")
	_leave(customer, Color.RED)


func _leave(customer: Customer, flash: Color) -> void:
	if customer.has_meta(&"leaving"):
		return
	customer.set_meta(&"leaving", true)
	customer.name = "%s_saindo" % customer.name  # libera o nome para o próximo igual
	var patience: PatienceComponent = customer.get_node_or_null("PatienceComponent")
	if patience:
		patience.pause()
	var trigger: PatienceAbilityTrigger = customer.get_node_or_null("GatilhoMagias")
	if trigger:
		trigger.stop()
	var caster: CustomerAbilityCaster = customer.get_node_or_null("Habilidades")
	if caster:
		caster.interrupt_all()
	queue.remove_customer(customer)
	var tween: Tween = customer.create_tween()
	tween.tween_property(customer, "modulate", flash, 0.15)
	tween.tween_property(customer, "modulate:a", 0.0, 0.5)
	tween.tween_callback(customer.queue_free)


func _set_status(customer: Customer, text: String) -> void:
	var entry: Dictionary = log_by_customer.get(String(customer.name), {})
	entry["status"] = text
	events.append("%s: %s" % [customer.name, text])


# --- Espetinhos ---------------------------------------------------------------

## Põe a fileira de espetinhos prontos no chão (o que está na mão do chef fica).
func restock() -> void:
	if item_scene == null:
		return
	for child in items_root.get_children():
		if child is CarryableItem and not child.is_held():
			child.queue_free()
	for i in floor_items.size():
		var data := floor_items[i] as ItemData
		if data == null:
			continue
		var item := item_scene.instantiate() as CarryableItem
		item.data = data
		items_root.add_child(item)
		item.global_position = shelf.global_position + Vector2(i * floor_spacing, 0)


func _floor_count() -> int:
	var total: int = 0
	for child in items_root.get_children():
		if child is CarryableItem and not child.is_held() and not child.is_queued_for_deletion():
			total += 1
	return total


# --- Painel -------------------------------------------------------------------

func _refresh_panel() -> void:
	if status_label == null:
		return
	var lines: PackedStringArray = []
	for customer in get_customers():
		var who: String = String(customer.name)
		var entry: Dictionary = log_by_customer.get(who, {})
		var patience: PatienceComponent = customer.get_node_or_null("PatienceComponent")
		var ratio: float = patience.get_ratio() if patience else 1.0
		var spells: Array = entry.get("magias", [])
		var spell_text: String = "-" if spells.is_empty() else ", ".join(spells.map(func(n: int) -> String: return str(n)))
		var state: String = entry.get("status", "")
		if state == "chegando" and patience and patience.is_running():
			state = "esperando"
		lines.append("%s  %3d%%  magias: %s  %s" % [who, roundi(ratio * 100.0), spell_text, state])
	if lines.is_empty():
		lines.append("(nenhum cliente)")
	var mana_text: String = "%d/%d" % [chef.mana.mana, chef.mana.max_mana] if chef.mana else "?"
	lines.append("chef: vida %d/%d  mana %s" % [chef.hp, chef.max_hp, mana_text])
	status_label.text = "\n".join(lines)


func _find_child_of_type(node: Node, type: Variant) -> Node:
	for child in node.get_children():
		if is_instance_of(child, type):
			return child
	return null
