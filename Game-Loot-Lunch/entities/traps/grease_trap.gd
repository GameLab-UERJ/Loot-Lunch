extends Area2D
class_name GreaseTrap


@export_range(0.1, 1.0, 0.05) var movement_multiplier: float = 0.45

var _affected_bodies: Dictionary = {}


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("set_movement_multiplier"):
		return
	if _affected_bodies.has(body):
		return
	_affected_bodies[body] = true
	body.set_movement_multiplier(movement_multiplier)


func _on_body_exited(body: Node2D) -> void:
	if not _affected_bodies.has(body):
		return
	_affected_bodies.erase(body)
	if is_instance_valid(body) and body.has_method("set_movement_multiplier"):
		body.set_movement_multiplier(1.0)
