extends Node2D
## Cena de teste das MAGIAS DA MANDY.
##
##   1 = SÍMBOLO DE BRUXARIA: surge embaixo do chef e anda junto com ele (-20% de
##       velocidade). Não dá para fugir. A Mandy fica conjurando enquanto ele dura.
##   2 = CAVEIRA DE FOGO: surge na mão da Mandy e voa no chef. Acertou: -1 caveira de
##       vida e -50% de velocidade por 3 s (desvie andando ou com dash).
##   3 = DEMONINHO: voa até o chef e GRUDA (-90% de velocidade). Enquanto ele está
##       grudado, os outros summons dançam. Depois de um tempo cai e derrete sozinho.
##       Aperte 3 de novo: o 2º demoninho fica mais rápido, se FUNDE com o primeiro e
##       ARRASTA o chef para o buraco do inferno (finaliza).
##   4 = simula a paciência caindo um nível (1ª vez símbolo, 2ª caveira, 3ª demoninho...)
##   5 = invoca o PATO do Patolino (para ver ele dançando enquanto o demoninho está grudado)
##   G = espetinho na mão | H = cura / revive | R = pega/larga | Espaço = dash


@export var item_scene: PackedScene
## Item que o G coloca na mão do chef.
@export var give_item: Resource


var _patience_level: int = 0


@onready var chef: Chef = $Chef
@onready var caster: CustomerAbilityCaster = $Mandy/Habilidades
@onready var patolino_caster: CustomerAbilityCaster = $Patolino/Habilidades
@onready var items_container: Node = $ItensNoChao


func _ready() -> void:
	chef.health_changed.connect(func(current: int, maximum: int) -> void:
		print("[Chef] vida %d/%d (%.1f caveiras)" % [current, maximum, current / 2.0]))
	chef.died.connect(func() -> void: print("[Chef] MORREU"))

	caster.ability_cast.connect(func(index: int, ability: CustomerAbility) -> void:
		print("[Mandy] magia %d: %s" % [index + 1, ability.name]))
	for ability in caster.get_abilities():
		if ability is AuraAbility:
			ability.aura_attached.connect(func(aura: StatusAura) -> void:
				print("[Símbolo] grudou no chef (%.0f%% mais lento)" % (aura.slow_percent * 100.0))
				aura.finished.connect(func(_t: Node2D) -> void: print("[Símbolo] acabou")))
		elif ability is ProjectileAbility:
			ability.fired.connect(_on_projectile_fired)
		elif ability is SummonAbility:
			ability.summoned.connect(_on_summoned)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.keycode:
		KEY_1:
			_try_cast(0)
		KEY_2:
			_try_cast(1)
		KEY_3:
			_try_cast(2)
		KEY_4:
			_patience_level += 1
			print("[Paciência] perdeu o nível %d" % _patience_level)
			caster.cast_for_patience_level(_patience_level)
		KEY_5:
			if not patolino_caster.cast(2):
				print("[Patolino] pato não saiu (limite de patos)")
		KEY_G:
			give_skewer()
		KEY_H:
			chef.heal_full()
			print("[Chef] curado")
		_:
			return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	var speed_label := get_node_or_null("Velocidade") as Label
	if speed_label:
		speed_label.text = "velocidade do chef: %d%%" % roundi(SlowComponent.get_multiplier_of(chef) * 100.0)


## Coloca um espetinho na mão do chef (se estiver vazia).
func give_skewer() -> CarryableItem:
	if item_scene == null or give_item == null or chef.hand_component.has_item():
		return null
	var item := item_scene.instantiate() as CarryableItem
	item.data = give_item as ItemData
	items_container.add_child(item)
	chef.hand_component.hold(item)
	print("[Teste] espetinho na mão")
	return item


func _try_cast(index: int) -> void:
	if not caster.cast(index):
		print("[Mandy] magia %d não saiu (ocupada, sem alvo ou limite de demoninhos)" % (index + 1))


func _on_projectile_fired(projectile: Projectile) -> void:
	projectile.hit.connect(func(body: Node2D) -> void: print("[Caveira] acertou %s!" % body.name))
	projectile.finished.connect(func(_at: Vector2) -> void: print("[Caveira] estourou"))


func _on_summoned(creature: Node2D) -> void:
	print("[Demoninho] invocado")
	if creature is LittleDemon:
		creature.attached.connect(func(_c: Node2D) -> void:
			print("[Demoninho] GRUDOU no chef! (outros summons dançando)"))
		creature.detached.connect(func(_c: Node2D) -> void: print("[Demoninho] soltou e derreteu"))
		creature.fused.connect(func(_c: Node2D) -> void: print("[Demoninho] FUSÃO!"))
		creature.chef_finalized.connect(func(_c: Node2D) -> void:
			print("[Demoninho] arrastou o chef para o inferno: FINALIZADO"))
