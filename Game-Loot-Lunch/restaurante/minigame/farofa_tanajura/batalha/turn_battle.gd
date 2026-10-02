extends Node
class_name TurnBattle
## BATALHA POR TURNOS estilo RPG clássico/Pokémon (Fase 3): o chef contra uma FILA de
## formigas, UMA por vez no ringue.
##
##   1. a próxima formiga da fila entra no `fight_slot`
##   2. TURNO DO CHEF: o BattleMenu mostra as 4 habilidades (teclas 1-4 ou clique)
##   3. TURNO DA FORMIGA: ela sorteia um ataque; cada ataque é um QTE de defesa
##   4. formiga nocauteada vai para o "cemitério" (`graveyard`) e entra a próxima
##
## `await battle.run()` devolve true (venceu todas) ou false (o chef caiu).
## As habilidades recebem a batalha para usar o QTE, o aviso na tela, o tremor e a arena.


signal ant_entered(ant: FormigaBattler)
signal ant_defeated(ant: FormigaBattler, index: int)
signal battle_finished(victory: bool)


@export var chef: ChefBattler
@export var menu: BattleMenu
@export var qte: QteTrack
@export var banner: MinigameBanner
## Onde as habilidades criam efeitos (pedras, ondas, buracos, sombra...).
@export var arena: Node2D
## Nó que treme nos impactos (normalmente a raiz da etapa).
@export var shake_target: Node2D
@export var fight_slot: Marker2D
## Fileira onde os corpos das formigas ficam (os drops saem daqui no fim).
@export var graveyard: Marker2D
@export var graveyard_spacing: float = 44.0
## Respiro entre um turno e outro.
@export var turn_pause: float = 0.35


var ants: Array[FormigaBattler] = []
var defeated: Array[FormigaBattler] = []
## Estatística de QTEs (o VIP avalia a elegância da luta).
var qte_successes: int = 0
var qte_total: int = 0
var _shake_tween: Tween
var _shake_origin: Vector2


func setup(queue: Array[FormigaBattler]) -> void:
	ants = queue.duplicate()
	defeated.clear()
	for i in ants.size():
		ants[i].level = i
		ants[i].display_name = "Tanajura %d/%d" % [i + 1, ants.size()]
	if shake_target:
		_shake_origin = shake_target.position


func run() -> bool:
	while not ants.is_empty():
		var ant: FormigaBattler = ants[0]
		await _bring_in(ant)
		while not ant.is_dead() and not chef.is_dead():
			# --- Turno do chef ---
			announce("Sua vez!", Color(0.95, 0.85, 0.5))
			var skill: BattleSkill = await menu.choose(chef, ant)
			if skill:
				await skill.execute(self, chef, ant)
			if ant.is_dead() or chef.is_dead():
				break
			await wait(turn_pause)
			# --- Turno da formiga ---
			var attack: FormigaSkill = ant.choose_skill()
			if attack:
				await attack.execute(self, ant, chef)
			await wait(turn_pause)
		if chef.is_dead():
			announce("O chef desmaiou...", Color(1.0, 0.4, 0.4))
			battle_finished.emit(false)
			return false
		await _defeat(ant)
		ants.pop_front()
	battle_finished.emit(true)
	return true


# --- Ferramentas para as habilidades -------------------------------------------

## Aviso curto no alto da tela.
func announce(text: String, color: Color = Color.WHITE) -> void:
	if banner:
		banner.toast(text, color)


## Conta um QTE de defesa (para a nota final).
func register_qte(success: bool) -> void:
	qte_total += 1
	if success:
		qte_successes += 1


func get_qte_ratio() -> float:
	return float(qte_successes) / float(qte_total) if qte_total > 0 else 1.0


func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


## Tremor de tela (impacto de terremoto, trombada...).
func shake(strength: float = 3.0, duration: float = 0.25) -> void:
	if shake_target == null:
		return
	if _shake_tween:
		_shake_tween.kill()
	_shake_tween = create_tween()
	var steps: int = maxi(int(duration / 0.04), 2)
	for i in steps:
		var falloff: float = 1.0 - float(i) / steps
		var offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength * falloff
		_shake_tween.tween_property(shake_target, "position", _shake_origin + offset, 0.04)
	_shake_tween.tween_property(shake_target, "position", _shake_origin, 0.04)


func add_effect(node: Node) -> void:
	(arena if arena else shake_target).add_child(node)


# --- Fluxo -----------------------------------------------------------------------

func _bring_in(ant: FormigaBattler) -> void:
	ant.home_position = fight_slot.global_position
	await ant.move_to(fight_slot.global_position, 0.6)
	ant.face(chef.global_position, ant.art_faces_left)
	if ant.hp_bar:
		ant.hp_bar.set_bar_visible(true)
	announce("%s entrou na luta!" % ant.display_name, Color(1.0, 0.7, 0.5))
	ant_entered.emit(ant)
	await wait(0.4)


func _defeat(ant: FormigaBattler) -> void:
	var index: int = defeated.size()
	defeated.append(ant)
	var spot: Vector2 = graveyard.global_position + Vector2(graveyard_spacing * index, 0)
	if ant.devoured:
		# Foi para a barriga do chef: só a bunda sobra, no cemitério.
		ant.global_position = spot
		ant.visible = false
	else:
		announce("%s nocauteada!" % ant.display_name, Color(0.55, 1.0, 0.55))
		await ant.play_death()
		var tween := create_tween().set_parallel(true)
		tween.tween_property(ant, "global_position", spot, 0.45).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(ant, "scale", Vector2(0.7, 0.7), 0.45)
		await tween.finished
	ant_defeated.emit(ant, index)
