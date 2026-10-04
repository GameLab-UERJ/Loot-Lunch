extends Node
class_name HorizontalDodge
## Deixa um ator andar SÓ PARA OS LADOS (◀ ▶ / A D), dentro de [min_x, max_x], enquanto
## estiver ligado. Usado na Chuva de Esferas: o chef desvia no espaço dele.
##
##   desvio.start(chef, 40, 320)    # liga
##   desvio.stop()                  # desliga (quem chama devolve o ator ao lugar)
##
## Se o ator tiver `sprite` (SheetSprite) e `face()` (ex.: Battler), toca "andar"/"idle" e vira para o lado do movimento.
## `bot_axis` (-1..1) deixa testes automáticos "apertarem" as setas.


signal moved(x: float)


@export var left_action: StringName = &"ui_left"
@export var right_action: StringName = &"ui_right"
@export var speed: float = 170.0


var actor: Node2D
var min_x: float = 0.0
var max_x: float = 640.0
var active: bool = false
## Eixo extra somado ao teclado (testes).
var bot_axis: float = 0.0
var _moving: bool = false


func start(who: Node2D, from_x: float, to_x: float) -> void:
	actor = who
	min_x = minf(from_x, to_x)
	max_x = maxf(from_x, to_x)
	active = true


func stop() -> void:
	active = false
	bot_axis = 0.0
	_set_moving(false, 0.0)


func _physics_process(delta: float) -> void:
	if not active or not is_instance_valid(actor):
		return
	var axis: float = clampf(Input.get_axis(left_action, right_action) + bot_axis, -1.0, 1.0)
	if is_zero_approx(axis):
		_set_moving(false, 0.0)
		return
	var x: float = clampf(actor.global_position.x + axis * speed * delta, min_x, max_x)
	actor.global_position.x = x
	_set_moving(true, axis)
	moved.emit(x)


func _set_moving(value: bool, axis: float) -> void:
	# Sem tipo de propósito (duck typing): funciona com qualquer ator que tenha
	# `face(ponto)` e um SheetSprite em `sprite` (ex.: Battler da batalha).
	if not is_instance_valid(actor):
		return
	if value and not is_zero_approx(axis) and actor.has_method("face"):
		actor.face(actor.global_position + Vector2(axis * 10.0, 0.0))
	if value == _moving:
		return
	_moving = value
	var sprite = actor.get("sprite")
	if sprite is SheetSprite:
		var walk: StringName = actor.get("walk_animation") if actor.get("walk_animation") != null else &"andar"
		var idle: StringName = actor.get("idle_animation") if actor.get("idle_animation") != null else &"idle"
		(sprite as SheetSprite).play_sheet(walk if value else idle)
