extends Node

class_name MovementComponent

@export var accerelation: int = 40
@export var max_speed: int = 100

var mov_direction: Vector2 = Vector2.ZERO

@onready var parent: Character = get_parent()


func _ready():
	if not parent is CharacterBody2D:
		push_error("Error: This node must be child of a CharacterBody2D.")
		
		set_process(false)
		set_physics_process(false)
		queue_free() 


func move() -> void:
	mov_direction = mov_direction.normalized()
	parent.velocity += mov_direction * accerelation
	parent.velocity = parent.velocity.limit_length(max_speed)


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
