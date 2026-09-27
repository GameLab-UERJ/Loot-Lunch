extends CustomerAbility
class_name SummonAbility
## MAGIA DE INVOCAÇÃO genérica (a ultimate de todo cliente): cria um ou mais Summon
## (pato devorador, demoninho...) perto do cliente. O summon é uma CENA (`summon_scene`);
## esta magia não sabe o que ele faz.


signal summoned(summon: Node2D)


@export_group("Invocação")
@export var summon_scene: PackedScene
## Quantos nascem por uso.
@export_range(1, 8) var amount: int = 1
## Máximo vivo AO MESMO TEMPO invocado por este cliente. 0 = sem limite.
@export_range(0, 16) var max_alive: int = 2
## Onde nasce, relativo ao cliente (na frente dele, no chão).
@export var spawn_offset: Vector2 = Vector2(0, 26)
## Espalha os summons quando nasce mais de um.
@export var spread: float = 16.0


var _alive: Array = []


func _init() -> void:
	super._init()
	requires_target = false  # o summon procura o alvo sozinho


## Quantos summons desta magia estão vivos.
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
	for i in amount:
		if max_alive > 0 and get_alive_count() >= max_alive:
			return
		var creature: Node = summon_scene.instantiate()
		if creature is Summon:
			creature.summoner = caster
			if target:
				creature.target = target
		get_world().add_child(creature)
		if creature is Node2D:
			var offset: Vector2 = spawn_offset
			if amount > 1:
				offset.x += (i - (amount - 1) * 0.5) * spread
			creature.global_position = caster.global_position + offset
		_alive.append(creature)
		summoned.emit(creature)
