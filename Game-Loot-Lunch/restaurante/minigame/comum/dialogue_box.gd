extends CanvasLayer
class_name DialogueBox
## CAIXA DE DIÁLOGO de cutscene (retrato + nome + texto com efeito máquina de escrever).
## Monta os nós por código (igual ao MinigameBanner), é só adicionar o nó na cena.
##
##   await dialogo.play(["VIP: Bom dia!", "Chef: Bom dia, Coronel!"])   # ESPAÇO/clique avança
##   dialogo.show_line("VIP", "Hmm...")      # fala SEM esperar o jogador (cenas cronometradas)
##   dialogo.close()
##
## Cada linha é "Quem: o que fala". `Quem` é uma CHAVE curta: o nome que aparece, a cor e
## o retrato saem dos dicionários `speaker_names`, `speaker_colors` e `speaker_portraits`
## (trocar o nome do personagem = mudar só o dicionário, não as falas).
## Linha sem "Quem:" (ou começando com "*") vira narração.
##
## ESPAÇO/clique: completa o texto que está sendo digitado; de novo, vai para a próxima.
## ESC (`skip_action`) pula o diálogo inteiro. Reutilizável: tutorial, NPCs do restaurante...


## Mostrou uma linha (índice dentro do `play`, chave de quem fala, texto).
signal line_shown(index: int, speaker: String, text: String)
signal advanced


@export var advance_action: StringName = &"chef_pick_drop"
@export var skip_action: StringName = &"ui_cancel"
@export var chars_per_second: float = 45.0
## Chave -> nome que aparece (ex.: "VIP" -> "Coronel Ossvaldo").
@export var speaker_names: Dictionary = {}
## Chave -> cor do nome.
@export var speaker_colors: Dictionary = {}
## Chave -> retrato (Texture2D; use AtlasTexture para pegar 1 quadro da folha).
@export var speaker_portraits: Dictionary = {}
## Chave -> true para ESPELHAR o retrato (ex.: o VIP olhando para o outro lado).
@export var speaker_portrait_flip: Dictionary = {}
@export var panel_color: Color = Color(0.1, 0.05, 0.12, 0.92)
@export var border_color: Color = Color(0.95, 0.72, 0.25, 1.0)
@export var text_color: Color = Color(0.97, 0.94, 0.88, 1.0)
@export var narration_color: Color = Color(0.8, 0.78, 0.9, 1.0)
@export var box_height: float = 66.0


var _root: PanelContainer
var _portrait: TextureRect
var _portrait_frame: PanelContainer
var _name: Label
var _text: Label
var _hint: Label
var _typing: Tween
var _waiting: bool = false
var _skipped: bool = false
var _hint_tween: Tween


func _init() -> void:
	layer = 31


func _ready() -> void:
	_build()
	_root.hide()


## Toca as falas em ordem, esperando o jogador em cada uma.
## Retorna false se o jogador pulou com ESC.
func play(lines: Array) -> bool:
	_skipped = false
	for i in lines.size():
		var parsed: Array = parse(String(lines[i]))
		show_line(parsed[0], parsed[1])
		line_shown.emit(i, parsed[0], parsed[1])
		_waiting = true
		await advanced
		if _skipped:
			break
	_waiting = false
	close()
	return not _skipped


## Mostra uma fala sem esperar ninguém. `speaker` vazio = narração. Texto vazio = fecha.
func show_line(speaker: String, text: String, color_override: Color = Color(0, 0, 0, 0)) -> void:
	if text == "":
		close()
		return
	var is_narration: bool = speaker == ""
	_name.visible = not is_narration
	_name.text = String(speaker_names.get(speaker, speaker))
	_name.add_theme_color_override("font_color", speaker_colors.get(speaker, border_color))
	var portrait: Texture2D = speaker_portraits.get(speaker, null)
	_portrait.texture = portrait
	_portrait.flip_h = bool(speaker_portrait_flip.get(speaker, false))
	_portrait_frame.visible = portrait != null
	_text.text = text
	var color: Color = narration_color if is_narration else text_color
	if color_override.a > 0.0:
		color = color_override
	_text.add_theme_color_override("font_color", color)
	_root.show()
	_hint.visible = false
	if _typing:
		_typing.kill()
	_text.visible_ratio = 0.0
	_typing = create_tween()
	_typing.tween_property(_text, "visible_ratio", 1.0, maxf(text.length() / maxf(chars_per_second, 1.0), 0.05))
	_typing.tween_callback(func() -> void: _hint.visible = _waiting)


func close() -> void:
	if _typing:
		_typing.kill()
		_typing = null
	_root.hide()


func is_typing() -> bool:
	return _typing != null and _typing.is_running()


## "VIP: Olá" -> ["VIP", "Olá"]. "* narração" ou sem ":" -> ["", texto].
static func parse(line: String) -> Array:
	var text: String = line.strip_edges()
	if text.begins_with("*"):
		return ["", text.substr(1).strip_edges()]
	var colon: int = text.find(":")
	if colon > 0 and colon <= 24 and not text.substr(0, colon).contains(" "):
		return [text.substr(0, colon), text.substr(colon + 1).strip_edges()]
	return ["", text]


func _unhandled_input(event: InputEvent) -> void:
	if not _waiting:
		return
	if InputMap.has_action(skip_action) and event.is_action_pressed(skip_action):
		get_viewport().set_input_as_handled()
		_skipped = true
		_waiting = false
		advanced.emit()
		return
	var ok: bool = InputMap.has_action(advance_action) and event.is_action_pressed(advance_action)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		ok = true
	if event is InputEventKey and event.pressed and not event.echo \
			and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		ok = true
	if not ok or (event is InputEventKey and event.echo):
		return
	get_viewport().set_input_as_handled()
	if is_typing():
		_typing.kill()
		_text.visible_ratio = 1.0
		_hint.visible = true
		return
	_waiting = false
	advanced.emit()


func _build() -> void:
	_root = PanelContainer.new()
	_root.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_root.offset_top = -box_height - 6.0
	_root.offset_bottom = -6.0
	_root.offset_left = 40.0
	_root.offset_right = -40.0
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = panel_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.set_content_margin_all(6)
	_root.add_theme_stylebox_override("panel", style)
	add_child(_root)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_root.add_child(row)

	_portrait_frame = PanelContainer.new()
	var frame_style := StyleBoxFlat.new()
	frame_style.bg_color = Color(0.22, 0.14, 0.2, 1.0)
	frame_style.border_color = border_color
	frame_style.set_border_width_all(1)
	_portrait_frame.add_theme_stylebox_override("panel", frame_style)
	row.add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(48, 48)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait_frame.add_child(_portrait)

	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 1)
	row.add_child(column)

	_name = Label.new()
	_name.add_theme_font_size_override("font_size", 10)
	_name.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.1))
	_name.add_theme_constant_override("outline_size", 3)
	column.add_child(_name)

	_text = Label.new()
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 10)
	_text.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.1))
	_text.add_theme_constant_override("outline_size", 3)
	column.add_child(_text)

	_hint = Label.new()
	_hint.text = "▼ ESPAÇO   (ESC pula)"
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hint.add_theme_font_size_override("font_size", 7)
	_hint.add_theme_color_override("font_color", Color(0.95, 0.72, 0.25, 0.85))
	_hint.visible = false
	column.add_child(_hint)
	_hint_tween = _hint.create_tween().set_loops()
	_hint_tween.tween_property(_hint, "modulate:a", 0.35, 0.45)
	_hint_tween.tween_property(_hint, "modulate:a", 1.0, 0.45)
