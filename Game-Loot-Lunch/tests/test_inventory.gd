extends Node2D


@onready var inventory: Inventory = $CanvasLayer/Inventory
@onready var carne: Item = $Carne
@onready var tomate: Item = $Tomate
@onready var farinha: Item = $Farinha


func _ready() -> void:
	inventory.add_item(carne)
	inventory.add_item(tomate)
	inventory.add_item(farinha)
	'''print("root:\n",get_children(),"\n-----------")
	print("grid:")
	inventory.print_inventory_cells()
	print("\n-----------")
	await get_tree().create_timer(5).timeout
	inventory.remove_item_at(Vector2i.RIGHT).force_follow_mouse()
	print(get_children())
	inventory.print_inventory_cells()'''
	
