class_name QueueMovementComponent
extends Node

## Componente reutilizável que leva o node pai até uma posição alvo.
## Cuida apenas do movimento físico; transições de estado (FSM do cliente)
## são responsabilidade de quem o utiliza (ver customer.gd).
##
## - Se o pai for um "Character", apenas ajustamos velocity/mov_direction;
##   o próprio Character já faz move_and_slide() + fricção sozinho em seu
##   _physics_process. process_priority negativo garante que este
##   componente rode ANTES do Character no mesmo frame.
## - Se o pai for outro Node2D/CharacterBody2D qualquer (sem a base
##   Character), movemos o node diretamente (fallback genérico).

signal arrived_at_target(target_position: Vector2)

@export var move_speed: float = 60.0
@export var arrival_threshold: float = 4.0

var _target_position: Vector2
var _is_moving: bool = false

var _character: Character
var _parent_node2d: Node2D


func _ready() -> void:
	process_priority = -10

	var parent: Node = get_parent()
	if parent is Character:
		_character = parent
	elif parent is Node2D:
		_parent_node2d = parent
	else:
		push_warning("QueueMovementComponent: o node pai precisa ser um Node2D (idealmente um Character).")


func move_to(new_target: Vector2) -> void:
	_target_position = new_target
	_is_moving = true


func stop() -> void:
	_is_moving = false
	if _character:
		_character.velocity = Vector2.ZERO
		_character.mov_direction = Vector2.ZERO


func is_moving() -> bool:
	return _is_moving


func _physics_process(delta: float) -> void:
	if not _is_moving:
		return

	if _character:
		_process_character_movement()
	elif _parent_node2d:
		_process_generic_movement(delta)


func _process_character_movement() -> void:
	var to_target: Vector2 = _target_position - _character.global_position
	var distance: float = to_target.length()

	if distance <= arrival_threshold:
		_is_moving = false
		_character.global_position = _target_position
		_character.velocity = Vector2.ZERO
		_character.mov_direction = Vector2.ZERO
		arrived_at_target.emit(_target_position)
		return

	var direction: Vector2 = to_target.normalized()
	_character.mov_direction = direction
	_character.velocity = direction * move_speed


func _process_generic_movement(delta: float) -> void:
	var to_target: Vector2 = _target_position - _parent_node2d.global_position
	var distance: float = to_target.length()

	if distance <= arrival_threshold:
		_is_moving = false
		_parent_node2d.global_position = _target_position
		if _parent_node2d is CharacterBody2D:
			_parent_node2d.velocity = Vector2.ZERO
		arrived_at_target.emit(_target_position)
		return

	var step_velocity: Vector2 = to_target.normalized() * move_speed

	if _parent_node2d is CharacterBody2D:
		_parent_node2d.velocity = step_velocity
		_parent_node2d.move_and_slide()
	else:
		_parent_node2d.global_position += step_velocity * delta
