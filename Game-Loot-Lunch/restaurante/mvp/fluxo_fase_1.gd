extends Node
class_name MvpLevelFlow
## FLUXO do MVP na FASE do restaurante (lvl_1). O MvpFlow pendura este nó como filho
## da raiz da fase (RestaurantLevel) e ele decide o que vem depois do turno:
##
##   Tempo acabou (bateu a meta OU NÃO)  ->  painel "Continuar"  ->  Boss do Cliente VIP
##   Chef caiu                          ->  "Tentar de novo" (fase do zero) / "Sair" (menu)
##
## A fase continua sem saber do MVP: este nó só escuta `level_finished`, esconde a tela
## de fim do HUD da fase e mostra um MinigameBanner com botões no lugar dela.


@export_group("Textos")
@export var time_up_title: String = "Fim do turno!"
@export var goal_done_title: String = "Meta batida!"
@export_multiline var boss_teaser: String = "Um cliente muito especial acabou de chegar...\nO Coronel Ossvaldo quer falar com o chef!"
@export var continue_text: String = "Continuar"
@export var death_title: String = "O chef caiu!"
@export var retry_text: String = "Tentar de novo"
@export var quit_text: String = "Sair para o menu"

@export_group("Visual")
## Tema dos botões (o mesmo do menu principal).
@export var button_theme: Theme
## Espera antes do painel (os clientes terminam de sair e a fase pausa).
@export var panel_delay: float = 1.0


var level: RestaurantLevel = null
var _banner: MinigameBanner = null


func _ready() -> void:
	level = get_parent() as RestaurantLevel
	if level == null:
		push_warning("MvpLevelFlow: o pai não é uma RestaurantLevel; fluxo desligado.")
		return
	# Roda pausado: a fase pausa a árvore no fim do turno e o painel precisa responder.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_banner = MinigameBanner.new()
	_banner.button_theme = button_theme
	add_child(_banner)
	level.level_finished.connect(_on_level_finished)


func _on_level_finished(success: bool) -> void:
	var died: bool = level.chef != null and level.chef.is_dead()
	var stats: String = ""
	if level.hud:
		stats = level.hud.end_stats.text  # mesmo resumo que o HUD da fase montou
		level.hud.end_screen.hide()  # o botão "Jogar de novo" do HUD não vale no MVP
	await get_tree().create_timer(panel_delay, true).timeout

	if died:
		# O resumo do HUD começa com o motivo ("O chef caiu!"), que já é o título.
		var lines: PackedStringArray = stats.split("\n")
		if not lines.is_empty() and lines[0] == death_title:
			lines.remove_at(0)
		var choice: int = await _banner.choose(death_title, "\n".join(lines),
			PackedStringArray([retry_text, quit_text]), Color(1.0, 0.45, 0.45))
		if choice == 0:
			MvpFlow.play_level_1(get_tree())
		else:
			MvpFlow.go_to_main_menu(get_tree())
		return

	# Tempo acabou: segue para o boss mesmo sem bater a meta.
	var title: String = goal_done_title if success else time_up_title
	var color: Color = Color(0.55, 1.0, 0.55) if success else Color(1.0, 0.85, 0.45)
	await _banner.choose(title, "%s\n\n%s" % [stats, boss_teaser],
		PackedStringArray([continue_text]), color)
	MvpFlow.play_boss_fight(get_tree())
