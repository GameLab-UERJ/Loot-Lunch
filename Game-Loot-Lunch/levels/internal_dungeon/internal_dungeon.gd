extends Node2D
class_name InternalDungeon


signal player_can_leave_dungeon


func _on_external_house_interact_with_player() -> void:
	player_can_leave_dungeon.emit()
