extends Node2D
class_name ExternalHouse

signal player_can_enter_house
signal stop_player_can_enter_house
signal player_can_enter_shop
signal stop_player_can_enter_shop
signal player_can_enter_cambat_zone
signal stop_player_can_enter_cambat_zone


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


func _on_combat_area_entered() -> void:
	player_can_enter_cambat_zone.emit()


func _on_combat_area_exited() -> void:
	stop_player_can_enter_cambat_zone.emit()


func _on_rooster_sfx_finished() -> void:
	await get_tree().create_timer(randi_range(5,15)).timeout
	rooster_sfx.play()


func _on_seagulls_sfx_finished() -> void:
	await get_tree().create_timer(randi_range(5,15)).timeout
	seagulls_sfx.play()
