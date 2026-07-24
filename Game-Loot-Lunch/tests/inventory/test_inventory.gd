extends Node2D


@onready var inventory_component: InventoryComponent = $Player/InventoryComponent
@onready var inventory: Inventory = $Player/InventoryLayer/Inventory
@onready var carne: Item = $Carne
@onready var carne2: Item = $Carne2
@onready var carne3: Item = $Carne3
@onready var carne4: Item = $Carne4
@onready var carne5: Item = $Carne5
@onready var carne6: Item = $Carne6
@onready var tomate: Item = $Tomate
@onready var sal: Item = $Sal
@onready var selected_cell: Label = $VBoxContainer/SelectedCell
@onready var selected_item: Label = $VBoxContainer/SelectedItem
@onready var selected_pos: Label = $VBoxContainer/SelectedPos
@onready var tutorial: Label = $VBoxContainer/Label


func _ready() -> void:
	tutorial.text = '''
	  Press    I    to    show/hide    Inventory
	  Walk    over    items    to    collect    them
	  Left    click    (stack)    to    pick    1  unit
	  Shift+click    (stack)    to    pick    all
	  Right    click    (stack)    to    split
	  Right    click    (bg)    to    drop    item'''

	# Conecta o pickup de cada item ao inventário do jogador
	for item_node: Item in [carne, carne2, carne3, carne4, carne5, carne6, tomate, sal]:
		item_node.picked_up.connect(inventory_component.add_item)


func _physics_process(_delta: float) -> void:
	if not inventory:
		return
	selected_cell.text = "cell: "+str(inventory.selected_cell)
	selected_item.text = "item: "+str(inventory.selected_item)
	selected_pos.text = "pos: "+str(inventory.selected_pos)


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_released("open_inventory"):
		# O InventoryComponent do player já alterna o inventário dele
		pass

func get_selected_position() -> Array[Vector2i]:
	var result : Array[Vector2i] = []
	for cell : InventoryCell in inventory.grid.get_children():
		if cell.is_selected:
			result.append(inventory.get_pos(cell))
	return result
