extends Node2D
class_name GoldenRays
## RAIOS DE LUZ girando atrás de alguém (o "momento Ratatouille" do VIP, item lendário,
## vitória...). Desenhados por código, sem arte.
##
##   await raios.burst()     # aparece crescendo e fica girando
##   raios.fade_out()


@export var ray_count: int = 12
@export var radius: float = 160.0
## Largura de cada raio (0..1 da fatia).
@export_range(0.05, 1.0, 0.05) var ray_width: float = 0.45
@export var color_inner: Color = Color(1.0, 0.9, 0.5, 0.75)
@export var color_outer: Color = Color(1.0, 0.75, 0.25, 0.0)
@export var spin_speed: float = 0.5


func _ready() -> void:
	hide()


func burst(duration: float = 0.5) -> void:
	show()
	scale = Vector2(0.1, 0.1)
	modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 1.0, duration * 0.6)
	await tween.finished


func fade_out(duration: float = 0.4) -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(hide)


func _process(delta: float) -> void:
	if visible:
		rotation += spin_speed * delta


func _draw() -> void:
	var slice: float = TAU / maxi(ray_count, 1)
	for i in ray_count:
		var a: float = i * slice
		var half: float = slice * ray_width * 0.5
		var points := PackedVector2Array([Vector2.ZERO,
			Vector2(cos(a - half), sin(a - half)) * radius,
			Vector2(cos(a + half), sin(a + half)) * radius])
		var colors := PackedColorArray([color_inner, color_outer, color_outer])
		draw_polygon(points, colors)
