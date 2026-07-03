extends Node
class_name ChaseComponent


signal next_chase_point_set(next_point : Vector2)
signal there_is_no_player


@onready var parent: Character = get_parent()
@onready var player: CharacterBody2D = get_tree().current_scene.get_node_or_null("Player")
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


func _on_path_timer_timeout() -> void:
	if not path_timer:
		return 
	
	if is_instance_valid(player):
		if navigation_agent.target_position != player.position:
			navigation_agent.target_position = player.position
	else:
		path_timer.stop()
		there_is_no_player.emit()
		navigation_agent.target_position = parent.global_position


func chase() -> void:
	if (not navigation_agent or 
		not navigation_agent.get_parent() or 
		navigation_agent.is_target_reached()
	):
		return 
	
	next_chase_point_set.emit(navigation_agent.get_next_path_position() - parent.global_position)
