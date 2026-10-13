extends "res://restaurante/clientes/entrega/teste_entrega.gd"
## Cena de teste das HABILIDADES do chef (herda a cena de teste da entrega).
##
## - Q (segurar 5 s e soltar): arremessa o espetinho. Acertou cliente com pedido = entrega.
##   Soltar antes dos 5 s ou levar dano (K) enquanto carrega = espetinho cai no pé.
## - Q mira com o MOUSE (linha pontilhada mostra o caminho).
## - E: deixa uma sombra no lugar. E de novo em até 10 s = volta para a sombra.
##   Cada habilidade gasta 1 barra de mana (voltar para a sombra não gasta).
## - Entregar pedido recupera vida e mana (DeliveryRewardComponent do chef).
## - M: enche a mana. J: gasta 1 de mana (para testar a barra).
## - Continua valendo: R pega/larga, B entrega na mão, G repõe, K dano, H cura, N pedidos.


@export var refill_mana_key: Key = KEY_M
@export var spend_mana_key: Key = KEY_J


func _ready() -> void:
	super._ready()
	for ability in AbilityComponent.find_all_in(chef):
		ability.activated.connect(_on_ability_activated.bind(ability))
		ability.interrupted.connect(_on_ability_interrupted.bind(ability))
		ability.not_enough_mana.connect(_on_not_enough_mana.bind(ability))
		if ability is ShadowAbility:
			ability.returned.connect(func(_from: Vector2, _to: Vector2) -> void:
				print("[E] voltou para a sombra"))
			ability.shadow_expired.connect(func() -> void: print("[E] a sombra sumiu (tempo acabou)"))
		if ability is ThrowSkewerAbility:
			ability.charge_started.connect(func() -> void: print("[Q] carregando..."))
			ability.charged.connect(func() -> void: print("[Q] CARREGADO! solte para arremessar"))
			ability.dropped.connect(func(item: CarryableItem) -> void:
				print("[Q] caiu no chão: %s" % item.data.display_name))


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and chef.mana:
		if key.keycode == refill_mana_key:
			chef.mana.restore_full()
			print("[Mana] cheia -> %d/%d" % [chef.mana.mana, chef.mana.max_mana])
			get_viewport().set_input_as_handled()
			return
		if key.keycode == spend_mana_key:
			chef.mana.try_spend(1)
			print("[Mana] gastou 1 -> %d/%d" % [chef.mana.mana, chef.mana.max_mana])
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)


func _on_ability_activated(ability: AbilityComponent) -> void:
	print("[%s] usada. Mana: %d/%d" % [ability.name, chef.mana.mana, chef.mana.max_mana])


func _on_ability_interrupted(ability: AbilityComponent) -> void:
	print("[%s] interrompida (levou dano)" % ability.name)


func _on_not_enough_mana(ability: AbilityComponent) -> void:
	print("[%s] sem mana!" % ability.name)
