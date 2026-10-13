extends Node2D
class_name TimingGauge
## BARRA de "ponto" desenhada por código (sem arte): mostra as zonas do
## TargetMeterProfile (antes / PONTO / depois) e o valor atual de um TargetMeterComponent.
##
## A zona perfeita fica com moldura dourada e a barra pulsa quando o valor está nela.
## Quem usa só aponta `meter`; nada mais. Funciona na vertical (temperatura da carne) e
## na horizontal (dose de manteiga).
##
## Mesmo espírito do ProgressBarComponent (barrinha de bancada), mas com zonas.


@export var meter: TargetMeterComponent
@export var size: Vector2 = Vector2(10, 90)
@export var vertical: bool = true
@export var caption: String = ""

@export_group("Cores")
## A "barra verde" do ponto.
@export var fill_color: Color = Color(0.45, 0.85, 0.35, 1.0)
@export var fill_over_color: Color = Color(0.9, 0.3, 0.2, 1.0)
@export var background_color: Color = Color(0.1, 0.05, 0.12, 0.85)
@export var under_zone_color: Color = Color(0.35, 0.45, 0.7, 0.25)
@export var perfect_zone_color: Color = Color(0.95, 0.72, 0.25, 0.35)
@export var over_zone_color: Color = Color(0.85, 0.2, 0.15, 0.3)
@export var frame_color: Color = Color(0.17, 0.11, 0.05, 1.0)
@export var perfect_frame_color: Color = Color(1.0, 0.85, 0.3, 1.0)


var _pulse: float = 0.0


func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()


func _draw() -> void:
	var profile: TargetMeterProfile = meter.profile if meter and meter.profile else null
	var value: float = meter.value if meter else 0.5
	var p_min: float = profile.perfect_min if profile else 0.68
	var p_max: float = profile.perfect_max if profile else 0.82
	var in_perfect: bool = value >= p_min and value <= p_max

	var back := Rect2(-size * 0.5, size)
	draw_rect(back.grow(1.0), frame_color)
	draw_rect(back, background_color)
	draw_rect(_band(back, 0.0, p_min), under_zone_color)
	draw_rect(_band(back, p_max, 1.0), over_zone_color)
	draw_rect(_band(back, p_min, p_max), perfect_zone_color)

	var color: Color = fill_over_color if value > p_max else fill_color
	if in_perfect:
		color = color.lightened(0.25 + 0.2 * sin(_pulse * 18.0))
	draw_rect(_band(back, 0.0, value), color)

	# Moldura da zona perfeita e o "ponteiro" do valor.
	var perfect_rect: Rect2 = _band(back, p_min, p_max).grow(1.0 if in_perfect else 0.0)
	draw_rect(perfect_rect, perfect_frame_color, false, 1.0)
	var marker: Rect2 = _band(back, value, value)
	if vertical:
		marker = Rect2(marker.position.x - 3.0, marker.position.y - 1.0, marker.size.x + 6.0, 2.0)
	else:
		marker = Rect2(marker.position.x - 1.0, marker.position.y - 3.0, 2.0, marker.size.y + 6.0)
	draw_rect(marker, Color.WHITE)

	if caption != "":
		var font: Font = ThemeDB.fallback_font
		var text_pos := Vector2(-size.x * 0.5 - 20.0, -size.y * 0.5 - 4.0) if vertical \
			else Vector2(-size.x * 0.5, -size.y * 0.5 - 4.0)
		var width: float = size.x + 40.0 if vertical else size.x
		draw_string_outline(font, text_pos, caption, HORIZONTAL_ALIGNMENT_CENTER, width, 9, 4,
			Color(0.1, 0.05, 0.12))
		draw_string(font, text_pos, caption, HORIZONTAL_ALIGNMENT_CENTER, width, 9,
			Color(0.95, 0.92, 0.85))


## Faixa da barra entre `from` e `to` (0..1). Vertical cresce de baixo para cima.
func _band(back: Rect2, from: float, to: float) -> Rect2:
	from = clampf(from, 0.0, 1.0)
	to = clampf(to, 0.0, 1.0)
	if vertical:
		var bottom: float = back.end.y
		return Rect2(back.position.x, bottom - back.size.y * to, back.size.x, back.size.y * (to - from))
	return Rect2(back.position.x + back.size.x * from, back.position.y, back.size.x * (to - from), back.size.y)
