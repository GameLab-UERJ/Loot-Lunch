extends Node
class_name MovementComponent


var acceleration: int
var max_speed: int


@onready var parent: Character = get_parent()
@onready var player: CharacterBody2D = get_tree().current_scene.get_node_or_null("Player")


func _ready():
	if not parent is Character:
		push_error("Error: This node must be child of a CharacterBody2D.")
		
		set_process(false)
		set_physics_process(false)
		queue_free() 
	
	acceleration = parent.acceleration
	max_speed = parent.max_speed


func move(mov_direction: Vector2) -> void:
	mov_direction = mov_direction.normalized()
	parent.velocity += mov_direction * acceleration
	parent.velocity = parent.velocity.limit_length(max_speed)
