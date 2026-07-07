extends Spawn
class_name Formigueiro


@export var chased_node : Node2D


@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D


func _on_spawned(spawned_creature: Character) -> void:
	if chased_node:
		(spawned_creature as Tanajura).chase_component.chased_node = chased_node
