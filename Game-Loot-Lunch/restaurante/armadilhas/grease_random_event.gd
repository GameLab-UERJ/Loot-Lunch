extends RandomEvent
class_name GreaseRandomEvent


@export var grease_scene: PackedScene
@export var warning_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(-96, -48, 192, 96)
@export var grease_lifetime: float = 8.0
@export var warning_duration: float = 1.0



func _ready() -> void:
	super()
	_random.randomize()


func _activate_event() -> void:
	if not grease_scene:
		return
	var spawn_position := Vector2(
		_random.randf_range(spawn_area.position.x, spawn_area.end.x),
		_random.randf_range(spawn_area.position.y, spawn_area.end.y)
	)
	if warning_scene:
		var warning: TrapWarning = warning_scene.instantiate()
		warning.position = spawn_position
		warning.visible_duration = warning_duration
		add_child(warning)
		warning.show_for(warning_duration)
		await get_tree().create_timer(warning_duration).timeout
		if not is_inside_tree():
			return
	var grease: GreaseTrap = grease_scene.instantiate()
	grease.position = spawn_position
	add_child(grease)
	if grease_lifetime > 0.0:
		await get_tree().create_timer(grease_lifetime).timeout
		if is_instance_valid(grease):
			grease.queue_free()
