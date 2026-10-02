extends BattleSkill
## 1. FRIGIDEIRADA: ataque físico básico. O chef corre até a formiga, desce a
## frigideira e volta. De graça e ainda recupera mana (`mana_gain`).


@export var damage: int = 6
## Onde o chef para em relação à formiga.
@export var approach_offset: Vector2 = Vector2(-34, 0)


func _execute(battle: TurnBattle, user: ChefBattler, target: FormigaBattler) -> void:
	user.face(target.global_position)
	await user.move_to(target.global_position + approach_offset, 0.25)
	var direction: Vector2 = target.global_position - user.global_position
	user.swing_pan(direction)
	await battle.wait(0.08)
	target.take_hit(damage, direction)
	battle.shake(2.0, 0.15)
	await battle.wait(0.2)
	await user.return_home(0.25)
	user.face(target.global_position)
