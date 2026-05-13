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

@onready var new_game_button: Button = $Content/Buttons/NewGameButton
@onready var continue_button: Button = $Content/Buttons/ContinueButton
@onready var settings_button: Button = $Content/Buttons/SettingsButton
@onready var quit_button: Button = $Content/Buttons/QuitButton
@onready var hover_audio: AudioStreamPlayer = $HoverAudio
@onready var press_audio: AudioStreamPlayer = $PressAudio


func _ready() -> void:
	hover_audio.stream = hover_sound
	press_audio.stream = press_sound


func _on_button_mouse_entered() -> void:
	if hover_audio.stream == null:
		return

	hover_audio.play()


func _on_new_game_button_pressed() -> void:
	print(new_game_button.text)
	_play_press_sound_and_quit()


func _on_continue_button_pressed() -> void:
	print(continue_button.text)
	_play_press_sound_and_quit()


func _on_settings_button_pressed() -> void:
	print(settings_button.text)
	_play_press_sound_and_quit()


func _on_quit_button_pressed() -> void:
	print(quit_button.text)
	_play_press_sound_and_quit()


func _play_press_sound_and_quit() -> void:
	# O jogo espera o som terminar para o clique não ser cortado pelo quit().
	if press_audio.stream != null:
		press_audio.play()
		await press_audio.finished

	get_tree().quit()
