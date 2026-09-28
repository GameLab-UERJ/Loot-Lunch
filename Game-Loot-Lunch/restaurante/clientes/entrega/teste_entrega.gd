extends Node2D
## Cena de teste da ENTREGA + PAGAMENTO + VIDA do chef.
##
## - R: pega um espetinho do chão (mão vazia) / larga no chão (mão cheia).
## - B perto do cliente com o espetinho na mão: entrega na mão.
## - R (largar) encostado no cliente: entrega por COLISÃO (o mesmo caminho
##   que o arremesso vai usar no futuro).
## - Certo = preço cheio (10). Errado = 25% do preço (arredondado: 3).
## - G: repõe a fileira de espetinhos no chão.
## - K: chef leva 1 de dano (meia caveira). H: cura 1 (se morreu, revive).
## - N: sorteia pedidos novos para todos os clientes.


@export var item_scene: PackedScene
## Espetinhos que aparecem no chão (tecla G repõe).
@export var restock_items: Array[Resource] = []
@export var restock_spacing: float = 36.0

@export_group("Teclas")
@export var damage_key: Key = KEY_K
@export var heal_key: Key = KEY_H
@export var reroll_key: Key = KEY_N
@export var restock_key: Key = KEY_G


@onready var chef: Chef = $Chef
@onready var items_root: Node2D = $ItensNoChao
@onready var shelf: Marker2D = $Fileira


func _ready() -> void:
	for payment in _find_all(self, func(n: Node) -> bool: return n is OrderPaymentComponent):
		payment.order_paid.connect(_on_order_paid.bind(payment))
	_restock()


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return

	if key.keycode == damage_key:
		chef.take_damage(1, Vector2.ZERO, 0)
		print("[Vida] dano -> %d/%d" % [chef.hp, chef.max_hp])
	elif key.keycode == heal_key:
		chef.heal(1)
		print("[Vida] cura -> %d/%d" % [chef.hp, chef.max_hp])
	elif key.keycode == reroll_key:
		for order in _find_all(self, func(n: Node) -> bool: return n is OrderComponent):
			order.generate_order()
	elif key.keycode == restock_key:
		_restock()
	else:
		return
	get_viewport().set_input_as_handled()


func _restock() -> void:
	if item_scene == null:
		return
	# Remove só o que está solto no chão (o que está na mão do chef fica).
	for child in items_root.get_children():
		if child is CarryableItem and not child.is_held():
			child.queue_free()

	for i in restock_items.size():
		var data := restock_items[i] as ItemData
		if data == null:
			continue
		var item := item_scene.instantiate() as CarryableItem
		item.data = data
		items_root.add_child(item)
		item.global_position = shelf.global_position + Vector2(i * restock_spacing, 0)


func _on_order_paid(correct: bool, amount: int, _deliverer: Node, payment: OrderPaymentComponent) -> void:
	var customer: String = String(payment.get_parent().name)
	var total: String = chef.wallet.format(chef.wallet.amount) if chef.wallet else "?"
	print("[Entrega] %s: %s  +%d  (total: %s)" % [customer, "CERTO" if correct else "ERRADO", amount, total])


func _find_all(node: Node, filter: Callable) -> Array:
	var found: Array = []
	for child in node.get_children():
		if filter.call(child):
			found.append(child)
		found.append_array(_find_all(child, filter))
	return found
