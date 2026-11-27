extends Area2D
class_name HitboxComponent
## Área que dá dano em quem tem `take_damage` (Character): espada do Player, olho voador,
## espinhos, panela do chef, morcego, Brasa...
##
## Acertou um corpo: dano na hora. Ficou encostado: dano de novo a cada `repeat_time` s.
## Cada corpo é acompanhado separado (vários alvos dentro ao mesmo tempo funcionam).


signal hit

@export var damage: int = 1
@export var knockback_force: int = 300
## Segundos entre um dano e outro enquanto o corpo continua encostado.
@export var repeat_time: float = 1.0
## Só acerta corpos deste grupo (ex.: &"chefs", &"inimigos"). Vazio = qualquer um da máscara.
## Os outros são ignorados (não levam dano nem apagam a hitbox).
@export var target_group: StringName = &""
## true = empurra o alvo PARA LONGE do centro da hitbox (ex.: encostar na Brasa).
## false = usa `knockback_direction` (ou a velocidade do pai, se estiver vazia).
@export var knockback_from_center: bool = false

## Verdadeiro enquanto tem algum alvo dentro.
var body_inside: bool = false
var knockback_direction: Vector2 = Vector2.ZERO

var _bodies: Array[Node2D] = []

@onready var collision_shape: CollisionShape2D = get_child(0)
@onready var timer: Timer = Timer.new()


func _init() -> void:
	var __ = connect("body_entered", Callable(self, "_on_body_entered"))
	__ = connect("body_exited", Callable(self, "_on_body_exited"))


func _ready() -> void:
	assert(collision_shape != null)
	timer.wait_time = repeat_time
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)


func _on_body_entered(body: Node2D) -> void:
	if not _is_target(body) or _bodies.has(body):
		return
	_bodies.append(body)
	body_inside = true
	_collide(body)
	if timer.is_inside_tree() and timer.is_stopped():
		timer.start()


func _on_body_exited(body: Node2D) -> void:
	_bodies.erase(body)
	body_inside = not _bodies.is_empty()
	if not body_inside:
		timer.stop()


func _on_timer_timeout() -> void:
	for body in _bodies.duplicate():
		if is_instance_valid(body) and body.is_inside_tree():
			_collide(body)
		else:
			_bodies.erase(body)
	body_inside = not _bodies.is_empty()
	if not body_inside:
		timer.stop()


func _is_target(body: Node2D) -> bool:
	return target_group == &"" or (body != null and body.is_in_group(target_group))


func _collide(body: Node2D) -> void:
	if not is_instance_valid(body):
		return
	if not body.has_method("take_damage"):
		queue_free()
		return
	var direction: Vector2 = knockback_direction
	if knockback_from_center:
		direction = global_position.direction_to(body.global_position)
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT.rotated(randf() * TAU)
	elif not direction:
		var parent_body := get_parent() as CharacterBody2D
		knockback_direction = parent_body.velocity.normalized() if parent_body else Vector2.ZERO
		direction = knockback_direction
	hit.emit()
	body.take_damage(damage, direction, knockback_force)
