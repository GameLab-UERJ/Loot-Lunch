extends Node2D
class_name InternalDungeon


@export var is_outdoor: bool = false


signal player_can_leave_dungeon


@onready var enemies: Node2D = $Enemies
@onready var player: Player = $Player


func _on_external_house_interact_with_player() -> void:
	player_can_leave_dungeon.emit()


func _ready() -> void:
	EnvironmentManager.is_outdoor = is_outdoor
