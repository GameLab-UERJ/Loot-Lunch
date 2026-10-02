extends FormigaSkill
## INVESTIDA: a formiga se encolhe (preparando o bote) e dispara contra o chef.
##
## QTE: aperte ESPAÇO no INÍCIO da corrida (o anel fecha no instante em que ela
## dispara). Acertou = frigideirada na cara dela (sem dano no chef + contra-ataque).
## SÓ HÁ UMA OPORTUNIDADE: apertar durante a preparação já perde a defesa.


@export var windup_min: float = 0.55
@export var windup_max: float = 1.1
@export var charge_time: float = 0.4
## O "impacto" do QTE: quanto depois do disparo (bem no começo da corrida).
@export var open_after: float = 0.06
@export var early_tolerance: float = 0.1
@export var late_tolerance: float = 0.12
@export var counter_damage: int = 3
@export var contact_offset: Vector2 = Vector2(26, 0)


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	# As formigas do fim da fila preparam o bote mais rápido.
	var windup: float = randf_range(windup_min, windup_max) * (1.0 - 0.06 * ant.level)
	battle.qte.configure(early_tolerance, late_tolerance, true, windup + 0.5)
	battle.qte.ring_anchor = chef.qte_anchor

	var base_scale: Vector2 = ant.sprite.scale
	var tween := create_tween()
	tween.tween_property(ant.sprite, "scale", base_scale * Vector2(1.2, 0.8), windup)
	tween.tween_callback(func() -> void:
		ant.sprite.scale = base_scale
		ant.sprite.speed_scale = 3.0
		ant.sprite.play_sheet(&"andar"))
	tween.tween_property(ant, "global_position", chef.global_position + contact_offset, charge_time) \
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)

	var beats: Array[float] = [windup + open_after]
	var hits: int = await battle.qte.run(beats)
	battle.register_qte(hits > 0)
	if hits > 0:
		tween.kill()
		ant.sprite.scale = base_scale
		chef.swing_pan(ant.global_position - chef.global_position)
		battle.announce("Frigideirada na cara!", Color(0.55, 1.0, 0.55))
		ant.take_hit(counter_damage, ant.global_position - chef.global_position)
		battle.shake(3.0, 0.2)
	else:
		if tween.is_running():
			await tween.finished
		chef.take_hit(damage, chef.global_position - ant.global_position)
		battle.shake(4.0, 0.25)
		await battle.wait(0.15)
	ant.sprite.speed_scale = 1.0
	await ant.return_home(0.4)
	ant.face(chef.global_position, ant.art_faces_left)
