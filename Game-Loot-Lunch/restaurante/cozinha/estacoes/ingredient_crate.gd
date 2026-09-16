extends KitchenStation
class_name IngredientCrate
## Caixa de ingredientes infinita: B com a mão vazia gera um item novo na mão.


@export var item_scene: PackedScene
@export var item_data: ItemData


func _interact(_actor: Node, actor_hand: HandComponent) -> void:
	if actor_hand == null or actor_hand.has_item() or item_scene == null:
		return

	var item: CarryableItem = item_scene.instantiate() as CarryableItem
	if item == null:
		push_error("IngredientCrate: item_scene precisa ter um CarryableItem na raiz.")
		return

	if item_data:
		item.data = item_data
	if not actor_hand.hold(item):
		item.queue_free()
