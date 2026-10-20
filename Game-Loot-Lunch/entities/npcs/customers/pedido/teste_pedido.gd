extends Node2D
## Cena de teste do PEDIDO do cliente.
##
## - Ande com o chef até um cliente: o balão aparece com o pedido.
## - Aura verde = quer o espetinho NO PONTO. Aura vermelha = quer TORRADO.
## - Tecla N: sorteia pedidos novos para todos os clientes.
## - No começo, faz um sorteio simulado e escreve as porcentagens no Output
##   (para conferir os 30% de "só cogumelo").


## Quantos sorteios simular para a estatística (0 desliga).
@export var simulated_rolls: int = 10000
@export var reroll_key: Key = KEY_N


func _ready() -> void:
	var orders: Array = _find_order_components(self)
	if orders.is_empty():
		push_warning("teste_pedido: nenhum OrderComponent na cena.")
		return
	if simulated_rolls > 0:
		_print_statistics(orders[0])


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == reroll_key:
		print("--- Novos pedidos ---")
		for order_component in _find_order_components(self):
			order_component.generate_order()
		get_viewport().set_input_as_handled()


func _print_statistics(order_component: OrderComponent) -> void:
	var counts: Dictionary = {}
	var burnt: int = 0
	for i in simulated_rolls:
		var order: CustomerOrder = order_component.roll_order()
		if order == null:
			return
		var key: String = order.option.display_name
		counts[key] = counts.get(key, 0) + 1
		if order.is_burnt():
			burnt += 1

	print("=== Sorteio simulado: %d pedidos ===" % simulated_rolls)
	for key in counts:
		print("  %-18s %5.1f %%" % [key, 100.0 * counts[key] / simulated_rolls])
	print("  %-18s %5.1f %%" % ["(torrado)", 100.0 * burnt / simulated_rolls])


func _find_order_components(node: Node) -> Array:
	var found: Array = []
	for child in node.get_children():
		if child is OrderComponent:
			found.append(child)
		found.append_array(_find_order_components(child))
	return found
