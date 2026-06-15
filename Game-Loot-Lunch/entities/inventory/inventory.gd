extends Control
class_name Inventory


const INVENTORY_CELL = preload("uid://b85fxrmr3ribs")


signal cell_left_clicked(cell : InventoryCell)


## Dimensão do inventário, x representando a
## quantidade de colunas e y a quantidade de linhas
@export var dimensions : Vector2i = Vector2i.ONE:
	set = set_dimensions
	
## Representá o nó a ser usado como base para dropar itens.
## Em geral, uma [Marker2D] seria o melhor mas pode usar algo como o [Player],
## por exemplo.
@export var node_to_drop : Node2D

@export var can_move_items : bool = true


var selected_cell : InventoryCell
var selected_item : Item
var selected_pos : Vector2i:
	get = get_selected_pos


@onready var container: PanelContainer = $Container
@onready var grid: GridContainer = $Container/Grid


func _ready() -> void:
	dimensions = dimensions


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if not selected_cell:
		return
	
	if event.is_action_released("right_click"):
		if selected_cell:
			handle_new_selected_cell(null)

func set_dimensions(value : Vector2i) -> void:
	if not value or not(value.x != 0 and value.y != 0):
		push_error("Dimension of Inventory can't have zero rows or columns")
		return
	dimensions = value
	
	var cell : InventoryCell
	if grid:
		grid.columns = dimensions.x
		for i in range(grid.get_child_count(),dimensions.x * dimensions.y):
			cell = INVENTORY_CELL.instantiate()
			cell.left_clicked.connect(handle_cell_left_clicked)
			cell.wants_item_removed.connect(handle_wants_item_removed)
			grid.add_child(cell)
		call_deferred("remove_empty_cells",grid.get_child_count()-dimensions.x * dimensions.y)


func handle_cell_left_clicked(cell : InventoryCell) -> void:
	cell_left_clicked.emit(cell)
	if can_move_items:
		handle_new_selected_cell(cell)


## Returns an array with the references of all empty cells
## [br]
## if 'first' is true, returns as soon as it finds one
func find_empty_cells(first : bool = false) -> Array[InventoryCell]:
	var result : Array[InventoryCell] = []
	for cell : InventoryCell in grid.get_children():
		if not cell.item:
			result.append(cell)
			if first:
				break
	return result


## returns the amount of empty cells removed.
func remove_empty_cells(max_number : int) -> int:
	if not grid:
		return 0
	if max_number <= 0:
		return 0
	
	var empty_cells : Array[InventoryCell] = find_empty_cells()
	if len(empty_cells) < max_number:
		max_number = len(empty_cells)
	
	for i in max_number:
		empty_cells[i].queue_free()
	return max_number


func handle_wants_item_removed(cell : InventoryCell) -> void:
	if selected_cell or not cell.item:
		return
	
	var item : Item = remove_item_at(get_pos(cell))
	if node_to_drop:
		item.global_position = node_to_drop.global_position
	else:
		push_error("Node where to drop items is not set. Dropped at position zero of ",item.get_parent())

func handle_new_selected_cell(cell : InventoryCell) -> void:
	if not cell:
		set_selected_cell(null)
		return
	
	if not selected_cell:
		if not cell.item:
			cell.is_selected = false
			return
		set_selected_cell(cell)
		return
	
	if selected_cell == cell:
		handle_new_selected_cell(null)
		return
		
	selected_cell.item = cell.item
	cell.item = selected_item

	cell.is_selected = false
	selected_cell.is_selected = false
	selected_cell = null
	selected_item = null


func add_item(item : Item) -> void:
	var cell : InventoryCell = find_empty_cells(true)[0]
	cell.set_item(item)


func remove_item() -> Item:
	if not selected_cell or not selected_cell.item:
		return null
	return null


func cancel_selected_item() -> void:
	if selected_cell:
		handle_new_selected_cell(null)


func set_selected_cell(value : InventoryCell) -> void:
	if selected_cell:
		selected_cell.is_selected = false
		selected_cell.set_item(selected_item)
		selected_item = null
	selected_cell = value
	if not selected_cell:
		selected_item = null
		return
	if selected_cell.item:
		selected_item = selected_cell.remove_item(self)
		selected_item.top_level = true
		selected_item.z_index = 100
		selected_item.force_follow_mouse()
		pass


func get_selected_pos() -> Vector2i:
	if selected_cell:
		selected_pos = get_pos(selected_cell)
	else:
		selected_pos = Vector2i.MIN
	return selected_pos


# TODO all those functions should be in a InventoryGrid class to modularize.

func get_cell(pos : Vector2i) -> InventoryCell:
	if pos.x >= dimensions.x or pos.y >= dimensions.y:
		push_error("Position "+str(pos)+" outside of Inventory's dimensions") 
		return null
	return grid.get_child(pos.x*dimensions.y + pos.y)


func get_pos(cell : InventoryCell) -> Vector2i:
	var pos : int = grid.get_children().find(cell)
	if pos == -1:
		return Vector2i.MIN
	return Vector2i(pos/dimensions.x, pos%dimensions.y)


func remove_item_at(pos : Vector2i) -> Item:
	var cell : InventoryCell = get_cell(pos)
	if not cell:
		return null
	var item : Item = cell.remove_item()
	if not item:
		push_warning("At pos " + str(pos) + ": ")
		return null
	return item


func print_inventory_cells() -> void:
	for cell : InventoryCell in grid.get_children():
		print(cell.get_children())
