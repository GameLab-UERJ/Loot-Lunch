extends Node
class_name DragAndDropManager


var cell : InventoryCell = get_parent()

## Drag & Drop - esta célula pode receber itens?
func can_drop_data(_pos: Vector2, data) -> bool:
	if not cell.can_receive_items:
		return false
	if cell.item:
		return false  # Já tem item
	return data is Item


## Drag & Drop - recebeu um item
func drop_data(_pos: Vector2, data) -> void:
	if not data is Item:
		return
	
	cell.item_dropped.emit(self, data)
	# Não chamamos set_item aqui, o CraftingGrid que gerencia
