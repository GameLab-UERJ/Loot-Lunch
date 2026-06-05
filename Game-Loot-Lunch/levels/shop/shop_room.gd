extends Node2D


signal player_can_leave_shop
signal stop_player_can_leave_shop

@export var shop_menu: ShopMenu
@export var shop_component: ShopComponent
@export var player_inventory_component: InventoryComponent

@onready var player: Player = $Player


func _ready() -> void:
	shop_menu.shop_opened.connect(_on_shop_menu_opened)
	shop_menu.shop_closed.connect(_on_shop_menu_closed)
	player_inventory_component.inventory_opened.connect(_on_player_inventory_opened)
	player_inventory_component.inventory_closed.connect(_on_player_inventory_closed)


func _on_leave_area_entered() -> void:
	player_can_leave_shop.emit()


func _on_leave_area_exited() -> void:
	stop_player_can_leave_shop.emit()

func _on_shop_npc_interactable_area_interact_with_player() -> void:
	if player_inventory_component.is_inventory_open():
		return

	shop_menu.open_shop(shop_component, player_inventory_component.get_inventory())


func _on_shop_menu_opened() -> void:
	player.can_control = false
	player_inventory_component.can_toggle_inventory = false


func _on_shop_menu_closed() -> void:
	player.can_control = true
	player_inventory_component.can_toggle_inventory = true


func _on_player_inventory_opened() -> void:
	player.can_control = false


func _on_player_inventory_closed() -> void:
	if not shop_menu.visible:
		player.can_control = true
