extends BossMinigame
class_name FarofaTanajuraMinigame
## FASE 3 da boss fight do VIP: A FAROFA DE TANAJURA ("Ritual Terrestre / Batalha").
##
##   1. O CLIENTE VIP (`summoner`) invoca `ant_count` (2) tanajuras pequenas, que saem do
##      chão nas vagas da formação, e chama a TANAJURA RAINHA (`boss_scene`, chefe com
##      asas), que desce do céu.
##   2. BATALHA EM TEMPO ATIVO (TurnBattle): todas ao mesmo tempo, cada uma com o seu
##      TEMPO DE ESPERA (as pequenas são mais rápidas que a Rainha).
##        Chef: 1 Frigideirada | 2 Investida Sombria | 3 Besta | 4 Devorar (<20%)
##        Pequenas: Investida | Terremoto | Lançar Pedra | Cavar (meia caveira por acerto)
##        Rainha: Cortes de Vento | Arremesso | Voar | Ultra Arremesso | Devorar e Conjurar
##   3. A Rainha caiu: as pequenas fogem, os drops (bundas) vão para a tábua e o chef
##      prepara a farofa (FarofaCutscene).
##
## Nota: metade vem da vida que sobrou, metade dos QTEs de defesa acertados.


@export var ant_scene: PackedScene
## Formigas pequenas no começo (no máximo o número de vagas da formação).
@export_range(0, 4) var ant_count: int = 2
## A TANAJURA RAINHA (chefe). Vazio = luta só com as pequenas.
@export var boss_scene: PackedScene
@export var boss_slot: Marker2D
@export var battle: TurnBattle
@export var chef: ChefBattler
## Quem INVOCA as formigas: o CLIENTE VIP (fica no alto da arena assistindo a luta).
@export var summoner: Node2D
## Fala do VIP antes de invocar.
@export var summon_line: String = "Quero tanajura FRESCA! Formigas, apareçam!"
@export var queen_line: String = "Majestade, venha!"
## Magia na mão do VIP e a terra explodindo onde cada formiga sai do chão.
@export var summon_fx: SheetAnimation
@export var erupt_fx: SheetAnimation
@export var rise_depth: float = 80.0
## Vagas das formigas pequenas (filhos Marker2D, na ordem em que são preenchidas).
@export var formation: Node2D

@export_group("Formigas rápidas")
## Quantas formigas pequenas (sorteadas) têm a espera menor. Não aparece na tela.
@export_range(0, 10) var fast_ant_count: int = 0
## Tempo de espera das rápidas (as normais usam o do formiga.tscn).
@export_range(0.5, 30.0, 0.1, "suffix:s") var fast_wait_time: float = 4.0

@export var cutscene: FarofaCutscene
@export var battle_layer: Node2D
## Quantos drops vão para a farofa no máximo (a animação fica curta).
@export_range(1, 10) var max_farofa_drops: int = 5

@export_group("Áudio")
@export var battle_bgm: AudioStream = preload("res://assets/music/montogoronto-ominousdark-medievalfantasy-song-309510.mp3")
@export var sfx_summon_cast: AudioStream = preload("res://assets/sfx/restaurante/minigames/batalha/fireball_cast.wav")
@export var sfx_ant_erupt: AudioStream = preload("res://assets/sfx/restaurante/minigames/batalha/earth_burst.wav")
@export var sfx_ant_dig: AudioStream = preload("res://assets/sfx/restaurante/minigames/batalha/ant_dig.wav")
@export var sfx_queen_roar: AudioStream = preload("res://assets/sfx/restaurante/minigames/batalha/queen_summon_roar.wav")
@export var sfx_queen_wings: AudioStream = preload("res://assets/sfx/restaurante/minigames/batalha/queen_wings.wav")
@export var sfx_queen_land: AudioStream = preload("res://assets/sfx/restaurante/minigames/batalha/rock_impact.wav")

var _bgm_player: AudioStreamPlayer = null


func _play_sfx(stream: AudioStream, volume_db: float = -3.0, pitch: float = 1.0) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.bus = &"SFX"
	p.volume_db = volume_db
	p.pitch_scale = pitch
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _on_begin() -> void:
	_setup_bgm()
	if _bgm_player and not _bgm_player.playing:
		_bgm_player.play()
	var ants: Array[FormigaBattler] = await _summon_ants()
	_pick_fast_ants(ants)
	var boss: FormigaBattler = await _summon_boss()
	if boss:
		ants.append(boss)
	battle.setup(ants)
	var victory: bool = await battle.run()
	if _bgm_player and _bgm_player.playing:
		var fade := create_tween()
		fade.tween_property(_bgm_player, "volume_db", -40.0, 0.6)
		fade.tween_callback(_bgm_player.stop)
	if not victory:
		finish(false, {"label": "O chef desmaiou na luta contra as tanajuras", "quality": 0.0})
		return

	await wait(0.5)
	var loot: Array[Dictionary] = await _award_boss_loot(boss)
	var spots: Array[Vector2] = []
	if boss and boss.drop:
		spots.append(boss.drop.global_position)
		boss.hide_drop()
	for drop in battle.drops:
		if spots.size() >= max_farofa_drops:
			break
		if is_instance_valid(drop):
			spots.append(drop.global_position)
			drop.hide()
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
		"loot": loot,  # itens ganhos (ainda só registro: o item não existe no jogo)
	})


## A Rainha caiu: o item dela (Asa de Formiga Rainha) voa até o chef + aviso.
## TODO: quando o item existir, entregá-lo ao inventário aqui (ou a partir de "loot").
func _award_boss_loot(boss: FormigaBattler) -> Array[Dictionary]:
	var loot: Array[Dictionary] = []
	var queen := boss as QueenAntBattler
	if queen == null or queen.loot_name == "":
		return loot
	loot.append(queen.get_loot())
	if battle:
		battle.announce("Você ganhou: %s!" % queen.loot_name, Color(1.0, 0.85, 0.35))
	await LootPopup.play(self, queen.get_loot_icon(), queen.global_position + Vector2(40, -50),
		chef.global_position + Vector2(0, -20), queen.loot_name, 1.5)
	return loot


func _on_finish(_success: bool) -> void:
	if battle:
		battle.stop()
	if _bgm_player and _bgm_player.playing:
		_bgm_player.stop()


func _setup_bgm() -> void:
	if battle_bgm and _bgm_player == null:
		_bgm_player = AudioStreamPlayer.new()
		_bgm_player.name = "BattleBgmPlayer"
		_bgm_player.stream = battle_bgm
		_bgm_player.bus = &"Music"
		_bgm_player.volume_db = -4.0
		add_child(_bgm_player)


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
	var count: int = mini(ant_count, slots.size()) if not slots.is_empty() else ant_count
	await _summoner_cast(summon_line)
	for i in count:
		var to: Vector2 = slots[i] if i < slots.size() else Vector2(400, 140 + 70 * i)
		var ant := ant_scene.instantiate() as FormigaBattler
		ant.slot_index = i
		battle_layer.add_child(ant)
		ant.global_position = to
		ant.home_position = to
		ant.face(chef.global_position, ant.art_faces_left)
		_play_sfx(sfx_ant_erupt, -3.5, randf_range(0.9, 1.1))
		_play_sfx(sfx_ant_dig, -5.5, randf_range(0.95, 1.05))
		if erupt_fx:
			SheetAnimation.spawn_once(erupt_fx, battle_layer, ant.feet_position())
		ant.rise_from_ground(rise_depth, 0.45)
		ants.append(ant)
		await wait(0.3)
	await wait(0.5)
	return ants


## O VIP levanta a mão: fala, pulinho e a magia na mão dele.
func _summoner_cast(line: String) -> void:
	if summoner == null:
		return
	popup(summoner.global_position + Vector2(0, -44), line, Color(1.0, 0.85, 0.45))
	var base_y: float = summoner.position.y
	var hop := create_tween()
	hop.tween_property(summoner, "position:y", base_y - 10.0, 0.15).set_ease(Tween.EASE_OUT)
	hop.tween_property(summoner, "position:y", base_y, 0.15).set_ease(Tween.EASE_IN)
	_play_sfx(sfx_summon_cast, -5.0)
	if summon_fx:
		SheetAnimation.spawn_once(summon_fx, self, summoner.global_position + Vector2(0, -12))
	await hop.finished
	await wait(0.5)


## O VIP chama a Rainha: ela desce do céu batendo as asas até a vaga dela.
func _summon_boss() -> FormigaBattler:
	if boss_scene == null:
		return null
	await _summoner_cast(queen_line)
	var boss := boss_scene.instantiate() as FormigaBattler
	battle_layer.add_child(boss)
	var to: Vector2 = boss_slot.global_position if boss_slot else Vector2(520, 180)
	boss.global_position = to + Vector2(40, -320)
	boss.home_position = to
	popup(Vector2(320, 120), "A TANAJURA RAINHA CHEGOU!", Color(1.0, 0.5, 0.45))
	_play_sfx(sfx_queen_roar, -2.5)
	_play_sfx(sfx_queen_wings, -3.5)
	var tween := create_tween()
	tween.tween_property(boss, "global_position", to, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_play_sfx(sfx_queen_land, -2.0)
	battle.shake(6.0, 0.4)
	await boss.squash(Vector2(1.2, 0.8), 0.25)
	await wait(0.3)
	return boss
