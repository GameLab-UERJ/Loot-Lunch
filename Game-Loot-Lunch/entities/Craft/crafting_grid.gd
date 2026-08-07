extends HBoxContainer
class_name CraftingGrid


signal craft_completed(result_item: Item)


@export var inventory: Inventory
@export var recipes: Array[Recipe] = []

const INVENTORY_CELL = preload("uid://b85fxrmr3ribs")

var grid_cells: Array[InventoryCell] = []
var current_recipe: Recipe
var result_slot: InventoryCell

@onready var grid_container: GridContainer = $GridContainer3x3


func _ready() -> void:
	_create_grid()
	_create_result_slot()


func _create_grid() -> void:
	grid_container.columns = 3
	
	for i in range(9):
		var cell := INVENTORY_CELL.instantiate()
		cell.can_receive_items = true
		cell.can_remove_items = true
		cell.gui_input.connect(_on_grid_cell_gui_input.bind(i))
		cell.wants_item_removed.connect(_on_item_removed.bind(i))
		grid_container.add_child(cell)
		grid_cells.append(cell)


func _create_result_slot() -> void:
	result_slot = INVENTORY_CELL.instantiate()
	result_slot.can_receive_items = false
	result_slot.can_remove_items = true
	result_slot.gui_input.connect(_on_result_gui_input)
	result_slot.name = "ResultSlot"
	add_child(result_slot)


func _on_grid_cell_gui_input(event: InputEvent, index: int) -> void:
	if not event.is_action_released("left_click"):
		return
	
	var cell = grid_cells[index]
	
	if inventory.selected_item:
		# Tem item na mão → coloca na célula
		if cell.item:
			# Devolve item existente ao inventário
			var old_item = cell.item
			var old_count = cell.count
			cell.set_item(null)
			old_item.dropped_count = old_count
			inventory.add_item(old_item)
		
		cell.set_item(inventory.selected_item)
		cell.count = inventory.selected_count
		
		inventory._cleanup_selection()
		if inventory.selected_cell:
			inventory.selected_cell.is_selected = false
			inventory.selected_cell = null
		
		_validate_recipe()
		accept_event()
	else:
		# Nada na mão → pega item da célula
		if cell.item:
			_pickup_from_grid(cell)
			accept_event()


func _pickup_from_grid(cell: InventoryCell) -> void:
	if not cell.item:
		return
	
	# Usa o MESMO sistema do Inventory
	# Define esta célula como selected_cell do inventário
	inventory.selected_cell = cell
	inventory.set_selected_cell(cell)
	
	_validate_recipe()


func _on_result_gui_input(event: InputEvent) -> void:
	if not event.is_action_released("left_click"):
		return
	
	if not current_recipe or not result_slot.item:
		return
	
	# Remove ingredientes do grid
	for grid_cell in grid_cells:
		if grid_cell.item:
			grid_cell.item.queue_free()
			grid_cell.set_item(null)
	
	# Pega o resultado
	var result_item := result_slot.item
	result_slot.set_item(null)
	
	# Adiciona ao inventário
	result_item.dropped_count = current_recipe.result_count
	inventory.add_item(result_item)
	
	craft_completed.emit(result_item)
	current_recipe = null


func _on_item_removed(cell: InventoryCell, _index: int) -> void:
	if cell.item:
		inventory.add_item(cell.item)
		cell.set_item(null)
	_validate_recipe()


func _validate_recipe() -> void:
	if result_slot.item:
		result_slot.item.queue_free()
		result_slot.set_item(null)
	
	current_recipe = null
	
	# Monta array com os itens atuais
	var current_items: Array[Item] = []
	for cell in grid_cells:
		current_items.append(cell.item)
	
	# Debug: mostra o que tem no grid
	print("=== Validando receita ===")
	for i in range(9):
		if grid_cells[i].item:
			print("  Slot ", i, ": ", grid_cells[i].item.item_name)
		else:
			print("  Slot ", i, ": vazio")
	
	print("  Recipes disponíveis: ", recipes.size())
	
	for recipe in recipes:
		print("  Testando receita: ", recipe.recipe_name)
		if recipe.matches(current_items):
			current_recipe = recipe
			var result_item := recipe.result_scene.instantiate() as Item
			result_slot.set_item(result_item)
			result_slot.count = recipe.result_count
			print("  >>> RECEITA ENCONTRADA: ", recipe.recipe_name)
			return
	
	print("  >>> Nenhuma receita encontrada")
