extends Control
class_name Inventory


const INVENTORY_CELL = preload("uid://b85fxrmr3ribs")

## Dimensão do inventário, x representando a
## quantidade de colunas e y a quantidade de linhas
@export var dimensions : Vector2i = Vector2i.ONE:
	set = set_dimensions


@onready var container: PanelContainer = $Container
@onready var grid: GridContainer = $Container/Grid


func _ready() -> void:
	dimensions = dimensions


func set_dimensions(value : Vector2i) -> void:
	if not value or not(value.x != 0 and value.y != 0):
		push_error("Dimension of Inventory can't have zero rows or columns")
		return
	dimensions = value
	
	if grid:
		grid.columns = dimensions.x
		for cell in range(grid.get_child_count(),dimensions.x * dimensions.y):
			grid.add_child(INVENTORY_CELL.instantiate())
		call_deferred("remove_empty_cells",grid.get_child_count()-dimensions.x * dimensions.y)
		#while dimensions.x * dimensions.y < grid.get_child_count():
		#	grid.get_child(0).queue_free()


## Returns an array with the references of all empty cells
func find_empty_cells() -> Array[InventoryCell]:
	var result : Array[InventoryCell] = []
	for cell : InventoryCell in grid.get_children():
		if cell.is_empty():
			result.append(cell)
	return result


## returns the amount of empty cells removed.
func remove_empty_cells(max_number : int) -> int:
	if not grid:
		return 0
	if max_number <= 0:
		push_warning("max_number must be positive for remove_empty_cells to have effect ("+str(max_number)+")")
		return 0
	
	var empty_cells : Array[InventoryCell] = find_empty_cells()
	if len(empty_cells) < max_number:
		max_number = len(empty_cells)
	
	for i in max_number:
		empty_cells[i].queue_free()
	return max_number
