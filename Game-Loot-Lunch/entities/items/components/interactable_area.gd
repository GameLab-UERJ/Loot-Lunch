extends Area2D
class_name InteractableArea


signal interact_with_player


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		interact_with_player.emit()
