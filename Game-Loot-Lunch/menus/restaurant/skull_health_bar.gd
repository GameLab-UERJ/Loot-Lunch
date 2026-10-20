extends HBoxContainer
class_name SkullHealthBar
## Barra de vida em CAVEIRAS, estilo corações do Zelda.
## Cada caveira vale `health_per_skull` pontos de vida (2 = dá para ter MEIA caveira).
##
## A arte é uma folha com 3 quadros lado a lado (jscoutinho_ui_vida.png, 72x24):
##   quadro 0 = cheia | quadro 1 = metade | quadro 2 = vazia
##
## Não sabe quem é o dono da vida: quem usa chama `set_health(atual, máximo)`.
## Reutilizável: chef, 2º jogador, chefão, qualquer barra de "corações".


@export_group("Arte")
@export var sheet: Texture2D
@export var frame_size: Vector2i = Vector2i(24, 24)
@export var full_frame: int = 0
@export var half_frame: int = 1
@export var empty_frame: int = 2
## Tamanho de cada caveira na tela (1 = tamanho da arte).
@export var skull_scale: float = 1.0

@export_group("Regras")
## Pontos de vida por caveira. 2 = meia caveira por dano; 1 = sem meia caveira.
@export_range(1, 8) var health_per_skull: int = 2

@export_group("Animação")
## "Soco" na caveira que mudou. 1 = desliga.
@export var punch_scale: float = 1.35
@export var punch_time: float = 0.18


var _frames: Array[AtlasTexture] = []
var _skulls: Array[TextureRect] = []
var _last_health: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_frames()


func set_health(current: int, maximum: int) -> void:
	if _frames.is_empty():
		_build_frames()
	current = clampi(current, 0, maxi(maximum, 0))
	var count: int = ceili(float(maxi(maximum, 0)) / health_per_skull)
	_resize(count)

	for i in _skulls.size():
		var remaining: int = current - i * health_per_skull
		var frame: int = empty_frame
		if remaining >= health_per_skull:
			frame = full_frame
		elif remaining > 0:
			frame = half_frame
		_skulls[i].texture = _get_frame(frame)

	if _last_health >= 0 and current != _last_health and not _skulls.is_empty():
		# A caveira que mudou: a que perdeu (dano) ou a que ganhou (cura) o último ponto.
		var changed_unit: int = current if current < _last_health else current - 1
		_punch(_skulls[clampi(changed_unit / health_per_skull, 0, _skulls.size() - 1)])
	_last_health = current


func _build_frames() -> void:
	_frames.clear()
	if sheet == null:
		return
	var columns: int = maxi(1, int(sheet.get_width() / frame_size.x))
	for i in columns:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(i * frame_size.x, 0, frame_size.x, frame_size.y)
		_frames.append(atlas)


func _get_frame(index: int) -> Texture2D:
	if _frames.is_empty():
		return null
	return _frames[clampi(index, 0, _frames.size() - 1)]


func _resize(count: int) -> void:
	while _skulls.size() < count:
		var skull := TextureRect.new()
		skull.custom_minimum_size = Vector2(frame_size) * skull_scale
		skull.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		skull.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		skull.pivot_offset = skull.custom_minimum_size * 0.5
		skull.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(skull)
		_skulls.append(skull)
	while _skulls.size() > count:
		_skulls.pop_back().queue_free()


func _punch(skull: TextureRect) -> void:
	if punch_scale == 1.0 or punch_time <= 0.0:
		return
	skull.scale = Vector2.ONE * punch_scale
	create_tween().tween_property(skull, "scale", Vector2.ONE, punch_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
