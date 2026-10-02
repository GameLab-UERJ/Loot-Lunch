extends CanvasLayer
class_name MinigameBanner
## Painel no MEIO DA TELA para as etapas da boss fight: título + instruções antes de
## começar, resultado no fim e avisos curtos ("Carne Carbonizada!", "Turno da formiga").
##
## Não precisa de cena (monta os nós por código, igual ao FloatingText):
##     var banner := MinigameBanner.new()
##     add_child(banner)
##     await banner.show_intro("Fase 1", "Segure ESPAÇO...")   # espera ESPAÇO/clique
##     banner.toast("PERFEITO!", Color.GREEN)
##
## Reutilizável: tutorial, telas de "fase concluída", avisos da fase do restaurante.


## O jogador confirmou (ESPAÇO, ENTER ou clique) o painel que estava aberto.
signal confirmed


## Ação que confirma o painel (além de ENTER e clique).
@export var confirm_action: StringName = &"chef_pick_drop"
@export var panel_color: Color = Color(0.1, 0.05, 0.12, 0.88)
@export var border_color: Color = Color(0.95, 0.72, 0.25, 1.0)
@export var title_color: Color = Color(1.0, 0.95, 0.8, 1.0)
@export var text_color: Color = Color(0.95, 0.92, 0.85, 1.0)
@export var outline_color: Color = Color(0.1, 0.05, 0.12, 1.0)


var _panel: PanelContainer
var _title: Label
var _body: Label
var _prompt: Label
var _image: TextureRect
var _toast: Label
var _waiting: bool = false
var _toast_tween: Tween


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_build()
	_panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting:
		return
	var ok: bool = event.is_action_pressed(confirm_action) if InputMap.has_action(confirm_action) else false
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		ok = true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		ok = true
	if ok:
		_waiting = false
		get_viewport().set_input_as_handled()
		_panel.hide()
		confirmed.emit()


## Título + instruções. Espera o jogador confirmar. Uso: `await banner.show_intro(...)`.
func show_intro(title: String, text: String, image: Texture2D = null,
		prompt: String = "[ESPAÇO] começar") -> void:
	_fill(title, text, image, prompt, title_color)
	_waiting = true
	await confirmed


## Painel de resultado. Com `prompt` vazio não espera ninguém (só mostra).
func show_result(success: bool, text: String, prompt: String = "") -> void:
	var color: Color = Color(0.55, 1.0, 0.55) if success else Color(1.0, 0.45, 0.45)
	_fill("SUCESSO!" if success else "FALHOU...", text, null, prompt, color)
	_waiting = prompt != ""


## Painel genérico que espera confirmação. Uso: `await banner.ask(...)`.
func ask(title: String, text: String, prompt: String, image: Texture2D = null,
		color: Color = Color(1.0, 0.95, 0.8)) -> void:
	_fill(title, text, image, prompt, color)
	_waiting = true
	await confirmed


func hide_panel() -> void:
	_waiting = false
	_panel.hide()


## Aviso curto no alto da tela que some sozinho.
func toast(message: String, color: Color = Color.WHITE, duration: float = 1.1) -> void:
	if _toast_tween:
		_toast_tween.kill()
	_toast.text = message
	_toast.modulate = color
	_toast.scale = Vector2(1.4, 1.4)
	_toast.show()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "scale", Vector2.ONE, 0.15) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_toast_tween.tween_interval(duration)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.25)
	_toast_tween.tween_callback(_toast.hide)


func _fill(title: String, text: String, image: Texture2D, prompt: String, color: Color) -> void:
	_title.text = title
	_title.add_theme_color_override("font_color", color)
	_body.text = text
	_body.visible = text != ""
	_image.texture = image
	_image.visible = image != null
	_prompt.text = prompt
	_prompt.visible = prompt != ""
	_panel.show()
	_panel.pivot_offset = _panel.size * 0.5
	_panel.scale = Vector2(0.85, 0.85)
	create_tween().tween_property(_panel, "scale", Vector2.ONE, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build() -> void:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(300, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = panel_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel.add_child(column)

	_title = _make_label(16, title_color)
	column.add_child(_title)

	_image = TextureRect.new()
	_image.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_image.custom_minimum_size = Vector2(128, 128)
	column.add_child(_image)

	_body = _make_label(10, text_color)
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(280, 0)
	column.add_child(_body)

	_prompt = _make_label(10, border_color)
	column.add_child(_prompt)

	_toast = _make_label(14, Color.WHITE)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -150.0
	_toast.offset_right = 150.0
	_toast.offset_top = 36.0
	_toast.offset_bottom = 60.0
	_toast.pivot_offset = Vector2(150, 12)
	_toast.hide()
	add_child(_toast)


func _make_label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", 4)
	return label
