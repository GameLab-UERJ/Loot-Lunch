extends Control
class_name Inventory


const INVENTORY_CELL = preload("uid://b85fxrmr3ribs")

## Dimensão do inventário, x representando a
## quantidade de colunas e y a quantidade de linhas
@export var dimensions : Vector2i = Vector2i.ONE:
	set = set_dimensions


var selected_cells : Array[InventoryCell] = []


@onready var container: PanelContainer = $Container
@onready var grid: GridContainer = $Container/Grid


func _ready() -> void:
	dimensions = dimensions


func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var mouse_event : InputEventMouseButton = event
	if mouse_event.is_action_released("right_click"):
		for cell : InventoryCell in selected_cells:
			cell.is_selected = false
			remove_from_selected_cells(cell)


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
			cell.selected.connect(add_to_selected_cells)
			cell.unselected.connect(remove_from_selected_cells)
			grid.add_child(cell)
		call_deferred("remove_empty_cells",grid.get_child_count()-dimensions.x * dimensions.y)


func add_to_selected_cells(cell : InventoryCell) -> void:
	selected_cells.append(cell)


func remove_from_selected_cells(cell : InventoryCell) -> void:
	selected_cells.erase(cell)


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


func get_cell(pos : Vector2i) -> InventoryCell:
	if pos.x >= dimensions.x or pos.y >= dimensions.y:
		push_error("Position "+str(pos)+" outside of Inventory's dimensions") 
		return null
	return grid.get_child(pos.y*dimensions.x + pos.x)


func add_item(item : Item) -> void:
	print('item to be added: ',item)
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
	item.show()
	return item


func print_inventory_cells() -> void:
	for cell : InventoryCell in grid.get_children():
		print(cell.get_children())
