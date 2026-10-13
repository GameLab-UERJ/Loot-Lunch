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
##     var escolha: int = await banner.choose("FALHOU...", "texto", ["Tentar de novo", "Sair"])
##
## Reutilizável: tutorial, telas de "fase concluída", avisos da fase do restaurante,
## menus de "tentar de novo / sair" (choose).


## O jogador confirmou (ESPAÇO, ENTER ou clique) o painel que estava aberto.
signal confirmed
## O jogador clicou num dos botões de `choose` (0 = primeiro botão).
signal choice_made(index: int)


## Ação que confirma o painel (além de ENTER e clique).
@export var confirm_action: StringName = &"chef_pick_drop"
@export var panel_color: Color = Color(0.1, 0.05, 0.12, 0.88)
@export var border_color: Color = Color(0.95, 0.72, 0.25, 1.0)
@export var title_color: Color = Color(1.0, 0.95, 0.8, 1.0)
@export var text_color: Color = Color(0.95, 0.92, 0.85, 1.0)
@export var outline_color: Color = Color(0.1, 0.05, 0.12, 1.0)
## Altura dos avisos curtos (toast) a partir do topo. Desça se houver barra de chefe.
@export var toast_top: float = 36.0
@export_group("Botões (choose)")
## Tema dos botões de `choose`. Vazio: botão simples nas cores do painel.
@export var button_theme: Theme
## Segundos em que os botões ficam travados ao abrir (quem estava apertando ESPAÇO no
## jogo não escolhe sem querer).
@export var choice_delay: float = 0.5


var _panel: PanelContainer
var _title: Label
var _body: Label
var _prompt: Label
var _image: TextureRect
var _toast: Label
var _choices: HBoxContainer
var _waiting: bool = false
var _choosing: bool = false
var _toast_tween: Tween


func _init() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_build()
	_panel.hide()


func _unhandled_input(event: InputEvent) -> void:
	if _choosing:
		# ESC escolhe o último botão (normalmente "Sair"). ESPAÇO/ENTER/setas: foco do botão.
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			var last: Button = _choices.get_child(_choices.get_child_count() - 1) as Button
			if last and not last.disabled:
				get_viewport().set_input_as_handled()
				last.pressed.emit()
		return
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


## Painel com BOTÕES (mouse ou teclado). Devolve o índice do botão escolhido.
## Uso: `var escolha: int = await banner.choose("O chef caiu!", "", ["Tentar de novo", "Sair"])`
## Setas trocam o botão, ESPAÇO/ENTER confirmam e ESC escolhe o último.
func choose(title: String, text: String, options: PackedStringArray,
		color: Color = Color(1.0, 0.95, 0.8), image: Texture2D = null) -> int:
	if options.is_empty():
		push_warning("MinigameBanner.choose: sem opções.")
		return -1
	_fill(title, text, image, "", color)
	_waiting = false
	for child in _choices.get_children():
		child.queue_free()
	var buttons: Array[Button] = []
	for i in options.size():
		var button := _make_button(options[i])
		button.disabled = true
		button.pressed.connect(_on_choice_pressed.bind(i))
		_choices.add_child(button)
		buttons.append(button)
	_choices.show()
	_choosing = true
	await get_tree().create_timer(choice_delay, true).timeout
	for button in buttons:
		if is_instance_valid(button):
			button.disabled = false
	if is_instance_valid(buttons[0]):
		buttons[0].grab_focus()
	var index: int = await choice_made
	return index


func hide_panel() -> void:
	_waiting = false
	_choosing = false
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
	_choices.hide()
	_choosing = false
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

	_choices = HBoxContainer.new()
	_choices.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices.add_theme_constant_override("separation", 10)
	_choices.hide()
	column.add_child(_choices)

	_toast = _make_label(14, Color.WHITE)
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -150.0
	_toast.offset_right = 150.0
	_toast.offset_top = toast_top
	_toast.offset_bottom = toast_top + 24.0
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


func _on_choice_pressed(index: int) -> void:
	if not _choosing:
		return
	_choosing = false
	_panel.hide()
	_choices.hide()
	choice_made.emit(index)


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(110, 20)
	if button_theme:
		button.theme = button_theme
		return button
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_focus_color", title_color)
	button.add_theme_color_override("font_hover_color", title_color)
	for state in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = panel_color.lightened(0.15 if state in ["hover", "focus"] else 0.05)
		style.border_color = border_color if state in ["hover", "focus", "pressed"] else border_color.darkened(0.45)
		style.set_border_width_all(1)
		style.set_content_margin_all(4)
		button.add_theme_stylebox_override(state, style)
	return button
