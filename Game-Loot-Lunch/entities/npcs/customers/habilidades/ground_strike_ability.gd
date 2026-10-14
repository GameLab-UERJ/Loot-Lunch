extends CustomerAbility
class_name GroundStrikeAbility
## MAGIA "CAI DO CÉU": marca o chão perto do chef e, depois do aviso, cai um GroundStrike
## (raio simples do Johnny, raio supremo...). A cena do ataque é `strike_scene`.
##
## No impacto a magia ainda pode SOLTAR coisas do ponto onde caiu (tudo opcional):
##   - `burst_data`: `burst_count` projéteis em volta, em todas as direções
##     (raio supremo: 8 esferas N, NE, L, SE, S, SO, O, NO);
##   - `strike_summon_scene`: um summon nasce no centro (raio supremo: a nuvem).
##
## Raio simples:   offset 0 (cai EM CIMA de onde o chef estava), sem burst, sem summon.
## Raio supremo:   offset 24..40 ("perto" do chef), burst de 8 esferas, nuvem.
## Sem chef livre (engolido pelo pato...) e `fallback_to_map_center`: cai no meio do mapa.


signal strike_spawned(strike: GroundStrike)
signal strike_landed(strike: GroundStrike, at: Vector2)
signal burst_fired(projectiles: Array)
signal summoned(creature: Node2D)


@export_group("Ataque")
@export var strike_scene: PackedScene
## Distância mínima/máxima do chef onde o ataque cai (direção sorteada). 0 e 0 = em cima.
@export var offset_min: float = 0.0
@export var offset_max: float = 0.0
## O cliente fica ocupado ("conjurando") até o raio cair.
@export var wait_for_impact: bool = true

@export_group("Projéteis no impacto")
## Vazio = não solta projéteis.
@export var burst_data: ProjectileData
@export_range(0, 32) var burst_count: int = 8
## Gira o leque (em graus). 0 = o primeiro vai para a direita (leste).
@export var burst_angle_offset: float = 0.0
## Cena do projétil. Vazio = `projetil.tscn`.
@export var projectile_scene: PackedScene

@export_group("Invocação no impacto")
## Vazio = não invoca nada.
@export var strike_summon_scene: PackedScene
## Máximo vivo ao mesmo tempo (desta magia). 0 = sem limite.
@export_range(0, 16) var summon_max_alive: int = 2


var _alive_summons: Array = []


## Quantos summons desta magia estão vivos.
func get_alive_summon_count() -> int:
	var still_alive: Array = []
	for node: Variant in _alive_summons:
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			still_alive.append(node)
	_alive_summons = still_alive
	return _alive_summons.size()


func _perform(target: Node2D) -> void:
	if strike_scene == null:
		return
	var strike := strike_scene.instantiate() as GroundStrike
	if strike == null:
		push_error("GroundStrikeAbility '%s': a cena não tem GroundStrike na raiz." % name)
		return

	# Sem alvo (chef engolido...) e `fallback_to_map_center`: cai no MEIO DO MAPA.
	var at: Vector2 = target.global_position + _random_offset() if is_instance_valid(target) \
		else get_aim_position(null)
	strike.struck.connect(_on_struck.bind(strike), CONNECT_ONE_SHOT)
	var world: Node = get_world()
	world.add_child(strike)
	# Alerta e marca são "chão": ficam logo ANTES do chef na árvore (desenhados embaixo
	# dele, mas em cima do piso). O raio caindo tem z_index alto e fica na frente.
	if is_instance_valid(target) and target.get_parent() == world:
		world.move_child(strike, target.get_index())
	strike.global_position = at
	strike_spawned.emit(strike)

	if wait_for_impact:
		await strike.struck


func _random_offset() -> Vector2:
	var high: float = maxf(offset_max, offset_min)
	if high <= 0.0:
		return Vector2.ZERO
	var distance: float = randf_range(offset_min, high)
	return Vector2.RIGHT.rotated(randf() * TAU) * distance


func _on_struck(at: Vector2, _hit: Array, strike: GroundStrike) -> void:
	strike_landed.emit(strike, at)
	_fire_burst(at)
	_summon_at(at)


func _fire_burst(at: Vector2) -> void:
	if burst_data == null or burst_count <= 0:
		return
	var fired: Array = Projectile.spawn_burst(projectile_scene, get_world(), burst_data,
			at, burst_count, caster, burst_angle_offset)
	burst_fired.emit(fired)


func _summon_at(at: Vector2) -> void:
	if strike_summon_scene == null:
		return
	if summon_max_alive > 0 and get_alive_summon_count() >= summon_max_alive:
		return
	var creature: Node = strike_summon_scene.instantiate()
	if creature is Summon:
		creature.summoner = caster
	get_world().add_child(creature)
	if creature is Node2D:
		creature.global_position = at
	_alive_summons.append(creature)
	summoned.emit(creature)
