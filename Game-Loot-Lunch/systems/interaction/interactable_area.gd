extends Area2D
class_name InteractableArea


signal interact_with_player
signal stop_interact_with_player


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_mask = 2						# Player layer
	collision_layer = 0


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		interact_with_player.emit()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		stop_interact_with_player.emit()
