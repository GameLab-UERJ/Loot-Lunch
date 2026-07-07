extends Node2D
class_name DungeonExterior


signal player_can_enter_internal_dungeon
signal stop_player_can_enter_internal_dungeon
signal player_can_enter_dungeon_way
signal stop_player_can_enter_dungeon_way
signal player_can_enter_shop
signal stop_player_can_enter_shop


@export var player_start_position : Marker2D
@export var internal_dungeon_entrance : Marker2D 
@export var dungeon_way_entrance : Marker2D  


@onready var player: Player = $Player


func _ready() -> void:
	if not player_start_position:
		player.position = Vector2(35, 305)
	else:
		player.global_position = player_start_position.global_position


func _on_internal_dungeon_area_entered() -> void:
	player_can_enter_internal_dungeon.emit()


func _on_internal_dungeon_area_exited() -> void:
	stop_player_can_enter_internal_dungeon.emit()


func _on_dungeon_way_area_entered() -> void:
	player_can_enter_dungeon_way.emit()


func _on_dungeon_way_area_exited() -> void:
	stop_player_can_enter_dungeon_way.emit()
	
	
func _on_shop_area_entered() -> void:
	player_can_enter_shop.emit()


func _on_shop_area_exited() -> void:
	stop_player_can_enter_shop.emit()
