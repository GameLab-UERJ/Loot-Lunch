class_name ShopMenu
extends Control


signal shop_opened
signal shop_closed


@onready var gold_label: Label = $Panel/VBoxContainer/GoldLabel
@onready var message_label: Label = $Panel/VBoxContainer/MessageLabel

@onready var buy_button: Button = $Panel/VBoxContainer/Buttons/BuyButton
@onready var sell_button: Button = $Panel/VBoxContainer/Buttons/SellButton
@onready var exit_button: Button = $Panel/VBoxContainer/Buttons/ExitButton

@onready var player_inventory: Inventory = $Panel/VBoxContainer/Inventories/PlayerBox/PlayerInventory
@onready var transfer_inventory: Inventory = $Panel/VBoxContainer/Inventories/TransferBox/TransferInventory
@onready var shop_inventory: Inventory = $Panel/VBoxContainer/Inventories/ShopBox/ShopInventory

var current_shop: ShopComponent
var real_player_inventory: Inventory
var player_item_copies: Dictionary[Item, Item] = {}
var sell_items: Dictionary[Item, Item] = {}
var transfer_item_prices: Dictionary[Item, int] = {}

enum ShopMode {
	NONE,
	BUY,
	SELL
}

var mode: ShopMode = ShopMode.NONE
var total_price: int = 0

func _ready() -> void:
	visible = false
	PlayerWallet.gold_changed.connect(update_gold_label)
	update_gold_label(PlayerWallet.gold)


func update_gold_label(new_gold: int) -> void:
	gold_label.text = "Gold Atual: " + str(new_gold)


func open_shop(shop: ShopComponent, inventory: Inventory) -> void:
	current_shop = shop
	real_player_inventory = inventory

	visible = true
	message_label.text = ""
	fill_player_inventory()
	fill_shop_inventory()
	clear_transfer()

	for inv: Inventory in [player_inventory, shop_inventory, transfer_inventory]:
		for cell: InventoryCell in inv.grid.get_children():
			if cell.split_stack.is_connected(inv._handle_split_stack):
				cell.split_stack.disconnect(inv._handle_split_stack)
			if cell.wants_item_removed.is_connected(inv.handle_wants_item_removed):
				cell.wants_item_removed.disconnect(inv.handle_wants_item_removed)
			if inv == player_inventory:
				if not cell.split_stack.is_connected(_on_player_cell_split_stack):
					cell.split_stack.connect(_on_player_cell_split_stack)
				if not cell.wants_item_removed.is_connected(_on_player_cell_wants_remove):
					cell.wants_item_removed.connect(_on_player_cell_wants_remove)

	shop_opened.emit()

func close_shop() -> void:
	clear_transfer()

	clear_inventory(player_inventory)

	visible = false
	shop_closed.emit()

func _on_exit_button_pressed() -> void:
	close_shop()


func clear_inventory(inventory: Inventory) -> void:
	for cell: InventoryCell in inventory.grid.get_children():
		if cell.item:
			cell.remove_item().queue_free()


func fill_shop_inventory() -> void:
	clear_inventory(shop_inventory)
	
	if not current_shop:
		return
		
	for item_scene: PackedScene in current_shop.get_item_scenes():
		var item: Item = current_shop.create_item(item_scene)
		add_child(item)
		shop_inventory.add_item(item)
		set_item_price_text(shop_inventory, item, current_shop.get_price(item_scene), Color.GREEN)


func fill_player_inventory() -> void:
	clear_inventory(player_inventory)
	player_item_copies.clear()

	if not real_player_inventory:
		return

	for cell: InventoryCell in real_player_inventory.grid.get_children():
		if cell.item:
			var item_copy: Item = create_item_copy(cell.item)
			if item_copy:
				item_copy.hide()
				add_child(item_copy)
				var empty: Array[InventoryCell] = player_inventory.find_empty_cells(true)
				if not empty.is_empty():
					var target: InventoryCell = empty[0]
					target.set_item(item_copy)
					target.count = cell.count
					player_item_copies[item_copy] = cell.item
					set_item_price_text(player_inventory, item_copy, get_sell_price(cell.item), Color.RED)


func start_buy_mode() -> void:
	mode = ShopMode.BUY
	update_total_message()


func start_sell_mode() -> void:
	mode = ShopMode.SELL
	update_total_message()


func _on_buy_button_pressed() -> void:
	if mode == ShopMode.BUY:
		confirm_buy()
	else:
		message_label.text = "Adicione itens da loja para comprar"


func _on_sell_button_pressed() -> void:
	if mode == ShopMode.SELL:
		confirm_sell()
	else:
		message_label.text = "Adicione itens do inventário para vender"
	

func confirm_buy() -> void:
	if total_price <= 0:
		message_label.text = "Nenhum item para comprar"
		return

	if not PlayerWallet.remove_gold(total_price):
		message_label.text = "Gold insuficiente"
		return

	for cell: InventoryCell in transfer_inventory.grid.get_children():
		if cell.item:
			var count: int = cell.count
			var item_scene = find_item_scene_by_item(cell.item)
			
			if item_scene:
				# Cria um novo item a partir da cena (não usa duplicate)
				var new_item = current_shop.create_item(item_scene)
				if new_item:
					add_child(new_item)
					new_item.dropped_count = count
					real_player_inventory.add_item(new_item)
			
			# Limpa o item da transferência
			cell.item.queue_free()
			cell.item = null
			cell.count = 0

	clear_transfer()
	fill_player_inventory()
	update_gold_label(PlayerWallet.gold)


func confirm_sell() -> void:
	if total_price <= 0:
		message_label.text = "Nenhum item para vender"
		return

	for cell: InventoryCell in transfer_inventory.grid.get_children():
		if cell.item:
			var real_item: Item = sell_items.get(cell.item)
			if real_item:
				remove_real_player_item(real_item, cell.count)

	PlayerWallet.add_gold(total_price)
	clear_transfer()
	fill_player_inventory()

func update_total_message() -> void:
	if mode == ShopMode.BUY:
		message_label.text = "Total da compra: " + str(total_price)
	elif mode == ShopMode.SELL:
		message_label.text = "Total da venda: " + str(total_price)
	else:
		message_label.text = "Escolha itens para comprar ou vender"


func _on_shop_inventory_cell_left_clicked(cell: InventoryCell) -> void:
	if not cell.item:
		return

	add_shop_item_to_transfer(cell.item)


func _on_player_inventory_cell_left_clicked(cell: InventoryCell) -> void:
	if not cell.item:
		return

	var shift = Input.is_key_pressed(KEY_SHIFT)
	add_player_item_to_transfer(cell, cell.count if shift else 1)


func _on_player_cell_split_stack(cell: InventoryCell, half: int) -> void:
	add_player_item_to_transfer(cell, half)


func _on_player_cell_wants_remove(cell: InventoryCell) -> void:
	add_player_item_to_transfer(cell, cell.count)


func find_item_scene_by_item(item: Item) -> PackedScene:
	if not current_shop:
		return null

	for item_scene: PackedScene in current_shop.get_item_scenes():
		var test_item: Item = current_shop.create_item(item_scene)

		if test_item.item_name == item.item_name:
			test_item.queue_free()
			return item_scene

		test_item.queue_free()

	return null
	

func add_shop_item_to_transfer(item: Item) -> void:
	if mode == ShopMode.SELL:
		message_label.text = "Finalize ou saia da venda atual"
		return
	if mode == ShopMode.NONE:
		start_buy_mode()

	var item_scene: PackedScene = find_item_scene_by_item(item)
	if not item_scene:
		message_label.text = "Item não encontrado na loja"
		return

	var price: int = current_shop.get_price(item_scene)

	if total_price + price > PlayerWallet.gold:
		message_label.text = "Gold insuficiente"
		return

	if not can_add_buy_item(item):
		message_label.text = "Inventário cheio"
		return

	if not can_add_to_transfer(item):
		message_label.text = "Transferência cheia"
		return

	# Verifica se já existe stack do mesmo item na transferência
	var stack_comp = item.get_node_or_null("StackableComponent")
	if stack_comp:
		for cell: InventoryCell in transfer_inventory.grid.get_children():
			if cell.item and cell.item.item_name == item.item_name:
				if cell.count < stack_comp.stack_size:
					cell.count += 1
					total_price += price
					set_item_price_text(transfer_inventory, cell.item, price * cell.count, Color.GREEN)
					update_total_message()
					return

	# Se não empilhou, cria novo item
	var new_item: Item = current_shop.create_item(item_scene)
	add_child(new_item)
	new_item.dropped_count = 1
	
	var empty = transfer_inventory.find_empty_cells(true)
	if empty.is_empty():
		new_item.queue_free()
		message_label.text = "Transferência cheia"
		return
	
	empty[0].set_item(new_item)
	empty[0].count = 1
	transfer_item_prices[new_item] = price
	set_item_price_text(transfer_inventory, new_item, price, Color.GREEN)

	total_price += price
	update_total_message()


func add_player_item_to_transfer(cell: InventoryCell, amount: int = 1) -> void:
	if mode == ShopMode.BUY:
		message_label.text = "Finalize ou saia da compra atual"
		return
	if mode == ShopMode.NONE:
		start_sell_mode()

	if player_inventory.selected_item:
		player_inventory.cancel_selected_item()

	var real_item: Item = player_item_copies.get(cell.item)
	if not real_item:
		message_label.text = "Item não encontrado no inventário"
		return

	var price: int = get_sell_price(real_item)
	if price < 0:
		message_label.text = "A loja não compra esse item"
		return

	var sell_amount: int = mini(amount, cell.count)
	if sell_amount <= 0:
		return

	var is_stackable := cell.is_stackable()

	if is_stackable and cell.count > sell_amount:
		cell.count -= sell_amount
		var sell_item: Item = create_item_copy(cell.item)
		if not sell_item:
			cell.count += sell_amount
			return
		sell_item.hide()
		add_child(sell_item)
		var empty := transfer_inventory.find_empty_cells(true)
		if empty.is_empty():
			cell.count += sell_amount
			sell_item.queue_free()
			return
		empty[0].set_item(sell_item)
		empty[0].count = sell_amount
		sell_items[sell_item] = real_item
		transfer_item_prices[sell_item] = price
		set_item_price_text(transfer_inventory, sell_item, price * sell_amount, Color.RED)
	else:
		var item_to_sell: Item = cell.remove_item()
		var empty := transfer_inventory.find_empty_cells(true)
		if empty.is_empty():
			cell.set_item(item_to_sell)
			cell.count = sell_amount
			return
		empty[0].set_item(item_to_sell)
		empty[0].count = sell_amount
		sell_items[item_to_sell] = real_item
		transfer_item_prices[item_to_sell] = price
		set_item_price_text(transfer_inventory, item_to_sell, price * sell_amount, Color.RED)

	total_price += price * sell_amount
	update_total_message()


func clear_transfer() -> void:
	clear_inventory(transfer_inventory)
	sell_items.clear()
	transfer_item_prices.clear()
	mode = ShopMode.NONE
	total_price = 0
	update_total_message()


func remove_real_player_item(item_to_remove: Item, amount: int = 1) -> void:
	for cell: InventoryCell in real_player_inventory.grid.get_children():
		if cell.item == item_to_remove:
			if cell.is_stackable() and cell.count > amount:
				cell.count -= amount
			elif cell.is_stackable() and cell.count <= amount:
				cell.remove_item().queue_free()
			else:
				cell.remove_item().queue_free()
			return

	for cell: InventoryCell in real_player_inventory.grid.get_children():
		if cell.item and cell.item.item_name == item_to_remove.item_name and cell.is_stackable() and cell.count > amount:
			cell.count -= amount
			return
		elif cell.item and cell.item.item_name == item_to_remove.item_name and cell.is_stackable():
			cell.remove_item().queue_free()
			return


func _on_transfer_inventory_cell_left_clicked(cell: InventoryCell) -> void:
	if player_inventory.selected_item:
		accept_split_for_sell()
		return

	if not cell.item:
		return

	if mode == ShopMode.BUY:
		undo_buy_item(cell)
	elif mode == ShopMode.SELL:
		undo_sell_item(cell)


func accept_split_for_sell() -> void:
	if mode == ShopMode.BUY:
		message_label.text = "Finalize ou saia da compra atual"
		player_inventory._restore_selected()
		return

	var source: InventoryCell = player_inventory.selected_cell
	var selected: Item = player_inventory.selected_item
	var count: int = player_inventory.selected_count

	if not source or not selected:
		return

	if mode == ShopMode.NONE:
		start_sell_mode()

	var real_item: Item = player_item_copies.get(selected)
	if not real_item and source.item:
		real_item = player_item_copies.get(source.item)

	if not real_item:
		player_inventory._cleanup_selection()
		message_label.text = "Item não encontrado no inventário"
		return

	var price: int = get_sell_price(real_item)
	if price < 0:
		player_inventory._cleanup_selection()
		message_label.text = "A loja não compra esse item"
		return

	selected.reparent(self)
	selected.hide()
	selected.top_level = false
	selected.z_index = 0
	selected.position = Vector2.ZERO

	var empty := transfer_inventory.find_empty_cells(true)
	if empty.is_empty():
		player_inventory._cleanup_selection()
		return
	empty[0].set_item(selected)
	empty[0].count = count

	sell_items[selected] = real_item
	transfer_item_prices[selected] = price
	set_item_price_text(transfer_inventory, selected, price * count, Color.RED)
	total_price += price * count
	update_total_message()

	player_inventory._cleanup_selection()


func undo_buy_item(cell: InventoryCell) -> void:
	var item: Item = cell.item
	if not item:
		return

	var per_unit_price: int = transfer_item_prices.get(item, 0)
	if per_unit_price <= 0:
		return

	if cell.is_stackable() and cell.count > 1:
		cell.count -= 1
		total_price -= per_unit_price
		set_item_price_text(transfer_inventory, item, per_unit_price * cell.count, Color.GREEN)
	else:
		cell.remove_item()
		total_price -= per_unit_price
		transfer_item_prices.erase(item)
		item.queue_free()

	update_mode_after_undo()


func undo_sell_item(cell: InventoryCell) -> void:
	var item: Item = cell.item
	var count: int = cell.count
	var real_item: Item = sell_items.get(item)

	total_price -= transfer_item_prices.get(item, 0)
	transfer_item_prices.erase(item)
	sell_items.erase(item)

	item.reparent(self)
	item.hide()
	item.top_level = false
	item.z_index = 0
	item.position = Vector2.ZERO
	cell.item = null
	cell.count = 0

	var empty: Array[InventoryCell] = player_inventory.find_empty_cells(true)
	if not empty.is_empty():
		var target: InventoryCell = empty[0]
		target.set_item(item)
		target.count = count
		if real_item:
			player_item_copies[item] = real_item
			set_item_price_text(player_inventory, item, get_sell_price(real_item), Color.RED)

	update_mode_after_undo()


func update_mode_after_undo() -> void:
	if count_items(transfer_inventory) == 0:
		mode = ShopMode.NONE
		total_price = 0

	update_total_message()


func create_item_copy(item: Item) -> Item:
	if item.scene_file_path:
		var item_scene: PackedScene = load(item.scene_file_path)
		return item_scene.instantiate() as Item

	var shop_item_scene: PackedScene = find_item_scene_by_item(item)
	if shop_item_scene:
		return current_shop.create_item(shop_item_scene)

	return null


func get_sell_price(item: Item) -> int:
	var price: int = current_shop.get_price_from_item(item)
	if price < 0:
		return -1

	return floori(price / 2.0)


func set_item_price_text(
		inventory: Inventory,
		item: Item,
		price: int,
		color: Color
) -> void:
	if price < 0:
		return

	for cell: InventoryCell in inventory.grid.get_children():
		if cell.item == item:
			cell.price_manager.set_price_text(str(price), color)
			return

func count_items(inventory: Inventory) -> int:
	var total: int = 0

	for cell: InventoryCell in inventory.grid.get_children():
		if cell.item:
			total += 1

	return total

func count_empty_cells(inventory: Inventory) -> int:	
	var total: int = 0

	for cell: InventoryCell in inventory.grid.get_children():
		if not cell.item:
			total += 1

	return total


func can_add_buy_item(item_to_buy: Item = null) -> bool:
	var empty_cells: int = count_empty_cells(real_player_inventory)
	var transfer_items: int = count_items(transfer_inventory)

	if transfer_items + 1 <= empty_cells:
		return true

	if not item_to_buy or not item_to_buy.has_node("StackableComponent"):
		return false

	var item_name: String = item_to_buy.item_name

	var available_stack_space: int = 0
	for cell: InventoryCell in real_player_inventory.grid.get_children():
		if cell.item and cell.item.item_name == item_name and cell.is_stackable():
			var stack_comp = cell.item.get_node("StackableComponent") as StackableComponent
			available_stack_space += stack_comp.stack_size - cell.count

	var units_in_transfer: int = 0
	for cell: InventoryCell in transfer_inventory.grid.get_children():
		if cell.item and cell.item.item_name == item_name:
			units_in_transfer += cell.count

	return units_in_transfer < available_stack_space


func can_add_to_transfer(item_to_check: Item) -> bool:
	if count_empty_cells(transfer_inventory) > 0:
		return true

	if not item_to_check.has_node("StackableComponent"):
		return false

	var stack_comp = item_to_check.get_node("StackableComponent") as StackableComponent
	for cell: InventoryCell in transfer_inventory.grid.get_children():
		if cell.item and cell.item.item_name == item_to_check.item_name and cell.count < stack_comp.stack_size:
			return true

	return false
