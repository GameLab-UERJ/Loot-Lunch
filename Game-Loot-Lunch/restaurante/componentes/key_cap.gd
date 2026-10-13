@tool
extends Node2D
class_name KeyCap
## TECLA desenhada por código (sem arte): uma tecla de teclado, as setas ou o mouse.
## Usada nos TUTORIAIS (quadro-negro) e nos avisos da batalha ("aperte ESPAÇO!").
##
##   key = "SPACE"        -> tecla larga escrita ESPAÇO
##   key = "LEFT" / "RIGHT" / "UP" / "DOWN"  -> setas desenhadas
##   key = "MOUSE" / "MOUSE_LEFT" / "MOUSE_RIGHT" -> mouse (botão aceso)
##   key = "SHIFT", "ENTER", "ESC" -> tecla larga com o nome
##   qualquer outro texto ("Q", "1", "F")  -> tecla com o texto
##
## `pressing = true` faz a tecla "afundar" sozinha de tempos em tempos (mostra que é para
## apertar). `held = true` deixa ela afundada (mostra que é para SEGURAR).
## `glow` acende a tecla (ex.: a janela do QTE abriu). Funciona no editor (@tool).


const INK := Color(0.17, 0.11, 0.06, 1.0)
const FACE := Color(0.96, 0.93, 0.85, 1.0)
const SIDE := Color(0.66, 0.6, 0.52, 1.0)
const HILITE := Color(1.0, 0.82, 0.3, 1.0)
const FONT_PATH := "res://assets/fonts/Silver.ttf"
## Nomes exibidos para as teclas especiais.
const NAMES := {
	"SPACE": "ESPAÇO",
	"SHIFT": "SHIFT",
	"ENTER": "ENTER",
	"ESC": "ESC",
	"TAB": "TAB",
	"BACKSPACE": "APAGAR",
}

static var _font: Font


@export var key: String = "SPACE":
	set(value):
		key = value
		queue_redraw()
## Texto no lugar do nome padrão (vazio = automático).
@export var label_override: String = "":
	set(value):
		label_override = value
		queue_redraw()
## Altura da tecla em pixels (a largura acompanha o texto).
@export var height: float = 18.0:
	set(value):
		height = value
		queue_redraw()
@export var font_size: int = 16:
	set(value):
		font_size = value
		queue_redraw()
## Afunda sozinha de tempos em tempos ("aperte").
@export var pressing: bool = false
## Fica afundada ("segure").
@export var held: bool = false:
	set(value):
		held = value
		queue_redraw()
## Segundos entre um aperto e outro (com `pressing`).
@export var press_period: float = 0.9
## Acende (contorno e face amarelados). Ex.: janela do QTE aberta.
@export var glow: bool = false:
	set(value):
		glow = value
		queue_redraw()
@export var face_color: Color = FACE
@export var ink_color: Color = INK


var _clock: float = 0.0
var _down: bool = false


static func get_font() -> Font:
	if _font == null:
		_font = load(FONT_PATH) as Font
		if _font == null:
			_font = ThemeDB.fallback_font
	return _font


## Nome da tecla de uma ação do Input Map (ex.: chef_pick_drop -> "SPACE").
## Devolve a primeira tecla de teclado da ação; sem tecla, o botão do mouse; senão "".
static func key_for_action(action: StringName) -> String:
	if not InputMap.has_action(action):
		return ""
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var code: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
			match code:
				KEY_SPACE: return "SPACE"
				KEY_LEFT: return "LEFT"
				KEY_RIGHT: return "RIGHT"
				KEY_UP: return "UP"
				KEY_DOWN: return "DOWN"
				KEY_SHIFT: return "SHIFT"
				KEY_ENTER, KEY_KP_ENTER: return "ENTER"
				KEY_ESCAPE: return "ESC"
			return OS.get_keycode_string(code).to_upper()
	for event in InputMap.action_get_events(action):
		if event is InputEventMouseButton:
			return "MOUSE_RIGHT" if event.button_index == MOUSE_BUTTON_RIGHT else "MOUSE_LEFT"
	return ""


## Largura que a tecla ocupa (para alinhar várias lado a lado).
func get_width() -> float:
	if _is_mouse():
		return height * 0.95
	if _is_arrow():
		return height
	var text: String = _text()
	var text_w: float = get_font().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var w: float = maxf(height, text_w + height * 0.6)
	if key == "SPACE":
		w = maxf(w, height * 3.4)
	return w


func _process(delta: float) -> void:
	if not pressing:
		if _down:
			_down = false
			queue_redraw()
		return
	_clock += delta
	var down: bool = fmod(_clock, maxf(press_period, 0.1)) < 0.18
	if down != _down:
		_down = down
		queue_redraw()


func _draw() -> void:
	if _is_mouse():
		_draw_mouse()
	else:
		_draw_key()


func _draw_key() -> void:
	var w: float = get_width()
	var h: float = height
	var depth: float = maxf(h * 0.18, 2.0)
	var sunk: bool = held or _down
	var lift: float = 0.0 if sunk else depth * 0.75
	var rect := Rect2(-w * 0.5, -h * 0.5 + depth * 0.5, w, h - depth * 0.5)

	# Lateral (a "altura" da tecla).
	_rounded(Rect2(rect.position + Vector2(0, depth * 0.4), rect.size), SIDE.darkened(0.15), ink_color, 1.0)
	# Face.
	var face := Rect2(rect.position - Vector2(0, lift), rect.size)
	var face_fill: Color = face_color.darkened(0.12) if sunk else face_color
	if glow:
		face_fill = face_fill.lerp(HILITE, 0.55)
	_rounded(face, face_fill, HILITE if glow else ink_color, 2.0 if glow else 1.0)
	# Brilho na borda de cima.
	draw_line(face.position + Vector2(3, 2), Vector2(face.end.x - 3, face.position.y + 2),
		Color(1, 1, 1, 0.55), 1.0)

	var center: Vector2 = face.get_center()
	if _is_arrow():
		_draw_arrow_glyph(center, h * 0.26)
		return
	var text: String = _text()
	var font: Font = get_font()
	var size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var ascent: float = font.get_ascent(font_size)
	var baseline := Vector2(center.x - size.x * 0.5, center.y - size.y * 0.5 + ascent)
	draw_string(font, baseline.round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink_color)


func _draw_arrow_glyph(center: Vector2, r: float) -> void:
	var dir := Vector2.RIGHT
	match key:
		"LEFT": dir = Vector2.LEFT
		"UP": dir = Vector2.UP
		"DOWN": dir = Vector2.DOWN
	var side: Vector2 = dir.orthogonal()
	var tip: Vector2 = center + dir * r
	var back: Vector2 = center - dir * r * 0.8
	draw_colored_polygon(PackedVector2Array([tip, back + side * r, back - side * r]), ink_color)


func _draw_mouse() -> void:
	var w: float = height * 0.95
	var h: float = height * 1.3
	var body := Rect2(-w * 0.5, -h * 0.5, w, h)
	var radius: float = w * 0.45
	var style := StyleBoxFlat.new()
	style.bg_color = face_color
	style.border_color = HILITE if glow else ink_color
	style.set_border_width_all(2 if glow else 1)
	style.set_corner_radius_all(int(radius))
	style.anti_aliasing = false
	style.draw(get_canvas_item(), body)
	var split_y: float = body.position.y + h * 0.42
	# Botão aceso.
	var lit: bool = held or _down or not pressing
	var hot_color: Color = HILITE if lit else HILITE.darkened(0.25)
	if key == "MOUSE_LEFT":
		_mouse_button(Rect2(body.position + Vector2(1.5, 1.5), Vector2(w * 0.5 - 2.0, h * 0.42 - 1.5)), hot_color, true)
	elif key == "MOUSE_RIGHT":
		_mouse_button(Rect2(Vector2(0.5, body.position.y + 1.5), Vector2(w * 0.5 - 2.0, h * 0.42 - 1.5)), hot_color, false)
	draw_line(Vector2(body.position.x + 1, split_y), Vector2(body.end.x - 1, split_y), ink_color, 1.0)
	draw_line(Vector2(0, body.position.y + 1), Vector2(0, split_y), ink_color, 1.0)
	# Rodinha.
	draw_rect(Rect2(-1.5, body.position.y + h * 0.14, 3, h * 0.16), ink_color)


func _mouse_button(rect: Rect2, color: Color, left: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	var r: int = int(rect.size.x * 0.8)
	if left:
		style.corner_radius_top_left = r
	else:
		style.corner_radius_top_right = r
	style.anti_aliasing = false
	style.draw(get_canvas_item(), rect)


func _rounded(rect: Rect2, fill: Color, border: Color, border_width: float) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(int(border_width))
	style.set_corner_radius_all(int(clampf(height * 0.22, 2.0, 6.0)))
	style.anti_aliasing = false
	style.draw(get_canvas_item(), rect)


func _text() -> String:
	if label_override != "":
		return label_override
	return NAMES.get(key, key)


func _is_mouse() -> bool:
	return key.begins_with("MOUSE")


func _is_arrow() -> bool:
	return key in ["LEFT", "RIGHT", "UP", "DOWN"]
