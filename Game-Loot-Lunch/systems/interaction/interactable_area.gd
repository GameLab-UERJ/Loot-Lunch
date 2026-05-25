extends Area2D
class_name InteractableArea


signal interact_with_player
signal stop_interact_with_player


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		interact_with_player.emit()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		stop_interact_with_player.emit()
