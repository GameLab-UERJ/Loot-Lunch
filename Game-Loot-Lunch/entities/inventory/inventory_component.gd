class_name InventoryComponent
extends Node


signal inventory_opened
signal inventory_closed


## Inventário controlado por este componente.
## [br]
## [b]Formato:[/b] Arraste uma cena/nó do tipo [Inventory] aqui.
## [b]Se vazio:[/b] O componente ignora pedidos de adicionar ou remover itens.
@export var inventory: Inventory

## Ação usada para abrir e fechar o inventário.
## [br]
## [b]Formato:[/b] Use uma ação cadastrada em Project Settings > Input Map.
## [b]Se vazio:[/b] O inventário não será alternado pelo teclado.
@export var toggle_action: StringName = &"open_inventory"

## Define se o inventário começa visível ao entrar na cena.
## [br]
## [b]Detalhes:[/b] Desative para o inventário ficar fechado até apertar a ação configurada.
@export var starts_visible: bool = false

var can_toggle_inventory: bool = true


func _ready() -> void:
	if not inventory:
		return
	
	inventory.item_added.connect(QuestManager.on_item_added)
	QuestManager.current_inventory = inventory
	
	inventory.visible = starts_visible
	if inventory.visible:
		inventory_opened.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not can_toggle_inventory:
		return
	if toggle_action.is_empty():
		return
	if event.is_action_released(toggle_action):
		toggle_inventory()
		if inventory:
			inventory.get_node("Button").visible = inventory.visible


func has_inventory() -> bool:
	return inventory != null


func add_item(item: Item) -> void:
	if not inventory:
		push_warning("InventoryComponent sem Inventory configurado.")
		return
	
	inventory.add_item(item)


func toggle_inventory() -> void:
	if not inventory:
		push_warning("InventoryComponent sem Inventory configurado.")
		return

	if inventory.visible:
		inventory.cancel_selected_item()

	inventory.visible = not inventory.visible
	if inventory.visible:
		inventory_opened.emit()
	else:
		inventory_closed.emit()


func is_inventory_open() -> bool:
	if not inventory:
		return false

	return inventory.visible


func remove_item_at(pos: Vector2i) -> Item:
	if not inventory:
		push_warning("InventoryComponent sem Inventory configurado.")
		return null

	return inventory.remove_item_at(pos)


func get_inventory() -> Inventory:
	return inventory
