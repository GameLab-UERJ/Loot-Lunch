extends Node
class_name MvpBossFlow
## FLUXO do MVP na BOSS FIGHT do Cliente VIP. O MvpFlow pendura este nó como filho do
## BossFightVip e ele:
##
##   - liga `offer_quit_on_fail`: perdeu em qualquer etapa -> "Tentar de novo" (repete a
##     etapa) ou "Sair para o menu" (volta ao menu; Jogar começa da Fase 1 de novo)
##   - venceu (matou a Rainha, entregou o prato e viu a reação do VIP) -> tela de
##     agradecimento


## Tema dos botões do painel de falha (o mesmo do menu principal).
@export var button_theme: Theme


var boss: BossFightVip = null


func _ready() -> void:
	boss = get_parent() as BossFightVip
	if boss == null:
		push_warning("MvpBossFlow: o pai não é um BossFightVip; fluxo desligado.")
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Este _ready roda antes do `run()` do boss (que é call_deferred): dá tempo de ligar.
	boss.offer_quit_on_fail = true
	if boss.banner and button_theme:
		boss.banner.button_theme = button_theme
	boss.boss_fight_finished.connect(_on_boss_fight_finished)


func _on_boss_fight_finished(success: bool, _results: Array) -> void:
	if success:
		MvpFlow.go_to_thanks(get_tree())
	else:
		MvpFlow.go_to_main_menu(get_tree())
