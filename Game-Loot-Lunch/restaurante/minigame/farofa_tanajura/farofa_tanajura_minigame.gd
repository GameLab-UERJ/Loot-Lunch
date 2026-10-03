extends BossMinigame
class_name FarofaTanajuraMinigame
## FASE 3 da boss fight do VIP: A FAROFA DE TANAJURA ("Ritual Terrestre / Batalha").
##
##   1. O chef pede para a CHURRASQUEIRA trazer as formigas do cativeiro: ela ri e
##      cospe `ant_count` tanajuras direto para a FORMAÇÃO (as vagas em `formation`).
##   2. BATALHA EM TEMPO ATIVO (TurnBattle): as 5 lutam AO MESMO TEMPO, cada uma com
##      o seu TEMPO DE ESPERA. `fast_ant_count` delas (sorteadas) esperam bem menos —
##      e nada na tela mostra quais são.
##        Chef: 1 Frigideirada | 2 Investida Sombria | 3 Besta | 4 Devorar (<20%)
##        Formiga: Investida | Terremoto | Lançar Pedra | Cavar — cada um com seu QTE
##   3. Vencidas as 5: os drops (bundas de tanajura) vão para a tábua e o chef prepara
##      a farofa (FarofaCutscene).
##
## Nota: metade vem da vida que sobrou, metade dos QTEs de defesa acertados.


@export var ant_scene: PackedScene
@export_range(1, 10) var ant_count: int = 5
@export var battle: TurnBattle
@export var chef: ChefBattler
## A churrasqueira (SheetSprite com "ociosa" e "risada").
@export var grill: SheetSprite
## De onde as formigas saem (a boca da churrasqueira).
@export var grill_mouth: Marker2D
## Vagas das formigas (filhos Marker2D, na ordem em que são preenchidas).
@export var formation: Node2D

@export_group("Formigas rápidas")
## Quantas formigas (sorteadas) têm a espera menor. Não aparece na tela.
@export_range(0, 10) var fast_ant_count: int = 2
## Tempo de espera das rápidas (as normais usam o do formiga.tscn).
@export_range(0.5, 30.0, 0.1, "suffix:s") var fast_wait_time: float = 4.0

@export var cutscene: FarofaCutscene
@export var battle_layer: Node2D


func _on_begin() -> void:
	var ants: Array[FormigaBattler] = await _summon_ants()
	_pick_fast_ants(ants)
	battle.setup(ants)
	var victory: bool = await battle.run()
	if not victory:
		finish(false, {"label": "O chef desmaiou na luta contra as tanajuras", "quality": 0.0})
		return

	await wait(0.5)
	var spots: Array[Vector2] = []
	for ant in battle.defeated:
		spots.append(ant.global_position + (ant.drop.position if ant.drop else Vector2.ZERO))
		ant.hide_drop()
	await chef.return_home(0.3)
	await cutscene.play(chef, spots)

	var hp_ratio: float = float(chef.hp) / float(maxi(chef.max_hp, 1))
	var quality: float = clampf(0.5 * hp_ratio + 0.5 * battle.get_qte_ratio(), 0.1, 1.0)
	finish(true, {
		"label": "Farofa de Tanajura",
		"quality": quality,
		"stars": BossMinigame.stars_for(quality),
		"hp_left": chef.hp,
		"qte": "%d/%d" % [battle.qte_successes, battle.qte_total],
	})


func _on_finish(_success: bool) -> void:
	if battle:
		battle.stop()


## Sorteia quais formigas são as rápidas (só muda o tempo de espera).
func _pick_fast_ants(ants: Array[FormigaBattler]) -> void:
	var order: Array[FormigaBattler] = ants.duplicate()
	order.shuffle()
	for i in mini(fast_ant_count, order.size()):
		var wait_component: BattleWaitComponent = order[i].wait
		if wait_component:
			wait_component.wait_time = fast_wait_time
			wait_component.reset()


func _slots() -> Array[Vector2]:
	var slots: Array[Vector2] = []
	if formation:
		for child in formation.get_children():
			if child is Node2D:
				slots.append((child as Node2D).global_position)
	return slots


func _summon_ants() -> Array[FormigaBattler]:
	var ants: Array[FormigaBattler] = []
	var slots: Array[Vector2] = _slots()
	popup(chef.global_position + Vector2(0, -50), "Churrasqueira! Traz as formigas!", Color(1.0, 0.9, 0.6))
	await wait(0.8)
	if grill:
		grill.play_sheet(&"risada", true)
	await wait(0.3)
	for i in ant_count:
		var ant := ant_scene.instantiate() as FormigaBattler
		battle_layer.add_child(ant)
		var from: Vector2 = grill_mouth.global_position
		var to: Vector2 = slots[i % slots.size()] if not slots.is_empty() else from + Vector2(120 + 40 * i, 80)
		ant.global_position = from
		ant.home_position = to
		var tween := create_tween().set_parallel(true)
		tween.tween_method(_spit_arc.bind(ant, from, to), 0.0, 1.0, 0.5)
		tween.tween_property(ant, "rotation", TAU, 0.5)
		popup(from + Vector2(0, -10), "Ptuh!", Color(1.0, 0.7, 0.4))
		ants.append(ant)
		await wait(0.18)
	await wait(0.55)
	if grill:
		grill.play_sheet(&"ociosa")
	return ants


func _spit_arc(t: float, ant, from: Vector2, to: Vector2) -> void:
	if is_instance_valid(ant):
		ant.global_position = from.lerp(to, t) + Vector2(0.0, -60.0 * sin(PI * t))
