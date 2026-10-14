extends Node2D
class_name KeyPrompt
## AVISO DE TECLA em cima de alguém: "qual tecla apertar AGORA". Uma ou mais teclas
## desenhadas (KeyCap) + um texto curto ("REBATA!", "PULE!", "DESVIE!").
##
##   var aviso := KeyPrompt.spawn(chef, Vector2(0, -60), ["SPACE"], "REBATA!")
##   aviso.set_active(true)    # acende a tecla (ex.: a janela do QTE abriu)
##   aviso.dismiss()           # some com uma animação e se apaga
##
## Teclas aceitas: as mesmas do KeyCap ("SPACE", "LEFT", "RIGHT", "MOUSE_LEFT", "Q"...).
## Um "/" sozinho na lista vira um separador escrito "ou".
##
## Fica pendurado em quem chamou (acompanha o personagem). Sem arte, sem cena.
## Reutilizável: QTEs da batalha, dicas no restaurante, tutoriais interativos.


@export var caption_color: Color = Color(1.0, 0.9, 0.45)
@export var caption_size: int = 24
@export var key_height: float = 28.0
## Sobe e desce de leve (px).
@export var bob_amount: float = 2.0
## Teclas "afundam" sozinhas (ensina que é para apertar). Desligue para "segure".
@export var animate_keys: bool = true


var caps: Array[KeyCap] = []
var _caption: Label
var _row: Node2D
var _clock: float = 0.0
var _active: bool = false
var _leaving: bool = false


## Cria o aviso como filho de `parent`, em `offset` (posição local), e devolve ele.
static func spawn(parent: Node, offset: Vector2, keys: PackedStringArray, caption: String = "",
		animate: bool = true) -> KeyPrompt:
	var prompt := KeyPrompt.new()
	prompt.animate_keys = animate
	prompt.position = offset
	parent.add_child(prompt)
	prompt.setup(keys, caption)
	return prompt


func _init() -> void:
	z_index = 95
	z_as_relative = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Monta (ou remonta) as teclas e o texto.
func setup(keys: PackedStringArray, caption: String) -> void:
	if _row:
		_row.queue_free()
	if _caption:
		_caption.queue_free()
	caps.clear()
	_row = Node2D.new()
	add_child(_row)
	var gap: float = 4.0
	var items: Array[Node2D] = []
	var total: float = 0.0
	for key in keys:
		if key == "/":
			var sep := Label.new()
			sep.text = "ou"
			_style_label(sep, caption_size - 4, Color(1, 1, 1, 0.9))
			sep.size = Vector2(16, 14)
			items.append(_wrap(sep, Vector2(16, 14)))
			total += 16.0 + gap
			continue
		var cap := KeyCap.new()
		cap.key = key
		cap.height = key_height
		cap.font_size = maxi(int(key_height * 0.82), 10)
		cap.pressing = animate_keys
		cap.press_period = 0.55
		caps.append(cap)
		items.append(cap)
		total += cap.get_width() + gap
	total -= gap
	var x: float = -total * 0.5
	for item in items:
		var w: float = item.get_width() if item is KeyCap else 16.0
		item.position = Vector2(x + w * 0.5, 0.0)
		_row.add_child(item)
		x += w + gap
	if caption != "":
		_caption = Label.new()
		_caption.text = caption
		_style_label(_caption, caption_size, caption_color)
		var font: Font = KeyCap.get_font()
		var text_size: Vector2 = font.get_multiline_string_size(caption, HORIZONTAL_ALIGNMENT_CENTER, -1, caption_size)
		_caption.size = text_size + Vector2(8, 2)
		_caption.position = Vector2(-_caption.size.x * 0.5, -key_height * 0.5 - _caption.size.y - 2.0)
		add_child(_caption)
	_appear()


## Acende/apaga as teclas (janela do QTE aberta, "agora!").
func set_active(value: bool) -> void:
	if value == _active:
		return
	_active = value
	for cap in caps:
		if is_instance_valid(cap):
			cap.glow = value


## Ritmo do "afundar" das teclas (0.15 = martelar rápido).
func set_press_period(seconds: float) -> void:
	for cap in caps:
		if is_instance_valid(cap):
			cap.press_period = seconds


## Troca só o texto (as teclas ficam).
func set_caption(text: String) -> void:
	if _caption:
		_caption.text = text


## Some (encolhe e apaga) e se libera.
func dismiss() -> void:
	if _leaving or not is_inside_tree():
		return
	_leaving = true
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(0.6, 0.6), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)


func _process(delta: float) -> void:
	_clock += delta
	if _row:
		_row.position.y = sin(_clock * 6.0) * bob_amount
	if _caption and _active:
		_caption.modulate = Color(1, 1, 1, 0.75 + 0.25 * sin(_clock * 20.0))
	elif _caption:
		_caption.modulate = Color.WHITE


func _appear() -> void:
	scale = Vector2(0.4, 0.4)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, 0.12)


func _wrap(control: Control, size: Vector2) -> Node2D:
	var holder := Node2D.new()
	control.position = -size * 0.5
	holder.add_child(control)
	return holder


func _style_label(label: Label, size: int, color: Color) -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", KeyCap.get_font())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.12))
	label.add_theme_constant_override("outline_size", 7)
