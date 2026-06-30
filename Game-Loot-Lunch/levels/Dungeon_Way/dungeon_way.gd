extends Node2D
class_name DungeonWay

signal player_can_enter_dungeon_exterior
signal player_can_enter_external_house
signal player_can_enter_shop

func _on_dungeon_exterior_area_entered() -> void:
	player_can_enter_dungeon_exterior.emit()

func _on_external_house_area_entered() -> void:
	player_can_enter_external_house.emit()
	
func _on_shop_area_entered() -> void:
	player_can_enter_shop.emit()
