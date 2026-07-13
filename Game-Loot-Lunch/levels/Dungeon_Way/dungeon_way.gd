extends Node2D
class_name DungeonWay


signal player_can_enter_dungeon_exterior
signal player_can_enter_external_house
signal player_can_enter_shop


@export var is_outdoor: bool = true
@export var player_start_position : Marker2D


@onready var player: Player = $Player


func _ready() -> void:
	
	EnvironmentManager.is_outdoor = is_outdoor
	
	if not player_start_position:
		player.position = Vector2(35,305)
	else:
		player.global_position = player_start_position.global_position


func _on_dungeon_exterior_area_entered() -> void:
	player_can_enter_dungeon_exterior.emit()


func _on_external_house_area_entered() -> void:
	player_can_enter_external_house.emit()
	
	
func _on_shop_area_entered() -> void:
	player_can_enter_shop.emit()
