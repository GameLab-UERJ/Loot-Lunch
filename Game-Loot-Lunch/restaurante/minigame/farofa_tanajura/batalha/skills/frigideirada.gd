extends BattleSkill
## 1. FRIGIDEIRADA: ataque físico básico. O chef corre até a formiga, toca a animação
## `frigideirada` (arte 48x48, acerto no quadro 4) e volta. De graça e ainda recupera
## mana (`mana_gain`).


@export var damage: int = 6
## Onde o chef para em relação à formiga (os pés dos dois na mesma linha).
@export var approach_offset: Vector2 = Vector2(-80, 24)
@export var attack_animation: StringName = &"frigideirada"
@export var hit_frame: int = 4
## Estrela do acerto (fx_impacto.tres).
@export var impact: SheetAnimation
## Cada frigideirada empurra a espera da formiga para trás (0.15 = perde 15%).
@export_range(0.0, 1.0, 0.05) var wait_knock_back: float = 0.15


func _execute(battle: TurnBattle, user: ChefBattler, target: FormigaBattler) -> void:
	user.face(target.global_position)
	await user.move_to(target.global_position + approach_offset, 0.22)
	user.face(target.global_position)
	var direction: Vector2 = target.global_position - user.global_position
	await user.act(attack_animation, hit_frame)
	target.take_hit(damage, direction)
	target.wait.knock_back(wait_knock_back)
	battle.fx(impact, target.global_position + Vector2(-34, 0))
	battle.shake(2.0, 0.15)
	await user.finish_action()
	await user.return_home(0.22)
	user.face(target.global_position)
