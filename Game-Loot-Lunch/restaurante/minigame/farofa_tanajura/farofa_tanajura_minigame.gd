extends BossMinigame
class_name FarofaTanajuraMinigame
## FASE 3 da boss fight do VIP: A FAROFA DE TANAJURA ("Ritual Terrestre / Batalha RPG").
##
##   1. O chef pede para a CHURRASQUEIRA trazer as formigas do cativeiro: ela ri e
##      cospe `ant_count` tanajuras, que ficam na fila.
##   2. BATALHA POR TURNOS (TurnBattle): uma formiga por vez.
##        Chef: 1 Frigideirada | 2 Investida Sombria | 3 Bolo de Fogo | 4 Devorar (<20%)
##        Formiga: Investida | Terremoto | Lançar Pedra | Cavar — cada um com seu QTE
##   3. Vencidas as 5: surgem 5 drops de bunda de tanajura e o chef prepara a farofa
##      (FarofaCutscene).
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
## Primeira vaga da fila e o passo entre as vagas.
@export var queue_start: Marker2D
@export var queue_spacing: Vector2 = Vector2(36, 0)
@export var cutscene: FarofaCutscene
@export var battle_layer: Node2D


func _on_begin() -> void:
	var ants: Array[FormigaBattler] = await _summon_ants()
	battle.setup(ants)
	var victory: bool = await battle.run()
	if not victory:
		finish(false, {"label": "O chef desmaiou na luta contra as tanajuras", "quality": 0.0})
		return

	await wait(0.5)
	var spots: Array[Vector2] = []
	for ant in battle.defeated:
		spots.append(ant.global_position)
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


func _summon_ants() -> Array[FormigaBattler]:
	var ants: Array[FormigaBattler] = []
	popup(chef.global_position + Vector2(0, -40), "Churrasqueira! Traz as formigas!", Color(1.0, 0.9, 0.6))
	await wait(1.0)
	if grill:
		grill.play_sheet(&"risada", true)
	await wait(0.4)
	for i in ant_count:
		var ant := ant_scene.instantiate() as FormigaBattler
		battle_layer.add_child(ant)
		var from: Vector2 = grill_mouth.global_position
		var to: Vector2 = queue_start.global_position + queue_spacing * i
		ant.global_position = from
		ant.home_position = to
		var tween := create_tween().set_parallel(true)
		tween.tween_method(_spit_arc.bind(ant, from, to), 0.0, 1.0, 0.55)
		tween.tween_property(ant, "rotation", TAU, 0.55)
		popup(from + Vector2(0, -10), "Ptuh!", Color(1.0, 0.7, 0.4))
		ants.append(ant)
		await wait(0.3)
	await wait(0.6)
	if grill:
		grill.play_sheet(&"ociosa")
	return ants


func _spit_arc(t: float, ant, from: Vector2, to: Vector2) -> void:
	if is_instance_valid(ant):
		ant.global_position = from.lerp(to, t) + Vector2(0.0, -60.0 * sin(PI * t))
