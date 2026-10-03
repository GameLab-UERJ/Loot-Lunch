extends FormigaSkill
## ARREMESSO (Rainha): ela agarra as formigas pequenas e ARREMESSA no chef, uma de cada
## vez. Sem formiga pequena no campo ela nem cogita usar (`can_use`).
##
## QTE: ESPAÇO quando a formiga chegar (um anel por formiga) para REBATER com a
## frigideira (`contra_rebater`): ela volta voando para a vaga dela, leva
## `reflect_damage` e fica tonta. Errou = `damage` no chef (2 = uma caveira inteira).


@export var grab_offset: Vector2 = Vector2(-56, -54)
@export var grab_time: float = 0.3
@export var flight_time: float = 0.75
@export var arc_height: float = 70.0
@export var reflect_damage: int = 8
@export var early_tolerance: float = 0.13
@export var late_tolerance: float = 0.09
@export var aim_offset: Vector2 = Vector2(44, -10)


func can_use(battle: TurnBattle, _ant: FormigaBattler) -> bool:
	return battle != null and not battle.alive_minions().is_empty()


func _execute(battle: TurnBattle, queen: FormigaBattler, chef: ChefBattler) -> void:
	var minions: Array[FormigaBattler] = battle.alive_minions()
	minions.sort_custom(func(a: FormigaBattler, b: FormigaBattler) -> bool:
		return a.slot_index < b.slot_index)
	for minion in minions:
		if minion.is_dead() or chef.is_dead():
			continue
		await _throw(battle, queen, minion, chef)
		await battle.wait(0.2)


func _throw(battle: TurnBattle, queen: FormigaBattler, minion: FormigaBattler, chef: ChefBattler) -> void:
	# 1. A Rainha agarra.
	if minion.hp_bar:
		minion.hp_bar.set_bar_visible(false)
	var claw: Vector2 = queen.global_position + grab_offset
	await minion.move_to(claw, grab_time)
	await queen.squash(Vector2(1.15, 0.85), 0.2)

	# 2. Arremessa girando; o anel fecha na chegada.
	var from: Vector2 = minion.global_position
	var to: Vector2 = chef.global_position + aim_offset
	battle.qte.configure(early_tolerance, late_tolerance, true, 0.6)
	battle.qte.ring_anchor = chef.qte_anchor
	var flight := create_tween().set_parallel(true)
	flight.tween_method(_fly.bind(minion, from, to), 0.0, 1.0, flight_time)
	flight.tween_property(minion.sprite, "rotation", -TAU * 2.0, flight_time)
	var beats: Array[float] = [flight_time]
	var hits: int = await battle.qte.run(beats)
	battle.register_qte(hits > 0)
	flight.kill()
	minion.sprite.rotation = 0.0

	if hits > 0:
		# 3a. Rebateu: volta voando para a vaga e leva o dano.
		chef.act(counter_animation, -1)
		battle.fx(impact, minion.global_position)
		battle.announce("Rebateu a formiga!", Color(0.55, 1.0, 0.55))
		minion.take_hit(reflect_damage, Vector2.RIGHT)
		battle.shake(3.0, 0.2)
		var back := create_tween()
		back.tween_method(_fly.bind(minion, minion.global_position, minion.home_position), 0.0, 1.0, 0.4)
		await back.finished
		if not minion.is_dead():
			minion.daze(counter_daze)
	else:
		# 3b. Acertou o chef.
		deal(battle, queen, chef, damage, chef.global_position - from)
		battle.shake(5.0, 0.3)
		await minion.hop(16.0, 0.2)
		var back := create_tween()
		back.tween_method(_fly.bind(minion, minion.global_position, minion.home_position), 0.0, 1.0, 0.45)
		await back.finished
	minion.global_position = minion.home_position
	minion.face(chef.global_position, minion.art_faces_left)
	if minion.hp_bar and not minion.is_dead():
		minion.hp_bar.set_bar_visible(true)


func _fly(t: float, node, from: Vector2, to: Vector2) -> void:
	if is_instance_valid(node):
		node.global_position = from.lerp(to, t) + Vector2(0.0, -arc_height * sin(PI * t))
