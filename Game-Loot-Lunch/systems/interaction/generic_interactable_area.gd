extends Area2D
class_name GenericInteractableArea

signal player_entered(player: Player)
signal player_exited(player: Player)

func _ready():
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	collision_mask = 2
	collision_layer = 0


func _on_body_entered(body):
	if body is Player:
		player_entered.emit(body)


func _on_body_exited(body):
	if body is Player:
		player_exited.emit(body)
