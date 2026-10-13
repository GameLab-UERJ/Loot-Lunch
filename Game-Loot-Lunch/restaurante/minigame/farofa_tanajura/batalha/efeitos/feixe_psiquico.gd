extends Node2D
class_name PsychicBeam
## FEIXE PSÍQUICO desenhado por código (sem arte): sai de `from` e vai até `to`, ondulando
## e piscando. `clash` (0..1) acende um choque de energia na ponta (o chef resistindo).
##
##   var feixe := PsychicBeam.new(); arena.add_child(feixe)
##   feixe.aim(boca_da_rainha, chef)      # liga
##   feixe.clash = progresso              # enquanto o jogador martela
##   await feixe.retract()  /  await feixe.vanish()


@export var width: float = 10.0
@export var core_color: Color = Color(1.0, 0.95, 1.0, 1.0)
@export var glow_color: Color = Color(0.75, 0.35, 1.0, 0.75)
@export var edge_color: Color = Color(0.45, 0.1, 0.65, 0.55)


var from: Vector2
var to: Vector2
## Quanto do caminho o feixe já percorreu (0..1).
var reach: float = 0.0
## Força do choque na ponta (0..1).
var clash: float = 0.0
var _clock: float = 0.0


func _init() -> void:
	z_index = 45


func aim(start: Vector2, end: Vector2, travel: float = 0.18) -> void:
	from = start
	to = end
	reach = 0.0
	var tween := create_tween()
	tween.tween_property(self, "reach", 1.0, travel)
	await tween.finished


## Volta para a origem (o chef venceu) e some.
func retract(duration: float = 0.3) -> void:
	var tween := create_tween()
	tween.tween_property(self, "reach", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tween.finished
	queue_free()


## Some no lugar (acertou).
func vanish(duration: float = 0.25) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	await tween.finished
	queue_free()


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	if reach <= 0.0:
		return
	var a: Vector2 = to_local(from)
	var b: Vector2 = to_local(from.lerp(to, reach))
	var dir: Vector2 = (b - a)
	if dir.length() < 1.0:
		return
	var normal: Vector2 = dir.orthogonal().normalized()
	var flicker: float = 0.85 + 0.15 * sin(_clock * 40.0)
	for layer in [[width * 1.8, edge_color, 3.0], [width, glow_color, 2.0], [width * 0.4, core_color, 1.0]]:
		var line := PackedVector2Array()
		var steps: int = 18
		for i in steps + 1:
			var t: float = float(i) / steps
			var wave: float = sin(t * 18.0 - _clock * 25.0) * layer[2] * sin(PI * t)
			line.append(a.lerp(b, t) + normal * wave)
		var c: Color = layer[1]
		c.a *= flicker
		draw_polyline(line, c, layer[0])
	# Choque na ponta (o chef segurando o raio).
	if clash > 0.0:
		var r: float = 6.0 + clash * 10.0 + sin(_clock * 30.0) * 1.5
		draw_circle(b, r * 1.6, Color(0.75, 0.35, 1.0, 0.35))
		draw_circle(b, r, Color(1.0, 0.9, 1.0, 0.9))
		for i in 6:
			var ang: float = _clock * 6.0 + i * TAU / 6.0
			draw_line(b, b + Vector2(cos(ang), sin(ang)) * r * 2.0, Color(1, 1, 1, 0.7), 1.5)
