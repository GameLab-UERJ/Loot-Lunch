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

var is_quitting: bool = false

var save_load_menu: SaveLoadMenu
var save_load_scene: PackedScene = preload("res://menus/saver_loader/save_load_menu.tscn")

@onready var new_game_button: Button = $Content/Buttons/NewGameButton
@onready var continue_button: Button = $Content/Buttons/ContinueButton
@onready var settings_button: Button = $Content/Buttons/SettingsButton
@onready var quit_button: Button = $Content/Buttons/QuitButton
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var press_audio: AudioStreamPlayer = $PressAudio
@onready var content: VBoxContainer = $Content


func _ready() -> void:
	EnvironmentManager.is_outdoor = is_outdoor
	hover_audio.stream = hover_sound
	press_audio.stream = press_sound


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
	print(settings_button.text)
	_play_press_sound_and_quit()


func _on_quit_button_pressed() -> void:
	print(quit_button.text)
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
