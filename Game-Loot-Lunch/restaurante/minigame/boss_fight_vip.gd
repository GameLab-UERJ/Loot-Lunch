extends Node2D
class_name BossFightVip
## GERENCIADOR da BOSS FIGHT do CLIENTE VIP: roda as etapas em sequência e termina
## com a entrega do prato.
##
##   Intro   intro_vip/intro_vip.tscn (cutscene: o Coronel Ossvaldo chega e pede o prato)
##   Fase 1  carne_sol/carne_sol.tscn                     (Conjuração Solar)
##   Fase 2  macaxeira_manteiga/macaxeira_manteiga.tscn   (Alquimia de Cozimento)
##   Fase 3  farofa_tanajura/farofa_tanajura.tscn         (Ritual Terrestre / batalha)
##   Final   imagem do prato completo + final_vip/avaliacao_vip.tscn (cutscene: o VIP
##           prova o prato e reage conforme as estrelas — ruim / médio / bom / perfeito)
##
## Não sabe o que cada etapa faz: instancia a cena (BossMinigame), mostra título e
## instruções, chama `begin()` e espera `finished(sucesso, resultado)`. Falhou = tenta a
## mesma etapa de novo (`retry_on_fail`). Etapa nova = mais uma cena na lista `stages`.
##
## Para ligar no restaurante: instancie boss_fight_vip.tscn (ou troque de cena para ela)
## e escute `boss_fight_finished`.


signal stage_started(index: int, stage: BossMinigame)
signal stage_finished(index: int, success: bool, result: Dictionary)
## `results` = um Dictionary por etapa (label, quality, stars...).
signal boss_fight_finished(success: bool, results: Array)
## O jogador escolheu SAIR no painel de falha (`offer_quit_on_fail`). Logo depois vem
## `boss_fight_finished(false, ...)`.
signal quit_requested


## Cutscene de abertura (antes do painel de introdução). Não conta no placar.
@export var intro_stage: PackedScene
## As etapas em ordem (cenas cuja raiz herda BossMinigame).
@export var stages: Array[PackedScene] = []
## Etapa final (a cutscene da avaliação do VIP). Recebe as estrelas das etapas por
## `set_results(resultados)`, se tiver esse método.
@export var delivery_stage: PackedScene
## Imagem do prato montado, mostrada antes da entrega.
@export var final_dish_texture: Texture2D
## Onde as etapas são instanciadas.
@export var stage_holder: Node2D
@export var banner: MinigameBanner
## Falhou: repete a etapa. Desligado: a boss fight acaba na primeira falha.
@export var retry_on_fail: bool = true
## Falhou: em vez de só "tentar de novo", mostra os botões "Tentar de novo" e "Sair".
## Sair encerra a boss fight com falha (`quit_requested` + `boss_fight_finished(false)`).
## Quem liga: o fluxo do MVP (restaurante/mvp/fluxo_boss_vip.gd).
@export var offer_quit_on_fail: bool = false
@export var retry_option_text: String = "Tentar de novo"
@export var quit_option_text: String = "Sair para o menu"
## Começa sozinho ao entrar na árvore.
@export var autostart: bool = true

@export_group("Textos")
@export var intro_title: String = "BOSS: O CLIENTE VIP"
@export_multiline var intro_text: String = "O Coronel Ossvaldo quer provar as tanajuras da fazenda dele num prato digno do Ossos & Brasas: Carne de Sol, Macaxeira na Manteiga de Garrafa e Farofa de Tanajura.\n\nTrês etapas de pura magia culinária. Capricha: o paladar dele é exigente!"


var results: Array[Dictionary] = []
var attempts: int = 0
var _current: BossMinigame = null


func _ready() -> void:
	DayNightSwitch.disable(self)  # boss fight é interna: sem o efeito de dia e noite
	if autostart:
		run.call_deferred()


## Roda a boss fight inteira. Retorna true se o VIP recebeu o prato.
func run() -> bool:
	results.clear()
	attempts = 0
	if intro_stage:
		await _play_stage(-1, intro_stage)  # cutscene: não entra no placar
	await banner.ask(intro_title, intro_text, "[ESPAÇO] aceitar o desafio")

	for i in stages.size():
		var result: Dictionary = await _play_stage(i, stages[i])
		if result.is_empty():
			return _end(false)
		results.append(result)

	await banner.ask("PRATO COMPLETO!", _summary_text(), "[ESPAÇO] levar ao VIP", final_dish_texture)

	var delivery: Dictionary = {}
	if delivery_stage:
		delivery = await _play_stage(stages.size(), delivery_stage)
		if delivery.is_empty():
			return _end(false)

	# A cutscene diz como o VIP reagiu (título, frase e cor); sem ela, vitória simples.
	var final_title: String = String(delivery.get("title", "VITÓRIA!"))
	var final_label: String = String(delivery.get("label", "O Cliente VIP aprovou o prato!"))
	var final_color: Color = delivery.get("color", Color(0.55, 1.0, 0.55))
	await banner.ask(final_title, "%s\n\n%s" % [final_label, _summary_text()],
		"[ESPAÇO] continuar", final_dish_texture, final_color)
	return _end(true)


## Joga uma etapa até passar. Retorna o resultado (vazio = desistiu / sem retry).
func _play_stage(index: int, scene: PackedScene) -> Dictionary:
	while true:
		attempts += 1
		var stage := scene.instantiate() as BossMinigame
		if stage == null:
			push_error("BossFightVip: a etapa %d não herda BossMinigame." % index)
			return {}
		stage.autostart_when_alone = false
		stage_holder.add_child(stage)
		_current = stage
		if stage.tutorial and not TutorialBoard.was_seen(stage.tutorial):
			# Primeira vez da etapa: o quadro desenhado no lugar do texto.
			await TutorialBoard.play(self, stage.tutorial, true)
		elif stage.show_intro_banner:
			await banner.ask(stage.title, stage.instructions, "[ESPAÇO] começar")
		if stage.has_method("set_results"):
			stage.set_results(results)  # a avaliação do VIP precisa das estrelas
		stage_started.emit(index, stage)
		stage.begin()

		var outcome: Array = await stage.finished
		var success: bool = outcome[0]
		var result: Dictionary = outcome[1]
		stage_finished.emit(index, success, result)
		await get_tree().create_timer(1.0, false).timeout

		var label: String = String(result.get("label", ""))
		if success:
			if index >= 0 and index < stages.size():
				await banner.ask("SUCESSO!", "%s\n%s%s" % [label, _stars_text(result), _loot_text(result)],
					"[ESPAÇO] próxima etapa", null, Color(0.55, 1.0, 0.55))
			_free_stage(stage)
			return result

		_free_stage(stage)
		if offer_quit_on_fail:
			var choice: int = await banner.choose("FALHOU...",
				"%s\n\nO VIP está ficando impaciente..." % label,
				PackedStringArray([retry_option_text, quit_option_text]), Color(1.0, 0.45, 0.45))
			if choice == 0:
				continue
			quit_requested.emit()
			return {}
		if not retry_on_fail:
			await banner.ask("FALHOU...", label, "[ESPAÇO] continuar", null, Color(1.0, 0.45, 0.45))
			return {}
		await banner.ask("FALHOU...", "%s\n\nO VIP está ficando impaciente..." % label,
			"[ESPAÇO] tentar de novo", null, Color(1.0, 0.45, 0.45))
	return {}


func _free_stage(stage: BossMinigame) -> void:
	if _current == stage:
		_current = null
	stage.queue_free()


func _end(success: bool) -> bool:
	boss_fight_finished.emit(success, results)
	return success


func _stars_text(result: Dictionary) -> String:
	var stars: int = int(result.get("stars", 0))
	return "Nota: %d de 3 estrelas" % stars if stars > 0 else ""


## Itens ganhos na etapa ("loot": [{id, name}]). Ainda só aviso: os itens não existem.
## TODO: quando houver inventário, entregar aqui os itens de `result["loot"]`.
func _loot_text(result: Dictionary) -> String:
	var names := PackedStringArray()
	for item in result.get("loot", []):
		if item is Dictionary:
			names.append(String(item.get("name", "?")))
	return "" if names.is_empty() else "\nItem ganho: %s" % ", ".join(names)


func _summary_text() -> String:
	var lines := PackedStringArray()
	for result in results:
		lines.append("%s  —  %d/3" % [String(result.get("label", "?")), int(result.get("stars", 0))])
	return "\n".join(lines)
