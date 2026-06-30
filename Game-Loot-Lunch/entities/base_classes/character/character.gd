extends CharacterBody2D
class_name Character


const FRICTION: float = 0.15


signal got_hurt


@export var hp: int = 2
@export var acceleration: int = 40
@export var max_speed: int = 100
@export var invencibility_time: float = 0.5


@onready var state_machine: Node = get_node("FiniteStateMachine")
@onready var animated_sprite: AnimatedSprite2D = get_node("AnimatedSprite2D")


var is_invincible: bool = false
var mov_direction: Vector2 = Vector2.ZERO


func _physics_process(_delta: float) -> void:
	move_and_slide()
	velocity = lerp(velocity, Vector2.ZERO, FRICTION)


func take_damage(dam: int, dir: Vector2, force: int) -> void:
	if is_invincible:
		return
  
	is_invincible = true
	start_invincibility()
	hp -= dam
	got_hurt.emit()
	if hp > 0:
		state_machine.set_state(state_machine.states.hurt)
		velocity += dir * force
	else:
		state_machine.set_state(state_machine.states.dead)
		velocity += dir * force * 2


func start_invincibility() -> void:
	await get_tree().create_timer(invencibility_time).timeout
	is_invincible = false
