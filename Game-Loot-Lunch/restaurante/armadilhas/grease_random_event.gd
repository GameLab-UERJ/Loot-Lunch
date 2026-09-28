extends RandomEvent
class_name GreaseRandomEvent


@export var grease_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(-96, -48, 192, 96)
@export var grease_lifetime: float = 8.0

var _random := RandomNumberGenerator.new()


func _ready() -> void:
	super()
	_random.randomize()


func _activate_event() -> void:
	if not grease_scene:
		return
	var grease: GreaseTrap = grease_scene.instantiate()
	grease.position = Vector2(
		_random.randf_range(spawn_area.position.x, spawn_area.end.x),
		_random.randf_range(spawn_area.position.y, spawn_area.end.y)
	)
	add_child(grease)
	if grease_lifetime > 0.0:
		await get_tree().create_timer(grease_lifetime).timeout
		if is_instance_valid(grease):
			grease.queue_free()
