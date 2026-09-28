extends Area2D
class_name GreaseTrap


@export_range(0.1, 1.0, 0.05) var movement_multiplier: float = 0.45

var _affected_bodies: Dictionary = {}
var _grease_tween: Tween

@onready var grease_sprite: Sprite2D = $GreaseSprite


func _ready() -> void:
	_grease_tween = create_tween().set_loops()
	_grease_tween.tween_property(grease_sprite, "modulate:a", 0.72, 0.45)
	_grease_tween.parallel().tween_property(grease_sprite, "scale", Vector2(1.06, 0.94), 0.45)
	_grease_tween.tween_property(grease_sprite, "modulate:a", 1.0, 0.45)
	_grease_tween.parallel().tween_property(grease_sprite, "scale", Vector2.ONE, 0.45)


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
