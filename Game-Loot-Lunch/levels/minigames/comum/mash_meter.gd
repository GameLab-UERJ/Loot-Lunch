extends Node2D
class_name MashMeter
## QTE de MARTELAR: aperte a ação (ESPAÇO) várias vezes até encher a barra antes do
## tempo acabar. A barra esvazia sozinha (`decay`), então não dá para parar.
##
##   var progresso: float = await medidor.run(14, 2.6, 2.0)   # 0..1 (1 = conseguiu)
##
## Desenhado por código (sem arte). Reutilizável: resistir a raio, empurrar porta,
## sacudir para se soltar...


signal finished(progress: float)


@export var action: StringName = &"chef_pick_drop"
@export var bar_size: Vector2 = Vector2(64, 8)
@export var prompt: String = "ESPAÇO!"
@export var fill_color: Color = Color(0.85, 0.5, 1.0)
@export var full_color: Color = Color(1.0, 1.0, 1.0)


## 0..1
var progress: float = 0.0
var _required: int = 1
var _decay: float = 0.0
var _time_left: float = 0.0
var _duration: float = 1.0
var _running: bool = false
var _bump: float = 0.0


func _init() -> void:
	z_index = 90
	visible = false


func is_running() -> bool:
	return _running


## `required` apertos enchem a barra; `decay` = apertos que "vazam" por segundo.
func run(required: int, duration: float, decay: float = 0.0) -> float:
	_required = maxi(required, 1)
	_duration = maxf(duration, 0.1)
	_time_left = _duration
	_decay = decay
	progress = 0.0
	_running = true
	visible = true
	var result: float = await finished
	return result


## Um aperto (o jogador ou um teste).
func press() -> void:
	if not _running:
		return
	progress = minf(progress + 1.0 / _required, 1.0)
	_bump = 1.0
	if progress >= 1.0:
		_finish()


func _unhandled_input(event: InputEvent) -> void:
	if _running and InputMap.has_action(action) and event.is_action_pressed(action) and not event.is_echo():
		get_viewport().set_input_as_handled()
		press()


func _process(delta: float) -> void:
	if not _running:
		return
	_time_left -= delta
	_bump = maxf(_bump - delta * 6.0, 0.0)
	progress = maxf(progress - _decay / _required * delta, 0.0)
	if _time_left <= 0.0:
		_finish()
	queue_redraw()


func _finish() -> void:
	if not _running:
		return
	_running = false
	queue_redraw()
	var result: float = progress
	var tween := create_tween()
	tween.tween_interval(0.25)
	tween.tween_callback(hide)
	finished.emit(result)


func _draw() -> void:
	var size: Vector2 = bar_size * (1.0 + _bump * 0.12)
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect.grow(2.0), Color(0.08, 0.04, 0.1, 0.9))
	var fill := rect
	fill.size.x *= progress
	draw_rect(fill, fill_color.lerp(full_color, progress * progress))
	draw_rect(rect.grow(2.0), Color(0.95, 0.72, 0.25), false, 1.0)
	# Tempo restante (linha embaixo).
	var t: float = clampf(_time_left / _duration, 0.0, 1.0)
	draw_line(Vector2(rect.position.x, rect.end.y + 4), Vector2(rect.position.x + rect.size.x * t, rect.end.y + 4),
		Color(1, 1, 1, 0.7), 2.0)
	var font: Font = ThemeDB.fallback_font
	var blink: float = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.02)
	var text_size: Vector2 = font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_CENTER, -1, 10)
	var at := Vector2(-text_size.x * 0.5, rect.position.y - 6)
	draw_string_outline(font, at, prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, 4, Color(0.1, 0.05, 0.12))
	draw_string(font, at, prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(1, 0.95, 0.6, blink))
