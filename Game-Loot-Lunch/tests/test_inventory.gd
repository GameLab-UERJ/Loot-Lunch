extends Node2D


@onready var inventory_cell: InventoryCell = $InventoryCell
@onready var carne: Item = $Carne
@onready var tomate: Item = $Tomate


func _on_add_tomate_down() -> void:
	var item : Item = inventory_cell.set_item(tomate)
	tomate.visible = false
	if item:
		item.visible = true


func _on_add_carne_down() -> void:
	var item : Item = inventory_cell.set_item(carne)
	carne.visible = false
	if item:
		item.visible = true


func _on_remove_down() -> void:
	var item : Item = inventory_cell.remove_item()
	item.visible = true
