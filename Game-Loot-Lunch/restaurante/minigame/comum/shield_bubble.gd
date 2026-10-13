extends Node2D
class_name ShieldBubble
## BOLHA DE PROTEÇÃO desenhada por código (sem arte) + LAÇOS de energia até quem protege.
## A Rainha usa com as Guardiãs: enquanto houver laço, ela não leva dano.
##
##   bolha.links = [guardia1, guardia2]   # laços até elas (some quando morrem)
##   bolha.flash()                         # pisca quando bloqueia um golpe
##   await bolha.pop()                     # estoura e some
##
## Reutilizável: escudo de chefe, item de proteção, barreira de fase.


@export var radius: float = 80.0
@export var color: Color = Color(0.45, 0.95, 1.0, 0.22)
@export var edge_color: Color = Color(0.7, 1.0, 1.0, 0.9)
@export var link_color: Color = Color(0.55, 0.95, 1.0, 0.75)
@export var link_width: float = 2.0
## Achata a bolha (1 = círculo).
@export var squash_y: float = 0.85


## Quem mantém a bolha (laços desenhados até cada um que ainda estiver na árvore).
var links: Array[Node2D] = []
var _clock: float = 0.0
var _flash: float = 0.0


func _process(delta: float) -> void:
	_clock += delta
	_flash = maxf(_flash - delta * 3.0, 0.0)
	queue_redraw()


func flash() -> void:
	_flash = 1.0


func pop() -> void:
	links.clear()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.4, 1.4), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.25)
	await tween.finished
	queue_free()


func _draw() -> void:
	var pulse: float = 0.5 + 0.5 * sin(_clock * 4.0)
	var fill := color
	fill.a = color.a * (0.8 + 0.4 * pulse) + _flash * 0.35
	var edge := edge_color.lerp(Color.WHITE, _flash)
	var points := PackedVector2Array()
	for i in 40:
		var a: float = TAU * i / 40.0
		points.append(Vector2(cos(a) * radius, sin(a) * radius * squash_y))
	draw_colored_polygon(points, fill)
	points.append(points[0])
	draw_polyline(points, edge, 2.0 + _flash * 2.0)
	# Brilho girando na borda.
	var spin: float = _clock * 1.5
	draw_arc(Vector2.ZERO, radius * 0.92, spin, spin + 0.8, 10, Color(1, 1, 1, 0.35), 2.0)
	# Laços até as Guardiãs (onda de energia).
	for link in links:
		if not is_instance_valid(link) or not link.is_inside_tree():
			continue
		var to: Vector2 = to_local(link.global_position + Vector2(0, -10))
		var line := PackedVector2Array()
		var steps: int = 14
		var normal: Vector2 = to.orthogonal().normalized()
		for i in steps + 1:
			var t: float = float(i) / steps
			var wave: float = sin(t * 12.0 - _clock * 10.0) * 3.0 * sin(PI * t)
			line.append(Vector2.ZERO.lerp(to, t) + normal * wave)
		var c := link_color
		c.a = link_color.a * (0.6 + 0.4 * pulse)
		draw_polyline(line, c, link_width)
