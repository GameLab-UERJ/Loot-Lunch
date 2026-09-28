extends HBoxContainer
class_name MoneyCounter
## Contador de dinheiro: ícone + número. O número "corre" até o valor novo
## e o ícone dá um pulinho quando ganha.
##
## Não sabe de onde vem o dinheiro: quem usa chama `set_amount(valor)`.
##
## Estrutura esperada:
##   Dinheiro (este script)
##   ├── Icone (TextureRect)
##   └── Valor (Label)


@export var count_time: float = 0.35
@export var punch_scale: float = 1.3
@export var punch_time: float = 0.2


var _displayed: float = 0.0
var _count_tween: Tween


@onready var icon: TextureRect = $Icone
@onready var value_label: Label = $Valor


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.pivot_offset = icon.custom_minimum_size * 0.5
	_set_displayed(_displayed)


func set_amount(value: int, animate: bool = true) -> void:
	if _count_tween:
		_count_tween.kill()
	if not animate or not is_inside_tree():
		_set_displayed(value)
		return

	if value > roundi(_displayed):
		_punch()
	_count_tween = create_tween()
	_count_tween.tween_method(_set_displayed, _displayed, float(value), count_time)


func _set_displayed(value: float) -> void:
	_displayed = value
	if value_label:
		value_label.text = str(roundi(value))


func _punch() -> void:
	icon.scale = Vector2.ONE * punch_scale
	create_tween().tween_property(icon, "scale", Vector2.ONE, punch_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
