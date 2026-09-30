extends Area2D
class_name InteractorComponent
## "Sensor" à frente do personagem. Detecta InteractableComponents e CarryableItems
## próximos e escolhe o mais perto. Não decide o que fazer: só responde "o que está ao alcance".
##
## Também acompanha o MOUSE: o interagível embaixo do cursor ganha a silhueta branca
## (`hovered_interactable`), e `get_target()` prefere ele na hora de interagir.
##
## Camada sugerida: collision_layer = 0, collision_mask = 24 (camadas 4 e 5).


signal focused_interactable_changed(interactable: InteractableComponent)
signal hovered_interactable_changed(interactable: InteractableComponent)


## Distância do centro do dono até o sensor, na direção em que ele olha.
@export var reach: float = 16.0
## Atualiza o destaque (highlight) do interagível mais próximo a cada frame.
@export var update_focus: bool = true
## Quem está interagindo. Se vazio, usa o nó pai.
@export var actor: Node

@export_group("Mouse")
## Destaca (silhueta branca) o interagível embaixo do mouse.
@export var use_mouse_hover: bool = true
## Camadas onde o mouse procura interagíveis (8 = camada 4 "interactables").
@export_flags_2d_physics var hover_mask: int = 8
## Distância máxima (do dono até a borda da área do objeto) para o clique funcionar.
@export var mouse_reach: float = 24.0


var focused_interactable: InteractableComponent = null
var hovered_interactable: InteractableComponent = null


func _ready() -> void:
	if actor == null:
		actor = get_parent()


func _physics_process(_delta: float) -> void:
	if update_focus:
		_refresh_focus()
		if use_mouse_hover:
			_refresh_hover()


func set_facing(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		position = direction.normalized() * reach


func get_nearest_interactable() -> InteractableComponent:
	return _get_nearest(func(area: Area2D) -> bool:
		return area is InteractableComponent and area.can_interact(actor)
	) as InteractableComponent


func get_nearest_carryable() -> CarryableItem:
	return _get_nearest(func(area: Area2D) -> bool:
		return area is CarryableItem and area.can_be_picked_up()
	) as CarryableItem


func clear_focus() -> void:
	if is_instance_valid(focused_interactable):
		focused_interactable.set_focused(false)
	focused_interactable = null
	focused_interactable_changed.emit(null)
	_set_hovered(null)


## Interagível embaixo do mouse (ou null).
func get_hovered_interactable() -> InteractableComponent:
	return hovered_interactable if is_instance_valid(hovered_interactable) else null


## O dono já consegue interagir com `interactable` daqui?
## Vale se o sensor encosta nele OU se o dono está a até `mouse_reach` da área dele.
func is_in_reach(interactable: InteractableComponent) -> bool:
	if not is_instance_valid(interactable):
		return false
	if overlaps_area(interactable):
		return true
	var origin: Vector2 = (actor as Node2D).global_position if actor is Node2D else global_position
	return _distance_to_area(origin, interactable) <= mouse_reach


## Com quem interagir agora (clique direito / T):
##   - mouse em cima de algo -> esse objeto, se estiver ao alcance (senão, nada);
##   - mouse no vazio        -> o mais perto à frente, como antes.
func get_target() -> InteractableComponent:
	var hovered: InteractableComponent = get_hovered_interactable()
	if use_mouse_hover and hovered:
		return hovered if hovered.can_interact(actor) and is_in_reach(hovered) else null
	return get_nearest_interactable()


func _refresh_focus() -> void:
	var nearest: InteractableComponent = get_nearest_interactable()
	if nearest == focused_interactable:
		return
	if is_instance_valid(focused_interactable):
		focused_interactable.set_focused(false)
	focused_interactable = nearest
	if nearest:
		nearest.set_focused(true)
	focused_interactable_changed.emit(nearest)


func _refresh_hover() -> void:
	var hovered: InteractableComponent = _find_under_mouse()
	_set_hovered(hovered)
	if hovered:
		# Atualiza todo frame: o jogador pode entrar/sair do alcance parado no mouse.
		hovered.set_hovered(true, is_in_reach(hovered))


func _set_hovered(interactable: InteractableComponent) -> void:
	if interactable == hovered_interactable:
		return
	if is_instance_valid(hovered_interactable):
		hovered_interactable.set_hovered(false)
	hovered_interactable = interactable
	hovered_interactable_changed.emit(interactable)


func _find_under_mouse() -> InteractableComponent:
	var mouse_position: Vector2 = get_global_mouse_position()
	var query := PhysicsPointQueryParameters2D.new()
	query.position = mouse_position
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.collision_mask = hover_mask

	var best: InteractableComponent = null
	var best_distance: float = INF
	for hit in get_world_2d().direct_space_state.intersect_point(query, 16):
		var interactable := hit.get("collider") as InteractableComponent
		if interactable == null or not interactable.can_interact(actor):
			continue
		var distance: float = mouse_position.distance_squared_to(interactable.global_position)
		if distance < best_distance:
			best_distance = distance
			best = interactable
	return best


## Distância de `point` até a borda mais perto das formas de colisão de `area`
## (0 se estiver dentro). Formas que não são retângulo/círculo usam o centro.
func _distance_to_area(point: Vector2, area: Area2D) -> float:
	var best: float = point.distance_to(area.global_position)
	for child in area.get_children():
		var shape_node := child as CollisionShape2D
		if shape_node == null or shape_node.shape == null or shape_node.disabled:
			continue
		var local: Vector2 = shape_node.global_transform.affine_inverse() * point
		var shape: Shape2D = shape_node.shape
		var distance: float = INF
		if shape is RectangleShape2D:
			var half: Vector2 = (shape as RectangleShape2D).size * 0.5
			var outside := Vector2(maxf(absf(local.x) - half.x, 0.0), maxf(absf(local.y) - half.y, 0.0))
			distance = outside.length()
		elif shape is CircleShape2D:
			distance = maxf(local.length() - (shape as CircleShape2D).radius, 0.0)
		else:
			distance = local.length()
		best = minf(best, distance)
	return best


func _get_nearest(filter: Callable) -> Area2D:
	var best: Area2D = null
	var best_distance: float = INF
	for area in get_overlapping_areas():
		if not filter.call(area):
			continue
		var distance: float = global_position.distance_squared_to(area.global_position)
		if distance < best_distance:
			best_distance = distance
			best = area
	return best
