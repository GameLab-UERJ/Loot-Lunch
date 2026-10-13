extends Area2D
class_name InteractorComponent
## "Sensor" à frente do personagem. Detecta InteractableComponents e CarryableItems
## próximos e escolhe o mais perto. Não decide o que fazer: só responde "o que está ao alcance".
##
## Também acompanha o MOUSE: o interagível embaixo do cursor ganha a silhueta branca
## (`hovered_interactable`), e `get_target()` prefere ele na hora de interagir.
##
## ALVO: a cada frame avisa ao interagível que o ESPAÇO usaria agora
## (`InteractableComponent.set_targeted`). É assim que a churrasqueira sabe qual
## espetinho destacar antes do jogador apertar. Só vira alvo quem REAGIRIA de verdade
## (`InteractableComponent.would_react`); sem alvo, o ESPAÇO pega/larga item do chão.
##
## Camada sugerida: collision_layer = 0, collision_mask = 24 (camadas 4 e 5).


signal focused_interactable_changed(interactable: InteractableComponent)
signal hovered_interactable_changed(interactable: InteractableComponent)
## O que o ESPAÇO usaria agora mudou (ou null).
signal targeted_interactable_changed(interactable: InteractableComponent)


## Distância do centro do dono até o sensor, na direção em que ele olha.
@export var reach: float = 16.0
## Atualiza o destaque (highlight) do interagível mais próximo a cada frame.
@export var update_focus: bool = true
## Quem está interagindo. Se vazio, usa o nó pai.
@export var actor: Node

@export_group("Itens soltos")
## Mão vazia + item solto ao alcance: o ESPAÇO PEGA o item, mesmo que ele esteja em
## cima de uma estação que também reagiria (caixa de carne, raiz de espeto...).
@export var prefer_loose_items: bool = true
## Silhueta no item que o ESPAÇO pegaria agora.
@export var item_outline_color: Color = Color.WHITE
@export var item_outline_width: float = 1.0

@export_group("Mouse")
## Destaca (silhueta branca) o interagível embaixo do mouse.
@export var use_mouse_hover: bool = true
## Camadas onde o mouse procura interagíveis (8 = camada 4 "interactables").
@export_flags_2d_physics var hover_mask: int = 8
## Distância máxima (do dono até a borda da área do objeto) para o clique funcionar.
@export var mouse_reach: float = 24.0


var focused_interactable: InteractableComponent = null
var hovered_interactable: InteractableComponent = null
## O que o ESPAÇO usaria agora (ver `get_target(true, true)`).
var targeted_interactable: InteractableComponent = null
## Item solto que o ESPAÇO pegaria agora (ver `get_item_target`).
var targeted_item: CarryableItem = null


func _ready() -> void:
	if actor == null:
		actor = get_parent()


func _physics_process(_delta: float) -> void:
	if update_focus:
		_refresh_focus()
		if use_mouse_hover:
			_refresh_hover()
		_refresh_target()


func set_facing(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		position = direction.normalized() * reach


## `require_reaction` = só quem faria algo agora (`would_react`), usado pelo ESPAÇO.
func get_nearest_interactable(require_reaction: bool = false) -> InteractableComponent:
	return _get_nearest(func(area: Area2D) -> bool:
		return area is InteractableComponent and _accepts(area, require_reaction)
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
	_set_targeted(null)
	_set_targeted_item(null)


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


## Com quem interagir agora (ESPAÇO / R):
##   - mouse em cima de algo ao alcance -> esse objeto;
##   - mouse em cima de algo LONGE      -> clique: nada. Teclado (`fallback_to_nearest`):
##                                         o mais perto à frente, como se o mouse não estivesse lá;
##   - mouse no vazio                   -> o mais perto à frente.
## `require_reaction`: ignora quem não faria nada agora (ver `would_react`).
func get_target(fallback_to_nearest: bool = false, require_reaction: bool = false) -> InteractableComponent:
	var hovered: InteractableComponent = get_hovered_interactable()
	if use_mouse_hover and hovered:
		if _accepts(hovered, require_reaction) and is_in_reach(hovered):
			return hovered
		if not fallback_to_nearest:
			return null
	return get_nearest_interactable(require_reaction)


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


func _refresh_target() -> void:
	var item: CarryableItem = get_item_target()
	_set_targeted_item(item)
	# Com um item para pegar, a estação embaixo dele não é o alvo do ESPAÇO.
	_set_targeted(null if item else get_target(true, true))


## Item solto que o ESPAÇO pegaria agora (mão vazia), ou null. O mouse em cima de uma
## estação ao alcance que reagiria tem preferência (o jogador escolheu ela).
func get_item_target() -> CarryableItem:
	if not prefer_loose_items:
		return null
	var hand: HandComponent = HandComponent.find_in(actor)
	if hand == null or hand.has_item():
		return null
	var hovered: InteractableComponent = get_hovered_interactable()
	if use_mouse_hover and hovered and is_in_reach(hovered) and hovered.would_react(actor):
		return null
	return get_nearest_carryable()


func _set_targeted_item(item: CarryableItem) -> void:
	if item == targeted_item:
		return
	if is_instance_valid(targeted_item) and targeted_item.sprite:
		SpriteOutline.hide_on(targeted_item.sprite)
	targeted_item = item
	if is_instance_valid(item) and item.sprite and item.sprite.texture:
		SpriteOutline.show_on(item.sprite, item_outline_color, item_outline_width)


func _accepts(interactable: InteractableComponent, require_reaction: bool) -> bool:
	if require_reaction:
		return interactable.would_react(actor)
	return interactable.can_interact(actor)


func _set_targeted(interactable: InteractableComponent) -> void:
	if interactable == targeted_interactable:
		return
	if is_instance_valid(targeted_interactable):
		targeted_interactable.set_targeted(false)
	targeted_interactable = interactable
	if interactable:
		interactable.set_targeted(true, actor)
	targeted_interactable_changed.emit(interactable)


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
