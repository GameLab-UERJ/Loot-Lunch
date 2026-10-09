@tool
extends Node2D
class_name ChalkDoodle
## RABISCO DE GIZ desenhado por código para os quadros de tutorial: setas, círculos,
## barrinhas com faixa dourada, números de etapa, "X", "✓", brilhinhos...
##
## Tudo com traço "de giz" (levemente torto e falhado), igual a um desenho no quadro.
## Funciona no editor (@tool): arraste os pontos no Inspector e veja na hora.
##
##   shape = ARROW      -> seta passando pelos `points` (com `bend` vira curva)
##   shape = LINE       -> linha/caminho pelos `points` (sem ponta)
##   shape = CIRCLE     -> círculo de raio `size.x`
##   shape = RECT       -> retângulo de tamanho `size` (centrado)
##   shape = GAUGE      -> barrinha (`size`, `vertical`) cheia até `ratio`, com a faixa
##                         dourada de `zone.x` a `zone.y` (0..1). `animate` = enche em loop.
##   shape = BADGE      -> bolinha com `text` (número da etapa)
##   shape = CROSS / CHECK / SPARKLE / BANG ("!") / RING (anel de QTE fechando)
##   shape = ARC_DOTS   -> arco pontilhado do primeiro ao último ponto (trajetória); com 3
##                         pontos, o do meio puxa a curva
##   shape = UNDERLINE  -> traço ondulado de largura `size.x`


enum Shape { ARROW, LINE, CIRCLE, RECT, GAUGE, BADGE, CROSS, CHECK, SPARKLE, BANG, RING, ARC_DOTS, UNDERLINE }

const CHALK := Color(0.95, 0.93, 0.86, 0.95)


@export var shape: Shape = Shape.ARROW:
	set(value):
		shape = value
		queue_redraw()
@export var points: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2(60, 0)]):
	set(value):
		points = value
		queue_redraw()
## Curva da seta/linha (px para o lado no meio do caminho). 0 = reta.
@export var bend: float = 0.0:
	set(value):
		bend = value
		queue_redraw()
@export var size: Vector2 = Vector2(20, 20):
	set(value):
		size = value
		queue_redraw()
@export var color: Color = CHALK:
	set(value):
		color = value
		queue_redraw()
@export var width: float = 2.0:
	set(value):
		width = value
		queue_redraw()
@export var dashed: bool = false:
	set(value):
		dashed = value
		queue_redraw()
@export var filled: bool = false:
	set(value):
		filled = value
		queue_redraw()
@export var text: String = "":
	set(value):
		text = value
		queue_redraw()
@export var font_size: int = 16:
	set(value):
		font_size = value
		queue_redraw()

@export_group("Barrinha (GAUGE)")
@export var vertical: bool = true:
	set(value):
		vertical = value
		queue_redraw()
@export_range(0.0, 1.0, 0.01) var ratio: float = 0.75:
	set(value):
		ratio = value
		queue_redraw()
## Faixa dourada (início, fim) de 0 a 1. (0, 0) = sem faixa.
@export var zone: Vector2 = Vector2(0.7, 0.8):
	set(value):
		zone = value
		queue_redraw()
@export var fill_color: Color = Color(0.45, 0.85, 0.45, 0.9):
	set(value):
		fill_color = value
		queue_redraw()
@export var zone_color: Color = Color(0.98, 0.78, 0.3, 0.95):
	set(value):
		zone_color = value
		queue_redraw()

@export_group("Animação")
## Seta: tracinhos andando. Barra: enche em loop. Anel: fecha em loop. Brilho: pisca.
@export var animate: bool = false
@export var speed: float = 1.0
## Semente do "tremido" do giz (mude para outro traço).
@export var seed_value: int = 1:
	set(value):
		seed_value = value
		queue_redraw()


var _clock: float = 0.0


func _process(delta: float) -> void:
	if animate:
		_clock += delta * speed
		queue_redraw()


func _draw() -> void:
	match shape:
		Shape.ARROW:
			_draw_path(true)
		Shape.LINE:
			_draw_path(false)
		Shape.CIRCLE:
			_draw_circle_chalk(Vector2.ZERO, size.x)
		Shape.RECT:
			_draw_rect_chalk(Rect2(-size * 0.5, size))
		Shape.GAUGE:
			_draw_gauge()
		Shape.BADGE:
			_draw_badge()
		Shape.CROSS:
			var r: float = size.x * 0.5
			_stroke(Vector2(-r, -r), Vector2(r, r), width + 1.0, color, 3)
			_stroke(Vector2(r, -r), Vector2(-r, r), width + 1.0, color, 4)
		Shape.CHECK:
			var r2: float = size.x * 0.5
			_stroke(Vector2(-r2, 0), Vector2(-r2 * 0.25, r2 * 0.7), width + 1.0, color, 5)
			_stroke(Vector2(-r2 * 0.25, r2 * 0.7), Vector2(r2, -r2 * 0.8), width + 1.0, color, 6)
		Shape.SPARKLE:
			_draw_sparkle()
		Shape.BANG:
			_draw_bang()
		Shape.RING:
			_draw_ring()
		Shape.ARC_DOTS:
			_draw_arc_dots()
		Shape.UNDERLINE:
			_draw_underline()


# --- Formas ---------------------------------------------------------------------

func _draw_path(with_head: bool) -> void:
	if points.size() < 2:
		return
	var path: PackedVector2Array = _sample_path()
	var march: float = fmod(_clock * 30.0, 12.0) if animate else 0.0
	var walked: float = 0.0
	for i in path.size() - 1:
		var a: Vector2 = path[i]
		var b: Vector2 = path[i + 1]
		if dashed or animate:
			var seg: float = a.distance_to(b)
			var t: float = 0.0
			while t < seg:
				var phase: float = fmod(walked + t + 12.0 - march, 12.0)
				var step: float = minf(1.5, seg - t)
				if phase < 7.0:
					draw_line(a.lerp(b, t / seg), a.lerp(b, (t + step) / seg), color, width)
				t += step
			walked += seg
		else:
			_stroke(a, b, width, color, i)
	if with_head:
		var tip: Vector2 = path[path.size() - 1]
		var back: Vector2 = path[maxi(path.size() - 3, 0)]
		var dir: Vector2 = (tip - back).normalized()
		var head: float = 6.0 + width * 2.0
		_stroke(tip, tip - dir.rotated(0.5) * head, width + 0.5, color, 90)
		_stroke(tip, tip - dir.rotated(-0.5) * head, width + 0.5, color, 91)


func _sample_path() -> PackedVector2Array:
	if is_zero_approx(bend) or points.size() != 2:
		return points
	var a: Vector2 = points[0]
	var b: Vector2 = points[1]
	var mid: Vector2 = (a + b) * 0.5 + (b - a).orthogonal().normalized() * bend
	var out := PackedVector2Array()
	for i in 17:
		var t: float = i / 16.0
		out.append(a.lerp(mid, t).lerp(mid.lerp(b, t), t))
	return out


func _draw_circle_chalk(center: Vector2, radius: float) -> void:
	if filled:
		draw_circle(center, radius, Color(color, color.a * 0.35))
	var count: int = 28
	for i in count:
		# Fecha um pouquinho além da volta (traço de giz que "passa" do começo).
		var a0: float = TAU * i / count - 0.2
		var a1: float = TAU * (i + 1) / count - 0.2
		var r0: float = radius + _jit(i, 0.8)
		var r1: float = radius + _jit(i + 1, 0.8)
		_stroke(center + Vector2.from_angle(a0) * r0, center + Vector2.from_angle(a1) * r1, width, color, i, false)
	_stroke(center + Vector2.from_angle(-0.2) * radius, center + Vector2.from_angle(0.15) * (radius + 1.5),
		width, color, 77, false)


func _draw_rect_chalk(rect: Rect2) -> void:
	if filled:
		draw_rect(rect, Color(color, color.a * 0.25))
	var c := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		_stroke(c[i], c[(i + 1) % 4], width, color, i * 7)


func _draw_gauge() -> void:
	var rect := Rect2(-size * 0.5, size)
	draw_rect(rect, Color(0.06, 0.07, 0.08, 0.6))
	var value: float = ratio
	if animate:
		value = clampf(fmod(_clock * 0.35, 1.25), 0.0, 1.0)
	# Faixa dourada.
	if zone.y > zone.x:
		draw_rect(_part(rect, zone.x, zone.y), Color(zone_color, 0.35))
	# Enchimento.
	if value > 0.0:
		var fill := _part(rect, 0.0, value)
		draw_rect(fill.grow(-1.0), fill_color)
	if zone.y > zone.x:
		var z := _part(rect, zone.x, zone.y)
		_draw_rect_lines(z, zone_color, 1.5)
	_draw_rect_lines(rect.grow(1.0), color, width)


## Pedaço da barra entre `from` e `to` (0..1). Vertical enche de baixo para cima.
func _part(rect: Rect2, from: float, to: float) -> Rect2:
	if vertical:
		return Rect2(rect.position.x, rect.end.y - rect.size.y * to, rect.size.x, rect.size.y * (to - from))
	return Rect2(rect.position.x + rect.size.x * from, rect.position.y, rect.size.x * (to - from), rect.size.y)


func _draw_rect_lines(rect: Rect2, line_color: Color, w: float) -> void:
	var c := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for i in 4:
		_stroke(c[i], c[(i + 1) % 4], w, line_color, i * 13, false)


func _draw_badge() -> void:
	var radius: float = size.x * 0.5
	draw_circle(Vector2.ZERO, radius, Color(color, 0.18) if not filled else color)
	_draw_circle_chalk(Vector2.ZERO, radius)
	if text != "":
		var font: Font = KeyCap.get_font()
		var s: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var ink: Color = Color(0.15, 0.14, 0.13) if filled else color
		draw_string(font, Vector2(-s.x * 0.5, -s.y * 0.5 + font.get_ascent(font_size)).round(), text,
			HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, ink)


func _draw_sparkle() -> void:
	var r: float = size.x * 0.5
	if animate:
		r *= 0.75 + 0.25 * sin(_clock * 6.0 + seed_value)
	_stroke(Vector2(0, -r), Vector2(0, r), width, color, 1, false)
	_stroke(Vector2(-r, 0), Vector2(r, 0), width, color, 2, false)
	var d: float = r * 0.45
	_stroke(Vector2(-d, -d), Vector2(d, d), maxf(width - 1.0, 1.0), color, 3, false)
	_stroke(Vector2(d, -d), Vector2(-d, d), maxf(width - 1.0, 1.0), color, 4, false)


func _draw_bang() -> void:
	var h: float = size.y
	var top := Vector2(0, -h * 0.5)
	var poly := PackedVector2Array([top + Vector2(-h * 0.14, 0), top + Vector2(h * 0.14, 0),
		Vector2(h * 0.06, h * 0.18), Vector2(-h * 0.06, h * 0.18)])
	draw_colored_polygon(poly, color)
	draw_circle(Vector2(0, h * 0.38), h * 0.1, color)


func _draw_ring() -> void:
	var inner: float = size.y
	var outer: float = size.x
	var t: float = 1.0 - fmod(_clock * 0.8, 1.0) if animate else ratio
	var radius: float = lerpf(inner, outer, t)
	var open: bool = radius <= inner + (outer - inner) * 0.2
	var ring_color: Color = fill_color if open else color
	draw_arc(Vector2.ZERO, inner, 0.0, TAU, 32, Color(ring_color, 0.5), 1.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, ring_color, width)


func _draw_arc_dots() -> void:
	if points.size() < 2:
		return
	var a: Vector2 = points[0]
	var b: Vector2 = points[points.size() - 1]
	# 3 pontos: o do meio puxa a curva. 2 pontos: arco para cima (`bend` = altura).
	var mid: Vector2 = points[1] if points.size() >= 3 \
		else (a + b) * 0.5 + Vector2(0, -absf(bend) if bend != 0.0 else -40.0)
	var offset: float = fmod(_clock, 1.0) if animate else 0.0
	var count: int = maxi(int(a.distance_to(b) / 7.0), 4)
	for i in count:
		var t: float = (i + offset) / count
		var p: Vector2 = a.lerp(mid, t).lerp(mid.lerp(b, t), t)
		draw_circle(p, width * 0.6, color)


func _draw_underline() -> void:
	var w: float = size.x
	var prev := Vector2(-w * 0.5, 0)
	var steps: int = maxi(int(w / 6.0), 2)
	for i in range(1, steps + 1):
		var x: float = -w * 0.5 + w * i / steps
		var p := Vector2(x, sin(i * 1.7 + seed_value) * 1.2)
		_stroke(prev, p, width, color, i, false)
		prev = p


# --- Traço de giz ---------------------------------------------------------------

## Linha "de giz": um traço principal levemente torto + um segundo mais fraco ao lado,
## com falhas aqui e ali (pseudo-aleatório fixo, não treme a cada quadro).
func _stroke(a: Vector2, b: Vector2, w: float, c: Color, salt: int, wobble: bool = true) -> void:
	var length: float = a.distance_to(b)
	if length < 0.01:
		return
	var parts: int = maxi(int(length / 8.0), 1)
	var normal: Vector2 = (b - a).orthogonal().normalized()
	var prev: Vector2 = a
	for i in range(1, parts + 1):
		var t: float = float(i) / parts
		var p: Vector2 = a.lerp(b, t)
		if wobble and i < parts:
			p += normal * _jit(salt * 31 + i, 0.9)
		var gap: bool = _hash(salt * 17 + i) > 0.93
		if not gap:
			draw_line(prev, p, c, w)
			draw_line(prev + normal * w * 0.6, p + normal * w * 0.6, Color(c, c.a * 0.35), maxf(w * 0.5, 1.0))
		prev = p


func _jit(i: int, amount: float) -> float:
	return (_hash(i) - 0.5) * 2.0 * amount


func _hash(i: int) -> float:
	var x: float = sin(float(i * 12.9898 + seed_value * 78.233)) * 43758.5453
	return x - floorf(x)
