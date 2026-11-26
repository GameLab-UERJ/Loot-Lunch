extends Node2D
class_name AmbientCreature
## BICHO DE CENÁRIO (morcego, aranha, alminha, cogumelinho, corvo...): só enfeite,
## não tem colisão e não interage com os jogadores.
##
## O nó fica parado no lugar onde foi colocado (a "âncora") e quem se mexe é o filho
## `Visual` (um SheetRowSprite tocando a linha 1 da folha). Assim, no editor, dá para
## arrastar o bicho e ver onde ele mora.
##
##   PARADO    -> só toca a animação (corvo, olho do brejo, vela)
##   VOO       -> voa em "8" em volta da âncora (morcego)
##   PENDURADO -> sobe e desce num fio de teia (aranha)
##   FLUTUAR   -> boia devagar para os lados (alminha)
##   PASSEAR   -> anda até um ponto sorteado dentro do raio, para, escolhe outro (cogumelinho)


enum Motion { PARADO, VOO, PENDURADO, FLUTUAR, PASSEAR }


@export var motion: Motion = Motion.PARADO
## Tamanho do passeio (VOO/FLUTUAR = amplitude; PASSEAR = raio; PENDURADO = y = comprimento do fio).
@export var area: Vector2 = Vector2(40, 16)
## Velocidade (VOO/FLUTUAR/PENDURADO = ciclos; PASSEAR = px/s).
@export var speed: float = 1.0
## Espelha o sprite para o lado em que está indo.
@export var flip_with_direction: bool = true
## A arte original olha para a ESQUERDA.
@export var art_faces_left: bool = false
## Espera entre um passeio e outro (PASSEAR), em segundos (mín, máx).
@export var wait_range: Vector2 = Vector2(1.0, 3.0)
@export var thread_color: Color = Color(0.92, 0.92, 0.98, 0.55)


var _time: float = 0.0
var _target: Vector2 = Vector2.ZERO
var _wait: float = 0.0


@onready var visual: SheetRowSprite = $Visual


func _ready() -> void:
	_time = randf() * 100.0
	visual.show_row(1)
	if visual.sprite_frames:
		var count: int = visual.sprite_frames.get_frame_count(visual.animation)
		visual.frame = randi() % maxi(1, count)
	visual.speed_scale = randf_range(0.9, 1.1)
	_wait = randf_range(wait_range.x, wait_range.y)


func _process(delta: float) -> void:
	_time += delta * speed
	var before: Vector2 = visual.position
	match motion:
		Motion.VOO:
			visual.position = Vector2(sin(_time) * area.x, sin(_time * 2.0) * area.y * 0.5)
		Motion.PENDURADO:
			visual.position = Vector2(0, (sin(_time) * 0.5 + 0.5) * area.y + 4.0)
			queue_redraw()
		Motion.FLUTUAR:
			visual.position = Vector2(sin(_time * 0.7) * area.x, sin(_time * 1.3) * area.y)
		Motion.PASSEAR:
			_wander(delta)
	if flip_with_direction and motion != Motion.PENDURADO:
		var dx: float = visual.position.x - before.x
		if absf(dx) > 0.01:
			visual.flip_h = (dx < 0.0) != art_faces_left


func _draw() -> void:
	if motion == Motion.PENDURADO and visual:
		draw_line(Vector2.ZERO, visual.position + Vector2(0, -3), thread_color, 1.0)


func _wander(delta: float) -> void:
	if _wait > 0.0:
		_wait -= delta
		visual.speed_scale = 0.0
		if _wait <= 0.0:
			_target = Vector2(randf_range(-area.x, area.x), randf_range(-area.y, area.y))
		return
	visual.speed_scale = 1.0
	visual.position = visual.position.move_toward(_target, speed * delta * 20.0)
	if visual.position.distance_to(_target) < 0.5:
		_wait = randf_range(wait_range.x, wait_range.y)
