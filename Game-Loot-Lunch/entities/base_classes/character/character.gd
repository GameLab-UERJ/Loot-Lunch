extends CharacterBody2D
class_name Character


const FRICTION: float = 0.15


signal took_damage
signal got_hurt
signal died


@export var hp: int = 2
@export var acceleration: int = 40
@export var max_speed: int = 100
@export var invencibility_time: float = 0.5


@onready var animated_sprite: AnimatedSprite2D = get_node("AnimatedSprite2D")


var is_invincible: bool = false
var mov_direction: Vector2 = Vector2.ZERO


func _physics_process(_delta: float) -> void:
	move_and_slide()
	velocity = lerp(velocity, Vector2.ZERO, FRICTION)


func take_damage(damage: int, direction: Vector2, force: int) -> void:
	if is_invincible:
		return
	
	start_invincibility()
	
	hp -= damage
	took_damage.emit()
	if hp > 0:
		got_hurt.emit()
		velocity += direction * force
	else:
		died.emit()
		#velocity += direction * force * 2


func start_invincibility() -> void:
	is_invincible = true
	await get_tree().create_timer(invencibility_time).timeout
	is_invincible = false
