extends Node2D
## Cena de teste das MAGIAS DO PATOLINO.
##
##   1 = QUACK: pato gigante na tela (50% transparente) -> o chef derruba o item
##   2 = OVO: projétil, 3 caveiras de dano (desvie andando ou com dash)
##   3 = PATO DEVORADOR (ultimate). Aperte 3 de novo para ter um 2º pato:
##       ele corre (buff) para comer o pato cheio e FINALIZA o chef.
##   ◀ ▶ (setas ou A/D) ALTERNADOS = sair da barriga do pato
##   4 = simula a paciência caindo um nível (1ª vez quack, 2ª ovo, 3ª pato...)
##   G = espetinho na mão | H = cura / revive | R = pega/larga (o item derrubado)


@export var item_scene: PackedScene
## Item que o G coloca na mão do chef.
@export var give_item: Resource


var _patience_level: int = 0


@onready var chef: Chef = $Chef
@onready var patolino: Node2D = $Patolino
@onready var caster: CustomerAbilityCaster = $Patolino/Habilidades
@onready var items_container: Node = $ItensNoChao


func _ready() -> void:
	chef.health_changed.connect(func(current: int, maximum: int) -> void:
		print("[Chef] vida %d/%d (%.1f caveiras)" % [current, maximum, current / 2.0]))
	chef.died.connect(func() -> void: print("[Chef] MORREU"))

	caster.ability_cast.connect(func(index: int, ability: CustomerAbility) -> void:
		print("[Patolino] magia %d: %s" % [index + 1, ability.name]))
	for ability in caster.get_abilities():
		if ability is QuackAbility:
			ability.items_dropped.connect(func(count: int) -> void:
				print("[Quack] QUACK! %d chef(s) derrubaram o item" % count))
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
		KEY_G:
			give_skewer()
		KEY_H:
			chef.heal_full()
			print("[Chef] curado")
		_:
			return
	get_viewport().set_input_as_handled()


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
		print("[Patolino] magia %d não saiu (ocupado, sem alvo ou limite de patos)" % (index + 1))


func _on_projectile_fired(projectile: Projectile) -> void:
	projectile.hit.connect(func(body: Node2D) -> void: print("[Ovo] acertou %s!" % body.name))
	projectile.finished.connect(func(_at: Vector2) -> void: print("[Ovo] splat"))


func _on_summoned(creature: Node2D) -> void:
	print("[Pato] invocado")
	if creature is DevourerDuck:
		creature.devoured.connect(func(_c: Node2D) -> void:
			print("[Pato] ENGOLIU o chef! Aperte ◀ ▶ alternados"))
		creature.chef_escaped.connect(func(_c: Node2D) -> void: print("[Pato] o chef escapou!"))
		creature.chef_finalized.connect(func(_c: Node2D) -> void:
			print("[Pato] comeu o pato cheio: chef FINALIZADO"))
		creature.celebrating_changed.connect(func(on: bool) -> void:
			if on:
				print("[Pato] sem alvo livre: parado comemorando"))
