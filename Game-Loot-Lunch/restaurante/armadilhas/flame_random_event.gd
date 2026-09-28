extends RandomEvent
class_name FlameRandomEvent


@export var flame_scene: PackedScene
@export var event_source_path: NodePath
@export var warning_duration: float = 1.5
@export var require_source_activity: bool = true


func _ready() -> void:
	super()
	var source: Node = get_node_or_null(event_source_path)
	if source and source.has_signal("item_placed"):
		source.connect("item_placed", _on_item_placed)


func _can_trigger_event() -> bool:
	if not require_source_activity:
		return true
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
	flame.warning_duration = warning_duration
	var source: Node = get_node_or_null(event_source_path)
	if source and source.has_method("burn_items"):
		flame.activated.connect(Callable(source, "burn_items"))
	flame.deactivated.connect(flame.queue_free)
	flame.trigger()


func _on_item_placed(_slot: CookingSlot, _item: CarryableItem) -> void:
	trigger_random_event()
