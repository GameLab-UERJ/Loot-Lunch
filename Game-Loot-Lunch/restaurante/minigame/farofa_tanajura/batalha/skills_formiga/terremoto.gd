extends FormigaSkill
## TERREMOTO: a formiga empina e PISA. Uma onda de choque corre pelo chão até o chef.
##
## QTE: aperte ESPAÇO quando a onda chegar (o anel fecha no instante certo) para PULAR.
## Pulou cedo demais = cai antes da onda passar (toma o dano).


@export var slam_min: float = 0.6
@export var slam_max: float = 1.0
## Velocidade da onda (px/s).
@export var wave_speed: float = 240.0
@export var jump_height: float = 30.0
@export var early_tolerance: float = 0.14
@export var late_tolerance: float = 0.1


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	var slam: float = randf_range(slam_min, slam_max)
	var distance: float = absf(chef.global_position.x - ant.global_position.x)
	var hit_time: float = slam + distance / wave_speed
	battle.qte.configure(early_tolerance, late_tolerance, true, 0.8)
	battle.qte.ring_anchor = chef.qte_anchor

	# Empina devagar e desce com tudo.
	var tween := create_tween()
	tween.tween_property(ant.sprite, "position", Vector2(0, -16), slam * 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ant.sprite, "position", Vector2.ZERO, slam * 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_slam.bind(battle, ant, distance))

	var started_ms: int = Time.get_ticks_msec()
	var beats: Array[float] = [hit_time]
	var hits: int = await battle.qte.run(beats)
	var elapsed: float = (Time.get_ticks_msec() - started_ms) / 1000.0
	battle.register_qte(hits > 0)
	if hits > 0:
		battle.announce("Pulou!", Color(0.55, 1.0, 0.55))
		await chef.hop(jump_height, 0.45)
	else:
		if elapsed < hit_time - early_tolerance:
			battle.announce("Pulou cedo demais!", Color(1.0, 0.6, 0.4))
			chef.hop(jump_height * 0.6, 0.3)
			await battle.wait(maxf(hit_time - elapsed, 0.0))
		chef.take_hit(damage)
		battle.shake(6.0, 0.35)
		await battle.wait(0.3)


func _slam(battle: TurnBattle, ant: FormigaBattler, distance: float) -> void:
	battle.shake(5.0, 0.3)
	var wave := OndaTerremoto.new()
	wave.speed = wave_speed
	wave.max_radius = distance + 50.0
	battle.add_effect(wave)
	wave.global_position = ant.global_position + Vector2(0, 8)
