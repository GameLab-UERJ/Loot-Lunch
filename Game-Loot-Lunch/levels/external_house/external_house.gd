extends Node2D
class_name ExternalHouse

signal player_can_enter_house
signal stop_player_can_enter_house
signal player_can_enter_shop
signal stop_player_can_enter_shop
signal player_can_enter_internal_dungeon
signal stop_player_can_enter_internal_dungeon


@export var player_start_position : Marker2D


@onready var player: Player = $Player
@onready var rooster_sfx: AudioStreamPlayer2D = $RoosterSfx
@onready var seagulls_sfx: AudioStreamPlayer2D = $SeagullsSfx


func _ready() -> void:
	if not player_start_position:
		player.position = Vector2(35,305)
	else:
		player.global_position = player_start_position.global_position

func _on_house_area_entered() -> void:
	player_can_enter_house.emit()


func _on_house_area_exited() -> void:
	stop_player_can_enter_house.emit()


func _on_shop_area_entered() -> void:
	player_can_enter_shop.emit()


func _on_shop_area_exited() -> void:
	stop_player_can_enter_shop.emit()


func _on_internal_dungeon_area_entered() -> void:
	player_can_enter_internal_dungeon.emit()


func _on_internal_dungeon_exited() -> void:
	stop_player_can_enter_internal_dungeon.emit()


func _on_rooster_sfx_finished() -> void:
	await get_tree().create_timer(randi_range(5,15)).timeout
	if TimeCycle.is_day():
		rooster_sfx.play()


func _on_seagulls_sfx_finished() -> void:
	await get_tree().create_timer(randi_range(5,15)).timeout
	if TimeCycle.is_day():
		seagulls_sfx.play()
