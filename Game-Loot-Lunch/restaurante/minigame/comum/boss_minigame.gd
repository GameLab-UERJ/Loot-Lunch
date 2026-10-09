extends Node2D
class_name BossMinigame
## BASE de toda ETAPA da boss fight do Cliente VIP (carne de sol, macaxeira, farofa...).
##
## Cuida só do que é comum:
##   - título + instruções (o BossFightVip mostra antes de começar)
##   - começar (`begin`) e terminar (`finish`) UMA vez, avisando por `finished`
##   - rodar SOZINHA para teste: abrindo a cena da etapa com F6 ela começa sozinha
##
## Quem herda sobrescreve `_on_begin()` e chama `finish(sucesso, resultado)` no fim.
## O gerenciador (BossFightVip) não sabe o que cada etapa faz: só instancia a cena,
## chama `begin()` e espera `finished`. Etapa nova = nova cena que herda daqui.


## A etapa acabou. `result` leva o que o VIP vai avaliar:
##   "quality" (0..1), "label" (ex.: "Carne de Sol Perfeita") e o que mais a etapa quiser.
signal finished(success: bool, result: Dictionary)


@export var title: String = "Etapa"
@export_multiline var instructions: String = ""
## Rodando a cena sozinha (F6), mostra as instruções e começa ao confirmar.
@export var autostart_when_alone: bool = true
## O BossFightVip mostra o painel de título/instruções antes de começar. Desligue em
## cutscenes (a cena entra direto).
@export var show_intro_banner: bool = true
## Quadro de TUTORIAL desenhado (TutorialBoard). Com ele, a primeira vez da etapa mostra
## o quadro no lugar do painel de instruções (nas tentativas seguintes volta o painel).
@export var tutorial: PackedScene


var running: bool = false
var _done: bool = false


func _ready() -> void:
	DayNightSwitch.disable(self)  # minigame é interno: sem o efeito de dia e noite
	if autostart_when_alone and get_tree().current_scene == self:
		_autostart.call_deferred()


func _autostart() -> void:
	var banner := MinigameBanner.new()
	add_child(banner)
	if tutorial:
		await TutorialBoard.play(self, tutorial)
	elif show_intro_banner:
		await banner.show_intro(title, instructions)
	finished.connect(func(success: bool, result: Dictionary) -> void:
		banner.show_result(success, "%s\n\n[R] reinicia a cena" % String(result.get("label", ""))))
	begin()


func _unhandled_input(event: InputEvent) -> void:
	# Só no teste isolado: R reinicia a cena depois do fim.
	if _done and get_tree().current_scene == self and event is InputEventKey \
			and event.pressed and not event.echo and event.keycode == KEY_R:
		get_tree().reload_current_scene()


func begin() -> void:
	if running or _done:
		return
	running = true
	_on_begin()


## Chame UMA vez quando a etapa terminar (as próximas chamadas são ignoradas).
func finish(success: bool, result: Dictionary = {}) -> void:
	if _done:
		return
	_done = true
	running = false
	_on_finish(success)
	finished.emit(success, result)


func is_done() -> bool:
	return _done


# --- Para sobrescrever -------------------------------------------------------

func _on_begin() -> void:
	pass


## Último momento antes de avisar o fim (parar timers, esconder mira...).
func _on_finish(_success: bool) -> void:
	pass


# --- Ajudantes ---------------------------------------------------------------

## Texto que sobe e some (reaproveita o FloatingText do restaurante).
func popup(at: Vector2, message: String, color: Color = Color.WHITE) -> void:
	FloatingText.spawn(self, at, message, color)


## Espera `seconds` segundos (respeita pausa). Uso: `await wait(0.5)`.
func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds, false).timeout


## Converte a qualidade (0..1) em estrelas (1..3) para o placar do VIP.
static func stars_for(quality: float) -> int:
	if quality >= 0.8:
		return 3
	if quality >= 0.45:
		return 2
	return 1
