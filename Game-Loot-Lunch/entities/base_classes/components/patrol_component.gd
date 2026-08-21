extends Node
class_name PatrolComponent


signal next_target_point_set(next_point: Vector2)


@export var enabled : bool = false
@export var patrol_radius : float = 100


var target: Vector2 = Vector2.ZERO
var target_reached: bool = true
var angle: float = 0.0
var old_position: Vector2 = Vector2.ZERO
var is_stuck: bool = false


@onready var parent: Character = get_parent()
@onready var path_timer: Timer = get_node_or_null("PathTimer")


func _ready() -> void:
	if not parent is Character:
		push_error("Error: This node must be child of a CharacterBody2D.")
		
		set_process(false)
		set_physics_process(false)
		queue_free()
	
	if not path_timer:
		path_timer = Timer.new()
		path_timer.wait_time = 4
		path_timer.autostart = true
		path_timer.timeout.connect(_on_path_timer_timeout)
		add_child(path_timer)



func _process(_delta: float) -> void:
	if not enabled:
		return
	
	# to patrol parent.parent needs to be RetangleSpawn
	if not parent.parent:
		return
	
	if  parent.global_position.distance_to(target) <= 1:
		target_reached = true
	
	patrol()


func _on_path_timer_timeout() -> void:
	if not path_timer:
		return 
	
	if not enabled:
		return
		
	target_reached = true


func enable() -> void:
	enabled = true


func disable() -> void:
	enabled = false


# The parent of this node must have an Area2D Territory with a CircleShape2D
func patrol() -> void:
	if target_reached:
		target_reached = false
		target = parent.parent.get_valid_point()
	
	next_target_point_set.emit(target - parent.global_position)
