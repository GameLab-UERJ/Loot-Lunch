extends Node2D
class_name ExternalHouse

signal player_can_enter_house
signal stop_player_can_enter_house
signal player_can_enter_shop
signal stop_player_can_enter_shop


@export var player_start_position : Marker2D


@onready var player: Player = $Player


func _ready() -> void:
	if not player_start_position:
		player.position = Vector2(35,305)
	else:
		player.global_position = player_start_position.global_position

func _on_house_area_entered() -> void:
	print('player_can_enter_house')
	player_can_enter_house.emit()


func _on_house_area_exited() -> void:
	print('player_cant_enter_house')
	stop_player_can_enter_house.emit()


func _on_shop_area_entered() -> void:
	print('player_can_enter_shop')
	player_can_enter_shop.emit()


func _on_shop_area_exited() -> void:
	print('player_cant_enter_shop')
	stop_player_can_enter_shop.emit()
