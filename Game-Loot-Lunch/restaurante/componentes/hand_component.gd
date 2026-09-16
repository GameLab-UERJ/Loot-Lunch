extends Node2D
class_name HandComponent
## "MãoUm": segura UM CarryableItem por vez e o mantém visível na posição da mão.
##
## Reutilizável: vai no Chef (mão do jogador), numa bancada (slot em cima do balcão),
## num fogão (panela), numa bandeja etc. Tudo que "segura um item" usa este componente.
##
## Posicione o nó onde o item deve aparecer (ex.: Vector2(16, 4) num personagem 64x64).


signal item_held(item: CarryableItem)
signal item_released(item: CarryableItem)


## Espelha a mão no eixo X quando o dono vira para a esquerda.
@export var flip_with_facing: bool = true


var held_item: CarryableItem = null


## Encontra o HandComponent filho direto de um nó (ex.: o Chef). Retorna null se não houver.
static func find_in(node: Node) -> HandComponent:
	if node == null:
		return null
	for child in node.get_children():
		if child is HandComponent:
			return child
	return null


func has_item() -> bool:
	return is_instance_valid(held_item)


func is_empty() -> bool:
	return not has_item()


func can_hold(item: CarryableItem) -> bool:
	return is_empty() and is_instance_valid(item) and item.can_be_picked_up()


## Coloca o item na mão. Funciona com item já na cena (chão) ou recém-instanciado.
func hold(item: CarryableItem) -> bool:
	if not can_hold(item):
		return false

	held_item = item
	if item.is_inside_tree():
		item.reparent(self, false)
	else:
		add_child(item)

	item.position = item.get_hold_offset()
	item.rotation = 0.0
	item.notify_held(self)
	item_held.emit(item)
	return true


## Larga o item dentro de `container` na posição global indicada (ex.: no chão).
func drop_to(container: Node, global_pos: Vector2) -> CarryableItem:
	var item: CarryableItem = _detach()
	if item == null:
		return null

	item.reparent(container, false)
	item.global_position = global_pos
	item.rotation = 0.0
	return item


## Passa o item desta mão para outra (chef -> bancada, bancada -> chef...).
func transfer_to(other: HandComponent) -> bool:
	if is_empty() or other == null or other == self or other.has_item():
		return false

	var item: CarryableItem = _detach()
	return other.hold(item)


func take_from(other: HandComponent) -> bool:
	return other != null and other.transfer_to(self)


## Remove e destrói o item (útil para lixeira / entregar pedido).
func consume_item() -> void:
	var item: CarryableItem = _detach()
	if item:
		item.queue_free()


func set_facing(direction: Vector2) -> void:
	if not flip_with_facing or is_zero_approx(direction.x):
		return
	var side: float = signf(direction.x)
	position.x = absf(position.x) * side
	scale.x = absf(scale.x) * side


func _detach() -> CarryableItem:
	if is_empty():
		held_item = null
		return null
	var item: CarryableItem = held_item
	held_item = null
	item.notify_released()
	item_released.emit(item)
	return item
