extends Node2D
class_name TrapWarning


@export var visible_duration: float = 1.0

var _animation_tween: Tween

@onready var warning_sprite: Sprite2D = $WarningSprite


func _ready() -> void:
	_animation_tween = create_tween().set_loops()
	_animation_tween.tween_property(warning_sprite, "modulate:a", 0.65, 0.22)
	_animation_tween.parallel().tween_property(warning_sprite, "scale", Vector2(0.48, 0.48), 0.22)
	_animation_tween.tween_property(warning_sprite, "modulate:a", 1.0, 0.22)
	_animation_tween.parallel().tween_property(warning_sprite, "scale", Vector2(0.42, 0.42), 0.22)


func show_for(duration: float = visible_duration) -> void:
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(self):
		queue_free()
