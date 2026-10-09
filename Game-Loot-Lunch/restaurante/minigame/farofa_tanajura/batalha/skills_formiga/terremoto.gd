extends FormigaSkill
## TERREMOTO: a formiga empina e PISA. A onda curta (terremoto_onda) estoura no pé
## dela e a onda longa (terremoto_onda_longa) corre pelo chão até o chef.
##
## QTE: aperte ESPAÇO quando a onda chegar (o anel fecha no instante certo) para PULAR
## (animação `pulo` do chef + poeira no pouso). Pulou cedo demais = cai antes da onda
## passar (toma o dano). Terremoto não tem contra-ataque: só desviar.


@export var slam_min: float = 0.55
@export var slam_max: float = 0.95
@export var early_tolerance: float = 0.13
@export var late_tolerance: float = 0.1

@export_group("Arte")
@export var short_wave: SheetAnimation
@export var long_wave: SheetAnimation
## Quadro da onda longa em que ela "chega" e o raio dela nesse quadro (pixels da arte).
@export var long_wave_reach_frame: int = 7
@export var long_wave_reach_radius: float = 108.0
@export var jump_animation: StringName = &"pulo"
@export var landing_dust: SheetAnimation


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	var slam: float = randf_range(slam_min, slam_max) * (1.0 - 0.04 * ant.level)
	var distance: float = absf(chef.feet_position().x - ant.feet_position().x)
	var travel: float = _travel_time()
	var hit_time: float = slam + travel
	battle.qte.configure(early_tolerance, late_tolerance, true, 0.8)
	battle.qte.ring_anchor = chef.qte_anchor

	# Empina devagar e desce com tudo.
	var tween := create_tween()
	tween.tween_property(ant.sprite, "position", Vector2(0, -18), slam * 0.8) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ant.sprite, "position", Vector2.ZERO, slam * 0.2) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(_slam.bind(battle, ant, distance))

	var started_ms: int = Time.get_ticks_msec()
	var beats: Array[float] = [hit_time]
	battle.qte.prompt_caption = "PULE!"
	var hits: int = await battle.qte.run(beats)
	var elapsed: float = (Time.get_ticks_msec() - started_ms) / 1000.0
	battle.register_qte(hits > 0)
	if hits > 0:
		battle.announce("Pulou!", Color(0.55, 1.0, 0.55))
		await _jump(battle, chef)
	else:
		if elapsed < hit_time - battle.qte.early_tolerance:
			battle.announce("Pulou cedo demais!", Color(1.0, 0.6, 0.4))
			_jump(battle, chef)
			await battle.wait(maxf(hit_time - elapsed, 0.0))
		deal(battle, ant, chef, damage)
		battle.shake(6.0, 0.35)
		await battle.wait(0.3)


func _travel_time() -> float:
	if long_wave == null:
		return 0.5
	return (long_wave_reach_frame + 0.5) / maxf(long_wave.fps, 0.001)


func _jump(battle: TurnBattle, chef: ChefBattler) -> void:
	if not await chef.act(jump_animation, -1):
		await chef.hop(30.0, 0.45)
	else:
		await chef.finish_action()
	battle.fx(landing_dust, chef.feet_position())


func _slam(battle: TurnBattle, ant: FormigaBattler, distance: float) -> void:
	battle.shake(5.0, 0.3)
	var at: Vector2 = ant.feet_position()
	battle.fx(short_wave, at)
	if long_wave == null:
		var wave := OndaTerremoto.new()
		wave.max_radius = distance + 50.0
		wave.speed = distance / maxf(_travel_time(), 0.01)
		battle.add_effect(wave)
		wave.global_position = at
		return
	var sprite: AnimatedSprite2D = battle.fx(long_wave, at)
	if sprite:
		# Estica na horizontal para a borda da onda chegar no chef no quadro certo.
		var stretch: float = distance / maxf(long_wave_reach_radius, 1.0)
		sprite.scale = Vector2(stretch, long_wave.scale.y)
