extends KitchenStation
class_name IngredientCrate
## Caixa de ingredientes infinita: B com a mão vazia gera um item novo na mão.


@export var item_scene: PackedScene
@export var item_data: ItemData


func _interact(_actor: Node, actor_hand: HandComponent) -> void:
	give_item(actor_hand)


## Cria um item novo direto na mão. Retorna true se entregou.
## Não entrega se a mão já estiver ocupada (só 1 item por vez).
func give_item(actor_hand: HandComponent) -> bool:
	if actor_hand == null or actor_hand.has_item() or item_scene == null:
		return false

	var node: Node = item_scene.instantiate()
	var item: CarryableItem = node as CarryableItem
	if item == null:
		push_error("IngredientCrate: item_scene precisa ter um CarryableItem na raiz.")
		node.queue_free()
		return false

	if item_data:
		item.data = item_data
	if not actor_hand.hold(item):
		item.queue_free()
		return false
	return true
