extends Area2D
class_name InteractableArea


signal interact_with_player
signal stop_interact_with_player


var enabled : bool = true:
	set(value):
		enabled = value
		if collision_shape:
			collision_shape.set_deferred("disabled",not enabled)


@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_mask = 2						# Player layer
	collision_layer = 0
	enabled = enabled


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		var inv: InventoryComponent = body.get_node("InventoryComponent") as InventoryComponent
		if inv:
			var item := get_parent() as Item
			if item and not item.picked_up.is_connected(inv.add_item):
				item.picked_up.connect(inv.add_item)
		interact_with_player.emit()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		stop_interact_with_player.emit()
