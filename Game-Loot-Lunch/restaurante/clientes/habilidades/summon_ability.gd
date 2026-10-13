extends CustomerAbility
class_name SummonAbility
## MAGIA DE INVOCAÇÃO genérica (a ultimate de todo cliente): cria um ou mais Summon
## (pato devorador, demoninho...). O summon é uma CENA (`summon_scene`); esta magia não
## sabe o que ele faz.
##
## ONDE NASCE:
##   - padrão: na frente do cliente (`spawn_offset`);
##   - `spawn_near_target`: PERTO DO CHEF, a `near_offset_min..max` px numa direção sorteada
##     (igual ao raio supremo do Johnny: tem mais cara de ultimate). Sem chef livre e com
##     `fallback_to_map_center`, nasce no MEIO DO MAPA.
##
## ENTRADA (opcional, `entrance_scene`): um "show" antes do summon aparecer. A cena tem
## script que herda SummonEntrance. Ex.: ovo que cai do céu e choca o pato (Patolino),
## buraco do inferno de onde sai o demoninho (Mandy). O summon só entra na fase quando a
## entrada libera (`summon_ready`), no lugar que ela disser.
##
## PROJÉTEIS AO SURGIR (opcional, `burst_data`): quando o summon aparece, solta
## `burst_count` projéteis em volta, em todas as direções (demoninho: 8 caveiras).


signal summoned(summon: Node2D)
signal burst_fired(projectiles: Array)


@export_group("Invocação")
@export var summon_scene: PackedScene
## Quantos nascem por uso.
@export_range(1, 8) var amount: int = 1
## Máximo vivo AO MESMO TEMPO invocado por este cliente (conta os que ainda estão na
## entrada). 0 = sem limite.
@export_range(0, 16) var max_alive: int = 2
## Onde nasce, relativo ao cliente (na frente dele, no chão). Ignorado com `spawn_near_target`.
@export var spawn_offset: Vector2 = Vector2(0, 26)
## Espalha os summons quando nasce mais de um.
@export var spread: float = 16.0

@export_group("Perto do chef")
## Nasce perto do CHEF (e não na frente do cliente).
@export var spawn_near_target: bool = false
## Distância mínima/máxima do chef (direção sorteada). 0 e 0 = em cima dele.
@export var near_offset_min: float = 24.0
@export var near_offset_max: float = 40.0

@export_group("Entrada")
## Cena com script que herda SummonEntrance. Vazio = o summon aparece direto.
@export var entrance_scene: PackedScene
## A entrada é "chão": fica desenhada embaixo do chef (logo antes dele na árvore).
@export var entrance_below_target: bool = true
## O cliente fica ocupado ("conjurando") até o summon aparecer.
@export var wait_for_entrance: bool = true

@export_group("Projéteis ao surgir")
## Vazio = não solta projéteis.
@export var burst_data: ProjectileData
@export_range(0, 32) var burst_count: int = 8
## Gira o leque (em graus). 0 = o primeiro vai para a direita (leste).
@export var burst_angle_offset: float = 0.0
## Cada projétil nasce afastado do centro esta distância.
@export var burst_start_radius: float = 10.0
## Onde nasce o leque, em relação ao summon.
@export var burst_offset: Vector2 = Vector2.ZERO
## Cena do projétil. Vazio = `projetil.tscn`.
@export var projectile_scene: PackedScene


var _alive: Array = []


func _init() -> void:
	super._init()
	requires_target = false  # o summon procura o alvo sozinho


## Quantos summons desta magia estão vivos (ou a caminho, dentro de uma entrada).
func get_alive_count() -> int:
	var still_alive: Array = []
	for node: Variant in _alive:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			still_alive.append(node)
	_alive = still_alive
	return _alive.size()


func cast(target: Node2D = null) -> bool:
	if summon_scene == null:
		push_warning("SummonAbility '%s' sem summon_scene." % name)
		return false
	if max_alive > 0 and get_alive_count() >= max_alive:
		return false
	return super.cast(target)


func _perform(target: Node2D) -> void:
	var last_entrance: SummonEntrance = null
	for i in amount:
		if max_alive > 0 and get_alive_count() >= max_alive:
			break
		var creature: Node = summon_scene.instantiate()
		if creature is Summon:
			creature.summoner = caster
			if target:
				creature.target = target
		_alive.append(creature)
		var at: Vector2 = _pick_spawn_position(target, i)
		if entrance_scene:
			last_entrance = _start_entrance(creature, target, at)
		else:
			_place(creature, at)

	if wait_for_entrance and last_entrance and not last_entrance.is_released():
		await last_entrance.summon_ready


# --- Onde nasce -------------------------------------------------------------------

func _pick_spawn_position(target: Node2D, index: int) -> Vector2:
	if spawn_near_target and is_instance_valid(target):
		var high: float = maxf(near_offset_max, near_offset_min)
		var distance: float = randf_range(near_offset_min, high) if high > 0.0 else 0.0
		return target.global_position + Vector2.RIGHT.rotated(randf() * TAU) * distance
	if spawn_near_target and fallback_to_map_center:
		return get_aim_position(null)  # sem chef livre (engolido...): nasce no meio do mapa
	var offset: Vector2 = spawn_offset
	if amount > 1:
		offset.x += (index - (amount - 1) * 0.5) * spread
	var origin: Vector2 = caster.global_position if caster else Vector2.ZERO
	return origin + offset


# --- Entrada ----------------------------------------------------------------------

func _start_entrance(creature: Node, target: Node2D, at: Vector2) -> SummonEntrance:
	var entrance := entrance_scene.instantiate() as SummonEntrance
	if entrance == null:
		push_error("SummonAbility '%s': a entrada não tem SummonEntrance na raiz." % name)
		_place(creature, at)
		return null
	entrance.creature = creature as Node2D
	entrance.target = target
	entrance.caster = caster
	entrance.summon_ready.connect(_on_entrance_ready.bind(creature, entrance), CONNECT_ONE_SHOT)

	var world: Node = get_world()
	world.add_child(entrance)
	if entrance_below_target and is_instance_valid(target) and target.get_parent() == world:
		world.move_child(entrance, target.get_index())  # chão: embaixo do chef
	entrance.global_position = at
	return entrance


func _on_entrance_ready(at: Vector2, creature: Node, entrance: SummonEntrance) -> void:
	if not is_instance_valid(creature):
		return
	if at == Vector2.INF or not is_inside_tree():
		creature.free()  # entrada cancelada: o summon nunca chegou a existir
		return
	if creature is Summon and entrance.skip_summon_intro:
		creature.play_intro = false
	_place(creature, at)


# --- Colocar na fase --------------------------------------------------------------

func _place(creature: Node, at: Vector2) -> void:
	get_world().add_child(creature)
	if creature is Node2D:
		creature.global_position = at
	summoned.emit(creature)
	_fire_burst(at + burst_offset)


func _fire_burst(at: Vector2) -> void:
	if burst_data == null or burst_count <= 0:
		return
	var fired: Array = Projectile.spawn_burst(projectile_scene, get_world(), burst_data,
			at, burst_count, caster, burst_angle_offset, burst_start_radius)
	burst_fired.emit(fired)
