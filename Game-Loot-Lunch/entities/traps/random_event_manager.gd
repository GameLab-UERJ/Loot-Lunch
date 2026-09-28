extends Node2D
class_name RandomEventManager


@export var flame_scene: PackedScene
@export var grease_scene: PackedScene
@export var event_interval: float = 8.0
@export var first_event_delay: float = 3.0
@export var grease_spawn_area: Rect2 = Rect2(-96, -48, 192, 96)
@export var grease_lifetime: float = 8.0
@export var automatic_events: bool = true
@export var event_source_path: NodePath

var _random := RandomNumberGenerator.new()
var _event_timer: Timer


func _ready() -> void:
	_random.randomize()
	_event_timer = Timer.new()
	_event_timer.wait_time = first_event_delay
	_event_timer.one_shot = true
	_event_timer.timeout.connect(_on_first_event_timeout)
	add_child(_event_timer)
	if automatic_events:
		_event_timer.start()


func trigger_random_event() -> void:
	if not _event_source_is_active():
		return
	if not flame_scene and not grease_scene:
		return
	if flame_scene and grease_scene:
		if _random.randf() < 0.5:
			_spawn_flame()
		else:
			_spawn_grease()
		return
	if flame_scene:
		_spawn_flame()
	else:
		_spawn_grease()


func _on_first_event_timeout() -> void:
	trigger_random_event()
	_event_timer.wait_time = event_interval
	_event_timer.one_shot = false
	_event_timer.start()


func _spawn_flame() -> void:
	var flame: FlameTrap = flame_scene.instantiate()
	add_child(flame)
	flame.deactivated.connect(flame.queue_free)
	flame.trigger()


func _spawn_grease() -> void:
	var grease: GreaseTrap = grease_scene.instantiate()
	grease.position = Vector2(
		_random.randf_range(grease_spawn_area.position.x, grease_spawn_area.end.x),
		_random.randf_range(grease_spawn_area.position.y, grease_spawn_area.end.y)
	)
	add_child(grease)
	if grease_lifetime > 0.0:
		await get_tree().create_timer(grease_lifetime).timeout
		if is_instance_valid(grease):
			grease.queue_free()


func _event_source_is_active() -> bool:
	if event_source_path.is_empty():
		return true
	var source: Node = get_node_or_null(event_source_path)
	if source == null or not source.has_method("get_count"):
		return false
	return int(source.call("get_count")) > 0
