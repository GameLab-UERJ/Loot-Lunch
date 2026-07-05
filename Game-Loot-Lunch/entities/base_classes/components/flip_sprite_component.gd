extends Node
class_name FlipSpriteComponent


@export var enabled : bool = true
@export var originally_looks_right : bool = true
## If set, sprite faces the x direction of movement. It has precedence over looking at node.
@export var look_to_movement : bool = true
## If not null, flips the sprite to face this node.
@export var node_to_face : Node2D


@onready var entity : Character = get_parent()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not enabled:
		return
	
	look_towards_movement()
	print((entity.velocity.x),", ", is_zero_approx(entity.velocity.x))
	if is_zero_approx(entity.velocity.x):
		face_node()


func look_towards_movement() -> void:
	if not look_to_movement:
		return
	
	if entity.velocity.x > 0:
		entity.animated_sprite.flip_h = not originally_looks_right
	elif entity.velocity.x < 0:
		entity.animated_sprite.flip_h = originally_looks_right


func face_node() -> void:
	if not node_to_face:
		return
	print('here')
	if entity.global_position.direction_to(node_to_face.global_position).x < 0:
		entity.animated_sprite.flip_h = originally_looks_right
	else:
		entity.animated_sprite.flip_h = not originally_looks_right


func enable() -> void:
	enabled = true


func disable() -> void:
	enabled = false
