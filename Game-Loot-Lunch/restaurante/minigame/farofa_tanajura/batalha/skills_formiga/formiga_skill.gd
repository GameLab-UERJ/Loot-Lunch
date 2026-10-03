extends Node
class_name FormigaSkill
## BASE de todo ATAQUE DA FORMIGA. Cada ataque é também um QTE de DEFESA do chef:
## a habilidade anima a formiga, arma o QteTrack da batalha e decide o que acontece
## se o jogador acertou ou errou o tempo.
##
## Quem herda sobrescreve `_execute(battle, ant, chef)` (pode usar `await`).
## Escolha por sorteio no FormigaBattler (`weight`). Novo ataque = novo nó filho da formiga.
##
## CONTRA-ATAQUE: acertou o QTE, o chef toca `counter_animation` (arte da pasta
## fx/player/contra), a formiga leva `counter_damage` e fica ATORDOADA `counter_daze`
## segundos (a espera dela para de encher e aparecem as estrelinhas).


@export var display_name: String = "Ataque"
## Chance relativa de ser sorteado.
@export_range(0.0, 10.0, 0.1) var weight: float = 1.0
## Dano no chef se ele NÃO se defender (em meias caveiras).
@export_range(0, 10) var damage: int = 2
@export var enabled: bool = true
## Depois de usada, fica de fora por tantos turnos DESTA formiga (0 = sem recarga).
@export_range(0, 10) var cooldown_turns: int = 0
## PRIORIDADE MÁXIMA: com `has_priority` verdadeiro, sai NA HORA, sem esperar a barra de
## espera da formiga encher (as outras formigas e o chef esperam).
@export var interrupts: bool = false

@export_group("Contra-ataque")
@export var counter_animation: StringName = &""
## Quadro do golpe na animação de contra-ataque (0 = primeiro).
@export var counter_hit_frame: int = 4
@export var counter_damage: int = 3
## Segundos atordoada depois de levar o contra-ataque.
@export_range(0.0, 10.0, 0.1, "suffix:s") var counter_daze: float = 2.0
## Estrela do acerto (fx_impacto.tres).
@export var impact: SheetAnimation


## Turno (da formiga) em que foi usada pela última vez.
var last_used_turn: int = -100


static func find_all_in(node: Node) -> Array[FormigaSkill]:
	var found: Array[FormigaSkill] = []
	if node == null:
		return found
	for child in node.get_children():
		if child is FormigaSkill:
			found.append(child)
	return found


## Pode ser sorteada agora? (ex.: Arremesso só com formigas no campo). Sobrescreva.
func can_use(_battle: TurnBattle, _ant: FormigaBattler) -> bool:
	return true


## Tem que sair AGORA, sem sorteio? (ex.: Devorar e Conjurar com a vida baixa). Sobrescreva.
func has_priority(_battle: TurnBattle, _ant: FormigaBattler) -> bool:
	return false


func is_cooling_down(ant: FormigaBattler) -> bool:
	return cooldown_turns > 0 and ant.turns_taken - last_used_turn <= cooldown_turns


## Dano no chef JÁ com o bônus da batalha (formigas em fúria com a Rainha voando).
## Use sempre isto em vez de `chef.take_hit` direto.
func deal(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler, amount: int,
		from_direction: Vector2 = Vector2.ZERO) -> int:
	var total: int = amount * (battle.damage_multiplier(ant) if battle else 1)
	return chef.take_hit(total, from_direction)


func execute(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler) -> void:
	battle.announce("%s usou %s!" % [ant.display_name, display_name], Color(1.0, 0.7, 0.5))
	await _execute(battle, ant, chef)


## Contra-ataque do chef: animação + dano + estrela + atordoa. Uso: `await counter(...)`.
## `hit_offset` = onde a estrela aparece em relação à formiga (no quadro do golpe).
func counter(battle: TurnBattle, ant: FormigaBattler, chef: ChefBattler,
		hit_offset: Vector2 = Vector2(-30, 0), amount: int = -1) -> void:
	chef.face(ant.global_position)
	await chef.act(counter_animation, counter_hit_frame)
	var dealt: int = counter_damage if amount < 0 else amount
	if not ant.is_dead():
		ant.take_hit(dealt, ant.global_position - chef.global_position)
		ant.daze(counter_daze)
	battle.fx(impact, ant.global_position + hit_offset)
	battle.shake(3.0, 0.2)


func _execute(_battle: TurnBattle, _ant: FormigaBattler, _chef: ChefBattler) -> void:
	pass
