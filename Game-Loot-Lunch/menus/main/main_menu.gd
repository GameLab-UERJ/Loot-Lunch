extends Control

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


const settings_scene = preload("res://menus/settings/settings_menu.tscn")

var is_quitting: bool = false

var save_load_menu: SaveLoadMenu
var save_load_scene: PackedScene = preload("res://menus/saver_loader/save_load_menu.tscn")

@onready var new_game_button: Button = $Content/Buttons/GridContainer3/NewGameButton
@onready var continue_button: Button = $Content/Buttons/GridContainer/ContinueButton
@onready var settings_button: Button = $Content/Buttons/GridContainer/SettingsButton
@onready var quit_button: Button = $Content/Buttons/GridContainer2/QuitButton
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var press_audio: AudioStreamPlayer = $PressAudio
@onready var content: HBoxContainer = $Content

@onready var background: TextureRect = $TextureRect2
@onready var game_title: TextureRect = $TextureRect

@onready var intro_layer: CanvasLayer = $IntroLayer
@onready var black_screen: ColorRect = $IntroLayer/BlackScreen
@onready var developer_logo: TextureRect = $IntroLayer/DeveloperLogo

@onready var menu_buttons: Array[Button] = [
	$Content/Buttons/GridContainer3/NewGameButton,
	$Content/Buttons/GridContainer/ContinueButton,
	$Content/Buttons/GridContainer/SettingsButton,
	$Content/Buttons/GridContainer2/QuitButton
]

var menu_ready: bool = false

func _ready() -> void:
	EnvironmentManager.is_outdoor = is_outdoor
	hover_audio.stream = hover_sound
	press_audio.stream = press_sound

	_setup_intro()

	await _play_intro()

	menu_ready = true

func _on_button_mouse_entered() -> void:
	if hover_audio.stream == null or is_quitting == true:
		return

	hover_audio.play()


func _on_new_game_button_pressed() -> void:
	_play_press_sound()
	EasyTransition.transition_to_path("uid://d3ypiu36avnv1",1.0,EasyTransition.TransitionAnim.CURTAIN)


func _on_continue_button_pressed() -> void:
	content.visible = false
	
	save_load_menu = save_load_scene.instantiate() as SaveLoadMenu
	get_tree().current_scene.call_deferred("add_child", save_load_menu)
	
	# Used for synchronization
	await get_tree().create_timer(0.1).timeout
	
	# Used to exit the new scene
	for child in get_children():
		if child.name == save_load_menu.name:
			child.save_load_menu_exit.connect(_return_from_menus)
	
	_on_mouse_pressed()



func _on_settings_button_pressed() -> void:
	_on_mouse_pressed()
	content.visible = false 
	var settings = settings_scene.instantiate()
	add_child(settings)


func _on_quit_button_pressed() -> void:
	_play_press_sound_and_quit()


func _disable_buttons() -> void:
	new_game_button.disabled = true
	continue_button.disabled = true
	settings_button.disabled = true
	quit_button.disabled = true


func _on_mouse_pressed() -> void:
	if press_audio == null:
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
