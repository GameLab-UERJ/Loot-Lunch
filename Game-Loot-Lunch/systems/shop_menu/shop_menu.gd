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


func open_shop(shop: ShopComponent, real_player_inventory: Inventory) -> void:
	current_shop = shop
	self.real_player_inventory = real_player_inventory

	visible = true
	message_label.text = ""
	fill_player_inventory()
	fill_shop_inventory()
	clear_transfer()
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
				add_child(item_copy)
				player_inventory.add_item(item_copy)
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
			var item: Item = cell.remove_item()
			real_player_inventory.add_item(item)

	clear_transfer()
	fill_player_inventory()


func confirm_sell() -> void:
	if total_price <= 0:
		message_label.text = "Nenhum item para vender"
		return

	for item_to_sell: Item in sell_items.values():
		remove_real_player_item(item_to_sell)

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

	add_player_item_to_transfer(cell)


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
	
	if not can_add_buy_item():
		message_label.text = "Inventário cheio"
		return

	var new_item: Item = current_shop.create_item(item_scene)
	add_child(new_item)
	transfer_inventory.add_item(new_item)
	transfer_item_prices[new_item] = price
	set_item_price_text(transfer_inventory, new_item, price, Color.GREEN)

	total_price += price
	update_total_message()


func add_player_item_to_transfer(cell: InventoryCell) -> void:
	if mode == ShopMode.BUY:
		message_label.text = "Finalize ou saia da compra atual"
		return
	if mode == ShopMode.NONE:
		start_sell_mode()

	var visual_item: Item = cell.item
	var real_item: Item = player_item_copies.get(visual_item)

	if not real_item:
		message_label.text = "Item não encontrado no inventário"
		return

	var price: int = current_shop.get_price_from_item(real_item)
	if price < 0:
		message_label.text = "A loja não compra esse item"
		return
	price = get_sell_price(real_item)

	var item_to_sell: Item = cell.remove_item()
	transfer_inventory.add_item(item_to_sell)

	sell_items[item_to_sell] = real_item
	transfer_item_prices[item_to_sell] = price
	set_item_price_text(transfer_inventory, item_to_sell, price, Color.RED)
	total_price += price
	update_total_message()


func clear_transfer() -> void:
	clear_inventory(transfer_inventory)
	sell_items.clear()
	transfer_item_prices.clear()
	mode = ShopMode.NONE
	total_price = 0
	update_total_message()


func remove_real_player_item(item_to_remove: Item) -> void:
	for cell: InventoryCell in real_player_inventory.grid.get_children():
		if cell.item == item_to_remove:
			cell.remove_item().queue_free()
			return


func _on_transfer_inventory_cell_left_clicked(cell: InventoryCell) -> void:
	if not cell.item:
		return

	if mode == ShopMode.BUY:
		undo_buy_item(cell)
	elif mode == ShopMode.SELL:
		undo_sell_item(cell)


func undo_buy_item(cell: InventoryCell) -> void:
	var item: Item = cell.remove_item()
	total_price -= transfer_item_prices.get(item, 0)
	transfer_item_prices.erase(item)
	item.queue_free()
	update_mode_after_undo()


func undo_sell_item(cell: InventoryCell) -> void:
	var item: Item = cell.remove_item()
	var real_item: Item = sell_items.get(item)

	total_price -= transfer_item_prices.get(item, 0)
	transfer_item_prices.erase(item)
	sell_items.erase(item)

	player_inventory.add_item(item)
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
			cell.set_price_text(str(price), color)
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
	
func can_add_buy_item() -> bool:
	var empty_cells: int = count_empty_cells(real_player_inventory)
	var transfer_items: int = count_items(transfer_inventory)

	return transfer_items + 1 <= empty_cells
