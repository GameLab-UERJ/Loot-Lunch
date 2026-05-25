extends Node2D


signal player_can_enter_house




func _on_interactable_area_interact_with_player() -> void:
	print('player_can_enter_house')
	player_can_enter_house.emit()
