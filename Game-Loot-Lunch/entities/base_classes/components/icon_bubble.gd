extends Node2D
class_name IconBubble
## Balão SIMPLES (desenhado por código, sem arte) com um ícone dentro.
## Não sabe o que é carne nem cogumelo — quem usa passa as texturas.
##
##   1 textura  -> o ícone inteiro            (ex.: só carne)
##   2 texturas -> metade de cada, lado a lado (ex.: misto = metade cogumelo | metade carne)
##   N texturas -> N fatias verticais, na ordem da lista (esquerda -> direita)
##
## Reutilizável: o que está assando em cada boca da churrasqueira, o que tem numa
## bancada, o que uma caixa entrega...
##
## Posicione ESTE nó na ponta do rabinho (o balão fica para cima dele).


signal bubble_shown
signal bubble_hidden


@export_group("Balão (pixels)")
## Largura x altura do corpo do balão, com a borda.
@export var body_size: Vector2i = Vector2i(16, 15)
## Altura do rabinho que aponta para baixo.
@export_range(0, 8) var tail_height: int = 3
@export var fill_color: Color = Color(0.97, 0.94, 0.87, 1.0)
@export var border_color: Color = Color(0.16, 0.10, 0.17, 1.0)

@export_group("Ícone")
## Tamanho máximo do ícone dentro do balão. A arte é encolhida para caber.
@export var icon_box: Vector2i = Vector2i(12, 11)
## Linha fina entre as fatias (misto). Transparente = sem linha.
@export var divider_color: Color = Color(0.16, 0.10, 0.17, 0.45)

@export_group("Destaque")
## Contorno extra quando este é o balão do item que o jogador vai pegar.
@export var highlight_color: Color = Color.WHITE

@export_group("Animação")
## Começa escondido (o normal: só aparece quando alguém chama `appear()`).
@export var start_hidden: bool = true
@export var pop_time: float = 0.15


var _icons: Array[Texture2D] = []
var _highlighted: bool = false
var _shown: bool = false
var _tween: Tween


func _ready() -> void:
	if start_hidden:
		visible = false
	else:
		_shown = true


# --- API pública ---

## Troca o conteúdo do balão. Lista de Texture2D (1 = inteiro, 2 = metade/metade...).
func set_icons(textures: Array) -> void:
	_icons.clear()
	for texture in textures:
		if texture is Texture2D:
			_icons.append(texture)
	queue_redraw()


func get_icons() -> Array[Texture2D]:
	return _icons


func set_highlighted(value: bool) -> void:
	if _highlighted == value:
		return
	_highlighted = value
	queue_redraw()


func is_highlighted() -> bool:
	return _highlighted


func is_shown() -> bool:
	return _shown


## Mostra o balão com um "pop" saindo do rabinho.
func appear() -> void:
	if _shown:
		return
	_shown = true
	visible = true
	_restart_tween()
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0
	_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, pop_time)
	_tween.parallel().tween_property(self, "modulate:a", 1.0, pop_time * 0.6)
	bubble_shown.emit()


## Esconde o balão encolhendo de volta para o rabinho.
func disappear() -> void:
	if not _shown:
		return
	_shown = false
	_restart_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "scale", Vector2(0.3, 0.3), pop_time * 0.8)
	_tween.parallel().tween_property(self, "modulate:a", 0.0, pop_time * 0.8)
	_tween.tween_callback(func() -> void: visible = false)
	bubble_hidden.emit()


# --- Desenho ---

func _draw() -> void:
	var body := Rect2(_body_top_left(), Vector2(body_size))
	if _highlighted:
		_draw_shape(body.grow(1.0), tail_height + 1, highlight_color)
	_draw_shape(body, tail_height, border_color)
	_draw_shape(body.grow(-1.0), tail_height - 1, fill_color)
	_draw_icons(body)


## Canto de cima/esquerda do corpo, com a ponta do rabinho em (0, 0).
func _body_top_left() -> Vector2:
	return Vector2(-floori(body_size.x / 2.0), -tail_height - body_size.y)


## Retângulo com cantos "arredondados" de 1 pixel + rabinho em escada para baixo.
func _draw_shape(rect: Rect2, tail: int, color: Color) -> void:
	if rect.size.x <= 2.0 or rect.size.y <= 2.0:
		return
	draw_rect(Rect2(rect.position.x + 1.0, rect.position.y, rect.size.x - 2.0, rect.size.y), color)
	draw_rect(Rect2(rect.position.x, rect.position.y + 1.0, rect.size.x, rect.size.y - 2.0), color)
	# Rabinho: cada linha 2 px mais estreita, centralizado no meio do corpo.
	var center_x: float = floorf(rect.position.x + rect.size.x * 0.5)
	var bottom: float = rect.end.y
	for row in range(maxi(tail, 0)):
		var half: int = tail - row
		draw_rect(Rect2(center_x - half + 1.0, bottom + row, half * 2.0 - 1.0, 1.0), color)


func _draw_icons(body: Rect2) -> void:
	var count: int = _icons.size()
	if count == 0:
		return
	var box_size := Vector2(icon_box)
	var box := Rect2((body.get_center() - box_size * 0.5).round(), box_size)
	var slice_width: float = box.size.x / count

	for i in count:
		var texture: Texture2D = _icons[i]
		var tex_size: Vector2 = texture.get_size()
		if tex_size.x <= 0.0 or tex_size.y <= 0.0:
			continue
		# O ícone inteiro, encolhido para caber na caixa e centralizado nela.
		var fit: float = minf(1.0, minf(box.size.x / tex_size.x, box.size.y / tex_size.y))
		var drawn_size: Vector2 = (tex_size * fit).round()
		var drawn := Rect2((box.get_center() - drawn_size * 0.5).round(), drawn_size)
		# Só a fatia i dele (em pixels do balão), convertida para pixels da textura.
		var slice := Rect2(box.position.x + slice_width * i, drawn.position.y, slice_width, drawn.size.y)
		var visible_part: Rect2 = drawn.intersection(slice)
		if visible_part.size.x <= 0.0:
			continue
		var source := Rect2(
			(visible_part.position - drawn.position) / fit,
			visible_part.size / fit
		)
		draw_texture_rect_region(texture, visible_part, source)

	if count > 1 and divider_color.a > 0.0:
		for i in range(1, count):
			var x: float = roundf(box.position.x + slice_width * i)
			draw_rect(Rect2(x, box.position.y, 1.0, box.size.y), divider_color)


func _restart_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
