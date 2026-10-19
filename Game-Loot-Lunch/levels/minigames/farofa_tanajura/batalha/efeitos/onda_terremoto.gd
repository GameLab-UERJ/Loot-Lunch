extends Node2D
class_name OndaTerremoto
## Onda de choque do TERREMOTO: um anel achatado (no chão) que cresce a `speed` px/s
## até `max_radius` e some. Desenhada por código; não precisa de cena nem de arte.


@export var speed: float = 240.0
@export var max_radius: float = 300.0
## Achatamento (1 = círculo; 0.3 = elipse "deitada" no chão).
@export var flatten: float = 0.3
@export var color: Color = Color(0.63, 0.44, 0.25, 0.9)
@export var dust_color: Color = Color(0.85, 0.7, 0.5, 0.8)


var radius: float = 0.0
var _seed: int = randi()


func _ready() -> void:
	z_index = -1


func _process(delta: float) -> void:
	radius += speed * delta
	modulate.a = clampf(1.0 - radius / max_radius, 0.0, 1.0) * 1.5
	if radius >= max_radius:
		queue_free()
	queue_redraw()


func _draw() -> void:
	for ring in 2:
		var r: float = radius - ring * 10.0
		if r <= 0.0:
			continue
		var points := PackedVector2Array()
		for i in 33:
			var angle: float = TAU * i / 32.0
			points.append(Vector2(cos(angle) * r, sin(angle) * r * flatten))
		draw_polyline(points, Color(color, color.a / (ring + 1)), 2.0 if ring == 0 else 1.0)
	# Pedrinhas pulando na frente da onda.
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	for i in 10:
		var angle: float = rng.randf() * TAU
		var hop: float = absf(sin(radius * 0.08 + i)) * 6.0
		var at := Vector2(cos(angle) * radius, sin(angle) * radius * flatten - hop)
		draw_rect(Rect2(at, Vector2(2, 2)), dust_color)
