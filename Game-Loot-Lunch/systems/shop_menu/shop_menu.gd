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

enum ShopMode {
	BUY,
	SELL
}

var mode: ShopMode = ShopMode.BUY
var total_price: int = 0

func _ready() -> void:
	visible = false
	PlayerWallet.gold_changed.connect(update_gold_label)
	update_gold_label(PlayerWallet.gold)


func update_gold_label(new_gold: int) -> void:
	gold_label.text = "Gold: " + str(new_gold)


func open_shop(shop: ShopComponent, real_player_inventory: Inventory) -> void:
	current_shop = shop
	self.real_player_inventory = real_player_inventory

	visible = true
	message_label.text = ""
	fill_player_inventory()
	fill_shop_inventory()
	select_buy_mode()
	shop_opened.emit()

func close_shop() -> void:
	clear_inventory(transfer_inventory)
	total_price = 0

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


func fill_player_inventory() -> void:
	clear_inventory(player_inventory)

	if not real_player_inventory:
		return

	for cell: InventoryCell in real_player_inventory.grid.get_children():
		if cell.item:
			var item_copy: Item = create_item_copy(cell.item)
			if item_copy:
				add_child(item_copy)
				player_inventory.add_item(item_copy)


func select_buy_mode() -> void:
	mode = ShopMode.BUY
	total_price = 0
	update_total_message()


func select_sell_mode() -> void:
	mode = ShopMode.SELL
	total_price = 0
	update_total_message()


func _on_buy_button_pressed() -> void:
	if mode == ShopMode.BUY:
		confirm_buy()
	else:
		select_buy_mode()


func _on_sell_button_pressed() -> void:
	select_sell_mode()
	

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

	total_price = 0
	fill_player_inventory()
	update_total_message()

func update_total_message() -> void:
	if mode == ShopMode.BUY:
		message_label.text = "Total da compra: " + str(total_price)
	else:
		message_label.text = "Total da venda: " + str(total_price)


func _on_shop_inventory_cell_left_clicked(cell: InventoryCell) -> void:
	if mode != ShopMode.BUY:
		return
	if not cell.item:
		return

	add_shop_item_to_transfer(cell.item)


func _on_player_inventory_cell_left_clicked(cell: InventoryCell) -> void:
	if mode != ShopMode.SELL:
		return
	if not cell.item:
		return

	print("Clicou em item do player: " + cell.item.item_name)


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
	var item_scene: PackedScene = find_item_scene_by_item(item)
	if not item_scene:
		message_label.text = "Item não encontrado na loja"
		return

	var price: int = current_shop.get_price(item_scene)

	if total_price + price > PlayerWallet.gold:
		message_label.text = "Gold insuficiente"
		return

	var new_item: Item = current_shop.create_item(item_scene)
	add_child(new_item)
	transfer_inventory.add_item(new_item)

	total_price += price
	update_total_message()


func create_item_copy(item: Item) -> Item:
	if item.scene_file_path:
		var item_scene: PackedScene = load(item.scene_file_path)
		return item_scene.instantiate() as Item

	var shop_item_scene: PackedScene = find_item_scene_by_item(item)
	if shop_item_scene:
		return current_shop.create_item(shop_item_scene)

	return null
