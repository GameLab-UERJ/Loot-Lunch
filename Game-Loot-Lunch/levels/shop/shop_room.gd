extends Node2D


signal player_can_leave_shop
signal stop_player_can_leave_shop


func _on_leave_area_entered() -> void:
	player_can_leave_shop.emit()


func _on_leave_area_exited() -> void:
	stop_player_can_leave_shop.emit()
