extends Node2D
class_name ProgressBarComponent
## Barrinha de progresso desenhada por código, para pendurar em qualquer coisa do mundo
## (tábua de corte, fogão, pé de cogumelo, barra de vida de cliente...).
##
## Quem usa chama `set_progress(0..1)` e `set_bar_visible(true/false)`.
## Posicione o nó onde a barra deve aparecer (ex.: Vector2(0, -18) acima do sprite).


@export var size: Vector2 = Vector2(24, 4)
## Se true, a barra fica centralizada na posição do nó. Se false, cresce para a direita.
@export var centered: bool = true
@export var fill_color: Color = Color(0.95, 0.72, 0.25, 1.0)
@export var background_color: Color = Color(0.0, 0.0, 0.0, 0.6)
@export var border_color: Color = Color(0.0, 0.0, 0.0, 0.5)
## Começa escondida (o normal: só aparece quando a tarefa começa).
@export var start_hidden: bool = true


var progress: float = 0.0


func _ready() -> void:
	if start_hidden:
		visible = false
	queue_redraw()


## `value` de 0.0 a 1.0.
func set_progress(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_bar_visible(value: bool) -> void:
	if visible == value:
		return
	visible = value
	queue_redraw()


func _draw() -> void:
	var origin: Vector2 = (-size * 0.5) if centered else Vector2.ZERO
	var back := Rect2(origin, size)

	draw_rect(back, background_color)

	var fill := back
	fill.size.x = size.x * progress
	if fill.size.x > 0.0:
		draw_rect(fill, fill_color)

	draw_rect(back, border_color, false, 1.0)
