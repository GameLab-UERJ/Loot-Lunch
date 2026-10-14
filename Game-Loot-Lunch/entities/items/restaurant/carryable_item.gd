extends Area2D
class_name CarryableItem
## Qualquer item que pode ser carregado por um HandComponent.
## Quando está numa mão, deixa de ser detectável (monitorable = false),
## então o InteractorComponent só enxerga itens soltos no chão.
##
## Camada sugerida: collision_layer = 16 (camada 5 "items"), mask = 0.


signal picked_up(hand: HandComponent)
signal dropped


@export var data: ItemData: set = set_data


var current_hand: HandComponent = null
## Dono da ÚLTIMA mão que segurou este item (ex.: o Chef que largou/arremessou).
## Usado pela entrega para saber quem recebe o pagamento.
var last_carrier: Node = null


@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")


func _ready() -> void:
	_apply_data()


func set_data(value: ItemData) -> void:
	data = value
	if is_node_ready():
		_apply_data()


func can_be_picked_up() -> bool:
	return current_hand == null


func is_held() -> bool:
	return current_hand != null


func get_hold_offset() -> Vector2:
	return data.hold_offset if data else Vector2.ZERO


## Chamado pelo HandComponent. Não chame diretamente.
func notify_held(hand: HandComponent) -> void:
	current_hand = hand
	set_deferred("monitorable", false)
	picked_up.emit(hand)


## Chamado pelo HandComponent. Não chame diretamente.
func notify_released() -> void:
	if current_hand:
		last_carrier = current_hand.get_parent()
	current_hand = null
	set_deferred("monitorable", true)
	dropped.emit()


## Põe o item no chão em `desired`, mas NUNCA dentro de algo sólido (bancada,
## churrasqueira, parede...): se o lugar está ocupado, procura o ponto livre mais perto
## em anéis em volta; sem nenhum livre, cai em `fallback` (ex.: no pé de quem largou).
## `mask` = camadas que contam como sólido (1 = mundo). `exclude` = corpos ignorados.
func settle(desired: Vector2, fallback: Vector2, mask: int = 1, exclude: Array[RID] = [],
		clearance: float = 8.0) -> Vector2:
	global_position = find_free_spot(desired, fallback, mask, exclude, clearance)
	return global_position


func find_free_spot(desired: Vector2, fallback: Vector2, mask: int = 1, exclude: Array[RID] = [],
		clearance: float = 8.0) -> Vector2:
	if not is_inside_tree():
		return desired
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = clearance
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = mask
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.exclude = exclude
	var is_free := func(point: Vector2) -> bool:
		query.transform = Transform2D(0.0, point)
		return space.intersect_shape(query, 1).is_empty()
	if is_free.call(desired):
		return desired
	# Anéis de 8 em 8 px; em cada anel, prefere o lado de quem largou (`fallback`).
	for ring in range(1, 6):
		var radius: float = ring * 8.0
		var best: Vector2 = Vector2.INF
		var best_distance: float = INF
		for i in 12:
			var point: Vector2 = desired + Vector2.RIGHT.rotated(TAU * i / 12.0) * radius
			if not is_free.call(point):
				continue
			var distance: float = point.distance_squared_to(fallback)
			if distance < best_distance:
				best_distance = distance
				best = point
		if best != Vector2.INF:
			return best
	return fallback


func _apply_data() -> void:
	if sprite:
		sprite.texture = data.texture if data else null
		sprite.scale = data.sprite_scale if data else Vector2.ONE
	queue_redraw()


func _draw() -> void:
	if sprite and sprite.texture:
		return
	var color: Color = data.placeholder_color if data else Color.WHITE
	draw_circle(Vector2.ZERO, 8.0, color)
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, Color(0, 0, 0, 0.6), 1.0)
