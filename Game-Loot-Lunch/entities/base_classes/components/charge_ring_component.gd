extends Node2D
class_name ChargeRingComponent
## Efeito visual de "CARREGANDO": uma elipse no chão (nos pés do personagem) que vai
## se fechando conforme o progresso, com uma seta + linha pontilhada mostrando a mira
## (`aim_direction` / `aim_length`). Quando completa, pulsa e a mira fica forte.
##
## Não sabe o que está sendo carregado: quem usa chama
##   start() -> set_progress(0..1) -> set_charged(true) -> stop() / fail()
## Reutilizável: arremesso, golpe carregado, cozinhar segurando botão...
##
## Posicione o nó nos pés do personagem (ex.: (0, 10)).


@export_group("Forma")
## Raios da elipse (x = largura, y = altura). Elipse achatada = "no chão".
@export var radius: Vector2 = Vector2(13, 5)
@export var width: float = 1.5
@export_range(8, 64) var segments: int = 32

@export_group("Cores")
@export var background_color: Color = Color(0, 0, 0, 0.35)
@export var charging_color: Color = Color(1.0, 0.7, 0.25, 0.9)
@export var charged_color: Color = Color(1.0, 0.95, 0.55, 1.0)
@export var fail_color: Color = Color(1.0, 0.3, 0.3, 1.0)

@export_group("Carregado")
## Velocidade da pulsação quando completo.
@export var pulse_speed: float = 10.0
## Quanto a elipse "incha" ao pulsar.
@export var pulse_amount: float = 0.18
## Setinha na direção da mira (só quando completo). 0 = sem seta.
@export var arrow_distance: float = 18.0
@export var arrow_size: float = 5.0

@export_group("Mira")
## Opacidade da seta/linha enquanto ainda carrega (1 = igual a carregado).
@export_range(0.0, 1.0) var charging_aim_alpha: float = 0.45
## Opacidade extra da linha pontilhada (em relação à seta).
@export_range(0.0, 1.0) var aim_line_alpha: float = 0.6
@export var dash_length: float = 4.0
@export var dash_gap: float = 4.0


## Direção da mira (quem usa atualiza todo frame).
var aim_direction: Vector2 = Vector2.RIGHT
## Comprimento da linha pontilhada da mira (0 = sem linha). Quem usa atualiza.
var aim_length: float = 0.0

var _active: bool = false
var _progress: float = 0.0
var _charged: bool = false
var _time: float = 0.0
var _fade_tween: Tween


func _ready() -> void:
	visible = false


func start() -> void:
	if _fade_tween:
		_fade_tween.kill()
	_active = true
	_progress = 0.0
	_charged = false
	_time = 0.0
	modulate = Color.WHITE
	visible = true
	queue_redraw()


func set_progress(value: float) -> void:
	_progress = clampf(value, 0.0, 1.0)
	queue_redraw()


func set_charged(value: bool) -> void:
	_charged = value
	if value:
		_progress = 1.0
	queue_redraw()


func is_charged() -> bool:
	return _charged


## Terminou bem (ex.: arremessou): some rápido.
func stop() -> void:
	_active = false
	_fade_out(0.12)


## Terminou mal (soltou cedo / levou dano): pisca vermelho e some.
func fail() -> void:
	_active = false
	_charged = false
	modulate = fail_color
	queue_redraw()
	_fade_out(0.35)


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	queue_redraw()


func _draw() -> void:
	var pulse: float = 1.0
	if _charged:
		pulse += (sin(_time * pulse_speed) * 0.5 + 0.5) * pulse_amount
	var r: Vector2 = radius * pulse

	# Fundo (elipse inteira, escura).
	draw_polyline(_ellipse_points(r, 0.0, TAU), background_color, width + 1.0, true)

	# Progresso (começa em cima e gira no sentido horário).
	var color: Color = charged_color if _charged else charging_color
	if _progress > 0.0:
		var start_angle: float = -PI * 0.5
		draw_polyline(_ellipse_points(r, start_angle, start_angle + TAU * _progress),
			color, width, true)

	# Seta + linha pontilhada da mira (fraquinha carregando, forte quando carregado).
	if (_active or _charged) and aim_direction != Vector2.ZERO:
		var dir: Vector2 = aim_direction.normalized()
		var aim_color: Color = color
		if not _charged:
			aim_color.a *= charging_aim_alpha
		if arrow_distance > 0.0:
			var tip: Vector2 = dir * (arrow_distance + arrow_size)
			var base: Vector2 = dir * arrow_distance
			var side: Vector2 = dir.orthogonal() * arrow_size * 0.6
			draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), aim_color)
		if aim_length > arrow_distance + arrow_size and dash_length > 0.0:
			var line_color: Color = aim_color
			line_color.a *= aim_line_alpha
			var d: float = arrow_distance + arrow_size + dash_gap
			while d < aim_length:
				var d_end: float = minf(d + dash_length, aim_length)
				draw_line(dir * d, dir * d_end, line_color, 1.0)
				d = d_end + dash_gap


func _ellipse_points(r: Vector2, from_angle: float, to_angle: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count: int = maxi(2, int(segments * absf(to_angle - from_angle) / TAU) + 1)
	for i in count + 1:
		var a: float = lerpf(from_angle, to_angle, float(i) / count)
		points.append(Vector2(cos(a) * r.x, sin(a) * r.y))
	return points


func _fade_out(time: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, time)
	_fade_tween.tween_callback(hide)
