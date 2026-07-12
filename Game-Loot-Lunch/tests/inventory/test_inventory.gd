extends Node2D


@onready var inventory: Inventory = $CanvasLayer/Inventory
@onready var carne: Item = $Carne
@onready var carne2: Item = $Carne2
@onready var carne3: Item = $Carne3
@onready var carne4: Item = $Carne4
@onready var carne5: Item = $Carne5
@onready var carne6: Item = $Carne6
@onready var tomate: Item = $Tomate
@onready var selected_cell: Label = $VBoxContainer/SelectedCell
@onready var selected_item: Label = $VBoxContainer/SelectedItem
@onready var selected_pos: Label = $VBoxContainer/SelectedPos
@onready var tutorial: Label = $VBoxContainer/Label


func _ready() -> void:
	tutorial.text = '''
	  Press    I    to    show/hide    Inventory
	  Left    click    (stack)    to    pick    1  unit
	  Shift+click    (stack)    to    pick    all
	  Right    click    (stack)    to    split
	  Right    click    (bg)    to    drop    item'''

	# Adiciona 6 Carnes e 1 Tomate automaticamente
	# As primeiras 5 carnes empilham na mesma célula (stack_size=5)
	# A 6ª vai pra outra célula; o Tomate vai pra uma terceira.
	inventory.add_item(carne)
	inventory.add_item(carne2)
	inventory.add_item(carne3)
	inventory.add_item(carne4)
	inventory.add_item(carne5)
	inventory.add_item(carne6)
	inventory.add_item(tomate)


func _physics_process(_delta: float) -> void:
	if not inventory:
		return
	selected_cell.text = "cell: "+str(inventory.selected_cell)
	selected_item.text = "item: "+str(inventory.selected_item)
	selected_pos.text = "pos: "+str(inventory.selected_pos)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_released("open_inventory"):
		inventory.visible = not inventory.visible

func get_selected_position() -> Array[Vector2i]:
	var result : Array[Vector2i] = []
	for cell : InventoryCell in inventory.grid.get_children():
		if cell.is_selected:
			result.append(inventory.get_pos(cell))
	return result
