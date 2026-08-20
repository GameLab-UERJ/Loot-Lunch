extends Node2D
class_name InsideHouse


@export var is_outdoor: bool = false


signal player_can_leave_house
signal stop_player_can_leave_house


func _on_door_area_entered() -> void:
	player_can_leave_house.emit()


func _on_door_area_exited() -> void:
	stop_player_can_leave_house.emit()

func _ready() -> void:
	EnvironmentManager.is_outdoor = is_outdoor
	_hide_prato_if_already_collected()


func _hide_prato_if_already_collected() -> void:
	if not _player_already_has_prato():
		return
	var prato := get_node_or_null("Prato")
	if prato:
		prato.queue_free()


func _player_already_has_prato() -> bool:
	var inventory: Inventory = GlobalData._find_inventory()
	if inventory and inventory.has_item("Prato"):
		return true
	for item_data: Dictionary in GlobalData.inventory_data:
		if item_data.get("item_name") == "Prato":
			return true
	return false
