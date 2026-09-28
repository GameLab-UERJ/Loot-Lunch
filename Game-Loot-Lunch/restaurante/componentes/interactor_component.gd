extends Area2D
class_name InteractorComponent
## "Sensor" à frente do personagem. Detecta InteractableComponents e CarryableItems
## próximos e escolhe o mais perto. Não decide o que fazer: só responde "o que está ao alcance".
##
## Camada sugerida: collision_layer = 0, collision_mask = 24 (camadas 4 e 5).


signal focused_interactable_changed(interactable: InteractableComponent)


## Distância do centro do dono até o sensor, na direção em que ele olha.
@export var reach: float = 16.0
## Atualiza o destaque (highlight) do interagível mais próximo a cada frame.
@export var update_focus: bool = true
## Quem está interagindo. Se vazio, usa o nó pai.
@export var actor: Node


var focused_interactable: InteractableComponent = null


func _ready() -> void:
	if actor == null:
		actor = get_parent()


func _physics_process(_delta: float) -> void:
	if update_focus:
		_refresh_focus()


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
