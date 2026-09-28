extends Area2D
class_name GreaseTrap


@export_range(0.1, 1.0, 0.05) var movement_multiplier: float = 0.45
@export_range(4.0, 64.0, 1.0) var hitbox_radius: float = 18.0

var _affected_bodies: Dictionary = {}

@onready var hitbox: CollisionShape2D = $Hitbox


func _ready() -> void:
	var circle_shape := hitbox.shape as CircleShape2D
	if circle_shape:
		circle_shape = circle_shape.duplicate()
		circle_shape.radius = hitbox_radius
		hitbox.shape = circle_shape


func _on_body_entered(body: Node2D) -> void:
	var chef: Chef = body as Chef
	if chef == null:
		return
	if _affected_bodies.has(chef):
		return
	_affected_bodies[chef] = true
	chef.set_movement_multiplier(movement_multiplier)


func _on_body_exited(body: Node2D) -> void:
	var chef: Chef = body as Chef
	if chef == null or not _affected_bodies.has(chef):
		return
	_affected_bodies.erase(chef)
	if is_instance_valid(chef):
		chef.set_movement_multiplier(1.0)
