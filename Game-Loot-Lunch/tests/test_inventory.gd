extends Node2D


@onready var inventory: Inventory = $CanvasLayer/Inventory
@onready var carne: Item = $Carne
@onready var tomate: Item = $Tomate
@onready var farinha: Item = $Farinha 
@onready var selected_cell: Label = $VBoxContainer/SelectedCell
@onready var selected_item: Label = $VBoxContainer/SelectedItem
@onready var selected_pos: Label = $VBoxContainer/SelectedPos
@onready var selected_positions: Label = $VBoxContainer/SelectedPositions


func _ready() -> void:
	carne.connect("picked_up",inventory.add_item)
	tomate.connect("picked_up",inventory.add_item)
	farinha.connect("picked_up",inventory.add_item)
	'''inventory.add_item(carne)
	inventory.add_item(tomate)
	inventory.add_item(farinha)
	print("root:\n",get_children(),"\n-----------")
	print("grid:")
	inventory.print_inventory_cells()
	print("\n-----------")
	await get_tree().create_timer(5).timeout
	inventory.remove_item_at(Vector2i.RIGHT).force_follow_mouse()
	print(get_children())
	inventory.print_inventory_cells()'''


func _physics_process(_delta: float) -> void:
	if not inventory:
		return
	selected_cell.text = "cell: "+str(inventory.selected_cell)
	selected_item.text = "item: "+str(inventory.selected_item)
	selected_pos.text = "pos: "+str(inventory.selected_pos)
	selected_positions.text = "positions set as selected:\n"+str(get_selected_position())


func _input(event: InputEvent) -> void:
	if Input.is_action_just_released("open_inventory"):
		inventory.visible = not inventory.visible

func get_selected_position() -> Array[Vector2i]:
	var result : Array[Vector2i] = []
	for cell : InventoryCell in inventory.grid.get_children():
		if cell.is_selected:
			result.append(inventory.get_pos(cell))
	return result
