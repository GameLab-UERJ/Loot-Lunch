extends Label
class_name FloatingText
## Texto que sobe e some (ex.: "+10 Almas" em cima do cliente, "-1" em cima do chef).
## Não precisa de cena: chame `FloatingText.spawn(...)` de qualquer lugar.


@export var rise: float = 18.0
@export var duration: float = 0.9


var _anchor: Vector2 = Vector2.ZERO


## Cria o texto em `global_pos`, dentro de `parent` (use a fase/cena atual).
static func spawn(parent: Node, global_pos: Vector2, message: String, color: Color = Color.WHITE) -> FloatingText:
	if parent == null:
		return null
	var label := FloatingText.new()
	label.text = message
	label.modulate = color
	label._anchor = global_pos
	parent.add_child(label)
	label.global_position = global_pos
	return label


func _init() -> void:
	z_index = 50
	visible = false  # só aparece depois de centralizado
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_font_size_override("font_size", 10)
	add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.1))
	add_theme_constant_override("outline_size", 4)


func _ready() -> void:
	# O tamanho só é conhecido depois de entrar na árvore: centraliza de novo.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	reset_size()
	global_position = _anchor - size * 0.5
	show()

	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", position.y - rise, duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.5).set_delay(duration * 0.5)
	tween.chain().tween_callback(queue_free)
