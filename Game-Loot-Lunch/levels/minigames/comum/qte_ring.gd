extends Node2D
class_name QteRing
## Anel de QTE desenhado por código: um círculo que FECHA até o alvo no instante do
## impacto. Fica verde enquanto a janela está aberta; no fim pisca verde (acertou) ou
## vermelho (errou) e some. Criado pelo QteTrack; não precisa de cena.


@export var start_radius: float = 34.0
@export var target_radius: float = 12.0
@export var width: float = 2.0
@export var idle_color: Color = Color(1.0, 0.95, 0.8, 0.9)
@export var open_color: Color = Color(0.55, 1.0, 0.45, 1.0)
@export var hit_color: Color = Color(0.55, 1.0, 0.45, 1.0)
@export var miss_color: Color = Color(1.0, 0.35, 0.3, 1.0)


var _time_to_hit: float = 0.5
var _total: float = 0.5
var _early: float = 0.15
var _late: float = 0.08
var _resolved: bool = false
var _color: Color


func setup(time_to_hit: float, early: float, late: float) -> void:
	_time_to_hit = time_to_hit
	_total = time_to_hit
	_early = early
	_late = late
	z_index = 40
	_color = idle_color


func resolve(success: bool) -> void:
	if _resolved:
		return
	_resolved = true
	_color = hit_color if success else miss_color
	queue_redraw()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.6, 1.6) if success else Vector2(0.6, 0.6), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	tween.chain().tween_callback(queue_free)


func _process(delta: float) -> void:
	if _resolved:
		return
	_time_to_hit -= delta
	_color = open_color if _time_to_hit <= _early and _time_to_hit >= -_late else idle_color
	queue_redraw()


func _draw() -> void:
	draw_arc(Vector2.ZERO, target_radius, 0.0, TAU, 32, Color(_color, 0.55), 1.0)
	var t: float = clampf(_time_to_hit / maxf(_total, 0.01), 0.0, 1.0)
	var radius: float = lerpf(target_radius, start_radius, t) if not _resolved else target_radius
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, _color, width)
