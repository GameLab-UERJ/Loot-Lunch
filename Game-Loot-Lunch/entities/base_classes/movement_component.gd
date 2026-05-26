extends Node

class_name MovementComponent

var accerelation: int
var max_speed: int

var mov_direction: Vector2 = Vector2.ZERO

var path_timer
var navigation_agent: NavigationAgent2D
var vector_to_next_point: Vector2

@onready var parent: Character = get_parent()

@onready var player: CharacterBody2D = get_tree().current_scene.get_node("Player")


func _ready():
	if not parent is CharacterBody2D:
		push_error("Error: This node must be child of a CharacterBody2D.")
		
		set_process(false)
		set_physics_process(false)
		queue_free() 
	
	# Only for enenmies
	if parent != player:
		path_timer = parent.get_node("PathTimer")
		navigation_agent = parent.get_node("NavigationAgent2D")
		
	accerelation = parent.accerelation
	max_speed = parent.max_speed


# -- Used by enemies -- 
func _on_path_timer_timeout() -> void:
	if is_instance_valid(player):
		if navigation_agent.target_position != player.position:
			navigation_agent.target_position = player.position
	else:
		path_timer.stop()
		parent.state_machine.set_state(parent.state_machine.states.idle)
		navigation_agent.target_position = parent.global_position


# -- Used by enemies -- 
func chase() -> void:
	if not navigation_agent.is_target_reached():
		vector_to_next_point = navigation_agent.get_next_path_position() - parent.global_position
		mov_direction = vector_to_next_point


# -- Used by player and enemies-- 
func move() -> void:
	mov_direction = mov_direction.normalized()
	parent.velocity += mov_direction * accerelation
	parent.velocity = parent.velocity.limit_length(max_speed)


# -- Used by player -- 
func get_input() -> void:
	mov_direction = Vector2.ZERO
	if Input.is_action_pressed("ui_down"):
		mov_direction += Vector2.DOWN
	if Input.is_action_pressed("ui_left"):
		mov_direction += Vector2.LEFT
	if Input.is_action_pressed("ui_right"):
		mov_direction += Vector2.RIGHT
	if Input.is_action_pressed("ui_up"):
		mov_direction += Vector2.UP
