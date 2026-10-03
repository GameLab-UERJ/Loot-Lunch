extends CanvasLayer
class_name CinemaBars
## FAIXAS PRETAS DE CINEMA (em cima e embaixo) + CLARÃO branco da tela inteira.
## Monta os nós por código, é só adicionar o nó na cena.
##
##   await faixas.show_bars()   # entram
##   await faixas.flash(0.9)    # clarão
##   await faixas.hide_bars()   # saem


@export var bar_height: float = 34.0
@export var bar_color: Color = Color.BLACK


var _top: ColorRect
var _bottom: ColorRect
var _flash: ColorRect


func _init() -> void:
	layer = 30


func _ready() -> void:
	_top = _make_rect(Control.PRESET_TOP_WIDE, bar_color)
	_bottom = _make_rect(Control.PRESET_BOTTOM_WIDE, bar_color)
	_flash = _make_rect(Control.PRESET_FULL_RECT, Color.WHITE)
	_flash.modulate.a = 0.0
	set_amount(0.0)


func show_bars(duration: float = 0.6) -> void:
	await _tween_amount(0.0, 1.0, duration)


func hide_bars(duration: float = 0.4) -> void:
	await _tween_amount(1.0, 0.0, duration)


## 0 = sem faixas, 1 = faixas inteiras.
func set_amount(t: float) -> void:
	if _top == null:
		return
	for bar in [_top, _bottom]:
		bar.offset_left = 0.0
		bar.offset_right = 0.0
	_top.offset_top = 0.0
	_top.offset_bottom = bar_height * t
	_bottom.offset_top = -bar_height * t
	_bottom.offset_bottom = 0.0


func flash(peak: float = 0.9, fade: float = 0.6) -> void:
	var tween := create_tween()
	tween.tween_property(_flash, "modulate:a", peak, 0.12)
	tween.tween_property(_flash, "modulate:a", 0.0, fade)
	await tween.finished


func _tween_amount(from: float, to: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_method(set_amount, from, to, duration).set_trans(Tween.TRANS_SINE)
	await tween.finished


func _make_rect(preset: Control.LayoutPreset, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.color = color
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	rect.set_anchors_and_offsets_preset(preset)
	return rect
