extends Area2D
class_name GreaseTrap


@export_range(0.1, 1.0, 0.05) var movement_multiplier: float = 0.45

var _affected_bodies: Dictionary = {}


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
