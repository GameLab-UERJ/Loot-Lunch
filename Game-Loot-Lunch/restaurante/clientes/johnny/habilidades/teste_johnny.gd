extends Node2D
## Cena de teste das MAGIAS DO JOHNNY (raio).
##
##   1 = RAIO: o alerta amarelo marca o chão onde o chef está; depois de um tempo o raio
##       cai. Pegou: ATORDOADO por 2 s (parado, sem agir). Saia do círculo ou dê dash.
##   2 = ESFERA DE RAIO: persegue o chef devagar. Pegou: -2 caveiras e atordoado por 5 s.
##   3 = RAIO SUPREMO: a mira cai PERTO do chef; no impacto solta 8 esferas (N, NE, L, SE,
##       S, SO, O, NO: -1 caveira e atordoado 2 s) e uma NUVEM que persegue o chef.
##       Nuvem encostou: grande choque + CONFUSO por 120 s (setas invertidas).
##       Nuvem encostou de novo no chef confuso: VIRA PÓ (finalizado).
##   4 = simula a paciência caindo um nível (raio -> esfera -> raio supremo...)
##   5 = caveira da MANDY (para ver o chef atordoado levando dano de outra magia)
##   6 = demoninho da MANDY (enquanto ele está grudado, a nuvem dança)
##   G = espetinho na mão | H = cura / revive | R = pega/larga | Espaço = dash


@export var item_scene: PackedScene
## Item que o G coloca na mão do chef.
@export var give_item: Resource


var _patience_level: int = 0


@onready var chef: Chef = $Chef
@onready var caster: CustomerAbilityCaster = $Johnny/Habilidades
@onready var mandy_caster: CustomerAbilityCaster = $Mandy/Habilidades
@onready var items_container: Node = $ItensNoChao
@onready var status_label: Label = get_node_or_null("Status")


func _ready() -> void:
	chef.health_changed.connect(func(current: int, maximum: int) -> void:
		print("[Chef] vida %d/%d (%.1f caveiras)" % [current, maximum, current / 2.0]))
	chef.died.connect(func() -> void: print("[Chef] MORREU"))

	caster.ability_cast.connect(func(index: int, ability: CustomerAbility) -> void:
		print("[Johnny] magia %d: %s" % [index + 1, ability.name]))
	for ability in caster.get_abilities():
		if ability is GroundStrikeAbility:
			ability.strike_landed.connect(func(_s: GroundStrike, at: Vector2) -> void:
				print("[%s] caiu em %s" % [ability.name, at.round()]))
			ability.burst_fired.connect(func(list: Array) -> void:
				print("[%s] soltou %d esferas" % [ability.name, list.size()]))
			ability.summoned.connect(_on_cloud_summoned)
		elif ability is ProjectileAbility:
			ability.fired.connect(func(projectile: Projectile) -> void:
				projectile.hit.connect(func(body: Node2D) -> void:
					print("[Esfera] acertou %s!" % body.name)))


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
			mandy_caster.cast(1)
		KEY_6:
			if not mandy_caster.cast(2):
				print("[Mandy] demoninho não saiu (limite)")
		KEY_G:
			give_skewer()
		KEY_H:
			chef.heal_full()
			print("[Chef] curado")
		_:
			return
	get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if status_label == null:
		return
	var parts: PackedStringArray = []
	var stun: StunComponent = StunComponent.find_in(chef)
	if stun and stun.is_active():
		parts.append("ATORDOADO %.1f s" % stun.get_time_left())
	var confusion: ConfusionComponent = ConfusionComponent.find_in(chef)
	if confusion and confusion.is_active():
		parts.append("CONFUSO %.0f s (setas invertidas)" % confusion.get_time_left())
	if chef.is_dead():
		parts.append("MORTO (H revive)")
	status_label.text = "chef: " + (" | ".join(parts) if not parts.is_empty() else "normal")


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
		print("[Johnny] magia %d não saiu (ocupado, sem alvo ou limite de nuvens)" % (index + 1))


func _on_cloud_summoned(creature: Node2D) -> void:
	print("[Nuvem] surgiu no centro do raio")
	if creature is StormCloud:
		creature.chef_confused.connect(func(_c: Node2D) -> void:
			print("[Nuvem] GRANDE CHOQUE: chef confuso (setas invertidas)"))
		creature.chef_finalized.connect(func(_c: Node2D) -> void:
			print("[Nuvem] chef já estava confuso: VIROU PÓ"))
