extends Node2D
class_name GarrafaManteiga
## GARRAFA DE MANTEIGA controlada pelo MOUSE (Fase 2).
##
##   - Segue o mouse na horizontal (entre `min_x` e `max_x`), com um leve atraso de peso.
##   - SEGURAR o clique esquerdo inclina a garrafa; depois de inclinada a manteiga ESCORRE
##     (um filete desenhado por código até `stream_floor_y`).
##   - Soltar o clique endireita a garrafa e o filete para.
##
## A garrafa não sabe de macaxeira nem de dose: quem usa pergunta `is_flowing()` e
## `get_stream_x()` e decide se a manteiga caiu no lugar certo.


signal flow_changed(is_flowing: bool)


@export var enabled: bool = false
@export var pour_action: StringName = &"left_click"
@export var min_x: float = 120.0
@export var max_x: float = 520.0
## Quão rápido a garrafa alcança o mouse (maior = mais "leve").
@export var follow_speed: float = 10.0
## Inclinação máxima ao despejar (graus). Negativo = inclina para a esquerda.
@export var tilt_degrees: float = -125.0
@export var tilt_speed: float = 9.0
## Parte da inclinação a partir da qual a manteiga começa a sair (0..1).
@export_range(0.1, 1.0) var flow_threshold: float = 0.8
## Altura (Y global) onde o filete acaba (a chapa).
@export var stream_floor_y: float = 215.0
## Boca da garrafa em relação ao centro (antes de girar).
@export var mouth_offset: Vector2 = Vector2(0, -30)
@export var stream_color: Color = Color(0.98, 0.8, 0.3, 1.0)
@export var stream_shadow_color: Color = Color(0.8, 0.55, 0.15, 1.0)


var pouring: bool = false
var _flowing: bool = false
var _clock: float = 0.0


func _process(delta: float) -> void:
	_clock += delta
	if enabled:
		var target_x: float = clampf(get_global_mouse_position().x, min_x, max_x)
		global_position.x = lerpf(global_position.x, target_x, clampf(follow_speed * delta, 0.0, 1.0))
	var target_rotation: float = deg_to_rad(tilt_degrees) if pouring and enabled else 0.0
	rotation = lerp_angle(rotation, target_rotation, clampf(tilt_speed * delta, 0.0, 1.0))

	var flowing: bool = pouring and enabled \
		and absf(rotation) >= absf(deg_to_rad(tilt_degrees)) * flow_threshold
	if flowing != _flowing:
		_flowing = flowing
		flow_changed.emit(_flowing)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled or pour_action == &"" or not InputMap.has_action(pour_action):
		return
	if event.is_action_pressed(pour_action):
		pouring = true
		get_viewport().set_input_as_handled()
	elif event.is_action_released(pour_action):
		pouring = false
		get_viewport().set_input_as_handled()


func set_enabled(value: bool) -> void:
	enabled = value
	if not enabled:
		pouring = false


func is_flowing() -> bool:
	return _flowing


func get_mouth_global() -> Vector2:
	return to_global(mouth_offset)


## X onde o filete encosta na chapa.
func get_stream_x() -> float:
	return get_mouth_global().x


func _draw() -> void:
	if not _flowing:
		return
	var mouth: Vector2 = mouth_offset
	var floor_point: Vector2 = to_local(Vector2(get_mouth_global().x, stream_floor_y))
	var wobble := Vector2(sin(_clock * 30.0), 0.0).rotated(-rotation)
	draw_line(mouth, floor_point + wobble, stream_shadow_color, 4.0)
	draw_line(mouth, floor_point + wobble, stream_color, 2.0)
	# Gotinhas descendo pelo filete.
	for i in 3:
		var t: float = fmod(_clock * 2.5 + i / 3.0, 1.0)
		draw_circle(mouth.lerp(floor_point, t), 2.0, stream_color.lightened(0.3))
	draw_circle(floor_point, 4.0 + sin(_clock * 20.0), stream_color)
