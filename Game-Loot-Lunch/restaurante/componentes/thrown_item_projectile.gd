extends Area2D
class_name ThrownItemProjectile
## PROJÉTIL que carrega um CarryableItem voando em linha reta (como uma lança).
##
##   - Encostou num DeliveryReceiverComponent que aceita o item -> entrega (receiver.receive)
##   - Bateu numa parede/corpo (camada `world_mask`)            -> cai no chão ali
##   - Voou `max_distance` sem acertar nada                     -> cai no chão ali
##
## Não precisa de cena: use `ThrownItemProjectile.launch(...)`.
## Reutilizável: arremesso do chef, bancada que "cospe" item, catapulta...
##
## Camadas: layer 0 (ninguém enxerga o projétil); mask = 8 (interactables, onde ficam os
## recebedores) + `world_mask` (paredes).


signal hit_receiver(receiver: DeliveryReceiverComponent, data: ItemData)
signal landed(item: CarryableItem)


var item: CarryableItem = null
var direction: Vector2 = Vector2.RIGHT
var speed: float = 300.0
var max_distance: float = 240.0
## Quem arremessou (recebe o pagamento). Também é ignorado nas colisões.
var thrower: Node = null
## Onde o item fica se cair no chão.
var landing_container: Node = null
## Altura do "arco" do voo (só visual, em pixels). 0 = reto.
var arc_height: float = 6.0

var _traveled: float = 0.0
var _finished: bool = false


## Cria o projétil, tira o item de onde estiver e lança.
## `rotation_offset` gira a arte do item (ex.: 90° se o espetinho é desenhado em pé).
static func launch(container: Node, thrown_item: CarryableItem, from: Vector2, dir: Vector2,
		launch_speed: float = 300.0, distance: float = 240.0, who: Node = null,
		rotation_offset: float = 0.0, hit_radius: float = 6.0, world_mask: int = 1) -> ThrownItemProjectile:
	if container == null or thrown_item == null or dir == Vector2.ZERO:
		return null

	var projectile := ThrownItemProjectile.new()
	projectile.name = "Arremesso"
	projectile.collision_layer = 0
	projectile.collision_mask = 8 | world_mask
	projectile.monitorable = false
	projectile.direction = dir.normalized()
	projectile.speed = launch_speed
	projectile.max_distance = distance
	projectile.thrower = who
	projectile.landing_container = container

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = hit_radius
	shape.shape = circle
	projectile.add_child(shape)

	container.add_child(projectile)
	projectile.global_position = from

	# O item vai "dentro" do projétil. Enquanto voa ninguém pega com R.
	projectile.item = thrown_item
	if thrown_item.is_inside_tree():
		thrown_item.reparent(projectile, false)
	else:
		projectile.add_child(thrown_item)
	thrown_item.position = Vector2.ZERO
	thrown_item.rotation = projectile.direction.angle() + rotation_offset
	thrown_item.set_deferred("monitorable", false)
	if who and thrown_item.last_carrier == null:
		thrown_item.last_carrier = who
	return projectile


func _physics_process(delta: float) -> void:
	if _finished:
		return
	if not is_instance_valid(item):
		queue_free()
		return

	var step: float = speed * delta
	global_position += direction * step
	_traveled += step

	# Arco visual: sobe e desce ao longo do voo.
	var t: float = clampf(_traveled / maxf(max_distance, 1.0), 0.0, 1.0)
	item.position.y = -sin(t * PI) * arc_height

	if _try_deliver():
		return
	if _hit_wall() or _traveled >= max_distance:
		_land()


func _try_deliver() -> bool:
	for area in get_overlapping_areas():
		var receiver := area as DeliveryReceiverComponent
		if receiver == null or not receiver.can_accept(item.data):
			continue
		var data: ItemData = item.data
		_finished = true
		item.position = Vector2.ZERO
		if receiver.receive(item, thrower):
			hit_receiver.emit(receiver, data)
			queue_free()
			return true
		_finished = false
	return false


func _hit_wall() -> bool:
	for body in get_overlapping_bodies():
		if body != thrower:
			return true
	return false


## Cai no chão onde está (em pé de novo, pronto para pegar com R).
func _land() -> void:
	_finished = true
	var container: Node = landing_container if is_instance_valid(landing_container) else get_parent()
	var dropped: CarryableItem = item
	dropped.reparent(container, false)
	dropped.global_position = global_position
	# Bateu numa bancada/parede: cai no chão livre do lado de cá, não dentro dela.
	var exclude: Array[RID] = []
	if thrower is CollisionObject2D:
		exclude.append((thrower as CollisionObject2D).get_rid())
	dropped.settle(global_position, global_position - direction * 16.0, collision_mask, exclude)
	dropped.rotation = 0.0
	dropped.set_deferred("monitorable", true)
	landed.emit(dropped)
	queue_free()
