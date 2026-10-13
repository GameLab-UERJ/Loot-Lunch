extends FormigaSkill
## RAIO PSÍQUICO (Rainha, só na FASE FINAL, sai VOANDO): ela concentra uma esfera na
## boca e dispara um feixe no chef. QTE de MARTELAR: aperte ESPAÇO sem parar para encher
## a barra (MashMeter) antes do tempo acabar.
##   - encheu  -> o chef segura o raio com a frigideira e ele volta (sem dano);
##   - não encheu -> leva `damage` proporcional ao que faltou (martelar pela metade =
##     metade do dano).


@export var charge_time: float = 0.9
@export var presses_needed: int = 12
@export var mash_time: float = 3.0
## Apertos que "vazam" por segundo (não dá para parar no meio).
@export var mash_decay: float = 2.0
## De onde sai o feixe (em relação à Rainha) e onde aparece a barra (em relação ao chef).
@export var mouth_offset: Vector2 = Vector2(-62, -18)
@export var meter_offset: Vector2 = Vector2(0, -64)
## Tecla (KeyPrompt) em relação à barra de martelar.
@export var prompt_offset: Vector2 = Vector2(0, -26)
@export var charge_anim: SheetAnimation


func _init() -> void:
	phases = [1]
	usable_airborne = true


func _execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	battle.announce("RAIO PSÍQUICO! Martele o ESPAÇO!", Color(0.85, 0.55, 1.0))
	var mouth: Vector2 = ant.global_position + mouth_offset

	# 1. Carga: esfera crescendo na boca.
	var orb: AnimatedSprite2D = charge_anim.create_sprite() if charge_anim else null
	if orb:
		battle.add_effect(orb)
		orb.global_position = mouth
		orb.scale = Vector2.ZERO
		var grow := orb.create_tween()
		grow.tween_property(orb, "scale", Vector2(3, 3), charge_time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ant.squash(Vector2(0.9, 1.1), charge_time)
	await battle.wait(charge_time)
	if orb:
		orb.queue_free()

	# 2. Feixe + barra de martelar.
	var beam := PsychicBeam.new()
	battle.add_effect(beam)
	await beam.aim(mouth, chef.global_position + Vector2(10, -8))
	battle.shake(2.0, 0.2)
	var meter := MashMeter.new()
	meter.prompt = ""  # a tecla grande (KeyPrompt) logo acima já diz o que fazer
	battle.add_effect(meter)
	meter.global_position = chef.global_position + meter_offset
	chef.act(counter_animation, -1)
	# Tecla grande em cima da barra: ESPAÇO afundando rápido ("martele!").
	var prompt := KeyPrompt.spawn(chef, meter_offset + prompt_offset, PackedStringArray(["SPACE"]), "MARTELE!")
	prompt.set_press_period(0.16)
	prompt.set_active(true)
	meter.run(presses_needed, mash_time, mash_decay)
	while meter.is_running():
		beam.clash = meter.progress
		if chef.sprite:
			chef.sprite.position.x = randf_range(-1.0, 1.0) * (1.0 - meter.progress) * 2.0
		await battle.get_tree().process_frame
	if chef.sprite:
		chef.sprite.position.x = 0.0
	prompt.dismiss()
	var progress: float = meter.progress
	battle.register_qte(progress >= 1.0)

	# 3. Resultado.
	if progress >= 1.0:
		battle.announce("Segurou o raio!", Color(0.55, 1.0, 0.55))
		battle.fx(impact, beam.to)
		await beam.retract()
	else:
		var hurt: int = maxi(ceili(damage * (1.0 - progress)), 1)
		deal(battle, ant, chef, hurt, Vector2.LEFT)
		battle.fx(impact, chef.global_position + Vector2(0, -6))
		battle.shake(5.0, 0.3)
		await beam.vanish()
	meter.queue_free()
