extends Area2D
class_name GreaseTrap
## POÇA DE GRAXA: quem pisa fica mais lento enquanto estiver dentro dela.
##
## Correção de 23/10/2026: a lentidão agora passa pelo SlowComponent (regra do projeto:
## "quem quiser deixar o personagem mais lento usa ESTE componente"). Antes a poça
## escrevia direto num multiplicador do Character, o que causava:
##   - duas poças encostadas: sair de UMA devolvia a velocidade normal, mesmo ainda
##     estando dentro da outra;
##   - graxa + magia de lentidão (Mandy/demoninho) se multiplicavam por fora do
##     SlowComponent (dois sistemas mexendo na mesma velocidade).
## Com o SlowComponent cada poça é uma FONTE: vale a lentidão mais forte, e se a poça
## sumir (queue_free) a lentidão dela sai sozinha.


## Velocidade dentro da graxa, em fração da normal (0.45 = anda a 45%).
@export_range(0.1, 1.0, 0.05) var movement_multiplier: float = 0.45
@export_range(4.0, 64.0, 1.0) var hitbox_radius: float = 18.0
## Cor que o personagem ganha enquanto está na graxa.
@export var slow_tint: Color = Color(0.75, 0.7, 0.55)

var _affected_bodies: Dictionary = {}

@onready var hitbox: CollisionShape2D = $Hitbox


func _ready() -> void:
	var circle_shape := hitbox.shape as CircleShape2D
	if circle_shape:
		circle_shape = circle_shape.duplicate()
		circle_shape.radius = hitbox_radius
		hitbox.shape = circle_shape


## O SlowComponent tira sozinho lentidões "esquecidas" depois de `max_source_time`.
## Quem continua parado na graxa tem a lentidão renovada a cada segundo.
var _refresh_left: float = 1.0


func _physics_process(delta: float) -> void:
	if _affected_bodies.is_empty():
		return
	_refresh_left -= delta
	if _refresh_left > 0.0:
		return
	_refresh_left = 1.0
	for body in _affected_bodies.keys():
		if is_instance_valid(body):
			SlowComponent.apply(body, self, 1.0 - movement_multiplier, 0.0, slow_tint)
		else:
			_affected_bodies.erase(body)


func _exit_tree() -> void:
	# Garante que ninguém fica lento se a poça sumir com alguém dentro.
	for body in _affected_bodies.keys():
		if is_instance_valid(body):
			SlowComponent.remove(body, self)
	_affected_bodies.clear()


func _on_body_entered(body: Node2D) -> void:
	var character := body as Character
	if character == null or _affected_bodies.has(character):
		return
	_affected_bodies[character] = true
	SlowComponent.apply(character, self, 1.0 - movement_multiplier, 0.0, slow_tint)


func _on_body_exited(body: Node2D) -> void:
	var character := body as Character
	if character == null or not _affected_bodies.has(character):
		return
	_affected_bodies.erase(character)
	if is_instance_valid(character):
		SlowComponent.remove(character, self)
