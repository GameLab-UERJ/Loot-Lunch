@tool
extends StaticBody2D
class_name MushroomTree
## Árvore-cogumelo do Reino Caveira. Trocar `variant` no Inspector troca o desenho
## (o atlas `arvores_cogumelo.png` tem várias, lado a lado). O nó fica no PÉ do talo,
## então mover a árvore no editor leva o sprite e a colisão juntos.
##
## Fica dentro do nó com y_sort do mapa: o chef passa por trás do chapéu.


const CELL: Vector2i = Vector2i(56, 64)
## Ponto do pé do talo dentro de cada célula do atlas.
const BASE: Vector2i = Vector2i(28, 60)
## Quantos pixels acima do pé fica a origem (melhora a ordem com o chef no y_sort).
const SORT_LIFT: int = 6


@export_range(0, 9) var variant: int = 0:
	set(value):
		variant = value
		_apply()
@export var flip: bool = false:
	set(value):
		flip = value
		_apply()


func _ready() -> void:
	_apply()


func _apply() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	var count: int = 1
	if sprite.texture:
		count = maxi(1, sprite.texture.get_width() / CELL.x)
	var v: int = clampi(variant, 0, count - 1)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(v * CELL.x, 0, CELL.x, CELL.y)
	sprite.centered = false
	sprite.flip_h = flip
	sprite.position = Vector2(-BASE.x, -BASE.y + SORT_LIFT)
