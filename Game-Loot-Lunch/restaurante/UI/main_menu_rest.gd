extends Control
## MENU PRINCIPAL do MVP do restaurante: Jogar, Créditos e Sair.
##
##   Jogar     -> Fase 1 (lvl_1) pelo MvpFlow (sempre do começo: o MVP não tem save)
##   Créditos  -> painel por cima do menu (restaurante/mvp/ui/creditos_mvp.tscn)
##   Sair      -> fecha o jogo
##
## A logo do GameLab só aparece na PRIMEIRA vez que o menu abre; voltando de uma fase
## o menu aparece direto.

## Som tocado quando o mouse passa por cima de um botão.
## [br]
## [b]Formato:[/b] Arraste um arquivo de áudio curto aqui.
## [b]Se vazio:[/b] Nenhum som toca ao passar o mouse.
@export var hover_sound: AudioStream

## Som tocado quando um botão é pressionado.
## [br]
## [b]Formato:[/b] Arraste um arquivo de áudio curto aqui.
## [b]Se vazio:[/b] O jogo fecha imediatamente após o clique.
@export var press_sound: AudioStream

@export var is_outdoor: bool = false


## A logo do GameLab já apareceu nesta sessão (vale entre trocas de cena).
static var _intro_played: bool = false

var is_quitting : bool = false
var animation_finished : bool = false

@onready var play_button: Button = $Content/Buttons/GridContainer3/NewGameButton
@onready var credits_button: Button = $Content/Buttons/GridContainer/CreditsButton
@onready var quit_button: Button = $Content/Buttons/GridContainer2/QuitButton
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var press_audio: AudioStreamPlayer = $PressAudio
@onready var content: HBoxContainer = $Content
@onready var credits_panel: MvpCredits = $CreditosMvp

@onready var background: TextureRect = $TextureRect2
@onready var game_title: TextureRect = $TextureRect

@onready var intro_layer: CanvasLayer = $IntroLayer
@onready var black_screen: ColorRect = $IntroLayer/BlackScreen
@onready var developer_logo: TextureRect = $IntroLayer/DeveloperLogo

@onready var menu_buttons: Array[Button] = [
	$Content/Buttons/GridContainer3/NewGameButton,
	$Content/Buttons/GridContainer/CreditsButton,
	$Content/Buttons/GridContainer2/QuitButton
]

var menu_ready: bool = false

func _ready() -> void:
	get_tree().paused = false
	EnvironmentManager.is_outdoor = is_outdoor
	hover_audio.stream = hover_sound
	press_audio.stream = press_sound
	credits_panel.hide()
	credits_panel.closed.connect(_return_from_menus)

	_setup_intro()

	await _play_intro()

	menu_ready = true


func _on_button_mouse_entered() -> void:
	if hover_audio.stream == null or is_quitting == true or not animation_finished:
		return

	hover_audio.play()


func _on_new_game_button_pressed() -> void:
	if not animation_finished:
		return
	_play_press_sound()
	MvpFlow.play_level_1(get_tree())


func _on_credits_button_pressed() -> void:
	if not animation_finished or is_quitting:
		return
	_on_mouse_pressed()
	content.visible = false
	credits_panel.open()


func _on_quit_button_pressed() -> void:
	if not animation_finished:
		return
	_play_press_sound_and_quit()


func _disable_buttons() -> void:
	play_button.disabled = true
	credits_button.disabled = true
	quit_button.disabled = true


func _on_mouse_pressed() -> void:
	if press_audio.stream == null:
		return

	press_audio.play()
	await press_audio.finished


func _play_press_sound() -> void:
	if is_quitting:
		return

	is_quitting = true
	_disable_buttons()

	# O jogo espera o som terminar para o clique não ser cortado pelo quit().
	if press_audio.stream != null:
		press_audio.play()
		await press_audio.finished


func _play_press_sound_and_quit() -> void:
	await _play_press_sound()
	get_tree().quit()


func _return_from_menus() -> void:
	content.visible = true
	credits_button.grab_focus()



#Todas as funções abaixo que usam tween foram feitas com ajuda de IA generativa.
func _setup_intro() -> void:

	game_title.scale = Vector2(1.0, 0.92)

	intro_layer.visible = true

	black_screen.modulate.a = 1.0
	developer_logo.modulate.a = 0.0

	game_title.modulate.a = 0.0

	for button in menu_buttons:
		button.modulate.a = 0.0

func _play_intro() -> void:
	# Voltando de uma fase: sem a logo do GameLab, o menu aparece direto.
	if _intro_played:
		await _show_main_menu()
		return
	_intro_played = true

	# ==========================================
	# LOGO DOS DESENVOLVEDORES - FADE IN
	# ==========================================

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		developer_logo,
		"modulate:a",
		1.0,
		1.0
	)

	await tween.finished


	# ==========================================
	# SEGURA A LOGO
	# ==========================================

	await get_tree().create_timer(1.2).timeout


	# ==========================================
	# LOGO DOS DESENVOLVEDORES - FADE OUT
	# ==========================================

	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		developer_logo,
		"modulate:a",
		0.0,
		1.0
	)

	await tween.finished


	# ==========================================
	# REVELA O MENU
	# ==========================================

	await _show_main_menu()

func _show_main_menu() -> void:
	# Remove a tela preta.
	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		black_screen,
		"modulate:a",
		0.0,
		0.8
	)

	await tween.finished

	intro_layer.visible = false

	# Agora começa a animação do menu.
	await _animate_menu()

func _animate_menu() -> void:
	var title_tween := create_tween()

	title_tween.set_parallel(true)
	title_tween.set_trans(Tween.TRANS_BACK)
	title_tween.set_ease(Tween.EASE_OUT)

	title_tween.tween_property(
		game_title,
		"modulate:a",
		1.0,
		0.8
	)

	title_tween.tween_property(
		game_title,
		"scale",
		Vector2.ONE,
		0.8
	)

	await title_tween.finished

	await get_tree().create_timer(0.15).timeout

	await _animate_buttons()


func _animate_buttons() -> void:
	for button in menu_buttons:
		var tween := create_tween()

		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)

		tween.tween_property(
			button,
			"modulate:a",
			1.0,
			0.35
		)

		await tween.finished
		await get_tree().create_timer(0.08).timeout
	animation_finished = true
	for button in menu_buttons:
		button.mouse_filter = Control.MOUSE_FILTER_STOP
	play_button.grab_focus()
