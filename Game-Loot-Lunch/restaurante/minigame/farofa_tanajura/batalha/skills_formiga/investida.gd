extends FormigaSkill
## INVESTIDA: a formiga se encolhe (preparando o bote) e dispara contra o chef,
## levantando poeira (investida_poeira).
##
## QTE: aperte ESPAÇO no INÍCIO da corrida (o anel fecha no instante em que ela
## dispara). Acertou = contra-frigideirada na cara dela (sem dano no chef, ela fica
## tonta). SÓ HÁ UMA OPORTUNIDADE: apertar durante a preparação já perde a defesa.


@export var windup_min: float = 0.5
@export var windup_max: float = 1.0
@export var charge_time: float = 0.36
## O "impacto" do QTE: quanto depois do disparo (bem no começo da corrida).
@export var open_after: float = 0.06
@export var early_tolerance: float = 0.1
@export var late_tolerance: float = 0.11
## Onde ela para em relação ao chef (os pés dos dois na mesma linha).
@export var contact_offset: Vector2 = Vector2(70, -24)
@export var dust_anim: SheetAnimation


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	# As formigas do fim da fila preparam o bote mais rápido.
	var windup: float = randf_range(windup_min, windup_max) * (1.0 - 0.06 * ant.level)
	battle.qte.configure(early_tolerance, late_tolerance, true, windup + 0.5)
	battle.qte.ring_anchor = chef.qte_anchor

	ant.face(chef.global_position, ant.art_faces_left)
	var base_scale: Vector2 = ant.sprite.scale
	var target: Vector2 = chef.global_position + contact_offset
	var tween := create_tween()
	tween.tween_property(ant.sprite, "scale", base_scale * Vector2(1.15, 0.85), windup)
	tween.tween_callback(func() -> void:
		ant.sprite.scale = base_scale
		ant.sprite.speed_scale = 3.0
		ant.sprite.play_sheet(&"andar")
		_dust_trail(battle, ant))
	tween.tween_property(ant, "global_position", target, charge_time) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	var beats: Array[float] = [windup + open_after]
	var hits: int = await battle.qte.run(beats)
	battle.register_qte(hits > 0)
	if hits > 0:
		# Ela termina a corrida e dá de cara na frigideira (o golpe cai bem na chegada).
		battle.announce("Frigideirada na cara!", Color(0.55, 1.0, 0.55))
		# Começa o golpe a tempo de o quadro do acerto cair na chegada dela.
		var time_left: float = windup + charge_time - tween.get_total_elapsed_time()
		await battle.wait(maxf(time_left - _counter_lead(chef), 0.0))
		await counter(battle, ant, chef, Vector2(-34, 0))
		tween.kill()
		ant.sprite.scale = base_scale
		var bounce := create_tween()
		bounce.tween_property(ant, "global_position", ant.global_position + Vector2(36, 0), 0.15) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await bounce.finished
	else:
		if tween.is_running():
			await tween.finished
		deal(battle, ant, chef, damage, chef.global_position - ant.global_position)
		battle.shake(4.0, 0.25)
		await battle.wait(0.12)
	ant.sprite.speed_scale = 1.0
	await ant.return_home(0.35)
	ant.face(chef.global_position, ant.art_faces_left)


func _dust_trail(battle: TurnBattle, ant: FormigaBattler) -> void:
	for i in 3:
		if not is_instance_valid(ant):
			return
		battle.fx(dust_anim, ant.feet_position() + Vector2(34, 0))
		await battle.wait(0.1)


## Segundos entre o começo da animação de contra-ataque e o quadro do golpe.
func _counter_lead(chef: ChefBattler) -> float:
	if chef.sprite == null or not chef.sprite.has_sheet(counter_animation):
		return 0.0
	return counter_hit_frame / maxf(chef.sprite.sprite_frames.get_animation_speed(counter_animation), 0.001)
