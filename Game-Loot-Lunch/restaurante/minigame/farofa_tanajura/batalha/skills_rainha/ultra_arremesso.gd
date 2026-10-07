extends FormigaSkill
## ULTRA ARREMESSO (Rainha): ela fica CARREGANDO uma bola de terra enorme por
## `charge_time` segundos. Nesse tempo as outras formigas esperam e SÓ O CHEF age
## (TurnBattle.channel).
##   - acertou `hits_needed` golpes NELA (qualquer habilidade) -> a bola cai em cima
##     das formigas: `fall_damage` em TODAS (pequenas e Rainha);
##   - não conseguiu -> ela arremessa a bola: `damage` (6 = 3 caveiras) no chef, SEM
##     chance de defesa.


@export_range(1.0, 30.0, 0.5, "suffix:s") var charge_time: float = 13.0
@export_range(1, 10) var hits_needed: int = 3
@export var fall_damage: int = 12
@export var ball_anim: SheetAnimation
@export var ball_offset: Vector2 = Vector2(0, -110)
@export var ball_start_scale: float = 0.6
@export var ball_end_scale: float = 3.0
@export var throw_time: float = 0.6
@export var break_anim: SheetAnimation
@export var crash_anim: SheetAnimation


func can_use(_battle: TurnBattle, ant: FormigaBattler) -> bool:
	return not ant.is_airborne()


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	var queen := ant as QueenAntBattler
	var ball: AnimatedSprite2D = ball_anim.create_sprite() if ball_anim else AnimatedSprite2D.new()
	ball.scale = Vector2.ONE * ball_start_scale
	ball.z_index = 30
	battle.add_effect(ball)
	ball.global_position = ant.global_position + ball_offset
	var grow := create_tween()
	grow.tween_property(ball, "scale", Vector2.ONE * ball_end_scale, charge_time)

	if queen:
		queen.begin_charge()
	battle.select_target(ant)
	battle.announce("BOLA DE TERRA! Acerte %d golpes na Rainha!" % hits_needed, Color(1.0, 0.8, 0.4))
	var status := func(left: float) -> void:
		if queen:
			queen.status_changed.emit("BOLA DE TERRA  %d/%d golpes  —  %.0fs" % [queen.charge_hits, hits_needed, ceilf(left)])
	var done := func() -> bool:
		return ant.is_dead() or (queen != null and queen.charge_hits >= hits_needed)
	await battle.channel(charge_time, done, status)
	grow.kill()
	var broke: bool = done.call()
	if queen:
		queen.end_charge()
		queen.status_changed.emit("")

	if ant.is_dead():
		ball.queue_free()
		return
	if broke:
		await _drop_on_ants(battle, ball)
	else:
		await _throw_at_chef(battle, ant, chef, ball)


func _drop_on_ants(battle: TurnBattle, ball: AnimatedSprite2D) -> void:
	battle.announce("A bola despencou nas formigas!", Color(0.55, 1.0, 0.55))
	var fall := create_tween()
	fall.tween_property(ball, "global_position:y", ball.global_position.y + 90.0, 0.35) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await fall.finished
	battle.shake(7.0, 0.4)
	battle.fx(break_anim, ball.global_position, null)
	ball.queue_free()
	for target in battle.alive_ants():
		battle.fx(crash_anim, target.feet_position())
		target.take_hit(fall_damage, Vector2.DOWN)
	await battle.wait(0.5)


func _throw_at_chef(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler, ball: AnimatedSprite2D) -> void:
	battle.announce("ULTRA ARREMESSO!", Color(1.0, 0.4, 0.35))
	await ant.squash(Vector2(1.2, 0.8), 0.2)
	var from: Vector2 = ball.global_position
	var to: Vector2 = chef.global_position + Vector2(0, -10)
	var flight := create_tween()
	flight.tween_method(func(t: float) -> void:
		if is_instance_valid(ball):
			ball.global_position = from.lerp(to, t) + Vector2(0, -60.0 * sin(PI * t)), 0.0, 1.0, throw_time)
	await flight.finished
	var crack: AnimatedSprite2D = battle.fx(break_anim, to)
	if crack:
		crack.scale = Vector2(3, 3)
	ball.queue_free()
	deal(battle, ant, chef, damage, Vector2.LEFT)
	battle.shake(9.0, 0.5)
	await battle.wait(0.5)
