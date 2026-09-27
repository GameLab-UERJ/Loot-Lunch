class_name PatienceComponent
extends Node2D

## Componente reutilizável de paciência para NPCs do restaurante.
## Gerencia uma contagem regressiva configurável e emite sinais quando
## o tempo muda ou se esgota completamente. Desenha uma barra de
## progresso visual em world space acima do NPC.
##
## Uso: adicione como filho de um Node2D (ex: Customer) via código ou
## na cena. Configure patience_time pelo Inspector — cada instância
## pode ter um valor diferente.

signal patience_changed(ratio: float)
signal patience_expired

@export var patience_time: float = 15.0

@export_group("Visual")
@export var bar_width: float = 32.0
@export var bar_height: float = 4.0
@export var bar_offset: Vector2 = Vector2(0.0, 0.0)
@export var warning_threshold: float = 0.5
@export var critical_threshold: float = 0.25
@export var color_safe: Color = Color(0.18, 0.8, 0.25)
@export var color_warning: Color = Color(0.95, 0.75, 0.1)
@export var color_critical: Color = Color(0.9, 0.15, 0.15)
@export var color_background: Color = Color(0.15, 0.15, 0.15, 0.85)
@export var show_bar: bool = true

var time_remaining: float = 0.0

var _is_running: bool = false
var _has_started: bool = false


func _ready() -> void:
	time_remaining = patience_time


func _process(delta: float) -> void:
	if not _is_running:
		return

	time_remaining = maxf(time_remaining - delta, 0.0)
	patience_changed.emit(get_ratio())
	queue_redraw()

	if time_remaining <= 0.0:
		_is_running = false
		patience_expired.emit()


func _draw() -> void:
	if not show_bar or not _has_started:
		return

	var ratio: float = get_ratio()
	var half_width: float = bar_width / 2.0
	var bar_pos: Vector2 = bar_offset - Vector2(half_width, 0.0)

	# Fundo da barra
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), color_background)

	# Preenchimento com cor baseada no ratio
	if ratio > 0.0:
		var fill_color: Color = _get_fill_color(ratio)
		var fill_width: float = bar_width * ratio
		draw_rect(Rect2(bar_pos, Vector2(fill_width, bar_height)), fill_color)


func start() -> void:
	time_remaining = patience_time
	_is_running = true
	_has_started = true
	queue_redraw()


func stop() -> void:
	_is_running = false
	_has_started = false
	time_remaining = patience_time
	queue_redraw()


func pause() -> void:
	_is_running = false


func resume() -> void:
	if time_remaining > 0.0:
		_is_running = true


func get_ratio() -> float:
	if patience_time <= 0.0:
		return 0.0
	return clampf(time_remaining / patience_time, 0.0, 1.0)


func is_running() -> bool:
	return _is_running


func has_started() -> bool:
	return _has_started


func _get_fill_color(ratio: float) -> Color:
	if ratio > warning_threshold:
		return color_safe
	if ratio > critical_threshold:
		return color_warning
	return color_critical
