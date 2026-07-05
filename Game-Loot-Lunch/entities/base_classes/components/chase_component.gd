extends Node
class_name ChaseComponent


signal next_chase_point_set(next_point : Vector2)
signal there_is_no_player
signal target_reached


@export var enabled : bool = true
@export var chased_node: Node2D


@onready var parent: Character = get_parent()
@onready var path_timer: Timer = get_node_or_null("PathTimer")
@onready var navigation_agent: NavigationAgent2D = get_node_or_null("NavigationAgent2D")


func _ready() -> void:
	if not parent is Character:
		push_error("Error: This node must be child of a CharacterBody2D.")
		
		set_process(false)
		set_physics_process(false)
		queue_free() 
	
	if not path_timer:
		path_timer = Timer.new()
		path_timer.wait_time = 0.5
		path_timer.autostart = true
		path_timer.timeout.connect(_on_path_timer_timeout)
		add_child(path_timer)
	
	if not navigation_agent:
		navigation_agent = NavigationAgent2D.new()
		parent.call_deferred("add_child",navigation_agent)


func _process(_delta: float) -> void:
	print(navigation_agent.is_target_reached())
	if not enabled:
		return
	
	chase()


func _on_path_timer_timeout() -> void:
	if not path_timer or not enabled:
		return 
	
	if is_instance_valid(chased_node):
		if navigation_agent.target_position != chased_node.position:
			navigation_agent.target_position = chased_node.position
	else:
		path_timer.stop()
		there_is_no_player.emit()
		navigation_agent.target_position = parent.global_position


func enable() -> void:
	enabled = true


func disable() -> void:
	enabled = false


func chase() -> void:
	if (not navigation_agent or 
		not navigation_agent.get_parent()
	):
		return 
	
	if navigation_agent.is_target_reached():
		target_reached.emit()
		return
	
	next_chase_point_set.emit(navigation_agent.get_next_path_position() - parent.global_position)
