extends RandomEvent
class_name FlameRandomEvent


@export var flame_scene: PackedScene
@export var event_source_path: NodePath


func _can_trigger_event() -> bool:
	if event_source_path.is_empty():
		return true
	var source: Node = get_node_or_null(event_source_path)
	if source == null or not source.has_method("get_count"):
		return false
	return int(source.call("get_count")) > 0


func _activate_event() -> void:
	if not flame_scene:
		return
	var flame: FlameTrap = flame_scene.instantiate()
	add_child(flame)
	flame.deactivated.connect(flame.queue_free)
	flame.trigger()
