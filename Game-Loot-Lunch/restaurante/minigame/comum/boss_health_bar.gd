extends CanvasLayer
class_name BossHealthBar
## BARRA DE VIDA GIGANTE de chefe no TOPO DA TELA (nome + barra + linha de status).
## Desenhada por código, sem cena: pendure como nó e chame `track(chefe)`.
##
##   barra.track(rainha)               # liga em rainha.health (BattleHealthComponent)
##   barra.set_status("VOANDO!")       # linha de baixo (vazio = some)
##
## O pedaço que acabou de sair fica branco um instante e escorre (dá para ver o golpe).
## Reutilizável: qualquer chefe com um BattleHealthComponent filho.


@export var bar_width: float = 360.0
@export var bar_height: float = 10.0
@export var top_margin: float = 6.0
@export var fill_color: Color = Color(0.78, 0.2, 0.32, 1.0)
@export var low_color: Color = Color(1.0, 0.45, 0.2, 1.0)
@export var trail_color: Color = Color(1.0, 0.95, 0.85, 1.0)
@export var back_color: Color = Color(0.1, 0.05, 0.12, 0.9)
@export var border_color: Color = Color(0.95, 0.72, 0.25, 1.0)
## Marcas na barra (ex.: 0.6 e 0.2, onde a Rainha devora as formigas).
@export var marks: Array[float] = []


var ratio: float = 1.0
var trail: float = 1.0
var _hp: int = 0
var _max: int = 1
var _trail_delay: float = 0.0
var _root: Control
var _name: Label
var _status: Label
var _bar: Control


func _init() -> void:
	layer = 12


func _ready() -> void:
	_build()
	hide()


func track(boss: Node, title: String = "") -> void:
	var health: BattleHealthComponent = BattleHealthComponent.find_in(boss)
	if health == null:
		return
	_name.text = title if title != "" else String(boss.get(&"display_name"))
	health.health_changed.connect(_on_health_changed)
	_hp = health.hp
	_max = maxi(health.max_hp, 1)
	ratio = float(_hp) / _max
	trail = ratio
	show()
	_bar.queue_redraw()


func set_status(text: String) -> void:
	_status.text = text
	_status.visible = text != ""


func _on_health_changed(current: int, maximum: int) -> void:
	_hp = current
	_max = maxi(maximum, 1)
	var new_ratio: float = float(current) / _max
	if new_ratio < ratio:
		_trail_delay = 0.4
	else:
		trail = new_ratio  # cura: sobe junto
	ratio = new_ratio
	_bar.queue_redraw()


func _process(delta: float) -> void:
	if not visible:
		return
	if _trail_delay > 0.0:
		_trail_delay -= delta
	elif trail > ratio:
		trail = maxf(trail - delta * 0.6, ratio)
		_bar.queue_redraw()


func _draw_bar() -> void:
	var rect := Rect2(Vector2.ZERO, Vector2(bar_width, bar_height))
	_bar.draw_rect(rect.grow(2.0), border_color)
	_bar.draw_rect(rect, back_color)
	if trail > ratio:
		_bar.draw_rect(Rect2(Vector2(bar_width * ratio, 0), Vector2(bar_width * (trail - ratio), bar_height)), trail_color)
	var color: Color = low_color if ratio <= 0.2 else fill_color
	_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar_width * ratio, bar_height)), color)
	_bar.draw_rect(Rect2(Vector2.ZERO, Vector2(bar_width * ratio, 2)), Color(1, 1, 1, 0.25))
	for m in marks:
		var x: float = bar_width * m
		_bar.draw_line(Vector2(x, -2), Vector2(x, bar_height + 2), border_color, 1.0)


func _build() -> void:
	_root = VBoxContainer.new()
	_root.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_root.offset_left = -bar_width * 0.5
	_root.offset_right = bar_width * 0.5
	_root.offset_top = top_margin
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_theme_constant_override("separation", 2)
	add_child(_root)

	_name = _label(10, Color(1.0, 0.9, 0.7))
	_root.add_child(_name)

	_bar = Control.new()
	_bar.custom_minimum_size = Vector2(bar_width, bar_height)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.draw.connect(_draw_bar)
	_root.add_child(_bar)

	_status = _label(9, Color(0.75, 0.9, 1.0))
	_status.hide()
	_root.add_child(_status)


func _label(font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.05, 0.12))
	label.add_theme_constant_override("outline_size", 4)
	return label
