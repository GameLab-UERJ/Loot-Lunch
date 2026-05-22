extends Control
class_name Inventory


const INVENTORY_CELL = preload("uid://b85fxrmr3ribs")

## Dimensão do inventário, x representando a
## quantidade de colunas e y a quantidade de linhas
@export var dimensions : Vector2i = Vector2i.ONE:
	set = set_dimensions


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
			cell.selected.connect(handle_new_selected_cell)
			grid.add_child(cell)
		call_deferred("remove_empty_cells",grid.get_child_count()-dimensions.x * dimensions.y)


## Returns an array with the references of all empty cells
## [br]
## if 'first' is true, returns as soon as it finds one
func find_empty_cells(first : bool = false) -> Array[InventoryCell]:
	var result : Array[InventoryCell] = []
	for cell : InventoryCell in grid.get_children():
		if cell.is_empty():
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
	selected_cell.is_selected = false
	cell.is_selected = false
	selected_cell = null
	selected_item = null


func get_cell(pos : Vector2i) -> InventoryCell:
	if pos.x >= dimensions.x or pos.y >= dimensions.y:
		push_error("Position "+str(pos)+" outside of Inventory's dimensions") 
		return null
	return grid.get_child(pos.y*dimensions.x + pos.x)


func get_pos(cell : InventoryCell) -> Vector2i:
	var pos : int = grid.get_children().find(cell)
	if pos == -1:
		return Vector2i.MIN
	return Vector2i(pos/dimensions.x, pos%dimensions.y)


func add_item(item : Item) -> void:
	var cell : InventoryCell = find_empty_cells(true)[0]
	cell.set_item(item)


func remove_item_at(pos : Vector2i) -> Item:
	var cell : InventoryCell = get_cell(pos)
	if not cell:
		return null
	var item : Item = cell.remove_item()
	if not item:
		push_warning("At pos " + str(pos) + ": ")
		return null
	return item


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
		selected_item = selected_cell.remove_item()
		selected_item.force_follow_mouse()
		pass


func get_selected_pos() -> Vector2i:
	if selected_cell:
		selected_pos = get_pos(selected_cell)
	else:
		selected_pos = Vector2i.MIN
	return selected_pos


func print_inventory_cells() -> void:
	for cell : InventoryCell in grid.get_children():
		print(cell.get_children())
