extends AbilityComponent
class_name PlantAbility
## HABILIDADE DE PLANTAR (fase 1-1: Q = pé de cogumelo, E = raiz de gravetos).
##
##   1. SEGURE a tecla -> o chef para e conjura: o anel nos pés enche e um círculo
##      marca no chão, à frente dele, onde a planta vai nascer.
##   2. Anel cheio -> a planta (`plant_scene`) BROTA ali (cresce com um "pop" e um efeito).
##   3. Soltou antes, levou dano ou o lugar ficou ocupado -> o anel pisca vermelho e nada nasce.
##
## Lugar ocupado (parede, muro de fogo, estação, jogador, outra planta) ou fora da
## `allowed_area` = não planta (o anel pisca vermelho na hora).
## Passou de `max_alive` plantas deste tipo: a mais VELHA murcha e some.
##
## Não sabe o que está plantando: é só uma cena. Pé de cogumelo, raiz de espeto, qualquer
## estação nova serve. Nova planta = outro nó PlantAbility com outra cena e outra tecla.
## De graça por padrão (`mana_cost` 0): nesta fase plantar é o básico da cozinha.


signal planted(plant: Node2D)
signal withered(plant: Node2D)
## Não plantou. reason: "ocupado", "fora", "cancelado".
signal plant_failed(reason: String)


@export var plant_scene: PackedScene
## Segundos segurando a tecla até a planta nascer.
@export var conjure_time: float = 0.6
## true = precisa SEGURAR até o fim; false = um toque basta (conjura sozinho).
@export var hold_to_conjure: bool = true
## Velocidade do chef enquanto conjura (0 = parado).
@export_range(0.0, 1.0) var move_speed_scale: float = 0.0

@export_group("Onde nasce")
## Distância à frente do chef.
@export var plant_distance: float = 24.0
## Ajuste fino (a origem das estações fica no meio do sprite, não no pé).
@export var plant_offset: Vector2 = Vector2(0, 2)
## Raio livre em volta do ponto para poder plantar.
@export var free_radius: float = 11.0
## Corpos que impedem plantar: 1 = mundo/estações, 2 = jogadores, 32 = muro de fogo/balcão.
@export_flags_2d_physics var blocking_bodies: int = 1 | 2 | 32
## Áreas que impedem plantar: 8 = interagíveis (outras estações e plantas).
@export_flags_2d_physics var blocking_areas: int = 8
## Retângulo (global) onde pode plantar. Vazio = qualquer lugar. A fase pode preencher
## com o lado de dentro do muro de fogo.
@export var allowed_area: Rect2 = Rect2()
## Onde a planta entra na árvore. Vazio = o mesmo pai do chef.
@export var plants_parent: Node

@export_group("Limite")
## Quantas plantas deste tipo podem existir. Passou = a mais velha murcha.
@export_range(1, 16) var max_alive: int = 2

@export_group("Visual")
@export var marker_color: Color = Color(0.75, 0.55, 1.0, 0.9)
@export var charge_ring: ChargeRingComponent
@export var grow_time: float = 0.35
@export var effect_sheet: Texture2D = preload("res://assets/art/restaurant/comidas/espetinhos/base/espeto/925.png")
@export var effect_row: int = 2

@export_group("Áudio")
@export var sfx_conjure: AudioStream = preload("res://assets/sfx/restaurante/chef/shadow_place.wav")
@export var sfx_planted: AudioStream = preload("res://assets/sfx/restaurante/chef/skewer_charged.wav")


var _conjuring: bool = false
var _elapsed: float = 0.0
var _target: Vector2 = Vector2.ZERO
var _marker: Line2D = null
var _planted: Array[Node2D] = []
var _sfx: AudioStreamPlayer2D = null


func _ready() -> void:
	super._ready()
	if charge_ring == null and user:
		for child in user.get_children():
			if child is ChargeRingComponent:
				charge_ring = child
				break
	_sfx = AudioStreamPlayer2D.new()
	_sfx.name = "PlantSfx"
	_sfx.bus = &"SFX"
	_sfx.volume_db = -4.0
	add_child(_sfx)


func is_busy() -> bool:
	return _conjuring


## Plantas vivas deste tipo, da mais velha para a mais nova.
func get_plants() -> Array[Node2D]:
	_prune()
	return _planted.duplicate()


## Ponto onde a planta nasceria agora.
func get_plant_position() -> Vector2:
	var facing: Vector2 = Vector2.RIGHT
	if user and "facing_direction" in user:
		facing = user.facing_direction
	if facing == Vector2.ZERO:
		facing = Vector2.RIGHT
	return (user as Node2D).global_position + facing.normalized() * plant_distance + plant_offset


## "" = dá para plantar; senão o motivo ("fora" / "ocupado").
func check_spot(point: Vector2) -> String:
	if allowed_area.has_area() and not allowed_area.grow(-free_radius).has_point(point):
		return "fora"
	var shape := CircleShape2D.new()
	shape.radius = free_radius
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, point)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = blocking_bodies
	if user is CollisionObject2D:
		query.exclude = [(user as CollisionObject2D).get_rid()]
	var space: PhysicsDirectSpaceState2D = (user as Node2D).get_world_2d().direct_space_state
	if not space.intersect_shape(query, 1).is_empty():
		return "ocupado"
	if blocking_areas != 0:
		query.collide_with_bodies = false
		query.collide_with_areas = true
		query.collision_mask = blocking_areas
		query.exclude = []
		for hit in space.intersect_shape(query, 8):
			var area := hit.get("collider") as Area2D
			if area and not (user as Node).is_ancestor_of(area):
				return "ocupado"
	return ""


# --- Habilidade -------------------------------------------------------------------

func _on_press() -> bool:
	if plant_scene == null or not (user is Node2D):
		return false
	var point: Vector2 = get_plant_position()
	var reason: String = check_spot(point)
	if reason != "":
		_flash_fail(reason)
		return false
	_conjuring = true
	_elapsed = 0.0
	_target = point
	_show_marker(point)
	if charge_ring:
		charge_ring.aim_length = 0.0
		charge_ring.start()
	_set_slow(true)
	_play(sfx_conjure)
	return true


func _on_release() -> void:
	if _conjuring and hold_to_conjure and _elapsed < conjure_time:
		_cancel("cancelado")


func _on_interrupt() -> void:
	if _conjuring:
		_cancel("cancelado")


func _process(delta: float) -> void:
	if not _conjuring:
		return
	_elapsed += delta
	if charge_ring:
		charge_ring.set_progress(_elapsed / maxf(conjure_time, 0.01))
	if _marker:
		var pulse: float = 1.0 + sin(_elapsed * 18.0) * 0.08
		_marker.scale = Vector2.ONE * pulse
	if _elapsed >= conjure_time:
		_finish()


func _finish() -> void:
	var reason: String = check_spot(_target)
	if reason != "":
		_cancel(reason)
		return
	_end_conjure()
	if charge_ring:
		charge_ring.set_charged(true)
		charge_ring.stop()
	_plant(_target)
	activated.emit()


func _plant(point: Vector2) -> void:
	_prune()
	while _planted.size() >= max_alive:
		wither(_planted[0])
	var plant := plant_scene.instantiate() as Node2D
	var parent: Node = plants_parent if plants_parent else (user as Node).get_parent()
	parent.add_child(plant)
	plant.global_position = point
	_planted.append(plant)
	_grow(plant)
	_spawn_effect(parent, point)
	_play(sfx_planted)
	planted.emit(plant)


## Faz a planta murchar e sumir (usada quando passa do limite).
func wither(plant: Node2D) -> void:
	_planted.erase(plant)
	if not is_instance_valid(plant) or plant.has_meta(&"withering"):
		return
	plant.set_meta(&"withering", true)
	var interactable := plant.get_node_or_null("InteractableComponent") as InteractableComponent
	if interactable:
		interactable.enabled = false
	_spawn_effect(plant.get_parent(), plant.global_position)
	var visual: CanvasItem = KitchenStation.find_visual(plant)
	var tween: Tween = plant.create_tween()
	if visual is Node2D:
		tween.tween_property(visual, "scale", (visual as Node2D).scale * Vector2(1.2, 0.2), 0.3)
	tween.parallel().tween_property(plant, "modulate", Color(0.6, 0.4, 0.8, 0.0), 0.3)
	tween.tween_callback(plant.queue_free)
	withered.emit(plant)


# --- Apoio -------------------------------------------------------------------------

func _grow(plant: Node2D) -> void:
	var visual: CanvasItem = KitchenStation.find_visual(plant)
	if not (visual is Node2D):
		return
	var node := visual as Node2D
	var final_scale: Vector2 = node.scale
	node.scale = final_scale * Vector2(0.3, 0.1)
	var tween: Tween = node.create_tween()
	tween.tween_property(node, "scale", final_scale * Vector2(0.9, 1.25), grow_time * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "scale", final_scale, grow_time * 0.4)


func _spawn_effect(parent: Node, point: Vector2) -> void:
	if effect_sheet == null or parent == null:
		return
	var effect := SpriteSheetEffect.new()
	effect.sheet = effect_sheet
	effect.row = effect_row
	effect.columns = 12
	effect.frame_size = Vector2i(64, 64)
	effect.fps = 22.0
	effect.scale = Vector2(0.5, 0.5)
	effect.z_index = 5
	parent.add_child(effect)
	effect.global_position = point + Vector2(0, -6)
	effect.effect_finished.connect(effect.queue_free)
	effect.play_once()


func _cancel(reason: String) -> void:
	_end_conjure()
	_flash_fail(reason)


func _flash_fail(reason: String) -> void:
	if charge_ring:
		charge_ring.start()
		charge_ring.fail()
	plant_failed.emit(reason)


func _end_conjure() -> void:
	_conjuring = false
	_set_slow(false)
	if _marker:
		_marker.queue_free()
		_marker = null


func _show_marker(point: Vector2) -> void:
	_marker = Line2D.new()
	_marker.width = 1.0
	_marker.default_color = marker_color
	_marker.closed = true
	_marker.z_index = 4
	var points := PackedVector2Array()
	for i in 20:
		var a: float = TAU * i / 20.0
		points.append(Vector2(cos(a) * free_radius, sin(a) * free_radius * 0.5))
	_marker.points = points
	var parent: Node = plants_parent if plants_parent else (user as Node).get_parent()
	parent.add_child(_marker)
	_marker.global_position = point + Vector2(0, 6)


func _set_slow(value: bool) -> void:
	if user == null:
		return
	if value and move_speed_scale < 1.0:
		SlowComponent.apply(user, self, 1.0 - move_speed_scale, 0.0, Color.WHITE)
	else:
		SlowComponent.remove(user, self)


func _play(stream: AudioStream) -> void:
	if stream and _sfx:
		_sfx.stream = stream
		_sfx.play()


func _prune() -> void:
	var alive: Array[Node2D] = []
	for i in _planted.size():
		var plant: Variant = _planted[i]
		if is_instance_valid(plant) and not (plant as Node2D).has_meta(&"withering"):
			alive.append(plant)
	_planted = alive
