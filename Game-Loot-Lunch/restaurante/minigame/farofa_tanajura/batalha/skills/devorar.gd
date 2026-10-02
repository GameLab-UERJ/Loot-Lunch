extends BattleSkill
## 4. DEVORAR: habilidade especial. SÓ ATIVA com a vida da formiga abaixo de
## `hp_threshold` (20%). O chef engole a formiga (nocaute na hora) e recupera vida.
## A bunda da tanajura fica (vai para a farofa!).


@export_range(0.0, 1.0, 0.01) var hp_threshold: float = 0.2
## Vida recuperada (em meias caveiras).
@export var heal_amount: int = 4
@export var approach_offset: Vector2 = Vector2(-26, 0)


func _why_not(_user: ChefBattler, target: FormigaBattler) -> String:
	if target.health.get_ratio() >= hp_threshold:
		return "só com a formiga abaixo de %d%% de vida" % roundi(hp_threshold * 100.0)
	return ""


func _execute(battle: TurnBattle, user: ChefBattler, target: FormigaBattler) -> void:
	user.face(target.global_position)
	await user.move_to(target.global_position + approach_offset, 0.25)
	battle.announce("NHAC!", Color(1.0, 0.85, 0.4))

	# A formiga é sugada para a boca do chef, girando e encolhendo.
	target.devoured = true
	if target.hp_bar:
		target.hp_bar.set_bar_visible(false)
	var mouth: Vector2 = user.global_position + Vector2(6, -14)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(target, "global_position", mouth, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	if target.sprite:
		tween.tween_property(target.sprite, "scale", Vector2.ZERO, 0.3)
		tween.tween_property(target.sprite, "rotation", TAU, 0.3)
	await tween.finished

	for i in 2:
		await user.squash(Vector2(1.3, 0.7), 0.15)
	target.health.invulnerable = false
	target.health.kill()
	user.heal(heal_amount)
	await user.return_home(0.3)
