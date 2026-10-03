extends BattleSkill
## 4. DEVORAR: habilidade especial. SÓ ATIVA com a vida da formiga abaixo de
## `hp_threshold` (20%). O chef chega perto, a MORDIDA (devorar_mordida, quadro 3 =
## NHAC) fecha em cima da formiga, ela é sugada (nocaute na hora) e o chef recupera vida
## com os coraçõezinhos (devorar_cura). A bunda da tanajura fica (vai para a farofa!).


@export_range(0.0, 1.0, 0.01) var hp_threshold: float = 0.2
## Vida recuperada (em meias caveiras).
@export var heal_amount: int = 4
@export var approach_offset: Vector2 = Vector2(-74, 24)
@export var bite_frame: int = 3

@export_group("Arte")
@export var bite_anim: SheetAnimation
@export var heal_anim: SheetAnimation


func _why_not(_user: ChefBattler, target: FormigaBattler) -> String:
	if target.health.get_ratio() >= hp_threshold:
		return "só com a formiga abaixo de %d%% de vida" % roundi(hp_threshold * 100.0)
	return ""


func _execute(battle: TurnBattle, user: ChefBattler, target: FormigaBattler) -> void:
	user.face(target.global_position)
	await user.move_to(target.global_position + approach_offset, 0.22)

	# A mordida fecha em cima da formiga.
	var bite: AnimatedSprite2D = battle.fx(bite_anim, target.global_position)
	if bite:
		await _wait_frame(bite, bite_frame)
	battle.announce("NHAC!", Color(1.0, 0.85, 0.4))
	battle.shake(3.0, 0.15)

	# A formiga é sugada para a boca do chef, girando e encolhendo.
	target.devoured = true
	target.health.invulnerable = false
	if target.hp_bar:
		target.hp_bar.set_bar_visible(false)
	var mouth: Vector2 = user.global_position + Vector2(8, -10)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(target, "global_position", mouth, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if target.sprite:
		tween.tween_property(target.sprite, "scale", Vector2.ZERO, 0.25)
		tween.tween_property(target.sprite, "rotation", TAU, 0.25)
	await tween.finished

	for i in 2:
		await user.squash(Vector2(1.3, 0.7), 0.12)
	target.health.kill()
	user.heal(heal_amount)
	battle.fx(heal_anim, user.global_position, user)
	await user.return_home(0.25)


func _wait_frame(sprite: AnimatedSprite2D, target_frame: int) -> void:
	while is_instance_valid(sprite) and sprite.is_playing() and sprite.frame < target_frame:
		await sprite.frame_changed
