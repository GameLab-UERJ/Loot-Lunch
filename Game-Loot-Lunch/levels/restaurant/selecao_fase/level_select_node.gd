@tool
extends Node2D
class_name LevelSelectNode
## PONTO DE FASE do mapa de seleção (a bandeirinha onde o chef e a Brasa param).
##
## Não sabe nada de teclado nem de troca de cena: só guarda os DADOS da fase
## (número, nome, cena, trancada, estrelas), desenha o ponto e avisa quem está em cima
## dele (ProximityComponent). Quem decide o que fazer é o `LevelSelectMap`.
##
## Nova fase no mapa = arrastar `ponto_fase.tscn` para o mapa e preencher o Inspector.
## Os campos aparecem no editor na hora (é @tool).


## Alguém subiu ou saiu do ponto. `count` = quantos jogadores estão em cima.
signal players_changed(count: int)


enum Status { PLAYABLE, LOCKED, COMING_SOON }


@export var level_id: String = "1-1":
	set(value):
		level_id = value
		_refresh()
@export var level_name: String = "":
	set(value):
		level_name = value
		_refresh()
## Cena da fase. Vazio = "Em breve" (a bandeira existe, a fase ainda não).
@export_file("*.tscn") var level_scene: String = ""
@export var locked: bool = false:
	set(value):
		locked = value
		_refresh()
@export_range(0, 3) var stars: int = 0:
	set(value):
		stars = clampi(value, 0, max_stars)
		_refresh()
@export_range(1, 3) var max_stars: int = 3:
	set(value):
		max_stars = value
		_refresh()

@export_group("Destaque")
## Cor do anel que pulsa quando um jogador está em cima.
@export var highlight_color: Color = Color(1.0, 0.82, 0.38, 0.9)
@export var locked_highlight_color: Color = Color(0.7, 0.68, 0.78, 0.8)
@export var ring_radius: Vector2 = Vector2(20, 10)


var _pulse: float = 0.0
var _shake: float = 0.0
var _last_count: int = 0


@onready var flag: SheetRowSprite = get_node_or_null("Bandeira")
@onready var padlock: Sprite2D = get_node_or_null("Cadeado")
@onready var number_label: Label = get_node_or_null("Numero")
@onready var stars_root: Node2D = get_node_or_null("Estrelas")
@onready var proximity: ProximityComponent = get_node_or_null("Proximidade")
@onready var light: PointLight2D = get_node_or_null("Luz")


func _ready() -> void:
	_refresh()
	if Engine.is_editor_hint():
		return
	if proximity:
		proximity.target_entered.connect(func(_b): _emit_count())
		proximity.target_exited.connect(func(_b): _emit_count())


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_pulse += delta
	var offset := Vector2.ZERO
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		offset.x = sin(_pulse * 60.0) * 2.0 * (_shake / 0.35)
	if is_highlighted() and not locked:
		offset.y = -absf(sin(_pulse * 5.0)) * 2.0
	if flag:
		flag.position = Vector2(_flag_x(), _flag_y()) + offset
	queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint() or not is_highlighted():
		return
	var color: Color = locked_highlight_color if locked else highlight_color
	var grow: float = 1.0 + sin(_pulse * 4.0) * 0.08
	var points := PackedVector2Array()
	for i in 33:
		var a: float = TAU * i / 32.0
		points.append(Vector2(cos(a) * ring_radius.x, sin(a) * ring_radius.y + 2.0) * grow)
	draw_polyline(points, color, 1.0)
	color.a *= 0.45
	var inner := PackedVector2Array()
	for p in points:
		inner.append(p * 1.12)
	draw_polyline(inner, color, 1.0)


# --- Consultas ---------------------------------------------------------------------

func get_status() -> Status:
	if locked:
		return Status.LOCKED
	if level_scene == "" or not ResourceLoader.exists(level_scene):
		return Status.COMING_SOON
	return Status.PLAYABLE


func is_playable() -> bool:
	return get_status() == Status.PLAYABLE


func get_players() -> Array:
	return proximity.get_targets() if proximity else []


func has_player(body: Node) -> bool:
	return get_players().has(body)


func is_highlighted() -> bool:
	return proximity != null and proximity.has_target()


## Treme a bandeira (fase trancada / em breve).
func shake() -> void:
	_shake = 0.35


# --- Visual ------------------------------------------------------------------------

func _refresh() -> void:
	if not is_inside_tree():
		return
	if flag == null:
		flag = get_node_or_null("Bandeira")
		padlock = get_node_or_null("Cadeado")
		number_label = get_node_or_null("Numero")
		stars_root = get_node_or_null("Estrelas")
		light = get_node_or_null("Luz")
	if number_label:
		number_label.text = level_id
		number_label.modulate = Color(0.75, 0.72, 0.8) if locked else Color.WHITE
	if padlock:
		padlock.visible = locked
	if flag:
		if Engine.is_editor_hint():
			flag.visible = true
		else:
			flag.show_row(2 if locked else 1)
	if light:
		light.enabled = not locked
	if stars_root:
		stars_root.visible = not locked
		var i: int = 0
		for child in stars_root.get_children():
			var star := child as Sprite2D
			if star == null:
				continue
			star.visible = i < max_stars
			star.frame = 0 if i < stars else 1
			i += 1


func _flag_x() -> float:
	return 7.0


func _flag_y() -> float:
	return -14.0


func _emit_count() -> void:
	var count: int = get_players().size()
	if count != _last_count:
		_last_count = count
		players_changed.emit(count)
