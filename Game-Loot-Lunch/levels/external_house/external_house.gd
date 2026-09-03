extends Node2D
class_name ExternalHouse

signal player_can_enter_house
signal stop_player_can_enter_house
signal player_can_enter_left
signal stop_player_can_enter_left
signal player_can_enter_combat_area
signal stop_player_can_enter_combat_area


@export var is_outdoor: bool = true
@export var player_start_position : Marker2D


@onready var player: Player = $Player
@onready var rooster_sfx: AudioStreamPlayer2D = $RoosterSfx
@onready var seagulls_sfx: AudioStreamPlayer2D = $SeagullsSfx


var was_already_opened : bool = false

func _ready() -> void:
	
	EnvironmentManager.is_outdoor = is_outdoor
	
	if not player_start_position:
		player.position = Vector2(35,305)
	else:
		player.global_position = player_start_position.global_position


func _on_house_area_entered() -> void:
	player_can_enter_house.emit()


func _on_house_area_exited() -> void:
	stop_player_can_enter_house.emit()


func _on_left_area_entered() -> void:
	player_can_enter_left.emit()


func _on_left_area_exited() -> void:
	stop_player_can_enter_left.emit()


func _on_combat_area_entered() -> void:
	player_can_enter_combat_area.emit()


func _on_combat_area_exited() -> void:
	stop_player_can_enter_combat_area.emit()


func _on_rooster_sfx_finished() -> void:
	await get_tree().create_timer(randi_range(5,15)).timeout
	if TimeCycle.is_day():
		rooster_sfx.play()


func _on_seagulls_sfx_finished() -> void:
	await get_tree().create_timer(randi_range(5,15)).timeout
	if TimeCycle.is_day():
		seagulls_sfx.play()


func _on_open_inventory() -> void:
	if not player.inventory_component.open_inventory():
		was_already_opened = true
	else:
		was_already_opened = false
	#print(was_already_opened)


func _on_close_inventory() -> void:
	if not was_already_opened:
		player.inventory_component.close_inventory()
