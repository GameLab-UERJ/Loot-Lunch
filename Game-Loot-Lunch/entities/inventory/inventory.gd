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
## Quantas unidades do item estão atualmente selecionadas/seguindo o mouse.
## Para não-stackáveis ou full-stack, = cell.count original.
## Para pick-up parcial (1 unidade de um stack), = 1.
var selected_count : int = 0
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


## Lida com o drop do item selecionado em uma célula alvo.
## Três casos: merge (mesmo tipo stackável), mover (vazia), swap (tipo diferente).
func _swap_or_merge(source: InventoryCell, target: InventoryCell) -> void:
	if not selected_item:
		return
	
	var src_item: Item = selected_item
	var src_count: int = selected_count
	
	# Caso 1: Merge — mesmo tipo, stackável, com espaço
	if target.item and target.item.item_name == src_item.item_name and target.is_stackable():
		var stack_comp = target.item.get_node("StackableComponent")
		if stack_comp:
			var space = stack_comp.stack_size - target.count
			if space > 0:
				var move = min(src_count, space)
				target.count += move
				src_count -= move
				
				if src_count <= 0:
					if source.count <= 0:
						source.item = null
					source.is_selected = false
					selected_cell = null
					selected_item = null
					selected_count = 0
					src_item.queue_free()
					return
				else:
					selected_count = src_count
					source.is_selected = false
					return
	
	# Caso 2: Célula vazia — move o item
	if not target.item:
		target.set_item(src_item)
		target.count = src_count
		
		if source.count <= 0:
			source.item = null
		
		source.is_selected = false
		selected_cell = null
		selected_item = null
		selected_count = 0
		return
	
	# Caso 3: Swap — tipos diferentes
	# Se a source ainda tem unidades virtuais (pick-up parcial),
	# não dá pra fazer swap limpo — retorna o carry pra source.
	if source.count > 0:
		set_selected_cell(null)
		return
	
	var tgt_item: Item = target.item
	var tgt_count: int = target.count
	
	target.item = src_item
	target.count = src_count
	source.item = tgt_item
	source.count = tgt_count
	
	source.is_selected = false
	target.is_selected = false
	selected_cell = null
	selected_item = null
	selected_count = 0


## Returns an array with the references of all empty cells
## [br]
## if 'first' is true, returns as soon as it finds one
func find_empty_cells(first : bool = false) -> Array[InventoryCell]:
	var result : Array[InventoryCell] = []
	for cell : InventoryCell in grid.get_children():
		if not cell.item and cell.count <= 0:
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
		# Chamado com null = cancelar/deselect (retorna item pra célula)
		set_selected_cell(null)
		return
	
	if not selected_cell:
		# Nada selecionado ainda — tenta selecionar esta célula
		if not cell.item:
			cell.is_selected = false
			return
		set_selected_cell(cell)
		return
	
	if selected_cell == cell:
		# Clicou na mesma célula = deselect (retorna o item)
		set_selected_cell(null)
		return
	
	# Tem um item selecionado e clicou em outra célula
	_swap_or_merge(selected_cell, cell)


## Adiciona um Item ao inventário.
## Se o item for stackável, tenta empilhar em células existentes
## do mesmo tipo antes de colocar numa célula vazia.
func add_item(item : Item) -> void:
	if not item:
		return
	
	var stack_comp = item.get_node("StackableComponent") if item.has_node("StackableComponent") else null
	
	if stack_comp:
		# Tenta empilhar em célula existente do mesmo tipo
		for cell: InventoryCell in grid.get_children():
			if cell.item and cell.item.item_name == item.item_name and cell.count < stack_comp.stack_size:
				cell.count += 1
				item.queue_free()
				return
	
	# Se não conseguiu empilhar, coloca em célula vazia
	var empty = find_empty_cells(true)
	if empty.is_empty():
		push_warning("Inventory is full!")
		return
	var cell = empty[0]
	cell.set_item(item)
	cell.count = 1


func remove_item() -> Item:
	if not selected_cell or not selected_cell.item:
		return null
	return null


## Cancela a seleção e retorna o item para a célula de origem.
func cancel_selected_item() -> void:
	if selected_cell:
		handle_new_selected_cell(null)


## Remove o item selecionado do inventário e dropa no node_to_drop.
func drop_selected_item() -> void:
	if not selected_cell or not selected_item:
		return
	
	selected_cell.is_selected = false
	
	if node_to_drop:
		selected_item.global_position = node_to_drop.global_position
	selected_item.show()
	selected_item.force_stop_follow_mouse()
	selected_item.top_level = false
	selected_item.z_index = 0
	
	selected_cell = null
	selected_item = null
	selected_count = 0


func set_selected_cell(value : InventoryCell) -> void:
	# Devolve item da célula anterior (se houver)
	if selected_cell:
		selected_cell.is_selected = false
		if selected_item:
			var remaining: int = selected_cell.count
			selected_cell.set_item(selected_item)
			selected_cell.count = remaining + selected_count
			selected_item = null
		selected_count = 0
	
	selected_cell = value
	if not selected_cell:
		selected_item = null
		return
	
	# Pega o item da nova célula
	if not selected_cell.item:
		selected_item = null
		return
	
	var is_stackable = selected_cell.is_stackable()
	var cell_count = selected_cell.count
	
	# Se for stackável, count > 1 e NÃO segurou Shift → pega só 1 unidade
	if is_stackable and cell_count > 1 and not Input.is_key_pressed(KEY_SHIFT):
		selected_count = 1
		selected_cell.count -= 1
		selected_item = selected_cell.remove_item_for_stack(self)
	else:
		# Pega o stack inteiro
		selected_count = cell_count
		selected_cell.count = 0
		selected_item = selected_cell.remove_item(self)
	
	if selected_item:
		selected_item.top_level = true
		selected_item.z_index = 100
		selected_item.force_follow_mouse()


func _handle_split_stack(cell: InventoryCell, half: int) -> void:
	if selected_cell or not cell.item:
		return
	if half <= 0 or half >= cell.count:
		return
	
	cell.count -= half
	
	# Pega o Item da célula e carrega metade do stack
	selected_item = cell.remove_item_for_stack(self)
	selected_cell = cell
	selected_count = half
	
	if selected_item:
		selected_item.top_level = true
		selected_item.z_index = 100
		selected_item.force_follow_mouse()


func get_selected_pos() -> Vector2i:
	if selected_cell:
		selected_pos = get_pos(selected_cell)
	else:
		selected_pos = Vector2i.MIN
	return selected_pos


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
