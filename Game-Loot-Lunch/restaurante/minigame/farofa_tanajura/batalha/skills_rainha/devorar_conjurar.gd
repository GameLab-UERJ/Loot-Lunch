extends FormigaSkill
## DEVORAR E CONJURAR (Rainha): PRIORIDADE MÁXIMA (`interrupts`). Quando a vida dela
## chega num limiar (QueenAntBattler.devour_thresholds: 60% e 20%, uma vez cada = só 2
## vezes na partida) ela NÃO espera a barra dela: solta na hora (voando, desce antes) e
## as pequenas e o chef esperam.
##   1. Devora as formigas pequenas do campo (elas MORREM, sem drop): cada uma cura
##      `heal_ratio` (20%) da vida máxima. Com 2 no campo = +40%.
##   2. Conjura `summon_count` formigas novas nas vagas livres (saem do chão).
##   3. Fica mais RÁPIDA: a espera dela é multiplicada por `wait_multiplier` (0.8 = 20%
##      mais rápida) a cada vez.
## Sem formiga no campo, só conjura. Nunca passa de 2 pequenas (o número de vagas).
##
## NO ÚLTIMO LIMIAR (20%) começa a FASE FINAL: em vez de formigas comuns ela conjura as
## GUARDIÃS (`final_summon_scene`: 2x vida, protegem a Rainha de qualquer dano) e LEVANTA
## VOO logo em seguida. Na fase final ela ataca do céu (Raio Psíquico, Esferas Psíquicas,
## 10 Cortes de Vento) e não usa mais o Ultra Arremesso.


@export_range(0.0, 1.0, 0.05) var heal_ratio: float = 0.2
@export_range(0, 4) var summon_count: int = 2
@export var mouth_offset: Vector2 = Vector2(-60, -6)
@export var bite_anim: SheetAnimation
@export var heal_anim: SheetAnimation
@export var erupt_anim: SheetAnimation
@export var rise_depth: float = 70.0
## A cada vez que usa, a espera da Rainha vira `wait_time * wait_multiplier`.
@export_range(0.1, 1.0, 0.05) var wait_multiplier: float = 0.8
@export_group("Fase final (último limiar)")
## Quem ela conjura no último limiar (formiga_guardia.tscn). Vazio = formigas comuns.
@export var final_summon_scene: PackedScene
## Cura por formiga devorada no último limiar (0 = não cura: a fase final é de 20% para
## baixo). Use `heal_ratio` para voltar ao comportamento antigo.
@export_range(0.0, 1.0, 0.05) var final_heal_ratio: float = 0.0
## Levanta voo logo depois de conjurar as Guardiãs.
@export var fly_after_final_summon: bool = true


func _init() -> void:
	interrupts = true
	usable_airborne = true  # voando, ela desce antes (ver `_execute`)


func has_priority(_battle: TurnBattle, ant: FormigaBattler) -> bool:
	var queen := ant as QueenAntBattler
	return queen != null and not queen.is_dead() and queen.pending_threshold() >= 0.0


func can_use(battle: TurnBattle, ant: FormigaBattler) -> bool:
	return has_priority(battle, ant)


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	var queen := ant as QueenAntBattler
	# Último limiar (o menor) = fase final.
	var going_final: bool = queen.health.get_ratio() <= queen.devour_thresholds.min()
	queen.consume_thresholds()
	if queen.airborne:
		await queen.land()
	var heal: float = final_heal_ratio if going_final else heal_ratio

	# 1. Devora quem estiver no campo.
	var minions: Array[FormigaBattler] = battle.alive_minions()
	if not minions.is_empty():
		battle.announce("A Rainha devorou as companheiras!", Color(1.0, 0.5, 0.45))
	for minion in minions:
		await _devour(battle, queen, minion, heal)

	# 2. Conjura novas (no último limiar: as Guardiãs).
	var scene: PackedScene = final_summon_scene if going_final else null
	if going_final:
		queen.enter_final_phase()
		battle.announce("FASE FINAL! A Rainha conjura as GUARDIÃS!", Color(0.6, 1.0, 1.0))
		battle.shake(4.0, 0.4)
		await battle.wait(0.5)
	var slots: Array[int] = battle.free_slots()
	var made: int = 0
	for slot in slots:
		if made >= summon_count:
			break
		var fresh: FormigaBattler = battle.spawn_minion(slot, scene)
		if fresh == null:
			continue
		made += 1
		battle.fx(erupt_anim, fresh.feet_position())
		fresh.face(chef.global_position, fresh.art_faces_left)
		fresh.rise_from_ground(rise_depth, 0.4)
		await battle.wait(0.15)
	if made > 0 and not going_final:
		battle.announce("A Rainha conjurou %d formiga%s!" % [made, "s" if made > 1 else ""], Color(1.0, 0.7, 0.5))
	if made > 0:
		await battle.wait(0.5)

	# 3. Mais rápida a cada conjuração.
	if queen.wait and wait_multiplier < 1.0:
		queen.wait.wait_time *= wait_multiplier
		battle.announce("A Rainha ficou mais rápida!", Color(1.0, 0.45, 0.4))
		await battle.wait(0.4)

	# 4. Fase final: sobe para o céu e de lá não desce enquanto houver Guardiã.
	if going_final and fly_after_final_summon and not queen.airborne:
		await queen.squash(Vector2(1.2, 0.8), 0.25)
		await queen.fly_up()


func _devour(battle: TurnBattle, queen: QueenAntBattler, minion: FormigaBattler, heal: float) -> void:
	minion.set_targetable(false)
	minion.show_alert(false)
	if minion.hp_bar:
		minion.hp_bar.set_bar_visible(false)
	var mouth: Vector2 = queen.global_position + mouth_offset
	var pull := create_tween().set_parallel(true)
	pull.tween_property(minion, "global_position", mouth, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if minion.sprite:
		pull.tween_property(minion.sprite, "scale", Vector2.ZERO, 0.35)
		pull.tween_property(minion.sprite, "rotation", TAU, 0.35)
	battle.fx(bite_anim, mouth)
	await pull.finished
	minion.eaten = true
	minion.health.invulnerable = false
	minion.health.kill()
	await queen.squash(Vector2(1.2, 0.8), 0.15)
	var gained: int = queen.heal(roundi(queen.health.max_hp * heal)) if heal > 0.0 else 0
	if gained > 0:
		battle.fx(heal_anim, queen.global_position + Vector2(0, -30), queen)
	await battle.wait(0.2)
