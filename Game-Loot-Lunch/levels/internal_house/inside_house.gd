extends Node2D
class_name InsideHouse

signal player_can_leave_house
signal stop_player_can_leave_house


func _on_door_area_entered() -> void:
	player_can_leave_house.emit()


func _on_door_area_exited() -> void:
	stop_player_can_leave_house.emit()
