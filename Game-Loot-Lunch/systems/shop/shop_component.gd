class_name ShopComponent
extends Node

## Cenas dos itens disponíveis para compra nesta loja e seus preços em Gold.
## [br]
## [b]Formato:[/b] Use uma cena de Item como chave e o preço em Gold como valor.
## [b]Se vazio:[/b] A loja não terá itens disponíveis para compra.
## [b]Se item tiver valor negativo:[/b] O item não será exibido na loja.
@export var items_prices: Dictionary[PackedScene, int] = {}

func get_price(item_scene: PackedScene) -> int:
	return items_prices.get(item_scene, -1)


func get_item_scenes() -> Array[PackedScene]:
	var result: Array[PackedScene] = []
	
	for item_scene in items_prices:
		if get_price(item_scene) >= 0:
			result.append(item_scene)
		
	return result


func create_item(item_scene: PackedScene) -> Item:
	var item := item_scene.instantiate() as Item
	
	if not item:
		push_error("A cena configurada na loja não é um Item: ", item_scene)
		return null

	return item


func get_price_from_item(item: Item) -> int:
	for item_scene: PackedScene in items_prices:
		if item.scene_file_path == item_scene.resource_path:
			return get_price(item_scene)

		var test_item := create_item(item_scene)
		if test_item and test_item.item_name == item.item_name:
			test_item.queue_free()
			return get_price(item_scene)
		if test_item:
			test_item.queue_free()

	return -1
