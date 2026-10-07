extends CanvasLayer
class_name TurnOrderBar
## BARRA DE TURNOS estilo Child of Light: uma linha do tempo onde o retrato de cada
## lutador anda da esquerda (ESPERA) até a direita (AÇÃO). Quem chega no fim age.
##
##   - Chef (aliado) anda POR CIMA da linha; formigas POR BAIXO.
##   - O número no retrato é a ordem prevista (1 = o próximo). O próximo pisca em branco
##     e o nome dele aparece na esquerda ("PRÓXIMO: Tanajura 2").
##   - Na VEZ DO CHEF (tempo parado) um anel em volta do retrato dele vai esvaziando
##     com os segundos que faltam para escolher.
##   - Atordoado = retrato apagado com "zz". Rainha voando (não ataca) = apagada, sem número.
##
## Desenhada por código (sem cena). Pendure na cena da luta e aponte `battle`.
## Reutilizável: qualquer batalha com `turn_order() -> Array[Dictionary]` (ver
## TurnBattle.turn_order) e, se quiser a contagem, `decision_left` / `decision_time`.


@export var battle: Node
## Distância da borda de baixo da tela (fica logo acima do menu de habilidades).
@export var bottom_margin: float = 66.0
@export var bar_height: float = 30.0
@export var side_margin: float = 6.0
## Largura da área do "PRÓXIMO: nome" na esquerda.
@export var label_width: float = 92.0
## Pedaço final da linha que é a zona de AÇÃO (0.15 = últimos 15%).
@export_range(0.05, 0.4, 0.01) var action_zone: float = 0.14
@export var icon_size: float = 14.0

@export_group("Cores")
@export var panel_color: Color = Color(0.1, 0.05, 0.12, 0.82)
@export var border_color: Color = Color(0.95, 0.72, 0.25, 1.0)
@export var track_color: Color = Color(0.55, 0.6, 0.75, 1.0)
@export var action_color: Color = Color(0.95, 0.72, 0.25, 1.0)
@export var ally_color: Color = Color(0.95, 0.72, 0.25, 1.0)
@export var enemy_color: Color = Color(0.75, 0.28, 0.25, 1.0)
@export var boss_color: Color = Color(0.6, 0.3, 0.8, 1.0)
@export var next_color: Color = Color.WHITE


var _canvas: Control
var _portraits: Dictionary = {}
var _clock: float = 0.0


func _init() -> void:
	layer = 14


func _ready() -> void:
	_canvas = Control.new()
	_canvas.name = "Linha"
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_canvas.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_canvas.offset_left = side_margin
	_canvas.offset_right = -side_margin
	_canvas.offset_bottom = -bottom_margin
	_canvas.offset_top = -bottom_margin - bar_height
	_canvas.draw.connect(_on_draw)
	add_child(_canvas)
	hide()


func _process(delta: float) -> void:
	var active: bool = battle != null and battle.has_method("turn_order") and battle.get("running") == true
	visible = active
	if active:
		_clock += delta
		_canvas.queue_redraw()


func _on_draw() -> void:
	var entries: Array = battle.turn_order()
	var size: Vector2 = _canvas.size
	var font: Font = _canvas.get_theme_default_font()
	var mid: float = size.y * 0.5

	_canvas.draw_rect(Rect2(Vector2.ZERO, size), panel_color)
	_canvas.draw_rect(Rect2(Vector2.ZERO, size), border_color, false, 1.0)

	# --- Linha do tempo -------------------------------------------------------------
	var x0: float = label_width + 8.0
	var x1: float = size.x - 10.0
	var xa: float = lerpf(x0, x1, 1.0 - action_zone)  # começo da zona de AÇÃO
	_canvas.draw_line(Vector2(x0, mid), Vector2(xa, mid), track_color, 2.0)
	_canvas.draw_line(Vector2(xa, mid), Vector2(x1, mid), action_color, 4.0)
	_canvas.draw_line(Vector2(xa, mid - 6), Vector2(xa, mid + 6), action_color, 1.0)
	_text(font, "ESPERA", Vector2(x0, size.y - 2), 7, Color(track_color, 0.8))
	_text(font, "AÇÃO", Vector2(x1 - 22, size.y - 2), 7, action_color)

	# --- Próximo (nome na esquerda) --------------------------------------------------
	var next: Dictionary = {}
	for entry in entries:
		if int(entry["order"]) == 1:
			next = entry
	var who: String = "—"
	var who_color: Color = Color.WHITE
	if not next.is_empty():
		var b: Node = next["battler"]
		who = "VOCÊ!" if next["ally"] else str(b.get("display_name"))
		who_color = ally_color if next["ally"] else Color(1.0, 0.6, 0.55)
	var title: String = "AGINDO:" if not next.is_empty() and next["acting"] else "PRÓXIMO:"
	_text(font, title, Vector2(4, 12), 8, Color(0.85, 0.85, 0.9))
	_text(font, who, Vector2(4, 25), 9, who_color)
	_canvas.draw_line(Vector2(label_width, 4), Vector2(label_width, size.y - 4), Color(border_color, 0.5), 1.0)

	# --- Retratos (desenha o próximo por último, por cima) ---------------------------
	var ordered: Array = entries.duplicate()
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _draw_rank(a) < _draw_rank(b))
	var placed: Array[Vector2] = []
	for entry in ordered:
		_draw_icon(entry, font, x0, xa, x1, mid, placed)


## Ordem de desenho: quem não age embaixo, o próximo em cima de todos.
func _draw_rank(entry: Dictionary) -> int:
	var order: int = int(entry["order"])
	return 1000 if order == 0 else 100 - order


func _draw_icon(entry: Dictionary, font: Font, x0: float, xa: float, x1: float, mid: float,
		placed: Array[Vector2]) -> void:
	var b: Node2D = entry["battler"]
	var ratio: float = float(entry["ratio"])
	var order: int = int(entry["order"])
	var at_action: bool = ratio >= 1.0 or entry["acting"]
	var x: float = lerpf(xa, x1, 0.5) if at_action else lerpf(x0, xa, ratio)
	var r: float = icon_size * 0.5
	var y: float = mid - r - 1.0 if entry["ally"] else mid + r + 1.0
	var center := Vector2(x, y)
	# Dois retratos no mesmo lugar (mesma espera): empurra o de baixo para a esquerda.
	var moved: bool = true
	while moved:
		moved = false
		for other in placed:
			if absf(other.y - center.y) < 1.0 and absf(other.x - center.x) < icon_size * 0.7:
				center.x = other.x - icon_size * 0.75
				moved = true
	placed.append(center)
	var base: Color = ally_color if entry["ally"] else (boss_color if entry["boss"] else enemy_color)
	var dim: bool = entry["stunned"] or order == 0

	# Fundo + retrato
	_canvas.draw_circle(center, r + 1.0, Color(0.05, 0.03, 0.06, 1.0))
	_canvas.draw_circle(center, r, Color(base, 0.55 if dim else 1.0))
	var tex: Texture2D = _portrait_of(b)
	if tex:
		var tex_size: Vector2 = tex.get_size()
		var fit: float = (icon_size - 3.0) / maxf(tex_size.x, tex_size.y)
		var draw_size: Vector2 = tex_size * fit
		_canvas.draw_texture_rect(tex, Rect2(center - draw_size * 0.5, draw_size), false,
			Color(1, 1, 1, 0.45) if dim else Color.WHITE)

	# Próximo a agir: anel branco piscando.
	if order == 1:
		var pulse: float = 0.6 + 0.4 * sin(_clock * 9.0)
		_canvas.draw_arc(center, r + 2.5, 0.0, TAU, 24, Color(next_color, pulse), 1.5)

	# Vez do chef: anel da contagem esvaziando.
	if entry["deciding"]:
		var total: float = maxf(float(battle.get("decision_time")), 0.001)
		var left: float = clampf(float(battle.get("decision_left")) / total, 0.0, 1.0)
		var warn: Color = Color(0.55, 1.0, 0.45) if left > 0.4 else Color(1.0, 0.45, 0.35)
		_canvas.draw_arc(center, r + 4.5, -PI * 0.5, -PI * 0.5 + TAU * left, 32, warn, 2.0)

	# Número da ordem / atordoado
	if entry["stunned"]:
		_text(font, "zz", center + Vector2(r - 2, -r + 4), 7, Color(0.7, 0.85, 1.0))
	elif order > 0:
		_text(font, str(order), center + Vector2(r - 1, r + 1), 7, Color.WHITE)


func _text(font: Font, text: String, at: Vector2, font_size: int, color: Color) -> void:
	if font == null:
		return
	_canvas.draw_string_outline(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color(0.08, 0.04, 0.1))
	_canvas.draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## Retrato = 1º quadro do idle, recortado no que não é transparente (guardado em cache).
func _portrait_of(b: Node) -> Texture2D:
	var key: int = b.get_instance_id()
	if _portraits.has(key):
		return _portraits[key]
	var tex: Texture2D = null
	var sprite := b.get("sprite") as AnimatedSprite2D
	if sprite and sprite.sprite_frames:
		var anim: StringName = b.get("idle_animation") if b.get("idle_animation") != null else sprite.animation
		if not sprite.sprite_frames.has_animation(anim):
			anim = sprite.animation
		if sprite.sprite_frames.has_animation(anim) and sprite.sprite_frames.get_frame_count(anim) > 0:
			tex = sprite.sprite_frames.get_frame_texture(anim, 0)
	if tex:
		var img: Image = tex.get_image()
		if img:
			if img.is_compressed():
				img.decompress()
			var used: Rect2i = img.get_used_rect()
			if used.size.x > 0 and used.size.y > 0:
				tex = ImageTexture.create_from_image(img.get_region(used))
	_portraits[key] = tex
	return tex
