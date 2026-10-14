@tool
extends CanvasLayer
class_name TutorialBoard
## QUADRO-NEGRO DE TUTORIAL (no estilo das telas de receita do Overcooked): um quadro
## com moldura de madeira, título a giz, etiqueta de papel colada ("NOVA RECEITA"),
## o DESENHO da página e uma legenda. Pausa o jogo enquanto está aberto.
##
## Cada página é um filho TutorialPage (na ordem da árvore). O quadro não sabe o que está
## desenhado: só mostra uma página de cada vez e cuida do título, legenda e rodapé.
##
##   ESPAÇO / ENTER / clique / ▶ -> próxima página (na última, fecha)
##   ◀                           -> página anterior
##   ESC                         -> pula o tutorial
##
## Uso por código (a fase ou o minigame chama no começo):
##     await TutorialBoard.play(self, preload("res://.../tutorial_x.tscn"))
##     await TutorialBoard.play(self, cena, true)   # só na primeira vez da sessão
##
## Tutorial novo = nova cena com raiz TutorialBoard (este script) + páginas TutorialPage.
## Tudo funciona no editor (@tool): abra a cena e veja o quadro montado.


## Uma página nova apareceu (índice).
signal page_changed(index: int)
## O jogador fechou o quadro (terminou ou pulou).
signal closed


const TITLE_FONT_PATH := "res://assets/fonts/ui/Sta.Toasty_font (1).ttf"
const BODY_FONT_PATH := "res://assets/fonts/Silver.ttf"


## Etiqueta de papel colada no canto (vazio = sem etiqueta).
@export var tag_text: String = "NOVA RECEITA":
	set(value):
		tag_text = value
		_refresh()
## Pausa a árvore enquanto o quadro está aberto.
@export var pause_game: bool = true
## Segundos em que o quadro ignora teclas ao abrir (quem vinha apertando ESPAÇO não pula).
@export var input_delay: float = 0.45
## Ação que avança (além de ENTER, clique e ▶).
@export var next_action: StringName = &"chef_pick_drop"
## Texto do botão na última página.
@export var close_text: String = "começar!"
## Página mostrada no editor (só para montar o desenho).
@export var editor_page: int = 0:
	set(value):
		editor_page = value
		if Engine.is_editor_hint():
			_show_page(clampi(value, 0, maxi(_pages().size() - 1, 0)), false)

@export_group("Cores")
@export var board_color: Color = Color(0.15, 0.17, 0.16, 1.0)
@export var frame_color: Color = Color(0.44, 0.28, 0.16, 1.0)
@export var chalk_color: Color = Color(0.95, 0.93, 0.86, 1.0)
@export var tag_color: Color = Color(0.78, 0.86, 0.9, 1.0)
@export var dim_color: Color = Color(0.0, 0.0, 0.0, 0.55)


static var _seen: Dictionary = {}


var current: int = 0
var _canvas: Control
var _title: Label
var _caption: RichTextLabel
var _footer: Node2D
var _next_cap: KeyCap
var _next_label: Label
var _nav: Node2D
var _skip_label: Label
var _was_paused: bool = false
var _open: bool = false
var _lock: float = 0.0
var _title_font: Font
var _body_font: Font


## Mostra o quadro da cena `scene` em cima de tudo e espera o jogador fechar.
## `only_once` = não mostra de novo se já foi visto nesta sessão (ex.: "Tentar de novo").
static func play(parent: Node, scene: PackedScene, only_once: bool = false) -> void:
	if scene == null or parent == null or not parent.is_inside_tree():
		return
	var key: String = scene.resource_path
	if only_once and _seen.has(key):
		return
	_seen[key] = true
	var board := scene.instantiate() as TutorialBoard
	if board == null:
		push_error("TutorialBoard.play: a raiz de %s não é um TutorialBoard." % key)
		return
	parent.add_child(board)
	await board.open()
	board.queue_free()


## Já foi mostrado nesta sessão?
static func was_seen(scene: PackedScene) -> bool:
	return scene != null and _seen.has(scene.resource_path)


func _init() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS


func _ready() -> void:
	_title_font = _make_title_font()
	_body_font = load(BODY_FONT_PATH) as Font
	_build()
	if Engine.is_editor_hint():
		_show_page(clampi(editor_page, 0, maxi(_pages().size() - 1, 0)), false)
		return
	visible = false
	for page in _pages():
		page.hide()
	# Abriu a cena do quadro sozinha (F6): mostra na hora, para conferir o desenho.
	_open_when_alone.call_deferred()


func _open_when_alone() -> void:
	if get_tree().current_scene == self:
		pause_game = false
		await open()
		get_tree().quit()


## Abre na primeira página e ESPERA fechar. Uso: `await quadro.open()`.
func open() -> void:
	if _pages().is_empty():
		return
	_was_paused = get_tree().paused
	if pause_game:
		get_tree().paused = true
	_open = true
	visible = true
	_lock = input_delay
	_show_page(0, true)
	_canvas.pivot_offset = Vector2(320, 180)
	_canvas.scale = Vector2(0.92, 0.92)
	create_tween().tween_property(_canvas, "scale", Vector2.ONE, 0.2) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await closed


func next_page() -> void:
	if current >= _pages().size() - 1:
		close()
	else:
		_show_page(current + 1, true)


func previous_page() -> void:
	if current > 0:
		_show_page(current - 1, true)


func close() -> void:
	if not _open:
		return
	_open = false
	visible = false
	if pause_game:
		get_tree().paused = _was_paused
	closed.emit()


func _process(delta: float) -> void:
	_lock = maxf(_lock - delta, 0.0)


func _input(event: InputEvent) -> void:
	if not _open or Engine.is_editor_hint():
		return
	var pressed_key: bool = event is InputEventKey and event.pressed and not event.echo
	var is_click: bool = event is InputEventMouseButton and event.pressed
	if not pressed_key and not is_click and not event.is_action_pressed(next_action):
		return
	get_viewport().set_input_as_handled()
	if _lock > 0.0:
		return
	if pressed_key:
		match event.physical_keycode:
			KEY_ESCAPE:
				close()
				return
			KEY_LEFT, KEY_A, KEY_BACKSPACE:
				previous_page()
				return
			KEY_RIGHT, KEY_D, KEY_ENTER, KEY_KP_ENTER:
				next_page()
				return
	if is_click and event.button_index == MOUSE_BUTTON_LEFT:
		next_page()
		return
	if event.is_action_pressed(next_action):
		next_page()


# --- Páginas ---------------------------------------------------------------------

func _pages() -> Array[TutorialPage]:
	var list: Array[TutorialPage] = []
	for child in get_children():
		if child is TutorialPage:
			list.append(child)
	return list


func _show_page(index: int, animated: bool) -> void:
	var pages: Array[TutorialPage] = _pages()
	if pages.is_empty() or _title == null:
		return
	current = clampi(index, 0, pages.size() - 1)
	for i in pages.size():
		pages[i].visible = i == current
	var page: TutorialPage = pages[current]
	_title.text = page.title
	_fit_title()
	_caption.text = "[center]%s[/center]" % page.caption
	var last: bool = current == pages.size() - 1
	_next_label.text = close_text if last else "próximo"
	_nav.visible = pages.size() > 1
	_skip_label.position.x = 118.0 if _nav.visible else 30.0
	_canvas.queue_redraw()
	if animated and not Engine.is_editor_hint():
		page.modulate.a = 0.0
		page.position = Vector2(12, 0)
		var tween := create_tween().set_parallel(true)
		tween.tween_property(page, "modulate:a", 1.0, 0.18)
		tween.tween_property(page, "position", Vector2.ZERO, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	page_changed.emit(current)


## Título comprido diminui a fonte até caber (sem invadir a etiqueta de papel).
func _fit_title() -> void:
	var size: int = 28
	while size > 16 and _title_font.get_string_size(_title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x > 380.0:
		size -= 2
	_title.add_theme_font_size_override("font_size", size)


func _refresh() -> void:
	if _canvas:
		_canvas.queue_redraw()


# --- Montagem (por código: o quadro não precisa de nós na cena) -------------------

func _build() -> void:
	_canvas = Control.new()
	_canvas.name = "_Quadro"
	_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_board)
	add_child(_canvas, false, Node.INTERNAL_MODE_FRONT)

	_title = Label.new()
	_title.position = Vector2(40, 12)
	_title.size = Vector2(520, 34)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.add_theme_font_override("font", _title_font)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_color", chalk_color)
	_title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	_title.add_theme_constant_override("shadow_offset_x", 1)
	_title.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_title, false, Node.INTERNAL_MODE_BACK)

	_caption = RichTextLabel.new()
	_caption.bbcode_enabled = true
	_caption.scroll_active = false
	_caption.position = Vector2(30, 290)
	_caption.size = Vector2(580, 46)
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.add_theme_font_override("normal_font", _body_font)
	_caption.add_theme_font_override("bold_font", _body_font)
	_caption.add_theme_font_size_override("normal_font_size", 19)
	_caption.add_theme_font_size_override("bold_font_size", 19)
	_caption.add_theme_color_override("default_color", chalk_color)
	_caption.add_theme_constant_override("line_separation", -3)
	add_child(_caption, false, Node.INTERNAL_MODE_BACK)

	_footer = Node2D.new()
	add_child(_footer, false, Node.INTERNAL_MODE_BACK)
	_next_cap = KeyCap.new()
	_next_cap.key = "SPACE"
	_next_cap.height = 15.0
	_next_cap.font_size = 13
	_next_cap.pressing = true
	_next_cap.press_period = 1.2
	_next_cap.position = Vector2(538, 343)
	_footer.add_child(_next_cap)
	_next_label = _small_label("próximo", Vector2(568, 335), HORIZONTAL_ALIGNMENT_LEFT)
	_footer.add_child(_next_label)

	_nav = Node2D.new()
	_footer.add_child(_nav)
	var left := KeyCap.new()
	left.key = "LEFT"
	left.height = 15.0
	left.position = Vector2(34, 343)
	_nav.add_child(left)
	var right := KeyCap.new()
	right.key = "RIGHT"
	right.height = 15.0
	right.position = Vector2(52, 343)
	_nav.add_child(right)
	_nav.add_child(_small_label("páginas", Vector2(64, 335), HORIZONTAL_ALIGNMENT_LEFT))
	_skip_label = _small_label("ESC pula", Vector2(118, 335), HORIZONTAL_ALIGNMENT_LEFT, 0.5)
	_footer.add_child(_skip_label)


func _small_label(text: String, at: Vector2, align: HorizontalAlignment, alpha: float = 0.8) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.size = Vector2(70, 16)
	label.horizontal_alignment = align
	label.add_theme_font_override("font", _body_font)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(chalk_color, alpha))
	return label


func _make_title_font() -> Font:
	var base := load(TITLE_FONT_PATH) as Font
	var body := load(BODY_FONT_PATH) as Font
	if base == null:
		return body
	# A fonte do título não tem acentos: o que faltar sai na fonte do texto.
	var font := FontVariation.new()
	font.base_font = base
	if body:
		font.fallbacks = [body]
	return font


# --- Desenho do quadro -------------------------------------------------------------

func _draw_board() -> void:
	var c: Control = _canvas
	c.draw_rect(Rect2(0, 0, 640, 360), dim_color)

	# Moldura de madeira.
	var outer := Rect2(6, 4, 628, 352)
	c.draw_rect(outer, frame_color.darkened(0.35))
	c.draw_rect(outer.grow(-2), frame_color)
	for i in 6:
		var y: float = outer.position.y + 3 + i * 2.0
		c.draw_line(Vector2(outer.position.x + 4, y), Vector2(outer.end.x - 4, y), Color(frame_color.lightened(0.2), 0.25))
	c.draw_rect(Rect2(outer.position.x + 2, outer.position.y + 2, outer.size.x - 4, 2), frame_color.lightened(0.3))

	# Quadro.
	var board := outer.grow(-9)
	c.draw_rect(board, board_color)
	c.draw_rect(Rect2(board.position, Vector2(board.size.x, 3)), board_color.darkened(0.4))
	# Manchas de giz apagado (fixas).
	var rng := RandomNumberGenerator.new()
	rng.seed = 7331
	for i in 34:
		var center := Vector2(rng.randf_range(board.position.x, board.end.x), rng.randf_range(board.position.y, board.end.y))
		var radius: float = rng.randf_range(14.0, 50.0)
		var alpha: float = rng.randf_range(0.004, 0.01)
		# Mancha macia: vários círculos que vão encolhendo (sem borda marcada).
		for k in 5:
			c.draw_circle(center, radius * (1.0 - k * 0.18), Color(1, 1, 1, alpha))
	for i in 14:
		var from := Vector2(rng.randf_range(board.position.x, board.end.x), rng.randf_range(board.position.y, board.end.y))
		var to: Vector2 = from + Vector2(rng.randf_range(40, 120), rng.randf_range(-6, 6))
		c.draw_line(from, to, Color(1, 1, 1, 0.025), rng.randf_range(4.0, 10.0))

	# Sublinhado do título (traço de giz).
	var y_line: float = 50.0
	var x0: float = 150.0
	var prev := Vector2(x0, y_line)
	for i in range(1, 49):
		var p := Vector2(x0 + i * 7.0, y_line + sin(i * 1.3) * 0.8)
		if i % 9 != 0:
			c.draw_line(prev, p, Color(chalk_color, 0.75), 2.0)
		prev = p

	# Pontinhos das páginas.
	var count: int = _pages().size()
	if count > 1:
		var start_x: float = 320.0 - (count - 1) * 7.0
		for i in count:
			var at := Vector2(start_x + i * 14.0, 343.0)
			if i == current:
				c.draw_circle(at, 3.5, chalk_color)
			else:
				c.draw_arc(at, 3.0, 0.0, TAU, 12, Color(chalk_color, 0.6), 1.0)

	_draw_tag(c)


func _draw_tag(c: Control) -> void:
	var text: String = tag_text
	var pages: Array[TutorialPage] = _pages()
	if current < pages.size() and pages[current].tag_text != "":
		text = pages[current].tag_text
	if text == "":
		return
	var font: Font = _title_font
	var size: int = 15
	var text_w: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var paper := Vector2(text_w + 18.0, 26.0)
	var xf := Transform2D(deg_to_rad(8.0), Vector2(560, 34))
	c.draw_set_transform_matrix(xf)
	var rect := Rect2(-paper * 0.5, paper)
	c.draw_rect(Rect2(rect.position + Vector2(2, 3), rect.size), Color(0, 0, 0, 0.3))
	c.draw_rect(rect, tag_color)
	c.draw_rect(Rect2(rect.position, Vector2(rect.size.x, 3)), tag_color.lightened(0.3))
	c.draw_string(font, Vector2(-text_w * 0.5, 6), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, Color(0.27, 0.38, 0.45))
	# Fitas adesivas.
	var tape := Color(0.93, 0.88, 0.7, 0.85)
	for side in [-1.0, 1.0]:
		var t := Transform2D(deg_to_rad(-30.0 * side), Vector2(side * (paper.x * 0.5 - 2.0), -paper.y * 0.5 + 1.0))
		c.draw_set_transform_matrix(xf * t)
		c.draw_rect(Rect2(-9, -4, 18, 8), tape)
	c.draw_set_transform_matrix(Transform2D.IDENTITY)
