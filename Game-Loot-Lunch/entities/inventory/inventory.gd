extends Control
class_name Inventory


const INVENTORY_CELL = preload("uid://b85fxrmr3ribs")


enum ItemAddSource {PICK_UP, SAVE_LOAD, SHOP, CRAFT, NONE}


signal cell_left_clicked(cell : InventoryCell)
signal item_added(item : Item)
signal item_dropped(item : Item)


## Dimensão do inventário, x representando a
## quantidade de colunas e y a quantidade de linhas
@export var dimensions : Vector2i = Vector2i.ONE:
	set = set_dimensions
@export var node_to_drop : Node2D
@export var can_move_items : bool = true
@export var can_drop_items : bool = true


var selected_cell : InventoryCell
## Item físico seguindo o mouse (pickup total / split).
## Fica null quando não há seleção.
var selected_item : Item
## Quantas unidades estamos carregando.
var selected_count : int = 0
var selected_pos : Vector2i:
	get = get_selected_pos
var current_item_added_source : ItemAddSource = ItemAddSource.NONE


@onready var container: PanelContainer = $Container
@onready var grid: GridContainer = $Container/Grid
@onready var crafting_grid: CraftingGrid = $CraftingGrid
@onready var item_added_sfx: AudioStreamPlayer = $ItemAddedSfx


func _ready() -> void:
	dimensions = dimensions
	crafting_grid.inventory = self
	crafting_grid.visible = false
	crafting_grid.visible = not crafting_grid.visible
	item_added.connect(_play_added_item_sfx)


func _process(_delta: float) -> void:
	if GlobalData.current_workbench == Workbench.Type.None:
		crafting_grid.visible = false
	else:
		crafting_grid.visible = true
	if not can_drop_items:
		return
	if not Input.is_action_just_released("right_click"):
		return
	if not selected_cell or not selected_item:
		return
	
	var mouse_global = get_global_mouse_position()
	
	# Verifica se o mouse está sobre alguma célula do CraftingGrid
	if crafting_grid and crafting_grid.visible:
		var sobre_crafting = false
		for craft_cell in crafting_grid.grid_cells:
			var cell_rect = Rect2(craft_cell.global_position, craft_cell.size)
			if cell_rect.has_point(mouse_global):
				sobre_crafting = true
				break
		# Verifica também o result_slot
		if crafting_grid.result_slot:
			var result_rect = Rect2(crafting_grid.result_slot.global_position, crafting_grid.result_slot.size)
			if result_rect.has_point(mouse_global):
				sobre_crafting = true
		
		if sobre_crafting:
			return  # Não dropa sobre o CraftingGrid
	
	# Verifica células do inventário normal
	var on_cell = false
	for cell in grid.get_children():
		var cell_rect = Rect2(cell.global_position, cell.size)
		if cell_rect.has_point(mouse_global):
			on_cell = true
			break
	
	if on_cell:
		return
	
	drop_selected_item()


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
			cell.split_stack.connect(_handle_split_stack)
			grid.add_child(cell)
		call_deferred("remove_empty_cells",grid.get_child_count()-dimensions.x * dimensions.y)


func handle_cell_left_clicked(cell : InventoryCell) -> void:
	cell_left_clicked.emit(cell)
	if can_move_items:
		handle_new_selected_cell(cell)


func _try_merge(source: InventoryCell, target: InventoryCell, src_item: Item, src_count: int) -> bool:
	if not target.item or target.item.item_name != src_item.item_name or not target.is_stackable():
		return false
	var stack_comp = target.item.get_node("StackableComponent")
	if not stack_comp:
		return false
	var space = stack_comp.stack_size - target.count
	if space <= 0:
		return false
	
	var move = min(src_count, space)
	target.count += move
	src_count -= move
	
	if src_count <= 0:
		if source.count <= 0:
			source.item = null
		selected_cell = null
		selected_item = null
		selected_count = 0
		src_item.queue_free()
		return true
	
	selected_count = src_count
	return true


func _place_on_empty(_source: InventoryCell, target: InventoryCell, src_item: Item, src_count: int) -> void:
	target.set_item(src_item)
	target.count = src_count
	
	selected_cell = null
	selected_item = null
	selected_count = 0


func _do_swap(source: InventoryCell, target: InventoryCell, src_item: Item, src_count: int) -> void:
	var tgt_item = target.item
	var tgt_count = target.count

	target.item = src_item
	target.count = src_count
	source.item = tgt_item
	source.count = tgt_count

	if src_item:
		src_item.reparent(target)
		src_item.hide()
		stop_follow_mouse(src_item)
		src_item.position = Vector2.ZERO
	if tgt_item:
		tgt_item.reparent(source)
		tgt_item.hide()
		stop_follow_mouse(tgt_item)
		tgt_item.position = Vector2.ZERO

	selected_cell = null
	selected_item = null
	selected_count = 0


func handle_new_selected_cell(cell : InventoryCell) -> void:
	if not cell:
		set_selected_cell(null)
		return
	
	# Se tem item na mão vindo do CraftingGrid (selected_item existe, selected_cell é null)
	if selected_item and not selected_cell:
		# Célula vazia → coloca
		if not cell.item:
			cell.set_item(selected_item)
			cell.count = selected_count
			_cleanup_selection()
			return
		
		# Célula ocupada → troca: pega item da célula pra mão
		var old_item = cell.item
		var old_count = cell.count
		
		# Coloca item do CraftingGrid na célula
		cell.set_item(null)
		cell.set_item(selected_item)
		cell.count = selected_count
		
		# Item antigo vai pra mão
		selected_item = old_item
		selected_count = old_count
		selected_cell = cell  # Agora o selected_cell é esta célula
		
		# Faz seguir o mouse
		selected_item.reparent(self)
		follow_mouse(selected_item)
		selected_item.show()
		
		return
	
	# Comportamento normal do inventário
	if not selected_cell:
		if not cell.item:
			return
		set_selected_cell(cell)
		return
	
	if selected_cell == cell:
		set_selected_cell(null)
		return
	
	var source = selected_cell
	var src_count = selected_count
	var src_item = selected_item
	
	if not src_item:
		src_item = source.item
	
	if not src_item:
		push_warning("Nothing to place")
		return
	
	if _try_merge(source, cell, src_item, src_count):
		return
	
	if not selected_item:
		set_selected_cell(null)
		return
	
	if not cell.item:
		_place_on_empty(source, cell, src_item, src_count)
		return
	
	if source.count > 0:
		set_selected_cell(null)
		return
	
	_do_swap(source, cell, src_item, src_count)


## Coloca item em célula vazia quando NÃO tem source (item veio do CraftingGrid)
func _place_on_empty_no_source(target: InventoryCell, src_item: Item, src_count: int) -> void:
	target.set_item(src_item)
	target.count = src_count


## Returns an array with the references of all empty cells.
## if 'first' is true, returns as soon as it finds one.
func find_empty_cells(first: bool = false) -> Array[InventoryCell]:
	var result: Array[InventoryCell] = []
	for cell: InventoryCell in grid.get_children():
		if not cell.item and cell.count <= 0:
			result.append(cell)
			if first:
				break
	return result


func remove_empty_cells(max_number: int) -> int:
	if not grid:
		return 0
	if max_number <= 0:
		return 0
	
	var empty_cells: Array[InventoryCell] = find_empty_cells()
	if len(empty_cells) < max_number:
		max_number = len(empty_cells)
	
	for i in max_number:
		empty_cells[i].queue_free()
	return max_number


func handle_wants_item_removed(cell: InventoryCell) -> void:
	if not cell.item:
		return
	
	if not can_drop_items:
		return
	
	if not node_to_drop:
		push_error("No node_to_drop set. Cannot remove item from inventory.")
		return
	
	# Restaura item carregado primeiro
	_restore_selected()
	
	var item: Item = remove_item_at(get_pos(cell))
	if not item:
		return
	# Reparenta pro mundo antes de setar posição (remove_item usa deferred)
	item.reparent(get_tree().current_scene)
	item.global_position = node_to_drop.global_position
	item.dropped_count = 1
	_disable_pickup_temporarily(item)


func add_item(item: Item, source : ItemAddSource = ItemAddSource.PICK_UP) -> void:
	print(ItemAddSource.find_key(source))
	if not item:
		return
	
	current_item_added_source = source
	# Se tem item carregado, restaura antes pra não duplicar
	_restore_selected()
	item.interactable_area.enabled = false
	var amount = max(1, item.dropped_count)
	item.dropped_count = 1  # reseta pro padrão
	var stack_comp = item.get_node_or_null("StackableComponent")
	
	if stack_comp:
		var stack_size = stack_comp.stack_size
		# Empilha em células existentes do mesmo tipo
		for cell: InventoryCell in grid.get_children():
			if not cell.item or cell.item.item_name != item.item_name:
				continue
			var space = stack_size - cell.count
			if space <= 0:
				continue
			var move = min(amount, space)
			cell.count += move
			amount -= move
			if amount <= 0:
				item.queue_free()
				item_added.emit(item)
				return
		# Coloca o resto em célula vazia
		if amount > 0:
			var empty = find_empty_cells(true)
			if empty.is_empty():
				push_warning("Inventory is full!")
				item.queue_free()
				return
			var cell = empty[0]
			cell.set_item(item)
			cell.count = amount
	else:
		# Não stackável
		var empty = find_empty_cells(true)
		if empty.is_empty():
			push_warning("Inventory is full!")
			return
		var cell = empty[0]
		cell.set_item(item)
		cell.count = 1
	item_added.emit(item)


func _play_added_item_sfx(_item : Item) -> void:
	match current_item_added_source:
		ItemAddSource.PICK_UP, ItemAddSource.CRAFT:
			item_added_sfx.play()
	current_item_added_source = ItemAddSource.NONE


func cancel_selected_item() -> void:
	if selected_cell:
		handle_new_selected_cell(null)


func drop_selected_item() -> void:
	if not selected_cell:
		return
	
	if not selected_item:
		return
	
	if not node_to_drop:
		push_error("No node_to_drop set. Cannot drop item.")
		_restore_selected()
		return
	
	var drop_pos := node_to_drop.global_position
	
	if selected_cell.item:
		# Duplicado (pickup parcial / split): dropa no mundo
		selected_item.reparent(get_tree().current_scene)
		selected_item.global_position = drop_pos
	else:
		# Item real (pickup total): reposiciona no mundo
		selected_item.reparent(get_tree().current_scene)
		selected_item.global_position = drop_pos
		selected_item.show()
	
	selected_item.dropped_count = selected_count
	
	stop_follow_mouse(selected_item)
	_disable_pickup_temporarily(selected_item)
	_cleanup_selection()
	item_dropped.emit()


func _cleanup_selection() -> void:
	selected_cell = null
	selected_item = null
	selected_count = 0


## Desativa o pickup do item dropped por 0.5s pra evitar
## que o player pegue ele de volta imediatamente.
func _disable_pickup_temporarily(item: Item) -> void:
	if not item or not item.interactable_area:
		return
	item.interactable_area.monitoring = false
	var timer := get_tree().create_timer(0.5)
	timer.timeout.connect(_make_dropped_item_pickupable.bind(item), CONNECT_ONE_SHOT)


func _make_dropped_item_pickupable(item: Item) -> void:
	if is_instance_valid(item) and item.interactable_area:
		item.interactable_area.monitoring = true
		item.interactable_area.enabled = true



## Restaura o item carregado (se houver) para a célula de origem.
func _restore_selected() -> void:
	if not selected_cell:
		return
	if selected_item:
		if selected_cell.item:
			selected_cell.count += selected_count
			selected_item.queue_free()
		else:
			selected_cell.set_item(selected_item)
			selected_cell.count = selected_count
	selected_cell = null
	selected_item = null
	selected_count = 0


func set_selected_cell(value: InventoryCell) -> void:
	if selected_cell:
		_restore_selected()
	
	# NOVO: Se tem item na mão mas sem selected_cell (veio do CraftingGrid)
	# e clicou em outra célula, restaura o item do CraftingGrid primeiro
	if selected_item and not selected_cell:
		if value and value.item:
			# Célula tem item - troca: devolve o do CraftingGrid, pega o novo
			pass  # Deixa o fluxo normal seguir
		elif not value or not value.item:
			# Célula vazia - coloca o item do CraftingGrid nela
			return  # Não pega novo item
	
	selected_cell = value
	if not selected_cell:
		selected_item = null
		return
	
	if not selected_cell.item:
		selected_item = null
		return
	
	var is_stackable = selected_cell.is_stackable()
	var cell_count = selected_cell.count
	
	if is_stackable and cell_count > 1 and not Input.is_key_pressed(KEY_SHIFT):
		selected_count = 1
		selected_cell.count -= 1
		selected_item = selected_cell.item.duplicate()
		add_child(selected_item)
		selected_item.show()
		follow_mouse(selected_item)
	else:
		selected_count = cell_count
		selected_cell.count = 0
		selected_item = selected_cell.remove_item(self, true, true)
		if selected_item:
			follow_mouse(selected_item)


func _handle_split_stack(cell: InventoryCell, half: int) -> void:
	if not cell.item:
		return
	if half <= 0 or half >= cell.count:
		return
	
	# Restaura item carregado primeiro
	_restore_selected()
	
	# Split: duplica o Item, original fica na célula
	var new_item = cell.item.duplicate()
	add_child(new_item)
	new_item.show()
	
	cell.count -= half
	
	selected_item = new_item
	selected_cell = cell
	selected_count = half
	
	if selected_item:
		follow_mouse(selected_item)


func follow_mouse(item : Item) -> void:
	item.interactable_area.enabled = false
	item.top_level = true
	item.z_index = 100
	item.force_follow_mouse()


func stop_follow_mouse(item : Item) -> void:
	item.top_level = false
	item.z_index = 0
	item.force_stop_follow_mouse()


func get_selected_pos() -> Vector2i:
	if selected_cell:
		selected_pos = get_pos(selected_cell)
	else:
		selected_pos = Vector2i.MIN
	return selected_pos


func has_item(item_name : String) -> bool:
	if not item_name:
		push_error("There is no item_name to check with ",self.name,".has_item()")
	
	return count(item_name) != 0


func count(item_name : String) -> int:
	if not item_name:
		push_error("There is no item_name to check with ",self.name,".has_item()")
	
	var result : int = 0
	for cell: InventoryCell in grid.get_children():
		if cell.item and item_name == cell.item.item_name:
			result += 1
	return result


func get_cell(pos: Vector2i) -> InventoryCell:
	if pos.x >= dimensions.x or pos.y >= dimensions.y:
		push_error("Position " + str(pos) + " outside of Inventory's dimensions")
		return null
	return grid.get_child(pos.x * dimensions.y + pos.y)


func get_pos(cell: InventoryCell) -> Vector2i:
	var pos: int = grid.get_children().find(cell)
	if pos == -1:
		return Vector2i.MIN
	return Vector2i(pos / dimensions.x, pos % dimensions.y)


func remove_item_at(pos: Vector2i) -> Item:
	var cell: InventoryCell = get_cell(pos)
	if not cell:
		return null
	var item: Item = cell.remove_item()
	if not item:
		push_warning("At pos " + str(pos) + ": ")
		return null
	return item


func print_inventory_cells() -> void:
	for cell: InventoryCell in grid.get_children():
		print(cell.get_children())
