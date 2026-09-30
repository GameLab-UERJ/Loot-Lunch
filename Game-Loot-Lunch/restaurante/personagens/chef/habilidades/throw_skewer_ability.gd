extends AbilityComponent
class_name ThrowSkewerAbility
## HABILIDADE 1 (tecla Q): ARREMESSAR O ESPETINHO COMO UMA LANÇA.
##
##   1. Com um espetinho pronto na mão, SEGURE Q -> começa a carregar (elipse nos pés).
##   2. Depois de `charge_time` (5 s) a elipse fecha, pulsa e o espetinho brilha:
##      está CARREGADO. A setinha mostra para onde vai.
##   3. SOLTE Q carregado -> gasta 1 mana e arremessa na direção do MOUSE
##      (ou para onde o chef olha, se `aim_with_mouse` estiver desligado).
##      Se acertar um cliente com pedido, a entrega é feita (paga igual à entrega na mão).
##
## MIRA: enquanto segura Q, o chef vira para o mouse e uma linha pontilhada mostra o
## caminho do espetinho. Dá para andar e mirar ao mesmo tempo.
##
## Dá errado (o espetinho CAI NO CHÃO, no pé do chef, e NÃO gasta mana):
##   - soltou Q antes de carregar;
##   - levou um golpe enquanto carregava.
##
## Só funciona com os itens de `throwable_items` (os 9 espetinhos: cru, perfeito, torrado).
## Precisa ter mana para COMEÇAR a carregar; a mana só é gasta no arremesso.
##
## Colocar como filho do Chef. O chef pode andar devagar enquanto carrega, mas não
## interage, não larga e não dá dash.


signal charge_started
signal charged
signal thrown(projectile: ThrownItemProjectile)
## O espetinho caiu no pé do chef (soltou cedo ou levou dano).
signal dropped(item: CarryableItem)


@export_group("Carga")
## Segundos segurando Q até poder arremessar.
@export var charge_time: float = 5.0
## Velocidade do chef enquanto carrega (1 = normal, 0 = parado).
@export_range(0.0, 1.0) var move_speed_scale: float = 0.5
## Elipse de carga (nos pés do chef). Vazio = procura um ChargeRingComponent no chef.
@export var charge_ring: ChargeRingComponent
## Brilho do espetinho quando carregado (pisca entre branco e esta cor).
@export var charged_flash_color: Color = Color(1.8, 1.7, 1.2)
@export var charged_flash_speed: float = 12.0

@export_group("Mira")
## Mira com o mouse. Desligado = arremessa para onde o chef está olhando (teclado/controle).
@export var aim_with_mouse: bool = true
## Mouse mais perto que isso do chef = usa a direção em que ele olha (evita mira "tremida").
@export var mouse_dead_zone: float = 6.0
## Linha pontilhada mostrando o caminho do arremesso.
@export var show_aim_line: bool = true

@export_group("Arremesso")
## Só estes ItemData podem ser arremessados. Vazio = qualquer item.
## (Array[Resource] de propósito, mesmo motivo das listas de receitas.)
@export var throwable_items: Array[Resource] = []
@export var projectile_speed: float = 320.0
## Distância máxima. Se não acertar ninguém até aqui, cai no chão.
@export var max_distance: float = 260.0
## Raio de acerto do espetinho em voo.
@export var hit_radius: float = 6.0
## Giro da arte no voo, para a CARNE ir na frente, como a ponta de uma lança.
## A arte do espetinho é desenhada inclinada (carne em cima à esquerda, ~-123°),
## por isso 123. Se trocar a arte, ajuste aqui.
@export var rotation_offset_degrees: float = 123.0
## Altura do arco do voo (visual).
@export var arc_height: float = 6.0
## Camadas que "param" o espetinho (paredes). 1 = World.
@export_flags_2d_physics var world_mask: int = 1

@export_group("Falha")
## Onde o espetinho cai quando dá errado (relativo ao chef). (0, 8) = nos pés.
@export var drop_offset: Vector2 = Vector2(0, 8)


var _charging: bool = false
var _elapsed: float = 0.0
var _is_charged: bool = false
var _item: CarryableItem = null
var _hand: HandComponent = null
var _movement: MovementComponent = null
var _normal_max_speed: int = -1


func _ready() -> void:
	super._ready()
	_hand = HandComponent.find_in(user)
	_movement = user.get_node_or_null("%MovementComponent") as MovementComponent if user else null
	if charge_ring == null and user:
		for child in user.get_children():
			if child is ChargeRingComponent:
				charge_ring = child
				break


# --- Estado --------------------------------------------------------------------

func is_busy() -> bool:
	return _charging


func is_charged() -> bool:
	return _is_charged


## Enquanto carrega com mira do mouse, o chef olha para a mira (andar não vira ele).
func controls_facing() -> bool:
	return _charging and aim_with_mouse


## Direção do arremesso agora: mouse (se ligado) ou para onde o chef olha.
func get_aim_direction() -> Vector2:
	if aim_with_mouse and user is CanvasItem and user is Node2D:
		var to_mouse: Vector2 = (user as CanvasItem).get_global_mouse_position() - (user as Node2D).global_position
		if to_mouse.length() > mouse_dead_zone:
			return to_mouse.normalized()
	return _get_facing()


## 0..1 de quanto já carregou.
func get_charge_progress() -> float:
	return clampf(_elapsed / maxf(charge_time, 0.001), 0.0, 1.0)


func can_throw(data: ItemData) -> bool:
	if data == null:
		return false
	if throwable_items.is_empty():
		return true
	for resource in throwable_items:
		var allowed := resource as ItemData
		if allowed and (allowed == data or (allowed.id != &"" and allowed.id == data.id)):
			return true
	return false


# --- Teclas --------------------------------------------------------------------

func _on_press() -> bool:
	if _hand == null or not _hand.has_item() or not can_throw(_hand.held_item.data):
		return false
	if not check_mana():
		return false

	_item = _hand.held_item
	_charging = true
	_is_charged = false
	_elapsed = 0.0
	_set_slow(true)
	if charge_ring:
		charge_ring.start()
	charge_started.emit()
	return true


func _on_release() -> void:
	if not _charging:
		return
	if _is_charged:
		_throw()
	else:
		_fail()


func _on_interrupt() -> void:
	_fail()


# --- Loop ----------------------------------------------------------------------

func _process(delta: float) -> void:
	if not _charging:
		return

	# O espetinho sumiu da mão por outro motivo (entregou, morreu...) -> cancela sem drop.
	if not is_instance_valid(_item) or _hand.held_item != _item:
		_end_charge()
		if charge_ring:
			charge_ring.fail()
		return

	_elapsed += delta
	var aim: Vector2 = get_aim_direction()
	if aim_with_mouse and user:
		user.set(&"facing_direction", aim)
	if charge_ring:
		charge_ring.aim_direction = aim
		charge_ring.aim_length = max_distance if show_aim_line else 0.0
		charge_ring.set_progress(get_charge_progress())

	if not _is_charged and _elapsed >= charge_time:
		_is_charged = true
		if charge_ring:
			charge_ring.set_charged(true)
		charged.emit()

	if _is_charged:
		var t: float = sin(_elapsed * charged_flash_speed) * 0.5 + 0.5
		_item.modulate = Color.WHITE.lerp(charged_flash_color, t)


# --- Interno -------------------------------------------------------------------

func _throw() -> void:
	var item: CarryableItem = _item
	_end_charge()
	if not spend_mana():
		_drop_at_feet(item)
		return

	var direction: Vector2 = get_aim_direction()
	var from: Vector2 = _hand.global_position
	_hand.drop_to(_get_container(), from)  # tira da mão (marca quem arremessou)
	var projectile := ThrownItemProjectile.launch(_get_container(), item, from, direction,
		projectile_speed, max_distance, user, deg_to_rad(rotation_offset_degrees),
		hit_radius, world_mask)
	if projectile:
		projectile.arc_height = arc_height
	if charge_ring:
		charge_ring.stop()
	activated.emit()
	thrown.emit(projectile)


func _fail() -> void:
	var item: CarryableItem = _item
	_end_charge()
	if charge_ring:
		charge_ring.fail()
	_drop_at_feet(item)


func _drop_at_feet(item: CarryableItem) -> void:
	if not is_instance_valid(item) or _hand.held_item != item:
		return
	var feet: Vector2 = (user as Node2D).global_position + drop_offset if user is Node2D else _hand.global_position
	var dropped_item: CarryableItem = _hand.drop_to(_get_container(), feet)
	if dropped_item:
		dropped.emit(dropped_item)


func _end_charge() -> void:
	_charging = false
	_is_charged = false
	_elapsed = 0.0
	_set_slow(false)
	if is_instance_valid(_item):
		_item.modulate = Color.WHITE
	_item = null


func _set_slow(value: bool) -> void:
	if _movement == null:
		return
	if value:
		if _normal_max_speed < 0:
			_normal_max_speed = _movement.max_speed
		_movement.max_speed = int(_normal_max_speed * move_speed_scale)
	elif _normal_max_speed >= 0:
		_movement.max_speed = _normal_max_speed
		_normal_max_speed = -1


func _get_facing() -> Vector2:
	var facing = user.get(&"facing_direction") if user else null
	return facing if facing is Vector2 and facing != Vector2.ZERO else Vector2.RIGHT


func _get_container() -> Node:
	if user and user.has_method(&"_get_items_container"):
		return user.call(&"_get_items_container")
	return user.get_parent() if user else get_tree().current_scene
