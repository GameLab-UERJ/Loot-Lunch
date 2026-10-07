extends Node2D
class_name TargetCursor
## MARCADOR DE ALVO: setinha dourada balançando em cima de quem está na mira.
## Desenhada por código (sem arte). Segue o nó escolhido até trocar de alvo.
##
##   cursor.follow(formiga, Vector2(0, -60))   # mira nela
##   cursor.follow(null)                       # some
##
## Reutilizável: alvo de batalha, item selecionado, indicador de "fale com ele".


@export var color: Color = Color(1.0, 0.85, 0.3, 1.0)
@export var outline: Color = Color(0.17, 0.11, 0.05, 1.0)
@export var size: Vector2 = Vector2(12, 8)
@export var bob_height: float = 3.0
@export var bob_speed: float = 6.0


var _target: Node2D = null
var _offset: Vector2 = Vector2.ZERO
var _clock: float = 0.0


func _ready() -> void:
	z_index = 60
	hide()


func follow(target: Node2D, offset: Vector2 = Vector2.ZERO) -> void:
	_target = target
	_offset = offset
	visible = is_instance_valid(target)
	_update_position()


func _process(delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(_target):
		hide()
		return
	_clock += delta
	_update_position()


func _update_position() -> void:
	if is_instance_valid(_target):
		global_position = _target.global_position + _offset + Vector2(0.0, sin(_clock * bob_speed) * bob_height)


func _draw() -> void:
	var half: float = size.x * 0.5
	var tri := PackedVector2Array([Vector2(-half, -size.y), Vector2(half, -size.y), Vector2(0, 0)])
	var border := PackedVector2Array([Vector2(-half - 2, -size.y - 1.5), Vector2(half + 2, -size.y - 1.5), Vector2(0, 2.5)])
	draw_colored_polygon(border, outline)
	draw_colored_polygon(tri, color)
